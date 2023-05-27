unit VideoUnit;

interface

uses
{$IFDEF FPC}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  SysUtils,
{$ELSE}
{$IF CompilerVersion >= 23.0}
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
  System.SysUtils,
{$ELSE}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  SysUtils,
{$IFEND}
{$ENDIF}
  FFUtils,
  FFTypes,
  libavcodec_avfft,
  libavcodec_bsf,
  libavcodec_codec,
  libavcodec_codec_defs,
  libavcodec_codec_desc,
  libavcodec_codec_id,
  libavcodec_codec_par,
  libavcodec_packet,
  libavcodec,
  libavdevice,
  libavfilter,
  libavfilter_buffersink,
  libavfilter_buffersrc,
  libavfilter_formats,
  libavformat,
  libavformat_avio,
  libavformat_url,
  libavutil,
  libavutil_audio_fifo,
  libavutil_avstring,
  libavutil_bprint,
  libavutil_buffer,
  libavutil_channel_layout,
  libavutil_common,
  libavutil_cpu,
  libavutil_dict,
  libavutil_display,
  libavutil_error,
  libavutil_eval,
  libavutil_fifo,
  libavutil_file,
  libavutil_frame,
  libavutil_hwcontext,
  libavutil_imgutils,
  libavutil_log,
  libavutil_mathematics,
  libavutil_md5,
  libavutil_mem,
  libavutil_motion_vector,
  libavutil_opt,
  libavutil_parseutils,
  libavutil_pixdesc,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt,
  libavutil_time,
  libavutil_timestamp,
  libswresample,
  libswscale,
  Winapi.Messages, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.ExtDlgs, Math,
  System.Actions, Vcl.ActnList, Vcl.Menus,
  StrUtils, Vcl.ComCtrls, MainUnit;

const
  STREAM_PIX_FMT = AV_PIX_FMT_YUV420P; (* default pix_fmt *)

  SCALE_FLAGS = SWS_BICUBIC;

type
  // a wrapper around a single output AVStream
  POutputStream = ^TOutputStream;

  TOutputStream = record
    st: PAVStream;
    enc: PAVCodecContext;

    (* pts of the next frame that will be generated *)
    next_pts: Int64;
    samples_count: Integer;

    frame: PAVFrame;
    tmp_frame: PAVFrame;

    tmp_pkt: PAVPacket;

    t, tincr, tincr2: Single;

    sws_ctx: PSwsContext;
    swr_ctx: PSwrContext;
  end;

procedure CreateVideo(FileName: UTF8String; w, h, FrameRate, duration: Integer; BkImage: TBitMap;
  ObjectList: PObjectLI);

implementation

uses
  ProgressViewUnit;

procedure log_packet(const fmt_ctx: PAVFormatContext; const pkt: PAVPacket);
var
  time_base: PAVRational;
begin
  time_base := @PAVStream(PPtrIdx(fmt_ctx.streams, pkt.stream_index)).time_base;
end;

function write_frame(fmt_ctx: PAVFormatContext; c: PAVCodecContext; st: PAVStream; frame: PAVFrame;
  pkt: PAVPacket): Integer;
var
  ret: Integer;
begin
  // send the frame to the encoder
  ret := avcodec_send_frame(c, frame);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  while ret >= 0 do
  begin
    ret := avcodec_receive_packet(c, pkt);
    if (ret = AVERROR_EAGAIN) or (ret = AVERROR_EOF) then
      Break
    else if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    (* rescale output packet timestamp values from codec to stream timebase *)
    av_packet_rescale_ts(pkt, c.time_base, st.time_base);
    pkt.stream_index := st.index;

    (* Write the compressed frame to the media file. *)
    log_packet(fmt_ctx, pkt);
    ret := av_interleaved_write_frame(fmt_ctx, pkt);
    (* pkt is now blank (av_interleaved_write_frame() takes ownership of
      * its contents and resets pkt), so that no unreferencing is necessary.
      * This would be different if one used av_write_frame(). *)
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
  end;

  if ret = AVERROR_EOF then
    Result := 1
  else
    Result := 0;
end;

(* Add an output stream. *)
function add_stream(ost: POutputStream; oc: PAVFormatContext; codec: PPAVCodec; codec_id: TAVCodecID;
  w, h, FrameRate: Integer): Integer;
var
  c: PAVCodecContext;
  i: Integer;
  layout: TAVChannelLayout;
begin
  // AV_CHANNEL_LAYOUT_STEREO
  layout.order := AV_CHANNEL_ORDER_NATIVE;
  layout.nb_channels := 2;
  layout.u.mask := AV_CH_LAYOUT_STEREO;
  layout.opaque := nil;

  (* find the encoder *)
  codec^ := avcodec_find_encoder(codec_id);
  if not Assigned(codec^) then
  begin
    Result := -1;
    Exit;
  end;

  ost.tmp_pkt := av_packet_alloc();
  if not Assigned(ost.tmp_pkt) then
  begin
    Result := -1;
    Exit;
  end;

  ost.st := avformat_new_stream(oc, nil);
  if not Assigned(ost.st) then
  begin
    Result := -1;
    Exit;
  end;
  ost.st.id := oc.nb_streams - 1;
  c := avcodec_alloc_context3(codec^);
  if not Assigned(c) then
  begin
    Result := -1;
    Exit;
  end;
  ost.enc := c;

  if codec^.ttype = AVMEDIA_TYPE_VIDEO then
  begin
    c.codec_id := codec_id;

    c.bit_rate := 20000000;
    (* Resolution must be a multiple of two. *)
    c.width := w;
    c.height := h;
    (* timebase: This is the fundamental unit of time (in seconds) in terms
      * of which frame timestamps are represented. For fixed-fps content,
      * timebase should be 1/framerate and timestamp increments should be
      * identical to 1. *)
    ost.st.time_base.num := 1;
    ost.st.time_base.den := FrameRate;
    c.time_base := ost.st.time_base;

    c.gop_size := 12; (* emit one intra frame every twelve frames at most *)
    c.pix_fmt := STREAM_PIX_FMT;
    if c.codec_id = AV_CODEC_ID_MPEG2VIDEO then
      (* just for testing, we also add B-frames *)
      c.max_b_frames := 2;
    if c.codec_id = AV_CODEC_ID_MPEG1VIDEO then
      (* Needed to avoid using macroblocks in which some coeffs overflow.
        * This does not happen with normal video, it just happens here as
        * the motion of the chroma plane does not match the luma plane. *)
      c.mb_decision := 2;
  end;

  (* Some formats want stream headers to be separate. *)
  if (oc.oformat.flags and AVFMT_GLOBALHEADER) <> 0 then
    c.flags := c.flags or AV_CODEC_FLAG_GLOBAL_HEADER;

  Result := 0;
end;

(* ************************************************************ *)
(* video output *)

function alloc_picture(pix_fmt: TAVPixelFormat; width, height: Integer): PAVFrame;

var
  picture: PAVFrame;
  ret: Integer;
begin
  picture := av_frame_alloc();
  if not Assigned(picture) then
  begin
    Result := nil;
    Exit;
  end;

  picture.Format := Ord(pix_fmt);
  picture.width := width;
  picture.height := height;

  (* allocate the buffers for the frame data *)
  ret := av_frame_get_buffer(picture, 0);
  if ret < 0 then
  begin
    Result := nil;
    Exit;
  end;

  Result := picture;
end;

function open_video(oc: PAVFormatContext; codec: PAVCodec; ost: POutputStream; opt_arg: PAVDictionary): Integer;

var
  ret: Integer;
  c: PAVCodecContext;
  opt: PAVDictionary;
begin
  c := ost.enc;
  opt := nil;

  av_dict_copy(@opt, opt_arg, 0);

  (* open the codec *)
  ret := avcodec_open2(c, codec, @opt);
  av_dict_free(@opt);
  if ret < 0 then
  begin
    Result := -1;
    Exit;
  end;

  (* allocate and init a re-usable frame *)
  ost.frame := alloc_picture(c.pix_fmt, c.width, c.height);
  if not Assigned(ost.frame) then
  begin
    Result := -1;
    Exit;
  end;

  (* If the output format is not YUV420P, then a temporary YUV420P
    * picture is needed too. It is then converted to the required
    * output format. *)
  ost.tmp_frame := nil;
  if c.pix_fmt <> AV_PIX_FMT_YUV420P then
  begin
    ost.tmp_frame := alloc_picture(AV_PIX_FMT_YUV420P, c.width, c.height);
    if not Assigned(ost.tmp_frame) then
    begin
      Result := -1;
      Exit;
    end;
  end;

  (* copy the stream parameters to the muxer *)
  ret := avcodec_parameters_from_context(ost.st.codecpar, c);
  if ret < 0 then
  begin
    Result := -1;
    Exit;
  end;

  Result := 0;
end;

function fill_rgb24_image(pict: PAVFrame; frame_index, width, heigth: Integer; bmp: TBitMap): Integer;
var
  w, h: Integer;
  x, y, i, j: Integer;
  InfoHeaderSize, ImageSize: Cardinal;
  MemBits: packed array of byte;
  MemBitMapInfo: packed array of byte;
begin
  i := frame_index;

  w := bmp.width;
  h := bmp.height;

  GetDIBSizes(bmp.Handle, InfoHeaderSize, ImageSize);
  SetLength(MemBitMapInfo, InfoHeaderSize);
  SetLength(MemBits, ImageSize);
  GetDIB(bmp.Handle, bmp.Palette, MemBitMapInfo[0], MemBits[0]);

  j := 0;
  for y := heigth - 3 downto 0 do
    for x := 0 to width - 1 do
    begin
      PByte(@PAnsiChar(pict.data[0])[y * pict.linesize[0] + (x * 3)])^ := MemBits[j * 4 + 2];
      PByte(@PAnsiChar(pict.data[0])[y * pict.linesize[0] + (x * 3 + 1)])^ := MemBits[(j * 4 + 1)];
      PByte(@PAnsiChar(pict.data[0])[y * pict.linesize[0] + (x * 3 + 2)])^ := MemBits[(j * 4)];
      Inc(j);
    end;
  Result := 0;
  MemBitMapInfo := nil;
  MemBits := nil;
end;

function get_video_frame(ost: POutputStream; frame: PPAVFrame; duration: Integer; bmp: TBitMap): Integer;
var
  c: PAVCodecContext;
  linesize: PInteger;
  rgbframe: PAVFrame;
begin
  c := ost.enc;

  rgbframe := alloc_picture(AV_PIX_FMT_RGB24, c.width, c.height);
  fill_rgb24_image(rgbframe, 0, c.width, c.height, bmp);

  (* check if we want to generate more frames *)
  if av_compare_ts(ost.next_pts, ost.enc.time_base, duration, av_make_q(1, 1)) > 0 then
  begin
    frame^ := nil;
    Result := 0;
    Exit;
  end;

  (* when we pass a frame to the encoder, it may keep a reference to it
    * internally; make sure we do not overwrite it here *)
  if av_frame_make_writable(ost.frame) < 0 then
  begin
    Result := -1;
    Exit;
  end;

  ost.sws_ctx := sws_getContext(c.width, c.height, AV_PIX_FMT_RGB24, c.width, c.height, AV_PIX_FMT_YUV420P, 0, 0, 0, 0);
  sws_scale(ost.sws_ctx, @rgbframe.data[0], @rgbframe.linesize[0], 0, c.height, @ost.frame.data[0],
    @ost.frame.linesize[0]);

  ost.frame.pts := ost.next_pts;
  Inc(ost.next_pts);

  frame^ := ost.frame;
  av_frame_free(@rgbframe);
  Result := 0;
end;

(*
  * encode one video frame and send it to the muxer
  * return 1 when encoding is finished, 0 otherwise
*)
function write_video_frame(oc: PAVFormatContext; ost: POutputStream; duration: Integer; bmp: TBitMap): Integer;
var
  frame: PAVFrame;
begin
  if get_video_frame(ost, @frame, duration, bmp) < 0 then
  begin
    Result := -1;
    Exit;
  end;
  Result := write_frame(oc, ost.enc, ost.st, frame, ost.tmp_pkt);
end;

procedure close_stream(oc: PAVFormatContext; ost: POutputStream);
begin
  avcodec_free_context(@ost.enc);
  av_frame_free(@ost.frame);
  av_frame_free(@ost.tmp_frame);
  sws_freeContext(ost.sws_ctx);
  swr_free(@ost.swr_ctx);
end;

(* ************************************************************ *)
(* media file output *)

procedure CreateVideo(FileName: UTF8String; w, h, FrameRate, duration: Integer; BkImage: TBitMap;
  ObjectList: PObjectLI);
var
  VideoStream: TOutputStream;
  outFmt: PAVOutputFormat;
  outContext: PAVFormatContext;
  VideoCodec: PAVCodec;
  ret: Integer;
  EncodeVideo: Integer;
  opt: PAVDictionary;
  i: Integer;
  buff: TBitMap;
  IsEnd: Boolean;
  CurrTime: Single;
begin
  ProgressForm.Show;

  Set8087CW($133F); { Disable all fpu exceptions }
  opt := nil;
  FillChar(VideoStream, SizeOf(VideoStream), 0);
  EncodeVideo := 0;
  avformat_alloc_output_context2(@outContext, nil, 'mpeg', PAnsiChar(AnsiString(FileName)));
  outFmt := outContext.oformat;
  buff := TBitMap.Create;
  buff.SetSize(BkImage.width, BkImage.height);

  (* Add the audio and video streams using the default format codecs
    * and initialize the codecs. *)
  if outFmt.video_codec <> AV_CODEC_ID_NONE then
  begin
    if add_stream(@VideoStream, outContext, @VideoCodec, outFmt.video_codec, w, h, FrameRate) < 0 then
      Exit;
    EncodeVideo := 1;
  end;

  (* Now that all the parameters are set, we can open the audio and
    * video codecs and allocate the necessary encode buffers. *)
  if open_video(outContext, VideoCodec, @VideoStream, opt) < 0 then
    Exit;

  av_dump_format(outContext, 0, PAnsiChar(AnsiString(FileName)), 1);
  (* open the output file, if needed *)
  if (outFmt.flags and AVFMT_NOFILE) = 0 then
  begin
    ret := avio_open(@outContext.pb, PAnsiChar(AnsiString(FileName)), AVIO_FLAG_WRITE);
    if ret < 0 then
      Exit;
  end;

  (* Write the stream header, if any. *)
  ret := avformat_write_header(outContext, @opt);
  if ret < 0 then
    Exit;

  CurrTime := 0;

  while (EncodeVideo <> 0) do
  begin
    if duration <> 0 then
      ProgressForm.gProgress.Progress := Round(CurrTime / 1000 / duration * 100);
    buff.Canvas.StretchDraw(Rect(0, 0, BkImage.width, BkImage.height), BkImage);
    IsEnd := True;
    TMainForm.DrawFrame(ObjectList, buff, IsEnd, CurrTime);
    EncodeVideo := write_video_frame(outContext, @VideoStream, duration, buff);
    if EncodeVideo < 0 then
    begin
      ProgressForm.Close;
      Exit;
    end;
    EncodeVideo := 1 - EncodeVideo;
    CurrTime := CurrTime + 1000 / FrameRate;
    Sleep(0);
  end;
  av_write_trailer(outContext);

  (* Close each codec. *)
  close_stream(outContext, @VideoStream);

  if (outFmt.flags and AVFMT_NOFILE) = 0 then
    (* Close the output file. *)
    avio_closep(@outContext.pb);

  (* free the stream *)
  avformat_free_context(outContext);

  ProgressForm.Close;
end;

end.

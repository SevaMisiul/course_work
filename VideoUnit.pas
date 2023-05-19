unit VideoUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs, Math,
  System.Actions, Vcl.ActnList, Vcl.Menus,
  StrUtils, Vcl.ComCtrls, MainUnit, vfw;

type
  AVI_COMPRESS_OPTIONS = packed record
    fccType: DWORD; // stream type, for consistency
    fccHandler: DWORD; // compressor
    dwKeyFrameEvery: DWORD; // keyframe rate
    dwQuality: DWORD; // compress quality 0-10,000
    dwBytesPerSecond: DWORD; // bytes per second
    dwFlags: DWORD; // flags... see below
    lpFormat: DWORD; // save format
    cbFormat: DWORD;
    lpParms: DWORD; // compressor options
    cbParms: DWORD;
    dwInterleaveEvery: DWORD; // for non-video streams only
  end;

  AVI_STREAM_INFO = packed record
    fccType: DWORD;
    fccHandler: DWORD;
    dwFlags: DWORD;
    dwCaps: DWORD;
    wPriority: word;
    wLanguage: word;
    dwScale: DWORD;
    dwRate: DWORD;
    dwStart: DWORD;
    dwLength: DWORD;
    dwInitialFrames: DWORD;
    dwSuggestedBufferSize: DWORD;
    dwQuality: DWORD;
    dwSampleSize: DWORD;
    rcFrame: TRect;
    dwEditCount: DWORD;
    dwFormatChangeCount: DWORD;
    szName: array [0 .. 63] of char;
  end;

function mmioStringToFOURCCA(sz: PChar; uFlags: DWORD): integer; stdcall;
  external 'winmm.dll';

procedure CreateAviFile(FileName: string; ObjectList: PObjectLI;
  var BkImage: TBitMap; FramesPerSecond: integer);

implementation

procedure CreateAviFile(FileName: string; ObjectList: PObjectLI;
  var BkImage: TBitMap; FramesPerSecond: integer);
var
  avifile: PAviFile;
  AVIStream, AVIComprStream: PAviStream;
  AVIStreamInfo: TAviStreamInfo;
  AVICompressInfo: TAviCompressOptions;
  InfoHeaderSize, ImageSize: Cardinal;
  biSizeImage, biHeight, biWidth: DWORD;
  MemBits: packed array of byte;
  MemBitMapInfo: packed array of byte;
  Buff: TBitMap;
  IsEnd: boolean;
  CurrTime: integer;
begin
  DeleteFile(FileName);
  Fillchar(AVICompressInfo, SizeOf(TAviCompressOptions), 0);
  Fillchar(AVIStreamInfo, SizeOf(TAviStreamInfo), 0);
  AVICompressInfo.fccHandler := mmioFOURCC('D', 'I', 'B', ' ');
  // Full frames Uncompressed
  AVIFileInit;

  if AVIFileOpenW(avifile, '123.avi', OF_CREATE, nil) = 0 then
  begin
    Buff := TBitMap.Create;
    Buff.SetSize(BkImage.Width, BkImage.Height);

    GetDIBSizes(BkImage.Handle, InfoHeaderSize, ImageSize);
    SetLength(MemBitMapInfo, InfoHeaderSize);
    SetLength(MemBits, ImageSize);
    GetDIB(BkImage.Handle, BkImage.Palette, MemBitMapInfo[0], MemBits[0]);

    biSizeImage := MemBitMapInfo[20] + MemBitMapInfo[21] shl 8 + MemBitMapInfo
      [22] shl 16 + MemBitMapInfo[23] shl 24;
    biHeight := MemBitMapInfo[4] + MemBitMapInfo[5] shl 8 + MemBitMapInfo[6]
      shl 16 + MemBitMapInfo[7] shl 24;
    biWidth := MemBitMapInfo[8] + MemBitMapInfo[9] shl 8 + MemBitMapInfo[10]
      shl 16 + MemBitMapInfo[11] shl 24;

    AVIStreamInfo.fccType := streamtypeVIDEO; // stream type video
    AVIStreamInfo.fccHandler := 0; // def AVI handler
    AVIStreamInfo.dwScale := 1;
    AVIStreamInfo.dwRate := FramesPerSecond; // fps 1 to 30
    AVIStreamInfo.dwSuggestedBufferSize := biSizeImage; // size of 1 frame
    SetRect(AVIStreamInfo.rcFrame, 0, 0, biWidth, biHeight);

    if AVIFileCreateStream(avifile, AVIStream, @AVIStreamInfo) = 0 then
    begin
      if AVIMakeCompressedStream(AVIComprStream, AVIStream,
        @AVICompressInfo, nil) = AVIERR_OK then
      begin
        if AVIStreamSetFormat(AVIComprStream, 0, @MemBitMapInfo[0],
          length(MemBitMapInfo)) = 0 then
        begin
          CurrTime := 0;
          repeat
            Buff.Canvas.StretchDraw(Rect(0, 0, BkImage.Width,
              BkImage.Height), BkImage);

            IsEnd := True;
            TMainForm.DrawFrame(ObjectList, Buff, IsEnd, CurrTime);
            GetDIBSizes(Buff.Handle, InfoHeaderSize, ImageSize);
            SetLength(MemBitMapInfo, InfoHeaderSize);
            SetLength(MemBits, ImageSize);
            GetDIB(Buff.Handle, Buff.Palette, MemBitMapInfo[0], MemBits[0]);

            biSizeImage := MemBitMapInfo[20] + MemBitMapInfo[21] shl 8 +
              MemBitMapInfo[22] shl 16 + MemBitMapInfo[23] shl 24;

            if AVIStreamWrite(AVIComprStream,
              CurrTime div (1000 div FramesPerSecond), 1, @MemBits[0],
              biSizeImage, AVIIF_KEYFRAME, 0, 0) <> 0 then
            begin
              ShowMessage('Error during Write AVI File');
              break;
            end;
            Inc(CurrTime, 1000 div FramesPerSecond);
          until IsEnd;
        end;
      end;
    end;
    AVIStreamRelease(AVIComprStream);
    AVIStreamRelease(AVIStream);
    AVIFileRelease(avifile);
    Buff.Destroy;
  end;
  AVIFileExit;
  MemBitMapInfo := nil;
  MemBits := nil;
end;

end.

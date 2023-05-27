unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs, Math,
  System.Actions, Vcl.ActnList, Vcl.Menus,
  ObjectUnit, StrUtils, ActionEditUnit, Vcl.ComCtrls, System.ImageList,
  Vcl.ImgList;

type
  TObjectIcon = class(TImage)
    procedure ObjectIconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private const
    SpaceLeft = 10;
    SpaceTop = 20;
    ObjectHeight = 90;
    ObjectWidth = 190;
  private
    FIsPng: Boolean;
  public
    constructor Create(AOwner: TComponent; Y: Integer; ImgPath: string);
    destructor Destroy; override;
    { properties }
    property IsPng: Boolean read FIsPng write FIsPng;
  end;

  PObjectLI = ^TObjectLI;

  TObjectLI = record
    ObjectImage: TObjectImage;
    Next: PObjectLI;
  end;

  TMainForm = class(TForm)
    btnCreateAnimation: TButton;
    scrlbObjects: TScrollBox;
    imgPanelOpen: TImage;
    OpenObjectIconDialog: TOpenPictureDialog;
    imgPanelClose: TImage;
    MainMenu: TMainMenu;
    RunAnimation1: TMenuItem;
    alMenuActions: TActionList;
    actRunAnimation: TAction;
    SaveVideoDialog: TSaveDialog;
    menuFile: TMenuItem;
    actSaveVideoAs: TAction;
    Savevideo1: TMenuItem;
    menuRun: TMenuItem;
    actSaveVideo: TAction;
    Savevideo2: TMenuItem;
    imglIcons: TImageList;
    actStopAnimation: TAction;
    Stopanimation1: TMenuItem;
    procedure btnCreateAnimationClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure AddImgClick(Sender: TObject);
    procedure imgPanelOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure scrlbObjectsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure scrlbObjectsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormClick(Sender: TObject);
    procedure FormDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure FormDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure imgPanelCloseClick(Sender: TObject);
    procedure actRunAnimationExecute(Sender: TObject);
    procedure Animation(Sender: TObject);
    procedure actSaveVideoAsExecute(Sender: TObject);
    procedure actSaveVideoExecute(Sender: TObject);
    procedure SaveVideoDialogCanClose(Sender: TObject; var CanClose: Boolean);
    procedure actStopAnimationExecute(Sender: TObject);
  private
    FAnimationBuff: TBitMap;
    FBackPict: TPicture;
    FIsFirstSave: Boolean;
    FLastUpdate, FRunTime: Cardinal;
    FObjectList: PObjectLI;
    FSelectedPicture: TPicture;
    FWaitingClickToCreate, FIsSelectedPng: Boolean;
    FAddObjectIcon: TImage;
    FObjectPanelTop: Integer;
    FLastClick: TPoint;
    FObjectFileNames: System.TArray<string>;
    procedure Start;
    procedure SwitchPanel;
    procedure PrepareSaveVideo(var bmp: TBitMap; var Duration: Integer);
    procedure SetMenu(Mode: Boolean);
    procedure CompleteAnimation;
  public
    destructor Destroy; override;
    procedure AddObject(Obj: TObjectImage);
    class procedure DrawFrame(Tmp: PObjectLI; Buff: TBitMap; var IsEnd: Boolean; CurrTime: Single);
    { properties }
    property ObjectList: PObjectLI read FObjectList write FObjectList;
    property ObjectPanelTop: Integer read FObjectPanelTop write FObjectPanelTop;
  end;

const
  VideoExtensions: array [1 .. 2] of string = ('*.mp4', '*.avi');

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  VideoUnit;

procedure TMainForm.actRunAnimationExecute(Sender: TObject);
var
  Tmp: PObjectLI;
begin
  scrlbObjects.Visible := False;
  imgPanelOpen.Visible := False;
  Tmp := ObjectList;
  while Tmp <> nil do
  begin
    with Tmp^.ObjectImage do
    begin
      CurrX := Left + Width div 2;
      CurrY := Top + Height div 2;
      AnimatedPicture.Assign(OriginPicture);
      if ActionList[0] <> nil then
      begin
        CurrAction := ActionList[0];
        with CurrAction^.Info do
        begin
          if (StartWidth = EndWidth) and (StartHeight = EndHeight) then
            TObjectImage.Resize(AnimatedPicture, StartWidth, StartHeight, IsPng);
          if (StartAngle = EndAngle) and (StartWidth = EndWidth) and (StartHeight = EndHeight) then
            TObjectImage.Rotate(AnimatedPicture, StartAngle, IsPng);
        end;
      end
      else
      begin
        TObjectImage.Resize(AnimatedPicture, ExplicitW, ExplicitH, IsPng);
        TObjectImage.Rotate(AnimatedPicture, Angle, IsPng);
      end;
      Visible := False;
    end;
    Tmp := Tmp^.Next;
  end;
  FAnimationBuff.SetSize(ClientWidth, ClientHeight);
  OnPaint := Animation;
  FRunTime := GetTickCount;
  FLastUpdate := 0;
  Self.Invalidate;
end;

procedure TMainForm.actSaveVideoAsExecute(Sender: TObject);
var
  bmp: TBitMap;
  Tmp: PObjectLI;
  Duration: Integer;
begin
  PrepareSaveVideo(bmp, Duration);

  if SaveVideoDialog.Execute then
  begin
    CreateVideo(SaveVideoDialog.FileName, bmp.Width, bmp.Height, 60, Duration div 1000, bmp, ObjectList);
    FIsFirstSave := False;
  end;
  bmp.Destroy;
end;

procedure TMainForm.actSaveVideoExecute(Sender: TObject);
var
  bmp: TBitMap;
  Tmp: PObjectLI;
  Duration: Integer;
begin
  PrepareSaveVideo(bmp, Duration);

  if FIsFirstSave then
    actSaveVideoAsExecute(Sender)
  else
    CreateVideo(SaveVideoDialog.FileName, bmp.Width, bmp.Height, 60, Duration div 1000, bmp, ObjectList);
  bmp.Destroy;
end;

procedure TMainForm.actStopAnimationExecute(Sender: TObject);
begin
  CompleteAnimation;
  Invalidate;
end;

procedure TMainForm.AddImgClick(Sender: TObject);
var
  FilePath, FileExtension, Rever: string;
  Tmp: TObjectIcon;
begin
  if OpenObjectIconDialog.Execute then
    if FileExists(OpenObjectIconDialog.FileName) then
    begin
      Rever := ReverseString(OpenObjectIconDialog.FileName);
      FileExtension := ReverseString(Copy(Rever, 1, Pos('.', Rever)));
      FilePath := 'objects\' + IntToStr(scrlbObjects.ControlCount - 1) + FileExtension;
      CopyFile(PChar(OpenObjectIconDialog.FileName), PChar(FilePath), False);

      TObjectIcon.Create(scrlbObjects, ObjectPanelTop - scrlbObjects.VertScrollBar.Position, FilePath);
      ObjectPanelTop := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;

      FAddObjectIcon.Top := ObjectPanelTop - scrlbObjects.VertScrollBar.Position;

      scrlbObjects.VertScrollBar.Range := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
    end
    else
      raise Exception.Create('File does not exist.');
end;

procedure TMainForm.AddObject(Obj: TObjectImage);
var
  Tmp: PObjectLI;
begin
  New(Tmp);
  Tmp^.ObjectImage := Obj;
  Tmp^.Next := ObjectList;
  ObjectList := Tmp;
end;

procedure TMainForm.Animation(Sender: TObject);
var
  Tmp: PObjectLI;
  CurrTime: Cardinal;
  IsEnd: Boolean;
begin
  CurrTime := GetTickCount - FRunTime;
  FAnimationBuff.Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), FBackPict.Graphic);
  Tmp := ObjectList;
  IsEnd := True;
  TMainForm.DrawFrame(Tmp, FAnimationBuff, IsEnd, CurrTime);
  Canvas.Draw(0, 0, FAnimationBuff);
  if IsEnd then
    CompleteAnimation;
  FLastUpdate := CurrTime;
  Sleep(0);
  Invalidate;
end;

procedure TMainForm.btnCreateAnimationClick(Sender: TObject);
var
  Res: Integer;
begin
  Res := BackMenuForm.ShowForSelection(FBackPict);

  if Res = mrOk then
  begin
    btnCreateAnimation.Visible := False;
    Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));

    TObjectImage.Resize(FBackPict, ClientWidth, ClientHeight, False, True);
    Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), FBackPict.Graphic);

    SetMenu(True);
    Start;

    imgPanelOpen.Visible := True;
    imgPanelOpen.Top := ClientHeight div 2 - imgPanelOpen.Height;
  end;
end;

procedure TMainForm.CompleteAnimation;
var
  Tmp: PObjectLI;
begin
  imgPanelOpen.Visible := True;
  Tmp := ObjectList;
  while Tmp <> nil do
  begin
    Tmp^.ObjectImage.Visible := True;
    Tmp := Tmp^.Next;
  end;
  OnPaint := FormPaint;
end;

destructor TMainForm.Destroy;
var
  Tmp1, Tmp2: PObjectLI;
begin
  FBackPict.Free;
  FObjectFileNames := nil;
  FAnimationBuff.Destroy;

  Tmp1 := ObjectList;
  while Tmp1 <> nil do
  begin
    Tmp2 := Tmp1;
    Tmp1 := Tmp1^.Next;
    Tmp2^.ObjectImage.Destroy;
  end;

  inherited Destroy;
end;

class procedure TMainForm.DrawFrame(Tmp: PObjectLI; Buff: TBitMap; var IsEnd: Boolean; CurrTime: Single);
var
  PixelTime, Alpha, CurrAlpha, NX, NY, TimeRatio: Extended;
  dltH, dltW: Integer;
  TmpPict: TPicture;
begin
  TmpPict := TPicture.Create;
  while Tmp <> nil do
    with Tmp^.ObjectImage, CurrAction^.Info do
    begin
      if (CurrAction <> nil) and (CurrAction^.Next <> nil) and (CurrTime >= CurrAction^.Next^.Info.TimeStart) then
      begin
        AnimatedPicture.Assign(OriginPicture);
        CurrAction := CurrAction^.Next;
        if (StartWidth = EndWidth) and (StartHeight = EndHeight) then
          TObjectImage.Resize(AnimatedPicture, StartWidth, StartHeight, IsPng);
        if (StartAngle = StartWidth) and (StartWidth = EndWidth) and (StartHeight = EndHeight) then
          TObjectImage.Rotate(AnimatedPicture, StartAngle, IsPng);
      end
      else if (CurrAction <> nil) and (CurrAction^.Next = nil) and (CurrTime >= TimeEnd) then
      begin
        CurrAction := CurrAction^.Next;
        TObjectImage.Resize(AnimatedPicture, EndWidth, EndHeight, IsPng);
        TObjectImage.Rotate(AnimatedPicture, EndAngle, IsPng);
      end;
      TmpPict.Assign(AnimatedPicture);
      IsEnd := IsEnd and (CurrAction = nil);
      if (CurrAction <> nil) and (CurrTime >= TimeStart) then
      begin
        TimeRatio := (CurrTime - TimeStart) / (TimeEnd - TimeStart);
        if ActType = actLineMove then
        begin
          CurrX := StartPoint.X + (EndPoint.X - StartPoint.X) * TimeRatio;
          CurrY := StartPoint.Y + (EndPoint.Y - StartPoint.Y) * TimeRatio;
        end
        else if ActType = actCircleMove then
        begin
          Alpha := ArcCos((R1X * R2X + R1Y * R2Y) / (sqr(Radius)));
          CurrAlpha := Alpha * TimeRatio;
          if R1X * R2Y - R1Y * R2X < 0 then
          begin
            NX := CircleCenterX - (R1X * Cos(CurrAlpha) + R1Y * Sin(CurrAlpha));
            NY := CircleCenterY - (-R1X * Sin(CurrAlpha) + R1Y * Cos(CurrAlpha));
          end
          else
          begin
            NX := CircleCenterX - (R1X * Cos(CurrAlpha) - R1Y * Sin(CurrAlpha));
            NY := CircleCenterY - (R1X * Sin(CurrAlpha) + R1Y * Cos(CurrAlpha));
          end;
          CurrX := NX;
          CurrY := NY;
        end;
        if (StartHeight <> EndHeight) or (StartWidth <> EndWidth) then
        begin
          dltH := Round((EndHeight - StartHeight) * TimeRatio);
          dltW := Round((EndWidth - StartWidth) * TimeRatio);
          Resize(TmpPict, StartWidth + dltW, StartHeight + dltH, IsPng);
        end;
        if (StartHeight <> EndHeight) or (StartWidth <> EndWidth) or (StartAngle <> EndAngle) then
          Rotate(TmpPict, StartAngle + Round((EndAngle - StartAngle) * TimeRatio), IsPng);
      end;
      Buff.Canvas.Draw(Round(CurrX) - TmpPict.Width div 2, Round(CurrY) - TmpPict.Height div 2, TmpPict.Graphic);
      Tmp := Tmp^.Next;
    end;
  TmpPict.Destroy;
end;

procedure TMainForm.FormClick(Sender: TObject);
var
  MousePos: TPoint;
begin
  if FWaitingClickToCreate then
  begin
    GetCursorPos(MousePos);
    MousePos := ScreenToClient(MousePos);
    TObjectImage.Create(Self, MousePos.X - Left, MousePos.Y - Top, FSelectedPicture, FIsSelectedPng);
    FWaitingClickToCreate := False;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Tmp: TImage;
  P: TPoint;
begin
  P := ScreenToClient(Point((Screen.Width - btnCreateAnimation.Width) div 2,
    (Screen.Height - btnCreateAnimation.Height) div 2));

  btnCreateAnimation.Top := P.Y;
  btnCreateAnimation.Left := P.X;

  SetMenu(False);
  FBackPict := nil;
  FAnimationBuff := TBitMap.Create;
  FObjectList := nil;
end;

procedure TMainForm.FormDragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if Source is TObjectIcon then
  begin
    TObjectImage.Create(Self, X, Y, FSelectedPicture, FIsSelectedPng);
    FWaitingClickToCreate := False;
  end
  else
  begin
    (Source as TObjectImage).Left := X - (Source as TObjectImage).Width div 2;
    (Source as TObjectImage).Top := Y - (Source as TObjectImage).Height div 2;
  end;
end;

procedure TMainForm.FormDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source is TObjectIcon) or (Source is TObjectImage);
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  if FBackPict <> nil then
    Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), FBackPict.Graphic);
end;

procedure TMainForm.imgPanelCloseClick(Sender: TObject);
begin
  SwitchPanel;
end;

procedure TMainForm.imgPanelOpenClick(Sender: TObject);
begin
  SwitchPanel;
end;

procedure TMainForm.PrepareSaveVideo(var bmp: TBitMap; var Duration: Integer);
var
  Tmp: PObjectLI;
begin
  bmp := TBitMap.Create;
  bmp.SetSize(ClientWidth, ClientHeight);
  bmp.Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), FBackPict.Graphic);
  Tmp := ObjectList;
  Duration := 0;
  while Tmp <> nil do
  begin
    with Tmp^.ObjectImage do
    begin
      CurrX := Left + Width div 2;
      CurrY := Top + Height div 2;
      AnimatedPicture.Assign(OriginPicture);
      if ActionList[0] <> nil then
      begin
        CurrAction := ActionList[0];
        with CurrAction^.Info do
        begin
          if (StartWidth = EndWidth) and (StartHeight = EndHeight) then
            TObjectImage.Resize(AnimatedPicture, StartWidth, StartHeight, IsPng);
          if (StartAngle = EndAngle) and (StartWidth = EndWidth) and (StartHeight = EndHeight) then
            TObjectImage.Rotate(AnimatedPicture, StartAngle, IsPng);
        end;
      end
      else
      begin
        TObjectImage.Resize(AnimatedPicture, ExplicitW, ExplicitH, IsPng);
        TObjectImage.Rotate(AnimatedPicture, Angle, IsPng);
      end;
      Duration := max(Duration, EndActionList^.Info.TimeEnd);
    end;
    Tmp := Tmp^.Next;
  end;
end;

procedure TMainForm.SaveVideoDialogCanClose(Sender: TObject; var CanClose: Boolean);
var
  btnSelected: Integer;
begin
  btnSelected := mrYes;
  if FileExists(SaveVideoDialog.FileName) then
    btnSelected := MessageDlg('File already exists. Overwrite it?', mtConfirmation, [mbYes, mbNo], 0);
  CanClose := btnSelected = mrYes;
end;

procedure TMainForm.scrlbObjectsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint;
  var Handled: Boolean);
begin
  scrlbObjects.VertScrollBar.Position := scrlbObjects.VertScrollBar.Position +
    Integer(scrlbObjects.VertScrollBar.Increment);
end;

procedure TMainForm.scrlbObjectsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint;
  var Handled: Boolean);
begin
  scrlbObjects.VertScrollBar.Position := scrlbObjects.VertScrollBar.Position -
    Integer(scrlbObjects.VertScrollBar.Increment);
end;

procedure TMainForm.SetMenu(Mode: Boolean);
begin
  menuFile.Enabled := Mode;
  menuRun.Enabled := Mode;
  actRunAnimation.Enabled := Mode;
  actSaveVideoAs.Enabled := Mode;
  actSaveVideo.Enabled := Mode;
end;

procedure TMainForm.Start;
var
  Path, Extn: string;
begin
  FIsFirstSave := True;
  DoubleBuffered := True;
  CreateDir('backgrounds');
  CreateDir('Icons');
  CreateDir('objects');

  SaveVideoDialog.Filter := '';
  for Extn in VideoExtensions do
    SaveVideoDialog.Filter := SaveVideoDialog.Filter + 'Video ' + Copy(Extn, 3) + '|' + Extn + '|';
  SaveVideoDialog.Filter := SaveVideoDialog.Filter + 'Any file|*.*';
  SaveVideoDialog.FileName := 'Video';
  SaveVideoDialog.DefaultExt := '.mp4';
  SaveVideoDialog.FilterIndex := 1;

  FObjectFileNames := TDirectory.GetFiles('objects');
  ObjectPanelTop := 20;
  FWaitingClickToCreate := False;

  for Path in FObjectFileNames do
  begin
    TObjectIcon.Create(scrlbObjects, ObjectPanelTop, Path);
    ObjectPanelTop := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
  end;

  FAddObjectIcon := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, 'icons\addicon.png');
  FAddObjectIcon.OnClick := AddImgClick;
  FAddObjectIcon.OnMouseDown := nil;

  scrlbObjects.VertScrollBar.Range := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;

end;

procedure TMainForm.SwitchPanel;
begin
  if scrlbObjects.Visible = False then
  begin
    imgPanelOpen.Visible := False;
    scrlbObjects.Visible := True;
  end
  else
  begin
    scrlbObjects.Visible := False;
    imgPanelOpen.Visible := True;
  end;
end;

{ TObjectIcon }

constructor TObjectIcon.Create(AOwner: TComponent; Y: Integer; ImgPath: string);
begin
  inherited Create(AOwner);
  OnMouseDown := ObjectIconMouseDown;
  Parent := TWinControl(AOwner);
  Picture.LoadFromFile(ImgPath);
  Proportional := True;
  Center := True;
  Height := ObjectHeight;
  Width := ObjectWidth;
  Top := Y;
  Left := SpaceLeft;
  IsPng := (Copy(ImgPath, Pos('.', ImgPath)) = '.png');
end;

destructor TObjectIcon.Destroy;
begin
  inherited Destroy;
end;

procedure TObjectIcon.ObjectIconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TControl(Sender).BeginDrag(False);
  (Self.Parent.Parent as TMainForm).FIsSelectedPng := TObjectIcon(Sender).IsPng;
  (Self.Parent.Parent as TMainForm).FWaitingClickToCreate := True;
  (Self.Parent.Parent as TMainForm).FSelectedPicture := TImage(Sender).Picture;
  (Self.Parent.Parent as TMainForm).SwitchPanel;
end;

end.

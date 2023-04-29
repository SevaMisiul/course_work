unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs, Math, ObjectOptionsUnit;

type
  TActionType = (actLineMove, actCircleMove);

  TAspectFrac = record
    Width, Height: Integer;
  end;

  TACtionInfo = record
    ActType: TActionType;
    TimeStart, TimeEnd: Integer;
  end;

  PActionLI = ^TActionLI;

  TActionLI = record
    Info: TACtionInfo;
    Next: PActionLI;
  end;

  TPixelArray = array [0 .. 32768] of TRGBTriple;
  PPixelArray = ^TPixelArray;

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
    { properties }
    property IsPng: Boolean read FIsPng write FIsPng;
  end;

  TObjectImage = class(TImage)
    procedure ObjectImageDblClick(Sender: TObject);
    procedure ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FOriginPicture: TPicture;
    FAspectRatio: TAspectFrac;
    FAngle: Integer;
    FActionList: PActionLI;
    FIsPng: Boolean;
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture; IsPngExtension: Boolean);
    procedure Rotate(Angle: Real);
    procedure Resize(NewHeight, NewWidth: Integer; IsProportional: Boolean);
    procedure ViewImage(Pict: TGraphic);
    { properties }
    property Angle: Integer read FAngle write FAngle;
    property AspectRatio: TAspectFrac read FAspectRatio;
    property OriginPicture: TPicture read FOriginPicture;
    property IsPng: Boolean read FIsPng;
  end;

  TMainForm = class(TForm)
    btnCreateAnimation: TButton;
    scrlbObjects: TScrollBox;
    imgPanelOpen: TImage;
    OpenObjectIconDialog: TOpenPictureDialog;
    imgPanelClose: TImage;
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
  private
    FSelectedPicture: TPicture;
    FWaitingFormClick, FIsSelectedPng: Boolean;
    FAddObjectIcon: TImage;
    FObjectPanelTop: Integer;
    FObjectFileNames: System.TArray<string>;
    procedure SwitchPanel;
  public
    property ObjectPanelTop: Integer read FObjectPanelTop write FObjectPanelTop;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

function GCD(A, B: Integer): Integer;
begin
  if B = 0 then
    result := A
  else
    result := GCD(B, A mod B);
end;

procedure ReduceFraction(var Frac: TAspectFrac);
var
  Tmp: Integer;
begin
  Tmp := GCD(Frac.Width, Frac.Height);
  Frac.Width := Frac.Width div Tmp;
  Frac.Height := Frac.Height div Tmp;
end;

procedure TMainForm.AddImgClick(Sender: TObject);
var
  FilePath: string;
  Tmp: TObjectIcon;
begin
  if OpenObjectIconDialog.Execute then
    if FileExists(OpenObjectIconDialog.FileName) then
    begin
      FilePath := 'objects\' + IntToStr(scrlbObjects.ControlCount) + Copy(OpenObjectIconDialog.FileName,
        Pos('.', OpenObjectIconDialog.FileName));
      CopyFile(PChar(OpenObjectIconDialog.FileName), PChar(FilePath), False);

      Tmp := TObjectIcon.Create(scrlbObjects, ObjectPanelTop - scrlbObjects.VertScrollBar.Position, FilePath);
      ObjectPanelTop := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;

      FAddObjectIcon.Top := ObjectPanelTop - scrlbObjects.VertScrollBar.Position;

      scrlbObjects.VertScrollBar.Range := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
    end
    else
      raise Exception.Create('File does not exist.');
end;

procedure TMainForm.btnCreateAnimationClick(Sender: TObject);
begin
  BackMenuForm.ShowModal;
  if BackMenuForm.BkPict <> nil then
  begin
    btnCreateAnimation.Visible := False;
    Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), BackMenuForm.BkPict.Graphic);

    imgPanelOpen.Visible := True;
    imgPanelOpen.Top := ClientHeight div 2 - imgPanelOpen.Height;
  end;
end;

procedure TMainForm.FormClick(Sender: TObject);
var
  MousePos: TPoint;
begin
  if FWaitingFormClick then
  begin
    GetCursorPos(MousePos);
    TObjectImage.Create(Self, MousePos.X, MousePos.Y, FSelectedPicture, FIsSelectedPng);
    FWaitingFormClick := False;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Path: string;
  Tmp: TImage;
begin
  DoubleBuffered := True;
  CreateDir('backgrounds');
  CreateDir('Icons');
  CreateDir('objects');
  FObjectFileNames := TDirectory.GetFiles('objects');
  ObjectPanelTop := 20;
  FWaitingFormClick := False;

  for Path in FObjectFileNames do
  begin
    Tmp := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, Path);
    ObjectPanelTop := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
  end;

  FAddObjectIcon := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, 'icons\addicon.png');
  FAddObjectIcon.OnClick := AddImgClick;
  FAddObjectIcon.DragMode := dmManual;

  scrlbObjects.VertScrollBar.Range := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
end;

procedure TMainForm.FormDragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if Source is TObjectIcon then
  begin
    TObjectImage.Create(Self, X, Y, FSelectedPicture, FIsSelectedPng);
    FWaitingFormClick := False;
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
  if BackMenuForm.BkPict <> nil then
    Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), BackMenuForm.BkPict.Graphic);
end;

procedure TMainForm.imgPanelCloseClick(Sender: TObject);
begin
  SwitchPanel;
end;

procedure TMainForm.imgPanelOpenClick(Sender: TObject);
begin
  SwitchPanel;
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

procedure TObjectIcon.ObjectIconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TControl(Sender).BeginDrag(False);
  (Self.Parent.Parent as TMainForm).FIsSelectedPng := TObjectIcon(Sender).IsPng;
  (Self.Parent.Parent as TMainForm).FWaitingFormClick := True;
  (Self.Parent.Parent as TMainForm).FSelectedPicture := TImage(Sender).Picture;
  (Self.Parent.Parent as TMainForm).SwitchPanel;
end;

{ TObjectImage }

constructor TObjectImage.Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture; IsPngExtension: Boolean);
begin
  inherited Create(AOwner);

  Parent := TWinControl(AOwner);
  Proportional := True;
  Stretch := True;
  Center := True;
  Picture.Assign(Pict);
  Height := Picture.Graphic.Height;
  Width := Picture.Graphic.Width;
  Top := Y - Height div 2;
  Left := X - Width div 2;

  OnDblClick := ObjectImageDblClick;
  OnMouseDown := ObjectImageMouseDown;

  FIsPng := IsPngExtension;
  FActionList := nil;
  FAspectRatio.Width := Width;
  FAspectRatio.Height := Height;
  ReduceFraction(FAspectRatio);
  FOriginPicture := TPicture.Create;
  FOriginPicture.Assign(Pict.Graphic);
end;

procedure TObjectImage.ObjectImageDblClick(Sender: TObject);
begin
  with ObjectOptionsForm do
  begin
    WidthRatio := AspectRatio.Width;
    HeightRatio := AspectRatio.Height;
    chbIsProportional.Checked := Self.Proportional;
    edtHeight.Text := IntToStr(OriginPicture.Graphic.Height);
    edtWidth.Text := IntToStr(OriginPicture.Graphic.Width);
    edtTop.Text := IntToStr(Self.Top + Self.Height div 2);
    edtLeft.Text := IntToStr(Self.Left + Self.Width div 2);
    edtAngle.Text := IntToStr(Self.Angle);
    Pict.Assign(OriginPicture);

    { fill list }

    ShowModal;
    if IsConfirm then
    begin
      // Resize(StrToInt(edtHeight.Text), StrToInt(edtWidth.Text), chbIsProportional.Checked);
      Angle := StrToInt(edtAngle.Text);
      Rotate(Angle);
      Self.Top := StrToInt(edtTop.Text) - Self.Height div 2;
      Self.Left := StrToInt(edtLeft.Text) - Self.Width div 2;
    end;
  end;

end;

procedure TObjectImage.ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Sleep(100);
  if (GetKeyState(VK_LBUTTON) and $8000) <> 0 then
    TControl(Sender).BeginDrag(False);
end;

procedure TObjectImage.Resize(NewHeight, NewWidth: Integer; IsProportional: Boolean);
var
  Bmp: TBitMap;
begin
  Self.Proportional := IsProportional;
  Bmp := TBitMap.Create;
  Bmp.Assign(OriginPicture.Graphic);
  Bmp.Canvas.StretchDraw(Rect(0, 0, NewWidth, NewHeight), Bmp);
  OriginPicture.Assign(Bmp);
  ViewImage(OriginPicture.Graphic);
end;

procedure TObjectImage.Rotate(Angle: Real);
var
  SinRad, CosRad, AngleRad: Real;
  RowSource, RowDest: PPixelArray;
  Y, X, I, DestColorType: Integer;
  SourcePoint, SourceCenter, DestCenter, MaxP, MinP: TPoint;
  Corners: array [1 .. 4] of TPoint;
  SourcePict, DestPict: TPNGObject;
  SourceBmp, DestBmp: TBitMap;
  DestAlpha, SourceAlpha: PByteArray;
  IsAlpha: Boolean;
begin
  AngleRad := Angle * Pi / 180;
  SinRad := Sin(AngleRad);
  CosRad := Cos(AngleRad);

  if IsPng then
  begin
    SourcePict := TPNGObject.Create;
    SourcePict.Assign(OriginPicture.Graphic);
    IsAlpha := (SourcePict.Header.ColorType = COLOR_RGBALPHA);
  end
  else
  begin
    SourceBmp := TBitMap.Create;
    SourceBmp.Assign(OriginPicture.Graphic);
  end;

  SourceCenter.Y := OriginPicture.Height div 2;
  SourceCenter.X := OriginPicture.Width div 2;

  Corners[1].X := -SourceCenter.X;
  Corners[1].Y := -SourceCenter.Y;
  Corners[2].X := Corners[1].X;
  Corners[2].Y := OriginPicture.Height - SourceCenter.Y;
  Corners[3].X := OriginPicture.Width - SourceCenter.X;
  Corners[3].Y := Corners[2].Y;
  Corners[4].X := Corners[3].X;
  Corners[4].Y := Corners[1].Y;

  for I := 1 to 4 do
  begin
    X := Corners[I].X;
    Y := Corners[I].Y;
    Corners[I].X := Round(CosRad * X + SinRad * Y);
    Corners[I].Y := Round(-SinRad * X + CosRad * Y);
  end;
  MaxP.X := Max(Max(Max(Corners[1].X, Corners[2].X), Corners[3].X), Corners[4].X);
  MinP.X := Min(Min(Min(Corners[1].X, Corners[2].X), Corners[3].X), Corners[4].X);
  MaxP.Y := Max(Max(Max(Corners[1].Y, Corners[2].Y), Corners[3].Y), Corners[4].Y);
  MinP.Y := Min(Min(Min(Corners[1].Y, Corners[2].Y), Corners[3].Y), Corners[4].Y);

  if IsPng then
  begin
    DestPict := TPNGObject.Create;
    DestPict.CreateBlank(COLOR_RGBALPHA, 8, MaxP.X - MinP.X + 1, MaxP.Y - MinP.Y + 1);
  end
  else
  begin
    DestBmp := TBitMap.Create;
    DestBmp.SetSize(MaxP.X - MinP.X + 1, MaxP.Y - MinP.Y + 1);
    DestBmp.PixelFormat := pf24bit;
  end;

  DestCenter.X := (MaxP.X - MinP.X + 1) div 2;
  DestCenter.Y := (MaxP.Y - MinP.Y + 1) div 2;

  for Y := MinP.Y to MaxP.Y - 1 do
  begin
    if IsPng then
      RowDest := DestPict.ScanLine[Y + DestCenter.Y]
    else
      RowDest := DestBmp.ScanLine[Y + DestCenter.Y];
    if IsPng and IsAlpha then
      SourceAlpha := DestPict.AlphaScanline[Y + DestCenter.Y];
    for X := MinP.X to MaxP.X - 1 do
    begin
      SourcePoint.X := Round(CosRad * X - SinRad * Y) + SourceCenter.X;
      SourcePoint.Y := Round(SinRad * X + CosRad * Y) + SourceCenter.Y;
      if (SourcePoint.X >= 0) and (SourcePoint.X < OriginPicture.Width) and (SourcePoint.Y >= 0) and
        (SourcePoint.Y < OriginPicture.Height) then
      begin
        if IsPng then
          RowSource := SourcePict.ScanLine[SourcePoint.Y]
        else
          RowSource := SourceBmp.ScanLine[SourcePoint.Y];
        RowDest[X + DestCenter.X] := RowSource[SourcePoint.X];

        if IsPng and IsAlpha then
        begin
          DestAlpha := SourcePict.AlphaScanline[SourcePoint.Y];
          SourceAlpha[X + DestCenter.X] := DestAlpha[SourcePoint.X];
        end;
      end;
    end;
  end;

  if IsPng then
  begin
    ViewImage(DestPict);
    DestPict.Free;
    SourcePict.Free;
  end
  else
  begin
    ViewImage(DestBmp);
    DestBmp.Free;
    SourceBmp.Free;
  end;
end;

procedure TObjectImage.ViewImage(Pict: TGraphic);
begin
  Picture.Assign(Pict);
  Height := Pict.Height;
  Width := Pict.Width;
end;

end.

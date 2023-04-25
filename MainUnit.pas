unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs;

type
  PixelArray = array [0 .. 32768] of TRGBTriple;
  PPixelArray = ^PixelArray;

  TObjectIcon = class(TImage)
    procedure ObjectIconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private const
    SpaceLeft = 10;
    SpaceTop = 20;
    ObjectHeight = 90;
    ObjectWidth = 190;
  public
    constructor Create(AOwner: TComponent; Y: Integer; ImgPath: string);
  end;

  TObjectImage = class(TImage)
    procedure ObjectImageDblClick(Sender: TObject);
    procedure ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private const
    BaseHeight = 100;
    BaseWidth = 200;
  private
    FZoom, FAngle: Real;
  public
    procedure Rotate1(Angle: Real);
    procedure Rotate(Angle: Real);
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture);
    property Zoom: Real read FZoom write FZoom;
    property Angle: Real read FAngle write FAngle;
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
    SelectedPicture: TPicture;
    WaitingFormClick: Boolean;
    AddObjectIcon: TImage;
    FObjectPanelTop: Integer;
    ObjectFileNames: System.TArray<string>;
    procedure SwitchPanel;
  public
    property ObjectPanelTop: Integer read FObjectPanelTop write FObjectPanelTop;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

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

      AddObjectIcon.Top := ObjectPanelTop - scrlbObjects.VertScrollBar.Position;

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
  Tmp: TObjectImage;
begin
  if WaitingFormClick then
  begin
    GetCursorPos(MousePos);
    Tmp := TObjectImage.Create(Self, MousePos.X - TObjectImage.BaseWidth div 2,
      MousePos.Y - TObjectImage.BaseHeight div 2, SelectedPicture);
    WaitingFormClick := False;
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
  ObjectFileNames := TDirectory.GetFiles('objects');
  ObjectPanelTop := 20;
  WaitingFormClick := False;

  for Path in ObjectFileNames do
  begin
    Tmp := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, Path);
    ObjectPanelTop := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
  end;

  AddObjectIcon := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, 'icons\addicon.png');
  AddObjectIcon.OnClick := AddImgClick;
  AddObjectIcon.DragMode := dmManual;

  scrlbObjects.VertScrollBar.Range := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
end;

procedure TMainForm.FormDragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if Source is TObjectIcon then
  begin
    TObjectImage.Create(Self, X - TObjectImage.BaseWidth div 2, Y - TObjectImage.BaseHeight div 2, SelectedPicture);
    WaitingFormClick := False;
  end
  else
  begin
    (Source as TObjectImage).Left := X - TObjectImage.BaseWidth div 2;
    (Source as TObjectImage).Top := Y - TObjectImage.BaseHeight div 2;
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
end;

procedure TObjectIcon.ObjectIconMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TControl(Sender).BeginDrag(False);
  (Self.Parent.Parent as TMainForm).WaitingFormClick := True;
  (Self.Parent.Parent as TMainForm).SelectedPicture := TImage(Sender).Picture;
  (Self.Parent.Parent as TMainForm).SwitchPanel;
end;

{ TObjectImage }

constructor TObjectImage.Create(AOwner: TComponent; X, Y: Integer; Pict: TPicture);
begin
  inherited Create(AOwner);
  OnDblClick := ObjectImageDblClick;
  OnMouseDown := ObjectImageMouseDown;
  Parent := TWinControl(AOwner);
  Picture := Pict;
  Proportional := True;
  Center := True;
  Height := BaseHeight;
  Width := BaseWidth;
  Top := Y;
  Left := X;
end;

procedure TObjectImage.ObjectImageDblClick(Sender: TObject);
begin
  Rotate1(30);
end;

procedure TObjectImage.ObjectImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Sleep(100);
  if (GetKeyState(VK_LBUTTON) and $8000) <> 0 then
    TControl(Sender).BeginDrag(False)
end;

procedure TObjectImage.Rotate(Angle: Real);
var
  SinRad, CosRad, AngleRad: Real;
  Row1, Row2: PPixelArray;
  OldBmp, RotatedBmp: TBitmap;
  Y, X, NewX, NewY: Integer;
begin
  OldBmp := TBitmap.Create;
  OldBmp.Assign(Picture.Graphic);
  OldBmp.PixelFormat := pf24bit;
  RotatedBmp := TBitmap.Create;
  RotatedBmp.SetSize(OldBmp.Width, OldBmp.Height);
  RotatedBmp.PixelFormat := pf24bit;
  AngleRad := Angle * Pi / 180;
  SinRad := Sin(AngleRad);
  CosRad := Cos(AngleRad);

  for Y := 0 to OldBmp.Height - 1 do
  begin
    Row1 := RotatedBmp.ScanLine[Y];
    for X := 0 to OldBmp.Width - 1 do
    begin
      NewX := Round(CosRad * X - SinRad * Y);
      NewY := Round(SinRad * X - CosRad * Y);
      if (NewX >= 0) and (NewX < OldBmp.Width) and (NewY >= 0) and (NewY < OldBmp.Height) then
      begin
        Row2 := OldBmp.ScanLine[NewY];
        Row1[X] := Row2[NewX];
      end;
    end;
  end;
  MainForm.Canvas.Draw(300, 300, RotatedBmp);
end;

end.

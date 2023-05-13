unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs, Math, System.Actions, Vcl.ActnList, Vcl.Menus,
  ObjectUnit, StrUtils, ActionEditUnit;

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
  private
    FLastUpdate, FRunTime: Cardinal;
    FObjectList: PObjectLI;
    FSelectedPicture: TPicture;
    FWaitingClickToCreate, FIsSelectedPng: Boolean;
    FAddObjectIcon: TImage;
    FObjectPanelTop: Integer;
    FLastClick: TPoint;
    FObjectFileNames: System.TArray<string>;
    procedure SwitchPanel;
  public
    destructor Destroy; override;
    procedure AddObject(Obj: TObjectImage);
    procedure CompleteAnimation;
    { properties }
    property ObjectList: PObjectLI read FObjectList write FObjectList;
    property ObjectPanelTop: Integer read FObjectPanelTop write FObjectPanelTop;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

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
      if ActionList[0] <> nil then
      begin
        CurrX := Left + Width div 2;
        CurrY := Top + Height div 2;
        CurrAction := ActionList[0];
      end;
      Visible := False;
    end;
    Tmp := Tmp^.Next;
  end;
  OnPaint := Animation;
  FRunTime := GetTickCount;
  FLastUpdate := 0;
  Self.Invalidate;
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
  PixelTime, R1X, R1Y, R2X, R2Y, Alpha, CurrAlpha, NX, NY: Extended;
  TmpBuff: TBitMap;
begin
  CurrTime := GetTickCount - FRunTime;

  TmpBuff := TBitMap.Create;
  TmpBuff.SetSize(ClientWidth, ClientHeight);
  TmpBuff.Canvas.StretchDraw(Rect(0, 0, ClientWidth, ClientHeight), BackMenuForm.BkPict.Graphic);
  Tmp := ObjectList;
  IsEnd := True;
  while Tmp <> nil do
    with Tmp^.ObjectImage do
    begin
      IsEnd := IsEnd and (CurrAction = nil);
      if (CurrAction <> nil) and (CurrTime >= CurrAction^.Info.TimeEnd * 1000) then
        CurrAction := CurrAction^.Next;
      if (CurrAction <> nil) and (CurrTime >= CurrAction^.Info.TimeStart * 1000) then
      begin
        if CurrAction^.Info.ActType = actLineMove then
          with CurrAction^.Info do
          begin
            CurrX := StartPoint.X + (EndPoint.X - StartPoint.X) / ((TimeEnd - TimeStart) * 1000) *
              (CurrTime - TimeStart);
            CurrY := StartPoint.Y + (EndPoint.Y - StartPoint.Y) / ((TimeEnd - TimeStart) * 1000) *
              (CurrTime - TimeStart);
          end
        else if CurrAction^.Info.ActType = actCircleMove then
        begin
          with CurrAction^.Info do
          begin
            R1X := CircleCenterX - StartPoint.X;
            R1Y := CircleCenterY - StartPoint.Y;
            R2X := CircleCenterX - EndPoint.X;
            R2Y := CircleCenterY - EndPoint.Y;
            Alpha := ArcCos((R1X * R2X + R1Y * R2Y) / (sqr(Radius)));
            CurrAlpha := Alpha / ((TimeEnd - TimeStart) * 1000) * (CurrTime - TimeStart);
            NX := CircleCenterX - (R1X * Cos(CurrAlpha) + R1Y * Sin(CurrAlpha));
            NY := CircleCenterY - (-R1X * Sin(CurrAlpha) + R1Y * Cos(CurrAlpha));
          end;
          CurrX := NX;
          CurrY := NY;
        end;
        TmpBuff.Canvas.Draw(Round(CurrX) - Picture.Width div 2, Round(CurrY) - Picture.Height div 2, Picture.Graphic);
      end;
      Tmp := Tmp^.Next;
    end;
  Canvas.Draw(0, 0, TmpBuff);
  if IsEnd then
    CompleteAnimation;
  FLastUpdate := CurrTime;
  Sleep(0);
  Invalidate;
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
  Tmp1 := ObjectList;
  while Tmp1 <> nil do
  begin
    Tmp2 := Tmp1;
    Tmp1 := Tmp1^.Next;
    Tmp2^.ObjectImage.Destroy;
  end;

  inherited Destroy;
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
  Path: string;
  Tmp: TImage;
begin
  DoubleBuffered := True;
  CreateDir('backgrounds');
  CreateDir('Icons');
  CreateDir('objects');
  FObjectFileNames := TDirectory.GetFiles('objects');
  ObjectPanelTop := 20;
  FWaitingClickToCreate := False;
  FObjectList := nil;

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
  (Self.Parent.Parent as TMainForm).FWaitingClickToCreate := True;
  (Self.Parent.Parent as TMainForm).FSelectedPicture := TImage(Sender).Picture;
  (Self.Parent.Parent as TMainForm).SwitchPanel;
end;

end.

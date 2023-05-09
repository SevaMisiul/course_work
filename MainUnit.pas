unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs, Math, System.Actions, Vcl.ActnList, Vcl.Menus,
  ObjectUnit, StrUtils;

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
  private
    FObjectList: PObjectLI;
    FSelectedPicture: TPicture;
    FWaitingFormClick, FIsSelectedPng, FWaitingCoordinatesClick: Boolean;
    FAddObjectIcon: TImage;
    FObjectPanelTop: Integer;
    FObjectFileNames: System.TArray<string>;
    procedure SwitchPanel;
  public
    destructor Destroy; override;
    procedure AddObject(Obj: TObjectImage);
    { properties }
    property ObjectList: PObjectLI read FObjectList write FObjectList;
    property WaitingCoordinatesClick: Boolean read FWaitingCoordinatesClick write FWaitingCoordinatesClick;
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
        CurrTime := -15;
        CurrAction := ActionList[0];
      end;
      Timer.Enabled := True;
      Timer.Interval := 15;
    end;
    Tmp := Tmp^.Next;
  end;
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
  FWaitingCoordinatesClick := False;
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

end.

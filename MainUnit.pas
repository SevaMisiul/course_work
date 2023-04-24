unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, BackMenuUnit, Vcl.ExtDlgs;

type
  TObjectIcon = class(TImage)
  private const
    SpaceLeft = 10;
    SpaceTop = 20;
    ObjectHeight = 90;
    ObjectWidth = 190;
  public
    constructor Create(AOwner: TComponent; Y: Integer; ImgPath: string);
  end;

  TObjectImage = class(TImage)
  private const
    BaseHeight = 200;
    BaseWidth = 100;
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; Pict: TPicture);
  end;

  TMainForm = class(TForm)
    btnCreateAnimation: TButton;
    scrlbObjects: TScrollBox;
    imgPanelSwitch: TImage;
    OpenObjectIconDialog: TOpenPictureDialog;
    procedure btnCreateAnimationClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure AddImgClick(Sender: TObject);
    procedure ObjectIconClick(Sender: TObject);
    procedure imgPanelSwitchClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure scrlbObjectsMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure scrlbObjectsMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormClick(Sender: TObject);
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
      Tmp.OnClick := ObjectIconClick;
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
    MainForm.Canvas.StretchDraw(Rect(0, 0, MainForm.ClientWidth, MainForm.ClientHeight), BackMenuForm.BkPict.Graphic);

    imgPanelSwitch.Visible := True;
    imgPanelSwitch.Top := ClientHeight div 2 - imgPanelSwitch.Height;
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
  CreateDir('backgrounds');
  CreateDir('Icons');
  CreateDir('objects');
  ObjectFileNames := TDirectory.GetFiles('objects');
  ObjectPanelTop := 20;
  WaitingFormClick := False;

  for Path in ObjectFileNames do
  begin
    Tmp := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, Path);
    Tmp.OnClick := ObjectIconClick;
    ObjectPanelTop := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
  end;

  AddObjectIcon := TObjectIcon.Create(scrlbObjects, ObjectPanelTop, 'icons\addicon.png');
  AddObjectIcon.OnClick := AddImgClick;

  scrlbObjects.VertScrollBar.Range := ObjectPanelTop + TObjectIcon.SpaceTop + TObjectIcon.ObjectHeight;
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  if BackMenuForm.BkPict <> nil then
    MainForm.Canvas.StretchDraw(Rect(0, 0, MainForm.ClientWidth, MainForm.ClientHeight), BackMenuForm.BkPict.Graphic);
end;

procedure TMainForm.imgPanelSwitchClick(Sender: TObject);
begin
  SwitchPanel;
end;

procedure TMainForm.ObjectIconClick(Sender: TObject);
begin
  WaitingFormClick := True;
  SelectedPicture := TImage(Sender).Picture;
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
  if imgPanelSwitch.Left = 0 then
  begin
    scrlbObjects.Visible := True;
    imgPanelSwitch.Left := scrlbObjects.Width;
    imgPanelSwitch.Picture.LoadFromFile('icons\left.png');
  end
  else
  begin
    scrlbObjects.Visible := False;
    imgPanelSwitch.Left := 0;
    imgPanelSwitch.Picture.LoadFromFile('icons\right.png');
  end;
end;

{ TObjectIcon }

constructor TObjectIcon.Create(AOwner: TComponent; Y: Integer; ImgPath: string);
begin
  inherited Create(AOwner);
  Parent := TWinControl(AOwner);
  Picture.LoadFromFile(ImgPath);
  Proportional := True;
  Center := True;
  Height := ObjectHeight;
  Width := ObjectWidth;
  Top := Y;
  Left := SpaceLeft;
end;

{ TObjectImage }

constructor TObjectImage.Create(AOwner: TComponent; X, Y: Integer; Pict: TPicture);
begin
  inherited Create(AOwner);
  Parent := TWinControl(AOwner);
  Picture := Pict;
  Proportional := True;
  Center := True;
  Height := BaseHeight;
  Width := BaseWidth;
  Top := Y;
  Left := X;
end;

end.

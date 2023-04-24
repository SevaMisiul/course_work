unit BackMenuUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, IOUtils, System.ImageList, Vcl.ImgList, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, ShellApi, Vcl.ExtDlgs;

type
  TBkImage = class(TImage)
  private const
    SpaceBtwHor = 60;
    SpaceBtwVert = 40;
    BkHeight = 189;
    BkWidth = 336;
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; ImgPath: string);
  end;

  TBackMenuForm = class(TForm)
    lbText: TLabel;
    BkPictureDialog: TOpenPictureDialog;
    scrlbBackground: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure AddImgClick(Sender: TObject);
    procedure BkClick(Sender: TObject);
    procedure OnMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure OnMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
  private
    FCurrLeft, FCurrTop: Integer;
    BkFileNames: System.TArray<string>;
    AddBkIcon: TImage;
    FBkPict: TPicture;
    procedure IncCoordinates;
  public
    property BkPict: TPicture read FBkPict;
    property CurrLeft: Integer read FCurrLeft write FCurrLeft;
    property CurrTop: Integer read FCurrTop write FCurrTop;
  end;

var
  BackMenuForm: TBackMenuForm;

implementation

{$R *.dfm}

procedure TBackMenuForm.IncCoordinates;
begin
  CurrLeft := CurrLeft + TBkImage.SpaceBtwHor + TBkImage.BkWidth;
  if CurrLeft + TBkImage.SpaceBtwHor + TBkImage.BkWidth > Width then
  begin
    CurrLeft := 60;
    CurrTop := CurrTop + TBkImage.BkHeight + TBkImage.SpaceBtwVert;
  end;
end;

constructor TBkImage.Create(AOwner: TComponent; X: Integer; Y: Integer; ImgPath: string);
begin
  inherited Create(AOwner);
  Parent := TWinControl(AOwner);
  Picture.LoadFromFile(ImgPath);
  Stretch := True;
  Height := TBkImage.BkHeight;
  Width := TBkImage.BkWidth;
  Top := Y;
  Left := X;
end;

procedure TBackMenuForm.OnMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  scrlbBackground.VertScrollBar.Position := scrlbBackground.VertScrollBar.Position - Integer(VertScrollBar.Increment);
end;

procedure TBackMenuForm.OnMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  scrlbBackground.VertScrollBar.Position := scrlbBackground.VertScrollBar.Position + Integer(VertScrollBar.Increment);
end;

procedure TBackMenuForm.AddImgClick(Sender: TObject);
var
  FilePath: string;
  Tmp: TBkImage;
begin
  if BkPictureDialog.Execute then
    if FileExists(BkPictureDialog.FileName) then
    begin
      FilePath := 'backgrounds\' + IntToStr(scrlbBackground.ControlCount) + Copy(BkPictureDialog.FileName,
        Pos('.', BkPictureDialog.FileName));
      CopyFile(PChar(BkPictureDialog.FileName), PChar(FilePath), False);

      Tmp := TBkImage.Create(scrlbBackground, CurrLeft, CurrTop - scrlbBackground.VertScrollBar.Position, FilePath);
      Tmp.OnClick := BkClick;
      IncCoordinates;

      AddBkIcon.Top := CurrTop - scrlbBackground.VertScrollBar.Position;
      AddBkIcon.Left := CurrLeft;

      scrlbBackground.VertScrollBar.Range := CurrTop + TBkImage.BkHeight + TBkImage.SpaceBtwVert;
    end
    else
      raise Exception.Create('File does not exist.');
end;

procedure TBackMenuForm.BkClick(Sender: TObject);
begin
  FBkPict := TImage(Sender).Picture;
  BackMenuForm.Close;
end;

procedure TBackMenuForm.FormCreate(Sender: TObject);
var
  BkPath: string;
  Tmp: TBkImage;
begin
  CurrLeft := 60;
  CurrTop := 10;

  FBkPict := nil;

  BkFileNames := TDirectory.GetFiles('backgrounds');

  for BkPath in BkFileNames do
  begin
    Tmp := TBkImage.Create(scrlbBackground, CurrLeft, CurrTop, BkPath);
    Tmp.OnClick := BkClick;
    IncCoordinates;
  end;

  AddBkIcon := TImage.Create(scrlbBackground);
  with AddBkIcon do
  begin
    Parent := scrlbBackground;
    Picture.LoadFromFile('icons\addicon.png');
    Proportional := True;
    Center := True;
    Height := TBkImage.BkHeight;
    Width := TBkImage.BkWidth;
    Top := CurrTop;
    Left := CurrLeft;
    OnClick := AddImgClick;
  end;

  scrlbBackground.VertScrollBar.Range := CurrTop + TBkImage.BkHeight + TBkImage.SpaceBtwVert;
end;

end.

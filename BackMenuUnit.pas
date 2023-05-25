unit BackMenuUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, IOUtils, System.ImageList, Vcl.ImgList, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, ShellApi, Vcl.ExtDlgs, StrUtils, Vcl.Imaging.jpeg;

type
  TBkImage = class(TImage)
    procedure BkClick(Sender: TObject);
  private const
    SpaceBtwHor = 60;
    SpaceBtwVert = 40;
    BkHeight = 189;
    BkWidth = 336;
  public
    constructor Create(AOwner: TComponent; X: Integer; Y: Integer; ImgPath: string; var IsCreated: Boolean);
  end;

  TBackMenuForm = class(TForm)
    lbText: TLabel;
    BkPictureDialog: TOpenPictureDialog;
    scrlbBackground: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure AddImgClick(Sender: TObject);
    procedure OnMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure OnMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
  private
    FCurrLeft, FCurrTop: Integer;
    BkFileNames: System.TArray<string>;
    AddBkIcon: TImage;
    FBkPict: TPicture;
    procedure IncCoordinates;
  public
    destructor Destroy; overload;
    function ShowForSelection(var BkPict: TPicture): Integer;
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

procedure TBackMenuForm.OnMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  scrlbBackground.VertScrollBar.Position := scrlbBackground.VertScrollBar.Position - Integer(VertScrollBar.Increment);
end;

function TBackMenuForm.ShowForSelection(var BkPict: TPicture): Integer;
begin
  Result := ShowModal;

  if Result = mrOk then
  begin
    BkPict := TPicture.Create;
    BkPict.Assign(FBkPict);
  end;
end;

procedure TBackMenuForm.OnMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  scrlbBackground.VertScrollBar.Position := scrlbBackground.VertScrollBar.Position + Integer(VertScrollBar.Increment);
end;

procedure TBackMenuForm.AddImgClick(Sender: TObject);
var
  FilePath, FileExtension, Rever: string;
  IsCreated: Boolean;
  Tmp: TBkImage;
begin
  if BkPictureDialog.Execute then
    if FileExists(BkPictureDialog.FileName) then
    begin
      Rever := ReverseString(BkPictureDialog.FileName);
      FileExtension := ReverseString(Copy(Rever, 1, Pos('.', Rever)));
      FilePath := 'backgrounds\' + IntToStr(scrlbBackground.ControlCount) + FileExtension;

      Tmp := TBkImage.Create(scrlbBackground, CurrLeft, CurrTop - scrlbBackground.VertScrollBar.Position,
        BkPictureDialog.FileName, IsCreated);
      if IsCreated then
      begin
        CopyFile(PChar(BkPictureDialog.FileName), PChar(FilePath), False);
        IncCoordinates;
      end
      else
        Tmp.Destroy;

      AddBkIcon.Top := CurrTop - scrlbBackground.VertScrollBar.Position;
      AddBkIcon.Left := CurrLeft;

      scrlbBackground.VertScrollBar.Range := CurrTop + TBkImage.BkHeight + TBkImage.SpaceBtwVert;
    end
    else
      raise Exception.Create('File does not exist.');
end;

destructor TBackMenuForm.Destroy;
var
  I: Integer;
begin
  BkFileNames := nil;

  inherited Destroy;
end;

procedure TBackMenuForm.FormCreate(Sender: TObject);
var
  BkPath: string;
  Tmp: TBkImage;
  IsCreated: Boolean;
begin
  CurrLeft := 60;
  CurrTop := 10;

  FBkPict := nil;

  BkFileNames := TDirectory.GetFiles('backgrounds');

  for BkPath in BkFileNames do
  begin
    Tmp := TBkImage.Create(scrlbBackground, CurrLeft, CurrTop, BkPath, IsCreated);
    if IsCreated then
      IncCoordinates
    else
      Tmp.Destroy;
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

{ TBkImage }

procedure TBkImage.BkClick(Sender: TObject);
begin
  (Self.Parent.Parent as TBackMenuForm).FBkPict := TImage(Sender).Picture;
  (Self.Parent.Parent as TBackMenuForm).ModalResult := mrOk;
end;

constructor TBkImage.Create(AOwner: TComponent; X: Integer; Y: Integer; ImgPath: string; var IsCreated: Boolean);
begin
  inherited Create(AOwner);
  OnClick := BkClick;
  Parent := TWinControl(AOwner);
  IsCreated := True;
  try
    Picture.LoadFromFile(ImgPath);
  except
    on E: EInvalidGraphic do
    begin
      ShowMessage('Image file is corrupted.');
      IsCreated := False;
    end;
  end;
  Stretch := True;
  Height := TBkImage.BkHeight;
  Width := TBkImage.BkWidth;
  Top := Y;
  Left := X;
end;

end.

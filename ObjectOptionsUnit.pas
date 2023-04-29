unit ObjectOptionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Math, Vcl.Imaging.pngimage;

type
  TObjectOptionsForm = class(TForm)
    pbPicture: TPaintBox;
    edtHeight: TEdit;
    chbIsProportional: TCheckBox;
    lbHeight: TLabel;
    lbWidth: TLabel;
    edtAngle: TEdit;
    lbAngle: TLabel;
    ListView1: TListView;
    lbActions: TLabel;
    btnAddAction: TButton;
    btnOk: TButton;
    btnCancel: TButton;
    edtWidth: TEdit;
    lbTop: TLabel;
    lbLeft: TLabel;
    edtTop: TEdit;
    edtLeft: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure pbPicturePaint(Sender: TObject);
    procedure edtHeightChange(Sender: TObject);
    procedure edtWidthChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FPicture: TPicture;
    FIsConfirm: Boolean;
    FHeightRatio, FWidthRatio: Integer;
  public
    property Pict: TPicture read FPicture write FPicture;
    property HeightRatio: Integer read FHeightRatio write FHeightRatio;
    property WidthRatio: Integer read FWidthRatio write FWidthRatio;
    property IsConfirm: Boolean read FIsConfirm;
  end;

var
  ObjectOptionsForm: TObjectOptionsForm;

implementation

{$R *.dfm}

procedure TObjectOptionsForm.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TObjectOptionsForm.btnOkClick(Sender: TObject);
begin
  if (edtHeight.Text <> '') and (edtHeight.Text <> '') and (edtAngle.Text <> '') then
  begin
    FIsConfirm := True;
    Close;
  end
  else
    ShowMessage('Fill in required filds');
end;

procedure TObjectOptionsForm.edtHeightChange(Sender: TObject);
begin
  if edtHeight.Modified and chbIsProportional.Checked and (edtHeight.Text <> '') then
    edtWidth.Text := IntToStr(Round(StrToInt(edtHeight.Text) / HeightRatio * WidthRatio))
  else if edtHeight.Modified and chbIsProportional.Checked and (edtHeight.Text = '') then
    edtWidth.Text := '';
end;

procedure TObjectOptionsForm.edtWidthChange(Sender: TObject);
begin
  if edtWidth.Modified and chbIsProportional.Checked and (edtWidth.Text <> '') then
    edtHeight.Text := IntToStr(Round(StrToInt(edtWidth.Text) / WidthRatio * HeightRatio))
  else if edtWidth.Modified and chbIsProportional.Checked and (edtWidth.Text = '') then
    edtHeight.Text := '';
end;

procedure TObjectOptionsForm.FormCreate(Sender: TObject);
begin
  Pict := TPicture.Create;
end;

procedure TObjectOptionsForm.FormShow(Sender: TObject);
begin
  FIsConfirm := False;
end;

procedure TObjectOptionsForm.pbPicturePaint(Sender: TObject);
begin
  if HeightRatio >= WidthRatio then
    pbPicture.Canvas.StretchDraw(Rect(100 - Round(200 / HeightRatio * WidthRatio) div 2, 0,
      100 + Round(200 / HeightRatio * WidthRatio) div 2, 200), Pict.Graphic)
  else
    pbPicture.Canvas.StretchDraw(Rect(0, 100 - Round(200 / WidthRatio * HeightRatio) div 2, 200,
      100 + Round(200 / WidthRatio * HeightRatio) div 2), Pict.Graphic);
end;

end.

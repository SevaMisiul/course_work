unit ObjectOptionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Math, Vcl.Imaging.pngimage,
  ActionEditUnit, ObjectUnit;

type
  TObjectOptionsForm = class(TForm)
    pbPicture: TPaintBox;
    edtHeight: TEdit;
    chbIsProportional: TCheckBox;
    lbHeight: TLabel;
    lbWidth: TLabel;
    edtAngle: TEdit;
    lbAngle: TLabel;
    lvActions: TListView;
    lbActions: TLabel;
    btnAddAction: TButton;
    btnOk: TButton;
    btnCancel: TButton;
    edtWidth: TEdit;
    lbTop: TLabel;
    lbLeft: TLabel;
    edtTop: TEdit;
    edtLeft: TEdit;
    btnDeleteAction: TButton;
    btnDeleteObject: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure pbPicturePaint(Sender: TObject);
    procedure edtHeightChange(Sender: TObject);
    procedure edtWidthChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnDeleteObjectClick(Sender: TObject);
    procedure btnAddActionClick(Sender: TObject);
  private
    FPicture: TPicture;
    FObjectOwner: TObjectImage;
    FIsConfirm: Boolean;
    FIsDeleting: Boolean;
    FHeightRatio, FWidthRatio: Integer;
  public
    procedure AddListViewItem(ActType: TActionType; TimeStart, TimeEnd: Integer);
    { properties }
    property ObjectOwner: TObjectImage read FObjectOwner write FObjectOwner;
    property Pict: TPicture read FPicture write FPicture;
    property HeightRatio: Integer read FHeightRatio write FHeightRatio;
    property WidthRatio: Integer read FWidthRatio write FWidthRatio;
    property IsConfirm: Boolean read FIsConfirm;
    property ISDeleting: Boolean read FIsDeleting;
  end;

var
  ObjectOptionsForm: TObjectOptionsForm;

implementation

{$R *.dfm}

procedure FillActionEditForm(StartT, EndT: Integer; StartPoint, EndPoint: TPoint; DefaultAction: TActionType = TActionType(0));
var
  Act: TActionType;
begin
  with ActionEditForm do
  begin
    cbActionType.Clear;
    for Act := Low(TActionType) to High(TActionType) do
    begin
      cbActionType.Items.Add(ActionNames[Act]);
    end;
    cbActionType.ItemIndex := Ord(DefaultAction);
    edtTimeStart.Text := IntToStr(StartT);
    edtTimeEnd.Text := IntToStr(EndT);
    edtStartPointX.Text := IntToStr(StartPoint.X);
    edtStartPointY.Text := IntToStr(StartPoint.Y);
    edtEndPointX.Text := IntToStr(EndPoint.X);
    edtEndPointY.Text := IntToStr(EndPoint.Y);
  end;
end;

procedure TObjectOptionsForm.AddListViewItem(ActType: TActionType; TimeStart, TimeEnd: Integer);
begin
  with lvActions.Items.Add do
  begin
    Caption := ActionNames[ActType];
    SubItems.Add(IntToStr(TimeStart));
    SubItems.Add(IntToStr(TimeEnd));
  end;
end;

procedure TObjectOptionsForm.btnAddActionClick(Sender: TObject);
var
  Act: TActionInfo;
begin
  FillActionEditForm(0, 0, Point(0, 0), Point(0, 0));
  ActionEditForm.ShowModal;
  if ActionEditForm.IsConfirm then
  begin
    with ActionEditForm, Act do
    begin
      ActType := TActionType(cbActionType.ItemIndex);
      TimeStart := StrToInt(edtTimeStart.Text);
      TimeEnd := StrToInt(edtTimeEnd.Text);
      StartPoint := Point(StrToInt(edtStartPointX.Text), StrToInt(edtStartPointY.Text));
      EndPoint := Point(StrToInt(edtEndPointX.Text), StrToInt(edtEndPointY.Text));
      AddListViewItem(ActType, TimeStart, TimeEnd);
    end;
    ObjectOwner.AddAction(Act);
  end;
end;

procedure TObjectOptionsForm.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TObjectOptionsForm.btnDeleteObjectClick(Sender: TObject);
var
  ClickedBtn: Integer;
begin
  ClickedBtn := MessageDlg('Are you sure you want to delete the object', mtWarning, [mbYes, mbNo], 0);
  if ClickedBtn = 6 then
  begin
    FIsDeleting := True;
    Close;
  end;
end;

procedure TObjectOptionsForm.btnOkClick(Sender: TObject);
begin
  if (edtHeight.Text <> '') and (edtHeight.Text <> '') and (edtAngle.Text <> '') and (edtTop.Text <> '') and
    (edtLeft.Text <> '') then
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
  FIsDeleting := False;
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

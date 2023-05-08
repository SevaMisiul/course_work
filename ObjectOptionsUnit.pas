unit ObjectOptionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Math, Vcl.Imaging.pngimage,
  ActionEditUnit, ObjectUnit, System.Actions, Vcl.ActnList;

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
    actList: TActionList;
    actDeleteAction: TAction;
    btnEditAction: TButton;
    actEditAction: TAction;
    procedure FormCreate(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure pbPicturePaint(Sender: TObject);
    procedure edtHeightChange(Sender: TObject);
    procedure edtWidthChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnDeleteObjectClick(Sender: TObject);
    procedure btnAddActionClick(Sender: TObject);
    procedure actListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure actDeleteActionExecute(Sender: TObject);
    procedure actEditActionExecute(Sender: TObject);
  private
    FPicture: TPicture;
    FObjectOwner: TObjectImage;
    FIsConfirm: Boolean;
    FIsDeleting: Boolean;
    FHeightRatio, FWidthRatio: Integer;
  public
    procedure UpdateActionList(Header: PACtionLI);
    procedure UpdateAfterDelete;
    procedure UpdateSelectedAction(Act: TActionInfo);
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

procedure TObjectOptionsForm.actEditActionExecute(Sender: TObject);
var
  Tmp: PACtionLI;
  Act: TActionInfo;
  Res: TModalResult;
begin
  Tmp := FObjectOwner.ActionList[lvActions.ItemIndex];
  Act := Tmp^.Info;

  Res := ActionEditForm.ShowForEdit(Act, FObjectOwner);

  if Res = mrOk then
    FObjectOwner.SetAction(Tmp, Act);
end;

procedure TObjectOptionsForm.actListUpdate(Action: TBasicAction; var Handled: Boolean);
begin
  actDeleteAction.Enabled := lvActions.ItemIndex >= 0;
  actEditAction.Enabled := lvActions.ItemIndex >= 0;
end;

procedure TObjectOptionsForm.btnAddActionClick(Sender: TObject);
var
  Act: TActionInfo;
  Res: TModalResult;
begin
  Res := ActionEditForm.ShowForAdd(Act, FObjectOwner);

  if Res = mrOk then
    FObjectOwner.AddAction(Act);
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

procedure TObjectOptionsForm.actDeleteActionExecute(Sender: TObject);
begin
  FObjectOwner.DeleteAction(lvActions.ItemIndex);
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
  UpdateActionList(FObjectOwner.ActionList[0]);
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

procedure TObjectOptionsForm.UpdateActionList(Header: PACtionLI);
begin
  lvActions.Items.Clear;
  while Header <> nil do
  begin
    with lvActions.Items.Add do
    begin
      Caption := ActionNames[Header^.Info.ActType];
      SubItems.Add(IntToStr(Header^.Info.TimeStart));
      SubItems.Add(IntToStr(Header^.Info.TimeEnd));
    end;
    Header := Header^.Next;
  end;
end;

procedure TObjectOptionsForm.UpdateAfterDelete;
begin
  lvActions.DeleteSelected;
end;

procedure TObjectOptionsForm.UpdateSelectedAction(Act: TActionInfo);
begin
  lvActions.Items.Item[lvActions.ItemIndex].Caption := ActionNames[Act.ActType];
  lvActions.Items.Item[lvActions.ItemIndex].SubItems[0] := IntToStr(Act.TimeStart);
  lvActions.Items.Item[lvActions.ItemIndex].SubItems[1] := IntToStr(Act.TimeEnd);
end;

end.

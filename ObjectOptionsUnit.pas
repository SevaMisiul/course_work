unit ObjectOptionsUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Math, Vcl.Imaging.pngimage,
  ObjectUnit, System.Actions, Vcl.ActnList;

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
    actAddAction: TAction;
    procedure pbPicturePaint(Sender: TObject);
    procedure edtHeightChange(Sender: TObject);
    procedure edtWidthChange(Sender: TObject);
    procedure actListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure actDeleteActionExecute(Sender: TObject);
    procedure actEditActionExecute(Sender: TObject);
    procedure actAddActionExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure chbIsProportionalClick(Sender: TObject);
  private
    FObjectOwner: TObjectImage;
  public
    function ShowForEdit(Obj: TObjectImage; var H, W, L, T, Angle: Integer; var IsProportional: Boolean): TModalResult;

    procedure UpdateActionList(Header: PACtionLI);
    procedure UpdateAfterDelete;
    procedure UpdateSelectedAction(Act: TActionInfo);
    { properties }
  end;

var
  ObjectOptionsForm: TObjectOptionsForm;

implementation

{$R *.dfm}

uses
  ActionEditUnit;

procedure TObjectOptionsForm.actAddActionExecute(Sender: TObject);
var
  Act: TActionInfo;
  Res: TModalResult;
begin
  Res := ActionEditForm.ShowForAdd(Act, FObjectOwner, Self);

  if Res = mrOk then
    FObjectOwner.AddAction(Act);
end;

procedure TObjectOptionsForm.actDeleteActionExecute(Sender: TObject);
begin
  FObjectOwner.DeleteAction(lvActions.ItemIndex);
end;

procedure TObjectOptionsForm.actEditActionExecute(Sender: TObject);
var
  Tmp: PACtionLI;
  Act: TActionInfo;
  Res: TModalResult;
begin
  Tmp := FObjectOwner.ActionList[lvActions.ItemIndex];
  Act := Tmp^.Info;

  Res := ActionEditForm.ShowForEdit(Act, FObjectOwner, Self);

  if Res = mrOk then
    FObjectOwner.SetAction(Tmp, Act);
end;

procedure TObjectOptionsForm.actListUpdate(Action: TBasicAction; var Handled: Boolean);
begin
  actDeleteAction.Enabled := lvActions.ItemIndex >= 0;
  actEditAction.Enabled := lvActions.ItemIndex >= 0;
end;

procedure TObjectOptionsForm.chbIsProportionalClick(Sender: TObject);
begin
  if chbIsProportional.Checked then
    edtWidth.Text := IntToStr(Round(StrToInt(edtHeight.Text) / FObjectOwner.AspectRatio.Height *
      FObjectOwner.AspectRatio.Width));
end;

procedure TObjectOptionsForm.edtHeightChange(Sender: TObject);
begin
  if edtHeight.Modified and chbIsProportional.Checked and (edtHeight.Text <> '') then
    edtWidth.Text := IntToStr(Round(StrToInt(edtHeight.Text) / FObjectOwner.AspectRatio.Height *
      FObjectOwner.AspectRatio.Width))
  else if edtHeight.Modified and chbIsProportional.Checked and (edtHeight.Text = '') then
    edtWidth.Text := '';
end;

procedure TObjectOptionsForm.edtWidthChange(Sender: TObject);
begin
  if edtWidth.Modified and chbIsProportional.Checked and (edtWidth.Text <> '') then
    edtHeight.Text := IntToStr(Round(StrToInt(edtWidth.Text) / FObjectOwner.AspectRatio.Width *
      FObjectOwner.AspectRatio.Height))
  else if edtWidth.Modified and chbIsProportional.Checked and (edtWidth.Text = '') then
    edtHeight.Text := '';
end;

procedure TObjectOptionsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (ModalResult = mrOk) and ((edtHeight.Text = '') or (edtWidth.Text = '') or (edtAngle.Text = '') or
    (edtTop.Text = '') or (edtLeft.Text = '')) then
  begin
    ShowMessage('Fill in required filds');
    CanClose := False;
  end;
  if ModalResult = mrAbort then
  begin
    CanClose := (MessageDlg('Are you sure you want to delete the object', mtWarning, [mbYes, mbNo], 0) = 6);
  end;
end;

procedure TObjectOptionsForm.pbPicturePaint(Sender: TObject);
begin
  if FObjectOwner.AspectRatio.Height >= FObjectOwner.AspectRatio.Width then
    pbPicture.Canvas.StretchDraw
      (Rect(100 - Round(200 / FObjectOwner.AspectRatio.Height * FObjectOwner.AspectRatio.Width) div 2, 0,
      100 + Round(200 / FObjectOwner.AspectRatio.Height * FObjectOwner.AspectRatio.Width) div 2, 200),
      FObjectOwner.OriginPicture.Graphic)
  else
    pbPicture.Canvas.StretchDraw
      (Rect(0, 100 - Round(200 / FObjectOwner.AspectRatio.Width * FObjectOwner.AspectRatio.Height) div 2, 200,
      100 + Round(200 / FObjectOwner.AspectRatio.Width * FObjectOwner.AspectRatio.Height) div 2),
      FObjectOwner.OriginPicture.Graphic);
end;

function TObjectOptionsForm.ShowForEdit(Obj: TObjectImage; var H, W, L, T, Angle: Integer; var IsProportional: Boolean)
  : TModalResult;
begin
  FObjectOwner := Obj;
  UpdateActionList(Obj.ActionList[0]);
  edtHeight.Text := IntToStr(H);
  edtWidth.Text := IntToStr(W);
  edtAngle.Text := IntToStr(Angle);
  chbIsProportional.Checked := IsProportional;
  edtTop.Text := IntToStr(T + Obj.Height div 2);
  edtLeft.Text := IntToStr(L + Obj.Width div 2);

  result := ShowModal;

  if result = mrOk then
  begin
    H := StrToInt(edtHeight.Text);
    W := StrToInt(edtWidth.Text);
    T := StrToInt(edtTop.Text);
    L := StrToInt(edtLeft.Text);
    Angle := StrToInt(edtAngle.Text);
    IsProportional := chbIsProportional.Checked;
  end;
end;

procedure TObjectOptionsForm.UpdateActionList(Header: PACtionLI);
begin
  lvActions.Items.Clear;
  while Header <> nil do
  begin
    with lvActions.Items.Add do
    begin
      Caption := ActionNames[Header^.Info.ActType];
      SubItems.Add(IntToStr(Header^.Info.TimeStart div 1000));
      SubItems.Add(IntToStr(Header^.Info.TimeEnd div 1000));
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
  lvActions.Items.Item[lvActions.ItemIndex].SubItems[0] := IntToStr(Act.TimeStart div 1000);
  lvActions.Items.Item[lvActions.ItemIndex].SubItems[1] := IntToStr(Act.TimeEnd div 1000);
end;

end.

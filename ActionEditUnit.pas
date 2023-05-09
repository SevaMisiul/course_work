unit ActionEditUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ObjectUnit, Vcl.ExtCtrls;

type
  TActionEditForm = class(TForm)
    cbActionType: TComboBox;
    lbActionType: TLabel;
    lbEndTime: TLabel;
    lbStartTime: TLabel;
    edtTimeStart: TEdit;
    edtTimeEnd: TEdit;
    btnCancel: TButton;
    btnOk: TButton;
    lbStartPointX: TLabel;
    edtStartPointX: TEdit;
    lbStartPointY: TLabel;
    edtStartPointY: TEdit;
    lbEndPointX: TLabel;
    edtEndPointX: TEdit;
    lbEndPointY: TLabel;
    edtEndPointY: TEdit;
    lbRadius: TLabel;
    edtRadius: TEdit;
    rgCenterPos: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cbActionTypeChange(Sender: TObject);
  private
    FObj: TObjectImage;
    FIsEditing: Boolean;
    FCurrAct: TACtionInfo;
    procedure GetActionInfo(var Act: TACtionInfo);
  public
    function ShowForAdd(var Act: TACtionInfo; Obj: TObjectImage): TModalResult;
    function ShowForEdit(var Act: TACtionInfo; Obj: TObjectImage): TModalResult;
  end;

var
  ActionEditForm: TActionEditForm;

implementation

{$R *.dfm}

uses
  ObjectOptionsUnit;

procedure TActionEditForm.cbActionTypeChange(Sender: TObject);
begin
  if TActionType(cbActionType.ItemIndex) = actLineMove then
  begin
    lbRadius.Visible := False;
    edtRadius.Visible := False;
    rgCenterPos.Visible := False;
  end
  else if TActionType(cbActionType.ItemIndex) = actCircleMove then
  begin
    lbRadius.Visible := True;
    edtRadius.Visible := True;
    rgCenterPos.Visible := True;
    rgCenterPos.ItemIndex := 0;
    edtRadius.Text := '';
  end;
end;

procedure TActionEditForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Tmp: PActionLI;
  StartT, EndT: Integer;
  IsCorrect: Boolean;
begin
  if (ModalResult = mrOk) and ((edtStartPointX.Text = '') or (edtStartPointY.Text = '') or (edtEndPointX.Text = '') or
    (edtEndPointY.Text = '') or (edtTimeStart.Text = '') or (edtTimeEnd.Text = '') or
    (StrToInt(edtTimeStart.Text) >= StrToInt(edtTimeEnd.Text)) or ((TActionType(cbActionType.ItemIndex) = actCircleMove)
    and ((edtRadius.Text = '') or (StrToInt(edtRadius.Text) < sqrt(sqr(StrToInt(edtStartPointX.Text) -
    StrToInt(edtEndPointX.Text)) + sqr(StrToInt(edtStartPointY.Text) - StrToInt(edtEndPointY.Text))) / 2)))) then
  begin
    ShowMessage('Fill in the fields correctly');
    CanClose := False;
  end
  else if (ModalResult = mrOk) and (FObj.ActionList[0] <> nil) and
    (StrToInt(edtTimeStart.Text) < FObj.EndActionList^.Info.TimeEnd) then
  begin
    StartT := StrToInt(edtTimeStart.Text);
    EndT := StrToInt(edtTimeEnd.Text);
    IsCorrect := True;
    Tmp := FObj.ActionList[0];
    while IsCorrect and (Tmp <> nil) do
    begin
      if not FIsEditing or (Tmp^.Info.TimeStart <> FCurrAct.TimeStart) and (Tmp^.Info.TimeEnd <> FCurrAct.TimeEnd) then
        IsCorrect := IsCorrect and not((StartT < Tmp^.Info.TimeEnd) and (StartT >= Tmp^.Info.TimeStart) or
          (EndT > Tmp^.Info.TimeStart) and (EndT <= Tmp^.Info.TimeEnd) or (StartT < Tmp^.Info.TimeStart) and
          (EndT > Tmp^.Info.TimeStart));
      Tmp := Tmp^.Next;
    end;
    if not IsCorrect then
    begin
      ShowMessage('Time interval conflict');
      CanClose := False;
    end;
  end;
end;

procedure TActionEditForm.FormCreate(Sender: TObject);
var
  I: TActionType;
begin
  for I := Low(TActionType) to High(TActionType) do
    cbActionType.Items.Add(ActionNames[I]);
end;

procedure TActionEditForm.GetActionInfo(var Act: TACtionInfo);
begin
  Act.ActType := TActionType(cbActionType.ItemIndex);
  Act.TimeStart := StrToInt(edtTimeStart.Text);
  Act.TimeEnd := StrToInt(edtTimeEnd.Text);
  Act.StartPoint.X := StrToInt(edtStartPointX.Text);
  Act.StartPoint.Y := StrToInt(edtStartPointY.Text);
  Act.EndPoint.X := StrToInt(edtEndPointX.Text);
  Act.EndPoint.Y := StrToInt(edtEndPointY.Text);
  if Act.ActType = actCircleMove then
  begin
    Act.Radius := StrToInt(edtRadius.Text);
    ACt.CenterPos := TCenterPos(rgCenterPos.ItemIndex);
  end;
end;

function TActionEditForm.ShowForAdd(var Act: TACtionInfo; Obj: TObjectImage): TModalResult;
var
  Tmp: TACtionInfo;
begin
  FObj := Obj;
  FIsEditing := False;

  if Obj.ActionList[0] <> nil then
  begin
    Tmp := Obj.EndActionList^.Info;
    edtTimeStart.Text := IntToStr(Tmp.TimeEnd);
    edtStartPointX.Text := IntToStr(Tmp.EndPoint.X);
    edtStartPointY.Text := IntToStr(Tmp.EndPoint.Y);
  end
  else
  begin
    edtTimeStart.Text := '';
    edtStartPointX.Text := IntToStr(FObj.Left + FObj.Width div 2);
    edtStartPointY.Text := IntToStr(FObj.Top + FObj.Height div 2);
  end;
  cbActionType.ItemIndex := 0;
  cbActionTypeChange(Self);
  edtTimeEnd.Text := '';
  edtEndPointX.Text := '';
  edtEndPointY.Text := '';

  result := ShowModal;

  if result = mrOk then
  begin
    GetActionInfo(Act);
  end;
end;

function TActionEditForm.ShowForEdit(var Act: TACtionInfo; Obj: TObjectImage): TModalResult;
begin
  FObj := Obj;
  FIsEditing := True;
  FCurrAct := Act;

  cbActionType.ItemIndex := Ord(Act.ActType);
  cbActionTypeChange(Self);
  if Act.ActType = actCircleMove then
  begin
    edtRadius.Text := IntToStr(Act.Radius);
    rgCenterPos.ItemIndex := Ord(Act.CenterPos);
  end;
  edtTimeStart.Text := IntToStr(Act.TimeStart);
  edtTimeEnd.Text := IntToStr(Act.TimeEnd);
  edtStartPointX.Text := IntToStr(Act.StartPoint.X);
  edtStartPointY.Text := IntToStr(Act.StartPoint.Y);
  edtEndPointX.Text := IntToStr(Act.EndPoint.X);
  edtEndPointY.Text := IntToStr(Act.EndPoint.Y);

  result := ShowModal;

  if result = mrOk then
  begin
    GetActionInfo(Act);
  end;
end;

end.

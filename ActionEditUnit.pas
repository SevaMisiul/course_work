unit ActionEditUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ObjectUnit, Vcl.ExtCtrls, Vcl.Menus, Vcl.Buttons,
  ObjectOptionsUnit;

type
  TPointEdit = (pStart, pEnd, pThird);

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
    lbThirdX: TLabel;
    lbThirdY: TLabel;
    edtThirdX: TEdit;
    edtThirdY: TEdit;
    bbtnStartPoin: TBitBtn;
    bbtnEndPoint: TBitBtn;
    bbtnThirdPoint: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cbActionTypeChange(Sender: TObject);
    procedure bbtnStartPoinClick(Sender: TObject);
    procedure bbtnEndPointClick(Sender: TObject);
    procedure bbtnThirdPointClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FObj: TObjectImage;
    FIsEditing: Boolean;
    FCurrAct: TACtionInfo;
    FIsWaitingClick: Boolean;
    FPointEdit: TPointEdit;
    FParentForm: TObjectOptionsForm;
    procedure PrepareForClick(TPEdt: TPointEdit);
    procedure GetActionInfo(var Act: TACtionInfo);
  public
    function ShowForAdd(var Act: TACtionInfo; Obj: TObjectImage; ParentF: TObjectOptionsForm): TModalResult;
    function ShowForEdit(var Act: TACtionInfo; Obj: TObjectImage; ParentF: TObjectOptionsForm): TModalResult;
  end;

var
  ActionEditForm: TActionEditForm;

implementation

{$R *.dfm}

uses
  MainUnit;

procedure TActionEditForm.bbtnEndPointClick(Sender: TObject);
begin
  PrepareForClick(pEnd);
end;

procedure TActionEditForm.bbtnStartPoinClick(Sender: TObject);
begin
  PrepareForClick(pStart);
end;

procedure TActionEditForm.bbtnThirdPointClick(Sender: TObject);
begin
  PrepareForClick(pThird);
end;

procedure TActionEditForm.cbActionTypeChange(Sender: TObject);
begin
  if TActionType(cbActionType.ItemIndex) = actLineMove then
  begin
    lbThirdX.Visible := False;
    lbThirdY.Visible := False;
    edtThirdX.Visible := False;
    edtThirdY.Visible := False;
    bbtnThirdPoint.Visible := False;
  end
  else if TActionType(cbActionType.ItemIndex) = actCircleMove then
  begin
    lbThirdX.Visible := True;
    lbThirdY.Visible := True;
    edtThirdX.Visible := True;
    edtThirdY.Visible := True;
    edtThirdX.Text := '';
    edtThirdY.Text := '';
    bbtnThirdPoint.Visible := True;
  end;
end;

procedure TActionEditForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Tmp: PActionLI;
  StartT, EndT: Integer;
  IsCorrect: Boolean;
  S, T, E: TPoint;
begin
  if (ModalResult = mrOk) and ((edtStartPointX.Text = '') or (edtStartPointY.Text = '') or (edtEndPointX.Text = '') or
    (edtEndPointY.Text = '') or (edtTimeStart.Text = '') or (edtTimeEnd.Text = '') or
    (StrToInt(edtTimeStart.Text) >= StrToInt(edtTimeEnd.Text)) or ((TActionType(cbActionType.ItemIndex) = actCircleMove)
    and ((edtThirdX.Text = '') or (edtThirdY.Text = '')))) then
  begin
    ShowMessage('Fill in the fields correctly');
    CanClose := False;
  end
  else if (ModalResult = mrOk) and ((TActionType(cbActionType.ItemIndex) = actCircleMove)) then
  begin
    S.X := StrToInt(edtStartPointX.Text);
    E.X := StrToInt(edtEndPointX.Text);
    T.X := StrToInt(edtThirdX.Text);
    S.Y := StrToInt(edtStartPointY.Text);
    E.Y := StrToInt(edtEndPointY.Text);
    T.Y := StrToInt(edtThirdY.Text);
    if (S.X - T.X) * (E.Y - T.Y) = (S.Y - T.Y) * (E.X - T.X) then
    begin
      ShowMessage('The points must not lie on the same line');
      CanClose := False;
    end;
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

procedure TActionEditForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  M: TPoint;
begin
  if FIsWaitingClick then
  begin
    ReleaseCapture;
    M.X := X;
    M.Y := Y;
    M := ClientToScreen(M);
    M := MainForm.ScreenToClient(M);
    case FPointEdit of
      pStart:
        begin
          edtStartPointX.Text := IntToStr(M.X);
          edtStartPointY.Text := IntToStr(M.Y);
        end;
      pEnd:
        begin
          edtEndPointX.Text := IntToStr(M.X);
          edtEndPointY.Text := IntToStr(M.Y);
        end;
      pThird:
        begin
          edtThirdX.Text := IntToStr(M.X);
          edtThirdY.Text := IntToStr(M.Y);
        end;
    end;
    FParentForm.Show;
    Self.Show;
    FIsWaitingClick := False;
  end;
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
    Act.ThirdPoint.X := StrToInt(edtThirdX.Text);
    Act.ThirdPoint.Y := StrToInt(edtThirdY.Text);
  end;
end;

procedure TActionEditForm.PrepareForClick(TPEdt: TPointEdit);
begin
  SetCaptureControl(Self);
  FIsWaitingClick := True;
  FPointEdit := TPEdt;
  Self.Hide;
  FParentForm.Hide;
end;

function TActionEditForm.ShowForAdd(var Act: TACtionInfo; Obj: TObjectImage; ParentF: TObjectOptionsForm): TModalResult;
var
  Tmp: TACtionInfo;
begin
  FObj := Obj;
  FIsEditing := False;
  FIsWaitingClick := False;
  FParentForm := ParentF;

  if Obj.ActionList[0] <> nil then
  begin
    Tmp := Obj.EndActionList^.Info;
    edtTimeStart.Text := IntToStr(Tmp.TimeEnd);
    edtStartPointX.Text := IntToStr(Tmp.EndPoint.X);
    edtStartPointY.Text := IntToStr(Tmp.EndPoint.Y);
  end
  else
  begin
    edtTimeStart.Text := '0';
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

function TActionEditForm.ShowForEdit(var Act: TACtionInfo; Obj: TObjectImage; ParentF: TObjectOptionsForm)
  : TModalResult;
begin
  FObj := Obj;
  FIsEditing := True;
  FCurrAct := Act;
  FIsWaitingClick := False;
  FParentForm := ParentF;

  cbActionType.ItemIndex := Ord(Act.ActType);
  cbActionTypeChange(Self);
  if Act.ActType = actCircleMove then
  begin
    edtThirdX.Text := IntToStr(Act.ThirdPoint.X);
    edtThirdY.Text := IntToStr(Act.ThirdPoint.Y);
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

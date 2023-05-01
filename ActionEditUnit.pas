unit ActionEditUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

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
    procedure FormShow(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FIsConfirm: Boolean;
  public
    { properties }
    property IsConfirm: Boolean read FIsConfirm;
  end;

var
  ActionEditForm: TActionEditForm;

implementation

{$R *.dfm}

uses
  MainUnit, ObjectOptionsUnit;

procedure TActionEditForm.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TActionEditForm.btnOkClick(Sender: TObject);
begin
  if (edtTimeStart.Text <> '') and (edtTimeEnd.Text <> '') and (cbActionType.Text <> '') and
    (StrToInt(edtTimeStart.Text) < StrToInt(edtTimeEnd.Text)) and (edtStartPointX.Text <> '') and
    (edtStartPointY.Text <> '') and (edtEndPointX.Text <> '') and (edtEndPointY.Text <> '') then
  begin
    FIsConfirm := True;
    Close;
  end
  else
    ShowMessage('Fill in the fields correctly');
end;

procedure TActionEditForm.FormShow(Sender: TObject);
begin
  FIsConfirm := False;
end;

end.

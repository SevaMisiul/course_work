unit ProgressViewUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Samples.Gauges;

type
  TProgressForm = class(TForm)
    gProgress: TGauge;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ProgressForm: TProgressForm;

implementation

{$R *.dfm}

procedure TProgressForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ProgressForm.gProgress.Progress := 100;
end;

procedure TProgressForm.FormShow(Sender: TObject);
begin
  ProgressForm.gProgress.Progress := 0;
end;

end.

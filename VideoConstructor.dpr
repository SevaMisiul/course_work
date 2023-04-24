program VideoConstructor;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  BackMenuUnit in 'BackMenuUnit.pas' {BackMenuForm},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TBackMenuForm, BackMenuForm);
  Application.Run;
end.

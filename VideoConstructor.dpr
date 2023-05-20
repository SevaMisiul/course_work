program VideoConstructor;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  BackMenuUnit in 'BackMenuUnit.pas' {BackMenuForm},
  Vcl.Themes,
  Vcl.Styles,
  ObjectOptionsUnit in 'ObjectOptionsUnit.pas' {ObjectOptionsForm},
  ActionEditUnit in 'ActionEditUnit.pas' {ActionEditForm},
  ObjectUnit in 'ObjectUnit.pas',
  VideoUnit in 'VideoUnit.pas',
  vfw in 'vfw.pas',
  MPEGFunctions in 'MPEGFunctions.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TBackMenuForm, BackMenuForm);
  Application.CreateForm(TObjectOptionsForm, ObjectOptionsForm);
  Application.CreateForm(TActionEditForm, ActionEditForm);
  Application.Run;
end.

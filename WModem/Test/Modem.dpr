program Modem;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  CommInt in 'Async32\CommInt.pas',
  CommObjs in 'Async32\CommObjs.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

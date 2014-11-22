program Counter;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  ArchManThd in '..\ARCHMAN\ArchManThd.pas',
  ArchMan_TLB in '..\ARCHMAN\ArchMan_TLB.pas',
  Misc in '..\UNITS\Misc.pas',
  SensorTypes in '..\UNITS\SensorTypes.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

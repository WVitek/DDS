program Replay;

uses
  Forms,
  Main in 'Main.pas' {FormReplay},
  Misc in '..\Units\Misc.pas',
  SensorTypes in '..\Units\SensorTypes.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  ArchManThd in '..\ArchMan\ArchManThd.pas',
  ArchMan_TLB in '..\ArchMan\ArchMan_TLB.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'СКУ : Повтор архива';
  Application.CreateForm(TFormReplay, FormReplay);
  Application.Run;
end.

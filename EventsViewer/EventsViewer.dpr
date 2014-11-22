program EventsViewer;

uses
  Forms,
  Main in 'Main.pas' {FormEventsView},
  Misc in '..\Units\Misc.pas',
  SensorTypes in '..\Units\SensorTypes.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  ArchManThd in '..\ArchMan\ArchManThd.pas',
  ArchMan_TLB in '..\ArchMan\ArchMan_TLB.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'СКУ : Просмотр событий';
  Application.CreateForm(TFormEventsView, FormEventsView);
  Application.Run;
end.

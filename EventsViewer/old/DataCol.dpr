program DataCol;

uses
  Forms,
  Main in 'Main.pas' {FormDataCol},
  Misc in '..\Units\Misc.pas',
  SensorTypes in '..\Units\SensorTypes.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  ArchManThd in '..\ArchMan\ArchManThd.pas',
  ArchMan_TLB in '..\ArchMan\ArchMan_TLB.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'СКУ : Сбор данных';
  Application.CreateForm(TFormDataCol, FormDataCol);
  Application.Run;
end.

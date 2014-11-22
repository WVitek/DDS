program ArchSync;

uses
  Forms,
  ArchMan_TLB in '..\ArchMan\ArchMan_TLB.pas',
  ArchManThd in '..\ArchMan\ArchManThd.pas',
  SensorTypes in '..\Units\SensorTypes.pas',
  main in 'main.pas' {FrmMain},
  DataTypes in '..\Units\DataTypes.pas',
  DdhAppX in '..\DDH_AppX\DdhAppX.pas',
  Misc in '..\Units\Misc.pas',
  FileMan in '..\ArchMan\FileMan.pas',
  Pinger in 'Pinger.pas',
  Common in 'Common.pas',
  UTime in '..\UNITS\UTime.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'СКУ Синхронизатор';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.

program Loader;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  SensorFrame in 'SensorFrame.pas' {FrameSensor: TFrame},
  Misc in '..\Units\Misc.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  ConvTP in '..\Units\convTP.pas',
  DataTypes in '..\Units\DataTypes.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

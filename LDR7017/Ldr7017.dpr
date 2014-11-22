program Ldr7017;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  SensorFrame in '..\Units\SensorFrame.pas' {FrameSensor: TFrame},
  Misc in '..\Units\Misc.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  ConvTP in '..\Units\convTP.pas',
  DataTypes in '..\Units\DataTypes.pas',
  ConversionForm in '..\Units\ConversionForm.pas' {FormConversion},
  SensorTypes in '..\UNITS\SensorTypes.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'Ldr7017';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

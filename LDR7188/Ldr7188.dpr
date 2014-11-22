program Ldr7188;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  SensorFrame in 'SensorFrame.pas' {FrameSensor: TFrame},
  Misc in '..\Units\Misc.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  ConvTP in '..\Units\convTP.pas',
  DataTypes in '..\Units\DataTypes.pas',
  SensorTypes in '..\UNITS\SensorTypes.pas',
  ConversionForm in '..\UNITS\ConversionForm.pas' {FormConversion};

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'Ldr7017';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormConversion, FormConversion);
  Application.Run;
end.

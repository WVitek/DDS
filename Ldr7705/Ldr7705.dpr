program Ldr7705;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  Misc in '..\Units\Misc.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  DataTypes in '..\Units\DataTypes.pas',
  SensorTypes in '..\UNITS\SensorTypes.pas',
  UFrameSensor in 'UFrameSensor.pas' {FrameSensor: TFrame},
  UFormConv in 'UFormConv.pas' {FormConv},
  UModem in '..\WModem\UModem.pas',
  CommInt in '..\WModem\CommInt.pas',
  CommObjs in '..\WModem\CommObjs.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'Ldr7705';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormConv, FormConv);
  Application.Run;
end.

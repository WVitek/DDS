program NetMLdr;

uses
  Forms,
  UTime in '..\UNITS\UTime.pas',
  UPRT in 'UPRT.pas',
  UPRT_COMPORT in 'UPRT_COMPORT.pas',
  UPRT_Liner in 'UPRT_Liner.pas',
  UNetW in 'UNetW.pas',
  UFrameLeasedLine in '..\UNITS\UFrameLeasedLine.pas' {FrameLeasedLine: TFrame},
  Misc in '..\Units\Misc.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  DataTypes in '..\Units\DataTypes.pas',
  SensorTypes in '..\UNITS\SensorTypes.pas',
  UFrameKP in 'UFrameKP.pas' {FrameKP: TFrame},
  UFrameAnalog in 'UFrameAnalog.pas' {FrameAnalog: TFrame},
  UTreeItem in 'UTreeItem.pas',
  UFormMain in 'UFormMain.pas' {FormMain},
  UModem in '..\WModem\UModem.pas',
  CommInt in '..\WModem\CommInt.pas',
  CommObjs in '..\WModem\CommObjs.pas',
  UCRC in 'UCRC.pas',
  UServices in 'UServices.pas',
  UPRT_UDP in 'UPRT_UDP.pas',
  UFrameUDPLine in 'UFrameUDPLine.pas' {FrameUDPLine: TFrame},
  UPRT_HalfduplexLiner in 'UPRT_HalfduplexLiner.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

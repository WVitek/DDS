program MLdr7188;

uses
  Forms,
  Misc in '..\Units\Misc.pas',
  DdhAppX in '..\DDH_AppX\Ddhappx.pas',
  DataTypes in '..\Units\DataTypes.pas',
  SensorTypes in '..\UNITS\SensorTypes.pas',
  UFrameKP in 'UFrameKP.pas' {FrameKP: TFrame},
  UFrameAnalog in 'UFrameAnalog.pas' {FrameAnalog: TFrame},
  UTreeItem in 'UTreeItem.pas',
  UFormMain in 'UFormMain.pas' {FormMain},
  UFrameMain in 'UFrameMain.pas' {FrameMain: TFrame},
  UModem in '..\WModem\UModem.pas',
  CommInt in '..\WModem\CommInt.pas',
  CommObjs in '..\WModem\CommObjs.pas',
  UCRC in 'UCRC.pas',
  UPRT in 'UPRT.pas',
  UServices in 'UServices.pas',
  UTime in '..\UNITS\UTime.pas',
  SysUtils, Windows;

{$R *.RES}

begin
  try
    Application.Initialize;
    Application.ShowMainForm:=False;
    Application.CreateForm(TFormMain, FormMain);
    Application.Run;
  except
    on e:Exception do
      Application.MessageBox(
        PChar(e.message),
        'Критический сбой MLdr7188',
        MB_OK or MB_ICONERROR
      );
  end;
end.

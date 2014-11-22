program Monitor;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  UFormPipe in 'UFormPipe.pas' {FormPipe},
  UFrameGroup in 'UFrameGroup.pas' {FrameGroup: TFrame},
  UFrameGraph in 'UFrameGraph.pas' {FrameGraph: TFrame},
  DataTypes in '..\Units\DataTypes.pas',
  DblGraphics in '..\Units\DblGraphics.pas',
  Misc in '..\Units\Misc.pas',
  ArchMan_TLB in '..\ArchMan\ArchMan_TLB.pas',
  DaySelect in '..\M_Shared\DaySelect.pas' {DateForm},
  SensorTypes in '..\Units\SensorTypes.pas',
  ArchManThd in '..\ArchMan\ArchManThd.pas',
  SensorOptions in '..\M_Shared\SensorOptions.pas' {FormSensorOptions},
  DateTimeSelect in '..\M_Shared\DateTimeSelect.pas' {FormDateTime},
  MessageForm in '..\M_Shared\MessageForm.pas' {FormMessage},
  DataTypes2 in 'DataTypes2.pas',
  UGroupOptions in 'UGroupOptions.pas' {GroupOptions},
  UFormAnaliz in 'UFormAnaliz.pas' {FormAnaliz},
  UWaveFormComputer in 'UWaveFormComputer.pas',
  UFFT in 'UFFT.pas',
  UScanner in 'UScanner.pas',
  Minimize in 'MINIMIZE.PAS',
  UFormScanner in 'UFormScanner.pas' {FormScanner},
  USortedList in '..\UNITS\USortedList.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

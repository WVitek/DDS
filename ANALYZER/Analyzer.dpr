program Analyzer;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  Sequences in 'Sequences.pas',
  ArchMan_TLB in '..\ArchMan\ArchMan_TLB.pas',
  ArchManThd in '..\ArchMan\ArchManThd.pas',
  Works in 'Works.pas',
  DataTypes in '..\Units\DataTypes.pas',
  FA32 in '..\Units\FA32.pas',
  SensorTypes in '..\UNITS\SensorTypes.pas',
  Misc in '..\UNITS\Misc.pas',
  Minimize in '..\UNITS\MINIMIZE.PAS',
  Student in 'STUDENT.PAS';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

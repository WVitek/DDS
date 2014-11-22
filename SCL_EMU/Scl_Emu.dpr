program Scl_Emu;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  Misc in '..\Units\Misc.pas',
  DataTypes in '..\Units\DataTypes.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

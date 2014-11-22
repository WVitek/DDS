program ArchMan;

uses
  Forms,
  ComObj,
  ActiveX,
  Main in 'Main.pas' {MainForm},
  ArchMan_TLB in 'ArchMan_TLB.pas',
  ArchManImplementation in 'ArchManImplementation.pas' {DDSArchiveManager: CoClass},
  FileMan in 'FileMan.pas',
  AMProvider in 'AMProvider.pas' {DDSArchiveManagerProvider: CoClass},
  Misc in '..\Units\Misc.pas';

{$R *.TLB}

{$R *.RES}

begin
  //if ParamCount=0 then exit;
  Application.ShowMainForm:=False;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

program Center;

uses
  Windows, Messages, SysUtils, Forms,
  Misc,
  Main in 'Main.pas' {FrmMain};

{$R *.RES}

var
  MainWndCaption:String;

procedure BeforeStart;
var
  hWnd:THandle;
  i:Integer;
begin
  MainWndCaption:=GetModuleFullName;
  hWnd:=Windows.FindWindow(nil,PChar(MainWndCaption));
  if hWnd<>0 then
  begin
    PostMessage(hWnd,WM_CLOSE,0,0);
    Sleep(1000);
  end;
  if FindCmdLineSwitch('close',['-','/'],True)
  then Halt(0);
end;

begin
  BeforeStart;
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.CreateForm(TFrmMain, FrmMain);
  FrmMain.Caption:=MainWndCaption;
  Application.Run;
end.

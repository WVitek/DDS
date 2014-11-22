unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  DdhAppX, Menus, IniFiles, Misc, ShellAPI, ExtCtrls;

type
  TProgramController=class;

  TFrmMain = class(TForm)
    AppExt: TDdhAppExt;
    TrayPopupMenu: TPopupMenu;
    pmiDDSClose: TMenuItem;
    pmiLine1: TMenuItem;
    Timer: TTimer;
    pmiReboot: TMenuItem;
    pmiShutdown: TMenuItem;
    procedure pmiCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure pmiProgramClick(Sender: TObject);
    procedure AppExtLBtnDown(Sender: TObject);
    procedure CloseProgs;
    procedure pmiShutdownClick(Sender: TObject);
    procedure pmiRebootClick(Sender: TObject);
    procedure pmiLogoffClick(Sender: TObject);
  private
    function Get_Progs(i: Integer): TProgramController;
  public
    { Public declarations }
    Ini:TIniFile;
    FProgs:TList;
  property
    Progs[i:Integer]:TProgramController read Get_Progs;
  end;

  TProgramController=class(TObject)
    mi:TMenuItem;
    AppName,CmdLine,CurDir:String;
    CreationFlags:Cardinal;
    SI:TStartupInfo;
    PI:TProcessInformation;
    Valid:Boolean;
    constructor CreateFromIniSection(Ini:TIniFile; const Section:String);
    procedure SupportProcessActivity;
    function StartProcess:Boolean;
    procedure CloseHandles;
    procedure QuitProcess;
    procedure RestoreMainWindow;
    function ProcessStillActive:Boolean;
    destructor Destroy;override;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.DFM}

function enumShowWindows(hwnd:THandle; CmdShow:Cardinal):Boolean;stdcall;
begin
  if IsWindow(hwnd) and IsWindowVisible(hwnd) then begin
    ShowWindowAsync(hwnd,CmdShow);
    SetActiveWindow(hwnd);
    Result:=False;
  end
  else Result:=True;
end;

procedure ShowThdWindows(ThdId:Cardinal; CmdShow:Cardinal);
begin
  EnumThreadWindows(ThdId,@enumShowWindows,CmdShow);
end;

procedure TFrmMain.pmiCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
const
  Config='Config';
  TPSize=16384;
type
  PDWORD=^DWORD;
  PTokenPrivileges=^_TOKEN_PRIVILEGES;
var
  SL:TStringList;
  i:Integer;
  PC:TProgramController;
  FName:String;
  PTH:THandle;
  TP:^_TOKEN_PRIVILEGES;
  j:Cardinal;
begin
{
  if ParamCount=0
  then FName:=GetModuleFullName+'.ini'
  else FName:=ExpandFileName(ParamStr(1));
}
  FName:=GetModuleFullName+'.ini';
  Ini:=TIniFile.Create(FName);
  FProgs:=TList.Create;
  SL:=TStringList.Create;
  try
    Ini.ReadSections(SL);
    for i:=0 to SL.Count-1 do begin
      PC:=TProgramController.CreateFromIniSection(Ini,SL[i]);
      if PC.Valid then begin
        FProgs.Add(PC);
        PC.mi.OnClick:=pmiProgramClick;
        TrayPopupMenu.Items.Insert(0,PC.mi);
      end
      else PC.Free;
    end;
  except
    Halt(1);
  end;
  SL.Free;
  GetMem(TP,TPSize);
  try
    FillChar(TP^,TPSize,0);
    if not OpenProcessToken(GetCurrentProcess,TOKEN_ALL_ACCESS,PTH)
    then// LastErrorMsg(FALSE)
    else begin
      TP^.PrivilegeCount:=1;
      if not LookupPrivilegeValue('','SeShutdownPrivilege',TP^.Privileges[0].Luid)
      then// LastErrorMsg(FALSE)
      else begin
        TP^.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
        if not AdjustTokenPrivileges(PTH,False,TP^,0,PTokenPrivileges(nil)^,PDWORD(nil)^)
        then// LastErrorMsg(FALSE)
        else begin
          FillChar(TP^,TPSize,0);
          if not GetTokenInformation(PTH,TokenPrivileges,TP,TPSize,j)
          then// LastErrorMsg(FALSE);
        end;
      end;
    end;
  finally
    FreeMem(TP,TPSize);
  end;
end;

function TFrmMain.Get_Progs(i: Integer): TProgramController;
begin
  Result:=FProgs[i];
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  CloseProgs;
end;

procedure TFrmMain.TimerTimer(Sender: TObject);
var
  i:Integer;
begin
  if FProgs=nil then exit;
  for i:=0 to FProgs.Count-1 do Progs[i].SupportProcessActivity;
end;

procedure TFrmMain.pmiProgramClick(Sender: TObject);
var
  i:Integer;
begin
  for i:=0 to FProgs.Count-1 do begin
    if Progs[i].mi=Sender then begin
      Progs[i].RestoreMainWindow;
      break;
    end;
  end;
end;

procedure TFrmMain.AppExtLBtnDown(Sender: TObject);
var
  P:TPoint;
begin
  GetCursorPos(P);
  TrayPopupMenu.Popup(P.x,P.y);
end;

procedure TFrmMain.CloseProgs;
var
  i:Integer;
begin
  for i:=0 to FProgs.Count-1 do Progs[i].Free;
  FProgs.Count:=0;
end;

{ TProgramController }

procedure TProgramController.CloseHandles;
begin
  CloseHandle(PI.hThread);
  CloseHandle(PI.hProcess);
end;

constructor TProgramController.CreateFromIniSection(Ini: TIniFile;
  const Section: String);

  function GetShowCmd(SCStr:String):Cardinal;
  begin
    SCStr:=UpperCase(Trim(SCStr));
    if SCStr='MAX' then Result:=SW_SHOWMAXIMIZED
    else if SCStr='MIN' then Result:=SW_SHOWMINNOACTIVE
    else Result:=SW_SHOWNORMAL;
  end;

  function GetPriority(PrStr:String):Cardinal;
  begin
    PrStr:=UpperCase(Trim(PrStr));
    if PrStr='IDLE' then Result:=IDLE_PRIORITY_CLASS
    else if PrStr='HIGH' then Result:=HIGH_PRIORITY_CLASS
    else if PrStr='REALTIME' then Result:=REALTIME_PRIORITY_CLASS
    else Result:=NORMAL_PRIORITY_CLASS; // if PrStr='NORMAL'
  end;

var
  Icon:TIcon;
  IconFile:String;
begin
  inherited Create;
  FillChar(SI,SizeOf(SI),0);
  SI.cb:=SizeOf(SI);
  SI.dwFlags:=STARTF_USESHOWWINDOW;
  SI.wShowWindow:=GetShowCmd(Ini.ReadString(Section,'ShowCmd',''));
  AppName:=ExpandFileName(Ini.ReadString(Section,'AppName',''));
  CmdLine:=Ini.ReadString(Section,'CmdLine','');
  CurDir:=ExpandFileName(Ini.ReadString(Section,'CurDir',''));
  CreationFlags:=GetPriority(Ini.ReadString(Section,'Priority',''));
  if StartProcess then begin
    mi:=TMenuItem.Create(nil);
    mi.Caption:=Ini.ReadString(Section,'Caption','empty caption');
    mi.Bitmap.PixelFormat:=pf8bit;
    mi.Bitmap.Width:=32;
    mi.Bitmap.Height:=32;
    Icon:=TIcon.Create;
    try
      try
        IconFile:=ExpandFileName(Ini.ReadString(Section,'IconFile',AppName));
        Icon.Handle:=ExtractIcon(HInstance,PChar(Iconfile),0);
        mi.Bitmap.Canvas.Draw(0,0,Icon);
      finally
        Icon.Free;
      end;
    except
    end;
    Valid:=True;
  end
  else Valid:=False;
end;

destructor TProgramController.Destroy;
begin
  QuitProcess;
  CloseHandles;
  mi.Free;
  inherited;
end;

procedure TProgramController.SupportProcessActivity;
begin
  if ProcessStillActive then exit;
  CloseHandles;
  StartProcess;
end;

function TProgramController.ProcessStillActive: Boolean;
var
  ExitCode:Cardinal;
begin
  ExitCode:=0;
  GetExitCodeProcess(PI.hProcess,ExitCode);
  Result:=(ExitCode=STILL_ACTIVE);
end;

procedure TProgramController.QuitProcess;
begin
  PostThreadMessage(PI.dwThreadId,WM_QUIT,0,0);
end;

function TProgramController.StartProcess: Boolean;
begin
  Result:=CreateProcess(
    PChar(AppName),PChar(CmdLine),nil,nil,False,CreationFlags,nil,PChar(CurDir),SI,PI
  );
end;

procedure TProgramController.RestoreMainWindow;
begin
//  ShowThdWindows(PI.dwThreadId,SW_SHOWNORMAL);
  PostThreadMessage(PI.dwThreadId,WM_ACTIVATEAPP,Cardinal(True),PI.dwThreadId);
end;

procedure TFrmMain.pmiShutdownClick(Sender: TObject);
begin
  CloseProgs;
  ExitWindowsEx(EWX_SHUTDOWN,0);
  Close;
end;

procedure TFrmMain.pmiRebootClick(Sender: TObject);
begin
  CloseProgs;
  ExitWindowsEx(EWX_REBOOT,0);
  Close;
end;

procedure TFrmMain.pmiLogoffClick(Sender: TObject);
begin
  CloseProgs;
  ExitWindowsEx(EWX_LOGOFF,0);
  Close;
end;

end.

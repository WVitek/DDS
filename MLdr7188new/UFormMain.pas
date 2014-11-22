unit UFormMain;

interface

uses
  Windows, MMSystem, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, Misc, DdhAppX, Menus, ExtCtrls, NMUDP, DataTypes,
  SensorTypes, StdCtrls, ComCtrls, UFrameMain, CommInt, UModem, UTreeItem, UPRT;

type
  TFormMain = class(TForm)
    AppExt: TDdhAppExt;
    PopupMenu: TPopupMenu;
    pmiClose: TMenuItem;
    pmiAbout: TMenuItem;
    NMUDP: TNMUDP;
    N2: TMenuItem;
    pmiShowHide: TMenuItem;
    Timer: TTimer;
    TreeView: TTreeView;
    Modem: TModem;
    TimerProcessIO: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure pmiCloseClick(Sender: TObject);
    procedure pmiAboutClick(Sender: TObject);
    procedure AppExtTrayDefault(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure NMUDPInvalidHost(var handled: Boolean);
    procedure NMUDPBufferInvalid(var handled: Boolean;
      var Buff: array of Char; var length: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure TreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure ModemConnFailed(Sender: TObject);
    procedure ModemConnect(Sender: TObject);
    procedure ModemResponse(Sender: TObject);
    procedure ModemDisconnect(Sender: TObject);
    procedure ProcessIO(Sender: TObject);
    procedure ModemModemRxChar(Sender: TObject; Count: Integer);
  private
    { Private declarations }
    TimerAutoSave:Integer;
  public
    { Public declarations }
    Cfg:TIniFile;
    Main:TItemMain;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.DFM}

//const
//  ProgName='MLdr7188';
//  Section=ProgName;

procedure TFormMain.FormCreate(Sender: TObject);
var
  hSysMenu:Integer;
  Ini:TIniFile;
  S,Section:String;
begin
  try
    InitFormattingVariables;
    S:=Misc.GetModuleFullName;
    Ini:=TIniFile.Create(S+'.ini');
    Cfg:=TIniFile.Create(S+'.wcf');
    Section:=ExtractFileName(S);
    Caption:=Ini.ReadString(Section,'AppTitle',Section);
    Application.Title := Caption;
    AppExt.TrayHint:=Ini.ReadString(Section,'TrayHint',Section);
    Main:=TItemMain.Load(Ini,Cfg,Section);
    Ini.Free;
    Application.Title:=Caption;
    hSysMenu:=GetSystemMenu(Handle,False);
    EnableMenuItem(hSysMenu,SC_CLOSE,MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
    ShowWindow(Application.Handle,0);
  except
    Application.Terminate;
  end;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Main.SaveCfg(Cfg);
  Main.Free;
  Cfg.Free;
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=Application.Terminated;
end;

procedure TFormMain.pmiCloseClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFormMain.pmiAboutClick(Sender: TObject);
begin
  Application.MessageBox(PChar(
    'СКУ'#13#10#13#10+
    'MultiLoader7188 full duplex '+GetFileBuildInfo+#13#13+
    'Интерфейс по дозвону с контроллерами нижнего уровня'),
    'О программе',
    MB_ICONINFORMATION or MB_OK or MB_TOPMOST);
end;

procedure TFormMain.AppExtTrayDefault(Sender: TObject);
begin
  if Application.Active then Visible:=not Visible else Visible:=TRUE;
  SetForegroundWindow(Handle);
end;

procedure TFormMain.TimerTimer(Sender: TObject);
begin
  Main.TimerProc;
  Inc(TimerAutoSave);
  if TimerAutoSave>=120 then begin
    Main.SaveCfg(Cfg);
    TimerAutoSave:=0;
  end;
end;

procedure TFormMain.NMUDPInvalidHost(var handled: Boolean);
begin
  handled:=True;
end;

procedure TFormMain.NMUDPBufferInvalid(var handled: Boolean;
  var Buff: array of Char; var length: Integer);
begin
  handled:=true;
end;

procedure TFormMain.FormKeyPress(Sender: TObject; var Key: Char);
const
  Pos:Integer=1;
  Pwd1:String='Programming!';
  Pwd2:String='DoDump!';
begin
  if (Key=Pwd1[Pos]) then begin
    if Pos<Length(Pwd1) then Inc(Pos)
    else begin
      Pos:=1;
      Main.SwitchProgramming;
    end;
  end
  else if (Key=Pwd2[Pos]) then begin
    if Pos<Length(Pwd2) then Inc(Pos)
    else begin
      Pos:=1;
      Main.SwitchDumping;
    end;
  end
  else Pos:=1;
end;

procedure TFormMain.TreeViewChange(Sender: TObject; Node: TTreeNode);
var
  F:TFrame;
begin
  if TreeView.Selected<>nil then TTreeItem(TreeView.Selected.Data).Leave;
  if Node<>nil then begin
    F:=TTreeItem(Node.Data).Enter;
    F.Align:=alClient;
    F.Parent:=Self;
  end;
end;

procedure TFormMain.ModemConnFailed(Sender: TObject);
begin
  Main.OnConnFailed;
end;

procedure TFormMain.ModemConnect(Sender: TObject);
begin
  Main.OnConnect;
end;

procedure TFormMain.ModemResponse(Sender: TObject);
begin
  Main.OnModemResponse;
end;

procedure TFormMain.ModemDisconnect(Sender: TObject);
begin
  Main.OnDisconnect;
end;

procedure TFormMain.ProcessIO(Sender: TObject);
begin
  Main.ProcessIO;
end;

procedure TFormMain.ModemModemRxChar(Sender: TObject; Count: Integer);
begin
  Main.ProcessIO;
end;

end.

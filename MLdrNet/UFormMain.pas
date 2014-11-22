unit UFormMain;

interface

uses
  Windows, MMSystem, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, Misc, DdhAppX, Menus, ExtCtrls, NMUDP, DataTypes,
  SensorTypes, StdCtrls, ComCtrls, CommInt, UModem, UTreeItem, UNetW;

type
  TWhatToDo = (wtdTimerProc, wtdSaveCfg, wtdFree);

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
    procedure ProcessIO(Sender: TObject);
  private
    { Private declarations }
    TimerAutoSave:Integer;
    procedure ForAllTreeItems(WhatToDo:TWhatToDo);
  public
    { Public declarations }
    Cfg:TIniFile;
  end;

var
  FormMain: TFormMain;

implementation

uses UTime, UFrameLeasedLine, UFrameKP, UFrameUDPLine, UPRT_COMPORT;

{$R *.DFM}

procedure TFormMain.FormCreate(Sender: TObject);
var
  hSysMenu:Integer;
  Ini:TIniFile;
  S,Section:String;
  i,n:Integer;
begin
  try
    SetMyTimeType(mttMSK);
    InitFormattingVariables;
    S:=Misc.GetModuleFullName;
    Ini:=TIniFile.Create(S+'.ini');
    Cfg:=TIniFile.Create(S+'.wcf');
    Section:=ExtractFileName(S);
    Caption:=Ini.ReadString(Section,'AppTitle',Section);
    Application.Title := Caption;
    AppExt.TrayHint:=Ini.ReadString(Section,'TrayHint',Section);
    UTime.SetMyTimeType(Ini.ReadInteger(Section,'MyTimeType',2));
    n:=Ini.ReadInteger(Section,'nLine',0);
    for i:=1 to n do begin
      S:=Ini.ReadString(Section,Format('Line%d',[i]),'');
      if S<>'' then TItemLLine.Load(TreeView.Items,nil,Ini,Cfg,S);
    end;
    if Ini.ReadBool(Section,'NetUDP',False)
    then TItemUDPLine.Load(NMUDP,TreeView.Items,nil,Ini,Cfg,'NetUDP');
    n:=Ini.ReadInteger(Section,'nKP',0);
    for i:=1 to n do begin
      S:=Ini.ReadString(Section,Format('KP%d',[i]),'');
      if S<>'' then TItemKP.Load(TreeView.Items,nil,Ini,Cfg,S);
    end;
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
  ForAllTreeItems(wtdSaveCfg);
  Cfg.Free;
  ForAllTreeItems(wtdFree);
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
    'NetMultiLoader '+GetFileBuildInfo+#13#13+
    'Загрузчик данных с контроллеров нижнего уровня'),
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
  ForAllTreeItems(wtdTimerProc);
  Inc(TimerAutoSave);
  if TimerAutoSave>=120 then
  begin
    TimerAutoSave:=0;
    ForAllTreeItems(wtdSaveCfg);
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
  iPwd:Integer=0;
  Pwd:array[1..3] of String=(
    'Programming!',
    'DoDump!',
    'SendSoftReset!'
  );
var
  KP:TItemKP;
begin
  KP:=TItemKP(TreeView.Selected.Data);
  if KP.ClassNameIs('TItemKP')
  then begin
    if iPwd>0 then begin
      if (Key=Pwd[iPwd][Pos]) then begin
        if Pos<Length(Pwd[iPwd])
        then Inc(Pos)
        else begin
          case iPwd of
            1: KP.SwitchProgramming;
            2: ;
            3: KP.SendSoftReset;
          end;
          iPwd:=0;
        end;
      end
      else
        iPwd:=0;
    end;
    if iPwd=0 then begin
      iPwd:=High(Pwd);
      while (iPwd>0) and (Key<>Pwd[iPwd][1]) do Dec(iPwd);
      Pos:=2;
    end;
  end;
end;

procedure TFormMain.TreeViewChange(Sender: TObject; Node: TTreeNode);
var
  F:TFrame;
begin
  if TreeView.Selected<>nil then TTreeItem(TreeView.Selected.Data).Leave;
  if (Node<>nil) and (TObject(Node.Data) is TTreeItem) then begin
    F:=TTreeItem(Node.Data).Enter(Self);
    F.Align:=alClient;
    F.Parent:=Self;
  end;
end;

procedure TFormMain.ProcessIO(Sender: TObject);
begin
  NetW_ProcessIO;
end;

procedure TFormMain.ForAllTreeItems(WhatToDo: TWhatToDo);
var
  i:Integer;
  Item:TTreeItem;
  Ns:TTreeNodes;
begin
  Ns:=TreeView.Items;
  for i:=0 to Ns.Count-1 do begin
    Item:=Ns.Item[i].Data;
    if Item is TTreeItem then begin
      case WhatToDo of
      wtdTimerProc:
        Item.TimerProc;
      wtdSaveCfg:
        Item.SaveCfg(Cfg);
      wtdFree:
        begin
          Item.Free;
          Ns.Item[i].Data:=nil;
        end;
      end;
    end;
  end;
end;

end.

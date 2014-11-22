unit UFrameUDPLine;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Comctrls, Contnrs, StdCtrls, IniFiles, NMUDP, UTreeItem, UPRT_UDP, UPRT_Liner;

type
  TFrameUDPLine = class(TFrame)
    GroupBox2: TGroupBox;
    Memo: TMemo;
    gbStat: TGroupBox;
    LabelStatSec: TLabel;
    LabelStatAll: TLabel;
    lblStatAll: TLabel;
    lblStatSec: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TUDPConnection = class(TObject)
    prt1:TPRT_UDP;
    prt2:TPRT_LINER;
    Stat:TLinkStat;
    procedure ProcessIO;
    constructor Create(IP:String; Port:Integer; UDP:TNMUDP);
    destructor Destroy;override;
  end;

  TItemUDPLine = class(TTreeItem)
  protected
    UDP:TNMUDP;
    FUL:TFrameUDPLine;
    Links:TStringList;
    FEvents:String;
    StatAll,StatSec:TLinkStat;
    procedure AddEvent(Time:TDateTime; Event:String);overload;
    procedure AddEvent(Event:String);overload;
    procedure NMUDPDataReceived(Sender: TComponent; NumberBytes: Integer;
      FromIP: String; Port: Integer);
    class function GetKeyStr(IP:String; Port:Integer):String;
    function GetLink(IP:String; Port:Integer):TUDPConnection;
    procedure UpdateFrame;
  public
    function Enter(Owner:TComponent):TFrame;override;
    function Leave:Boolean;override;
//    function Validate:Boolean;override;
    constructor Load(UDP:TNMUDP; Nodes:TTreeNodes; ParentNode:TTreeNode; Ini,Cfg:TIniFile; const Section:String);reintroduce;
    destructor Destroy;override;
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
  end;


implementation

uses
  Misc, UTime, UNetW, UCRC;

{$R *.DFM}

{ TItemUDPLine }

procedure TItemUDPLine.AddEvent(Time: TDateTime; Event: String);
begin
  Event:=LogMsg(Time,Event);
  if FUL<>nil then begin
    FUL.Memo.SelStart:=0;
    FUL.Memo.SelText:=Event;
  end;
  FEvents:=Event+FEvents;
  WriteToLog(Event);
end;

procedure TItemUDPLine.AddEvent(Event: String);
begin
  AddEvent(GetMyTime,Event);
end;

destructor TItemUDPLine.Destroy;
var
  i:Integer;
begin
  for i:=Links.Count-1 downto 0
  do TUDPConnection(Links.Objects[i]).Free;
  Links.Free;
end;

function TItemUDPLine.Enter(Owner: TComponent): TFrame;
begin
  FUL:=TFrameUDPLine.Create(Owner);
  FUL.Memo.Text:=FEvents;
  FUL.Memo.SelStart:=Length(FEvents);
  UpdateFrame;
  Result:=FUL;
end;

class function TItemUDPLine.GetKeyStr(IP: String; Port: Integer): String;
begin
  Result:=IP+':'+IntToStr(Port);
end;

function TItemUDPLine.GetLink(IP: String; Port:Integer): TUDPConnection;
var
  Key:String;
  i:Integer;
begin
  Key:=GetKeyStr(IP,Port);
  if not Links.Find(Key,i) then begin
    i:=Links.AddObject(Key,TUDPConnection.Create(IP,Port,UDP));
    AddEvent('UDP/IP-связь с '+Key);
  end;
  Result:=Pointer(Links.Objects[i]);
end;

function TItemUDPLine.Leave: Boolean;
begin
  FUL.Free; FUL:=nil;
  Result:=True;
end;

constructor TItemUDPLine.Load(UDP:TNMUDP; Nodes: TTreeNodes; ParentNode: TTreeNode;
  Ini, Cfg: TIniFile; const Section: String);
begin
  Self.Section:=Section;
  Node:=Nodes.AddChildObject(ParentNode, Section, Self);
  Links:=CreateSortedStringList;
  Self.UDP:=UDP;
  UDP.OnDataReceived:=NMUDPDataReceived;
end;

procedure TItemUDPLine.NMUDPDataReceived(Sender: TComponent;
  NumberBytes: Integer; FromIP: String; Port: Integer);
type
  TCharArray = array[0..MaxInt-1] of char;
var
  InBuf:String;
  Buf:^TCharArray;
  Link:TUDPConnection;
begin
  SetLength(InBuf,NumberBytes);
  Buf:=@(InBuf[1]);
  UDP.ReadBuffer(Buf^,NumberBytes);
  if (FromIP<>'127.0.0.1') {and (InBuf[Length(InBuf)]=Chr($0D))} then
  begin
    Link:=GetLink(FromIP,Port);
    Link.prt1.AddToRxQue(InBuf);
  end;
end;

procedure TItemUDPLine.SaveCfg(Cfg: TIniFile);
begin
  // nothing to do
end;

procedure TItemUDPLine.TimerProc;
var
  i:Integer;
  L:TUDPConnection;
begin
  i:=Links.Count-1;
  StatAll.Add(StatSec); StatSec.Clear;
  while i>=0 do begin
    L:=TUDPConnection(Links.Objects[i]);
    StatSec.Add(L.Stat); L.Stat.Clear;
    if L.prt1.LinkTimeout then begin
      AddEvent('Таймаут связи  '+Links[i]);
      Links.Delete(i);
      L.Free;
    end;
    Dec(i);
  end;
  UpdateFrame;
end;

procedure TItemUDPLine.UpdateFrame;
begin
  if FUL=nil then exit;
  FUL.lblStatAll.Caption:=StatAll.GetMsg;
  FUL.lblStatSec.Caption:=StatSec.GetMsg;
end;

{ TUDPConnection }

constructor TUDPConnection.Create(IP: String; Port: Integer; UDP: TNMUDP);
begin
  inherited Create;
  prt1:=TPRT_UDP.Create(UDP,IP,Port);
  prt2:=TPRT_Liner.Create(prt1);
  NetW_addProcessIO(ProcessIO);
end;

destructor TUDPConnection.Destroy;
begin
  NetW_remProcessIO(ProcessIO);
  NetW_remConn(prt2);
  prt2.Free;
  prt1.Free;
  inherited;
end;

procedure TUDPConnection.ProcessIO;
begin
  repeat until StdProcessIO(prt2,Stat);
end;

end.

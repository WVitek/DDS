{.$DEFINE TestMode}
unit UFrameLeasedLine;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls, IniFiles, Contnrs, UTreeItem,
  UPRT, UPRT_COMPORT, UPRT_LINER;

type
  TItemLLine = class;

  TFrameLeasedLine = class(TFrame)
    gbLine: TGroupBox;
    GroupBox2: TGroupBox;
    Panel: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    edPort: TEdit;
    BtnChange: TButton;
    cbWorking: TCheckBox;
    Memo: TMemo;
    comboBaudRate: TComboBox;
    stModemState: TStaticText;
    stInfoO: TStaticText;
    stInfoI: TStaticText;
    stConnTime: TStaticText;
    procedure BtnChangeClick(Sender: TObject);
    procedure cbWorkingClick(Sender: TObject);
  private
    { Private declarations }
    Main:TItemLLine;
  public
    { Public declarations }
  end;

  TServiceHandler = function:Boolean of object;

  TItemLLine = class(TTreeItem)
  private
    FLL:TFrameLeasedLine;
    procedure SetWorking(const Value: Boolean);
  protected
    FEvents:String;
    FWorking,FInTimerProc:Boolean;
    // Persistent variables
    ComPort:String;
    BaudRate:Cardinal;
    FNoAlarm:Boolean;
    // communication variables
    ConnectionTimer:Cardinal;
    Stat:TLinkStat;
    PPSI,SpeedI,SumI:Cardinal;
    PPSO,SpeedO,SumO:Cardinal;
    Buf:String;
    RxWaitData:Boolean;
    LastDataLen:Integer;
    StateChangeLogDelay:Integer;
    // PRT
    prtCom:TPRT_COMPORT;
    Prt:TPRT_LINER;
    //
    procedure RefreshFrame;
    procedure ProcessIO;
  public
    function Enter(Owner:TComponent):TFrame;override;
    function Leave:Boolean;override;
    function Validate:Boolean;override;
    constructor Load(Nodes:TTreeNodes; ParentNode:TTreeNode; Ini,Cfg:TIniFile; const Section:String);
    destructor Destroy;override;
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
  public
    NoAnswerWatchTimer:Cardinal;
    property Working:Boolean read FWorking write SetWorking;
    property NoAlarm:Boolean read FNoAlarm;
    procedure CommEvent(Event:String);
    procedure AddEvent(Time:TDateTime; Event:String);
  end;

implementation

uses
  Misc, UTime, UNetW;

{$R *.DFM}

{ TItemLLine }

procedure TItemLLine.AddEvent(Time:TDateTime; Event: String);
begin
  Event:=LogMsg(Time,Event);
  if FLL<>nil then begin
    FLL.Memo.SelStart:=0;
    FLL.Memo.SelText:=Event;
  end;
  FEvents:=Event+FEvents;
  WriteToLog(Event);
end;

procedure TItemLLine.CommEvent(Event: String);
const
  Count:Integer=0;
begin
  Inc(Count);
{
  if (Count>=512) then begin
    if FLL<>nil then FLL.Memo7188.Text:='';
    CommEvents:='';
    Count:=0;
  end;
  if FLL<>nil then begin
    FLL.Memo7188.SelStart:=0;
    FLL.Memo7188.SelText:=Event+#13#10;
  end;
  CommEvents:=Event+#13#10+CommEvents;
}
end;

constructor TItemLLine.Load(Nodes:TTreeNodes; ParentNode:TTreeNode;
  Ini,Cfg: TIniFile; const Section: String);
var
  HalfDuplex,CheckRLSD:Boolean;
begin
  Self.Section:=Section;
  Node:=Nodes.AddChildObject(ParentNode,Section,Self);
  ComPort:=Cfg.ReadString(Section,'ComPort','COM1');
  BaudRate:=Cfg.ReadInteger(Section,'BaudRate',19200);
  HalfDuplex:=Ini.ReadBool(Section,'HalfDuplex',False);
  CheckRLSD:=Ini.ReadBool(Section,'CheckRLSD',False);
  Working:=True;
  prtCom:=TPRT_COMPORT.Create;
  prtCom.CheckRLSD:=CheckRLSD;
  prt:=TPRT_LINER.Create(prtCom,HalfDuplex);
  NetW_addProcessIO(ProcessIO);
end;

destructor TItemLLine.Destroy;
begin
  NetW_remProcessIO(ProcessIO);
  prt.Free;
  prtCom.Free;
end;

function TItemLLine.Enter(Owner:TComponent): TFrame;
begin
  FLL:=TFrameLeasedLine.Create(Owner);
  FLL.Main:=Self;
  FLL.edPort.Text:=ComPort;
  FLL.comboBaudRate.Text:=IntToStr(Baudrate);
  FLL.cbWorking.Checked:=FWorking;
  FLL.Memo.Text:=FEvents;
  FLL.Memo.SelStart:=Length(FEvents);
  RefreshFrame;
  Result:=FLL;
end;

function TItemLLine.Leave: Boolean;
begin
  FLL.Free; FLL:=nil;
  Result:=True;
end;

procedure TItemLLine.RefreshFrame;
const
  SecProDay=24*3600;
var
  CT:Cardinal;
  S:String;
begin
  FLL.stInfoI.Caption:=Format('R:%.4d/%.2d %.5dK',[SpeedI,PPSI,SumI shr 10]);
  FLL.stInfoO.Caption:=Format('T:%.4d/%.2d %.5dK',[SpeedO,PPSO,SumO shr 10]);
  CT:=ConnectionTimer;
  if CT>SecProDay then begin
    S:=IntToStr(CT div SecProDay)+':';
    CT:=CT mod SecProDay;
  end
  else S:='';
  FLL.stConnTime.Caption:=S+TimeToStr(CT*dtOneSecond)+' ';
end;

procedure TItemLLine.SetWorking(const Value: Boolean);
begin
  FWorking := Value;
  if FLL<>nil then FLL.cbWorking.Checked:=Value;
end;

const LogDelay = 60;

procedure TItemLLine.TimerProc;
begin
  if FInTimerProc then exit;
  FInTimerProc:=True;
  if Working xor prtCom.Opened then
  begin
    if Working then begin
      prtCom.ComName:=ComPort;
      prtCom.BaudRate:=BaudRate;
      prt.Open;
      if prtCom.Opened
      then AddEvent(GetMyTime,'Опрос запущен')
      else begin
        Dec(StateChangeLogDelay);
        if StateChangeLogDelay<=0 then
        begin
          AddEvent(GetMyTime,'Ошибка открытия порта');
          StateChangeLogDelay := LogDelay;
        end;
        //Working:=False;
      end;
    end
    else begin
      Inc(StateChangeLogDelay);
      if StateChangeLogDelay>=0 then
      begin
        AddEvent(GetMyTime,'Опрос приостановлен');
        StateChangeLogDelay := -LogDelay;
      end;
      prt.Close;
    end;
  end;
  if prtCom.Opened then Inc(ConnectionTimer);
  SpeedI:=Stat.BytesI; PPSI:=Stat.PacketsI; Inc(SumI,Stat.BytesI);
  SpeedO:=Stat.BytesO; PPSO:=Stat.PacketsO; Inc(SumO,Stat.BytesO);
  FillChar(Stat,SizeOf(Stat),0);
  if FLL<>nil then RefreshFrame;
  FInTimerProc:=False;
end;

function TItemLLine.Validate: Boolean;
begin
  try
    // Storing
    ComPort:=FLL.edPort.Text;
    BaudRate:=StrToInt(FLL.comboBaudRate.Text);
    Result:=True;
  except
    Result:=False;
  end;
end;

procedure TItemLLine.SaveCfg(Cfg: TIniFile);
begin
  Cfg.WriteString(Section,'ComPort',ComPort);
  Cfg.WriteInteger(Section,'BaudRate',BaudRate);
end;

procedure TFrameLeasedLine.BtnChangeClick(Sender: TObject);
begin
  Main.ChangeData(BtnChange,Panel);
end;

procedure TFrameLeasedLine.cbWorkingClick(Sender: TObject);
begin
  Main.FWorking:=cbWorking.Checked;
end;

procedure TItemLLine.ProcessIO;
var
  NothingToDo:Boolean;
begin
  repeat
    NothingToDo:=True;
    if PrtCom.Opened
    then NothingToDo:=StdProcessIO(Prt,Stat);
  until NothingToDo or Application.Terminated;
end;

end.

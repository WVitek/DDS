{.$DEFINE TestMode}
unit UFrameMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UTreeItem, StdCtrls, ExtCtrls, IniFiles, UModem, CommInt, UPRT, UServices,
  Contnrs;

const
  MaxPacketDataSize = MaxARQDataSize-2;
  MPDS2 = MaxPacketDataSize div 2;

type
  TItemMain = class;

  TFrameMain = class(TFrame)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Panel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    edPort: TEdit;
    BtnChange: TButton;
    edTarifUnit: TEdit;
    cbWorking: TCheckBox;
    Memo: TMemo;
    comboBaudRate: TComboBox;
    Memo7188: TMemo;
    cbLeased: TCheckBox;
    stModemState: TStaticText;
    stInfoO: TStaticText;
    stInfoI: TStaticText;
    stConnTime: TStaticText;
    edMaxConnTime: TEdit;
    Label6: TLabel;
    stARQState: TStaticText;
    procedure BtnChangeClick(Sender: TObject);
    procedure cbWorkingClick(Sender: TObject);
    procedure cbLeasedClick(Sender: TObject);
  private
    { Private declarations }
    Main:TItemMain;
  public
    { Public declarations }
  end;

  TServiceHandler = function:Boolean of object;

  TPacketHeader = packed record
    FromAddr,ServiceID:Byte;
  end;

  TPacket=record
    Hdr:TPacketHeader;
    Data:packed array[0..MaxPacketDataSize-1] of Byte;
  end;

  TItemMain = class(TTreeItem)
  private
    procedure SetWorking(const Value: Boolean);
    function GetModem: TModem;
    procedure SetLeasedLine(const Value: Boolean);
    function GetService(i: Integer): TService;
  protected
    FM:TFrameMain;
    KPs:TList;
    iCurKP:Integer;
    FEvents,CommEvents:String;
    FWorking:Boolean;
    FirstPacket:Boolean;
    // Persistent variables
    ComPort:String;
    BaudRate:TBaudRate;
    TarifUnit:Cardinal;
    MaxDialTime,MaxConnTime,FRedialInterval:Cardinal;
    DialCmd,InitCmd:String;
    AnswerTimeout:Cardinal;
    FNoAlarm:Boolean;
    // communication variables
    FLeasedLine,FCheckRLSD:Boolean;
    ConnectionTimer,OnlineTimer:Cardinal;
    PPSI,SpeedI,SumI:Cardinal;
    PPSO,SpeedO,SumO:Cardinal;
    Buf:String;
    RxWaitData:Boolean;
    LastDataLen:Integer;
    // PRT
    PrtModem:TPRT_Modem;
    PrtARQ:TPRT_ARQ;
    //
    SvcList:TObjectList;
    iNextSvc:Integer;
    SvcReprog:TServiceReprog;
    SvcDump:TServiceDump;
    //
    procedure RefreshFrame;
    procedure sendPacket(const Data:String; SvcID:Integer);
    function ProcessPacket(MustRX,CanTX:Boolean):Boolean;
    procedure UnknownServiceHandler(SvcID:Byte; Data:String);
    procedure Connect(Cmd:String);
  public
    function Enter:TFrame;override;
    function Leave:Boolean;override;
    function Validate:Boolean;override;
    constructor Load(Ini,Cfg:TIniFile; const Section:String);
    destructor Destroy;override;
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
    procedure ProcessIO;
  protected
    property Service[i:Integer]:TService read GetService;
  public
    Period:TDateTime;
    NoAnswerWatchTimer:Cardinal;
    property Working:Boolean read FWorking write SetWorking;
    property LeasedLine:Boolean read FLeasedLine write SetLeasedLine;
    property Modem:TModem read GetModem;
    property RedialInterval:Cardinal read FRedialInterval;
    property NoAlarm:Boolean read FNoAlarm;
    function FindKP(Address:Integer; var KP:TTreeItem):Integer;
    procedure SwitchProgramming;
    procedure SwitchDumping;
    procedure CommEvent(Event:String);
    procedure AddEvent(Time:TDateTime; Event:String);
    procedure ShowARQState(TxRd,TxWr,RxRd,RxWr:Integer);
    procedure OnConnect;
    procedure OnDisconnect;
    procedure OnConnFailed;
    procedure OnModemResponse;
  end;

function ItemMain:TItemMain;

implementation

uses UFormMain, UFrameKP, Misc, UCRC, UTime;

{$R *.DFM}

function ItemMain:TItemMain;
begin
  Result:=FormMain.Main;
end;

{ TItemMain }

procedure TItemMain.AddEvent(Time:TDateTime; Event: String);
begin
  Event:=LogMsg(Time,Event);
  if FM<>nil then begin
    FM.Memo.SelStart:=0;
    FM.Memo.SelText:=Event;
  end;
  FEvents:=Event+FEvents;
  WriteToLog(Event);
end;

procedure TItemMain.CommEvent(Event: String);
const
  Count:Integer=0;
begin
  Inc(Count);
  if (Count>=512) then begin
    if FM<>nil then FM.Memo7188.Text:='';
    CommEvents:='';
    Count:=0;
  end;
  if FM<>nil then begin
    FM.Memo7188.SelStart:=0;
    FM.Memo7188.SelText:=Event+#13#10;
  end;
  CommEvents:=Event+#13#10+CommEvents;
end;

procedure TItemMain.OnConnFailed;
var
  S:String;
begin
  S:='Нет связи : '+ModemResponses[Modem.ResponseCode];
  if ConnectionTimer>0 then S:=S+Format(' (%ds)',[ConnectionTimer]);
  AddEvent(GetMyTime,S);
  if iCurKP>=0
  then TItemKP(KPs[iCurKP]).PauseDial;
  iCurKP:=-1;
end;

constructor TItemMain.Load(Ini,Cfg: TIniFile;
  const Section: String);
var
  i,Cnt:Integer;
  S:String;
begin
  Self.Section:=Section;
  Node:=FormMain.TreeView.Items.AddObject(nil,'MLdr7188',Self);
  InitCmd:=Ini.ReadString(Section,'InitCmd','AT E0');
  DialCmd:=Ini.ReadString(Section,'DialCmd','');
  FLeasedLine:=(DialCmd='');
  FCheckRLSD:=Ini.ReadBool(Section,'CheckRLSD',True);
  if not FCheckRLSD
  then Modem.MonitorEvents:=Modem.MonitorEvents - [evRLSD];
  AnswerTimeout:=Ini.ReadInteger(Section,'AnswerTimeout',8);
  ComPort:=Cfg.ReadString(Section,'ComPort','COM1');
  BaudRate:=TBaudRate(Cfg.ReadInteger(Section,'BaudRateCode',Integer(br19200)));
  if Ini.ReadBool(Section,'DsrSensitivity',True) then begin
    Modem.Options:=Modem.Options + [coDsrSensitivity];
    Modem.MonitorEvents:=Modem.MonitorEvents + [evDSR];
  end;
  Modem.ReadBufSize:=4096;
  Modem.WriteBufSize:=4096;
  TarifUnit:=Cfg.ReadInteger(Section,'TarifUnit',15);
  MaxConnTime:=Cfg.ReadInteger(Section,'MaxConnTime',45);
  MaxDialTime:=Ini.ReadInteger(Section,'MaxDialTime',60);
  FRedialInterval:=Ini.ReadInteger(Section,'RedialInterval',60);
  UTime.SetMyTimeType(Ini.ReadInteger(Section,'MyTimeType',0));
  FNoAlarm:=Ini.ReadBool(Section,'NoAlarm',False);
  FormMain.NMUDP.RemoteHost:=Ini.ReadString(Section,'Host','127.0.0.1');
  Period:=Ini.ReadInteger(Section,'Period',1000)*dtOneMSec;
{$IFDEF TestMode}
  PrtModem:=TPRT_Test.Create;
{$ELSE}
  PrtModem:=TPRT_Modem.Create(Modem);
{$ENDIF}
  PrtARQ:=TPRT_ARQ.Create(PrtModem);
  Cnt:=Ini.ReadInteger(Section,'KPCount',0);
  KPs:=TList.Create;
  for i:=1 to Cnt do begin
    S:=Ini.ReadString(Section,Format('KP%.2d',[i]),'');
    if S<>''
    then KPs.Add(TItemKP.Load(Self,Ini,Cfg,S));
  end;
  iCurKP:=-1;
  Working:=True;
  PrtARQ.TimeServer:=TServiceTimeServer.Create;
  SvcList:=TObjectList.Create(True);
//  SvcList.Add(TServiceTime.Create);
  SvcList.Add(TServiceAlarm.Create);
  SvcList.Add(TServiceADC.Create);
  SvcReprog:=TServiceReprog.Create;
  SvcList.Add(SvcReprog);
  SvcDump:=TServiceDump.Create;
  SvcList.Add(SvcDump);
  AddEvent(GetMyTime,'ЗАПУСК');
end;

procedure TItemMain.UnknownServiceHandler(SvcID:Byte; Data:String);
var
  S:String;
begin
  if Length(Data)=0 then S:=''
  else S:=getHexDump(Data[1],Length(Data));
  CommEvent(Format('Svc%d?%s', [SvcID,S]));
end;

destructor TItemMain.Destroy;
var
  i:Integer;
begin
  SvcList.Free;
  PrtARQ.TimeServer.Free;
  PrtARQ.Free;
  PrtModem.Free;
  Modem.Close;
  AddEvent(GetMyTime,'ОСТАНОВ');
  for i:=0 to KPs.Count-1 do TItemKP(KPs[i]).Free;
  KPs.Free;
  inherited;
end;

function TItemMain.Enter: TFrame;
begin
  FM:=TFrameMain.Create(FormMain);
  FM.Main:=Self;
  FM.edPort.Text:=ComPort;
  FM.comboBaudRate.ItemIndex:=Integer(BaudRate);
  FM.edTarifUnit.Text:=IntToStr(TarifUnit);
  FM.edMaxConnTime.Text:=IntToStr(MaxConnTime);
  FM.cbWorking.Checked:=FWorking;
  FM.cbLeased.Checked:=FLeasedLine;
  FM.Memo.Text:=FEvents;
  FM.Memo.SelStart:=Length(FEvents);
  FM.Memo7188.Text:=CommEvents;
  RefreshFrame;
  Result:=FM;
end;

function TItemMain.GetModem: TModem;
begin
  Result:=FormMain.Modem;
end;

function TItemMain.Leave: Boolean;
begin
  FM.Free; FM:=nil;
  Result:=True;
end;

procedure TItemMain.OnConnect;
begin
{$IFDEF TestMode}
  while PrtARQ.CanTX do SendPacket('0123456789012345',1);
{$ENDIF}
  OnlineTimer:=0;
  LastDataLen:=0;
  AddEvent(GetMyTime,Format('Связь установлена (за %ds)',[ConnectionTimer]));
  FirstPacket:=True;
  PrtModem.TxBufEmpty:=True;
  NoAnswerWatchTimer:=0;
  SumI:=0; SumO:=0;
end;

function TItemMain.ProcessPacket(MustRX,CanTX:Boolean):Boolean;
var
  i:Integer;
  Found:Boolean;
  KP:TItemKP;
  Pack:TPacket;
  Size:Integer;
  Svc:TService;
  SvcID:Integer;
  Data:String;
begin
  Result:=False;
  if MustRX then begin
    NoAnswerWatchTimer:=0;
    Size:=PrtARQ.Rx(Pack);
    Pack.Hdr:=Pack.Hdr;
    SetLength(Data,Size-SizeOf(Pack.Hdr));
    Move(Pack.Data,Data[1],Length(Data));
    if iCurKP<0
    then iCurKP:=FindKP(Pack.Hdr.FromAddr,TTreeItem(KP))
    else KP:=TItemKP(KPs[iCurKP]);
    if (KP<>nil) and FirstPacket then begin
      KP.ManualDialRequest:=False;
      FirstPacket:=False;
      AddEvent(GetMyTime,'Ответ "'+KP.Name+'"');
    end;
    Found:=False;
    for i:=0 to SvcList.Count-1 do begin
      Svc:=Service[i];
      if(Pack.Hdr.ServiceID=Svc.ID)then begin
        Svc.receiveData(Pack.Hdr.FromAddr,Data);
        Found:=True;
        break;
      end;
    end;
    if (Pack.Hdr.ServiceID<>0) and not Found
    then UnknownServiceHandler(Pack.Hdr.ServiceID,Data);
    Result:=True;
  end;
  if CanTX then begin
    SvcID:=0;
    Data:='';
    i:=iNextSvc;
    Found:=False;
    repeat
      Svc:=Service[i];
      if Svc.HaveDataToTransmit then begin
        Svc.getDataToTransmit(Data,MaxPacketDataSize);
        SvcID:=Svc.ID;
      end;
      Inc(i); if i>=SvcList.Count then i:=0;
    until (i=iNextSvc) or Found;
    iNextSvc:=i;
    if Data<>'' then begin
      Result:=True;
      sendPacket(Data,SvcID);
    end;
  end;
end;

procedure TItemMain.RefreshFrame;
const
  SecProDay=24*3600;
var
  CT:Cardinal;
  S:String;
begin
  if Modem.Enabled
  then FM.stModemState.Caption:=sModemStates[Modem.State]
  else FM.stModemState.Caption:='- - -';
  FM.stInfoI.Caption:=Format('R:%.4d/%.2d %.5dK',[SpeedI,PPSI,SumI shr 10]);
  FM.stInfoO.Caption:=Format('T:%.4d/%.2d %.5dK',[SpeedO,PPSO,SumO shr 10]);
  CT:=ConnectionTimer;
  if Modem.State=msOnline then Inc(CT,OnlineTimer);
  if CT>SecProDay then begin
    S:=IntToStr(CT div SecProDay)+':';
    CT:=CT mod SecProDay;
  end
  else S:='';
  FM.stConnTime.Caption:=S+TimeToStr(CT*dtOneSecond)+' ';
end;

procedure TItemMain.SetWorking(const Value: Boolean);
begin
  FWorking := Value;
  if FM<>nil then FM.cbWorking.Checked:=Value;
end;

procedure TItemMain.SwitchProgramming;
begin
  if SvcReprog.Programming then begin
    AddEvent(GetMyTime,'Процесс перепрошивки остановлен');
    SvcReprog.stopProgramming;
  end
  else begin
    AddEvent(GetMyTime,'Инициирована перепрошивка контроллера');
    SvcReprog.startProgramming;
  end;
end;

type
  TFakeModem = class(TModem)
  end;

procedure TItemMain.TimerProc;
var
  i,iFound:Integer;
  KP:TItemKP;
  S:String;
begin
  if Working xor Modem.Enabled then begin
    if Working then begin
      try
        Modem.DeviceName:=ComPort;
        Modem.BaudRate:=BaudRate;
        Modem.Open;
        sleep(100);
        if not FLeasedLine then begin
//          LeasedLine:=Modem.RLSD;
          i:=2;
          while i>0 do begin
            try
              Modem.PurgeIn;
              Modem.DoCmd(InitCmd);
              sleep(100);
              break;
            except
              sleep(500);
            end;
            Dec(i);
          end;
          if i<0 then raise Exception.Create('Modem init failed');
        end;
        if not FCheckRLSD then TFakeModem(Modem).SetState(msOnline);
        AddEvent(GetMyTime,'Опрос запущен');
        exit;
      except
        on E:Exception do begin
          AddEvent(GetMyTime,'Ошибка открытия порта: '+E.Message);
          Working:=False;
          Modem.Close;
        end;
      end;
    end
    else begin
      AddEvent(GetMyTime,'Опрос приостановлен');
      Modem.Disconnect(InitCmd);
      if not FCheckRLSD then TFakeModem(Modem).SetState(msOffline);
      Modem.Close;
    end;
  end;
  if Modem.Enabled
  then case Modem.State of
    msOffline: // ищем, куда звонить
      if iCurKP<0 then begin
        iFound:=-1;
        for i:=0 to KPs.Count-1 do begin
          KP:=TItemKP(KPs[i]);
          if KP.ManualDialRequest then begin
            iFound:=i; break;
          end
          else if (iFound<0) and KP.AutoDialRequest then iFound:=i;
        end;
        if iFound>=0 then begin
          iCurKP:=iFound;
          KP:=TItemKP(KPs[iFound]);
          if KP.ManualDialRequest
          then S:='Ручной дозвон'
          else S:='Автодозвон';
          AddEvent(GetMyTime,S+' "'+KP.Name+'"');
          sleep(100);
          Connect(DialCmd+KP.Phone);
        end;
      end;
    msOnline:
    begin
      Inc(OnlineTimer);
      Inc(NoAnswerWatchTimer);
      if not FLeasedLine and
        ((TarifUnit=1) or ((ConnectionTimer+OnlineTimer) mod TarifUnit=TarifUnit-1))
      then begin
        S:='';
        if ((ConnectionTimer+OnlineTimer)>=MaxConnTime-1)
        then S:=Format('Ограничение времени сеанса связи (%ds)',[MaxConnTime])
        else if (NoAnswerWatchTimer>=AnswerTimeout)
        then S:=Format('Таймаут ответа контроллера (%ds)',[AnswerTimeout])
        else begin
          if (iCurKP>=0) and not TItemKP(KPs[iCurKP]).NeedConnection
          then S:='Контроллер передал накопленные данные';
        end;
        if S<>'' then begin
          NoAnswerWatchTimer:=0;
          AddEvent(GetMyTime,S);
          Modem.Disconnect(InitCmd);
          // Чтобы часто не ломился в дозвон :)
          if iCurKP>=0
          then TItemKP(KPs[iCurKP]).PauseDial;
        end;
      end;
    end;
    msConnection:
    begin
      Inc(ConnectionTimer);
      if ConnectionTimer>MaxDialTime then begin
        AddEvent(GetMyTime,Format('Превышено время ожидания несущей (%dс)',[MaxDialTime]));
        Modem.Disconnect(InitCmd);
      end;
    end;
    msDisconnection:
    begin
      Inc(NoAnswerWatchTimer);
      if NoAnswerWatchTimer>=5 then begin
        NoAnswerWatchTimer:=0;
        AddEvent(GetMyTime,'Пока не удаётся разорвать соединение :(');
        Modem.Disconnect(InitCmd);
      end;
    end;
  end;
  SpeedI:=BytesI; PPSI:=PacketsI; Inc(SumI,BytesI); BytesI:=0; PacketsI:=0;
  SpeedO:=BytesO; PPSO:=PacketsO; Inc(SumO,BytesO); BytesO:=0; PacketsO:=0;
  if FM<>nil then RefreshFrame;
  for i:=0 to KPs.Count-1 do TItemKP(KPs[i]).TimerProc;
end;

function TItemMain.Validate: Boolean;
var
  TU,MCT:Double;
begin
  try
    // Checking
    CheckMinMax(TU,1,60,FM.edTarifUnit);
    CheckMinMax(MCT,1,86400,FM.edMaxConnTime);
    // Storing
    ComPort:=FM.edPort.Text;
    BaudRate:=TBaudRate(FM.comboBaudRate.ItemIndex);
    TarifUnit:=Round(TU);
    MaxConnTime:=Round(MCT);
    Result:=True;
  except
    Result:=False;
  end;
end;

procedure TItemMain.SaveCfg(Cfg: TIniFile);
var
  i:Integer;
begin
  Cfg.WriteString(Section,'ComPort',ComPort);
  Cfg.WriteInteger(Section,'BaudRateCode',Integer(BaudRate));
  Cfg.WriteInteger(Section,'TarifUnit',TarifUnit);
  Cfg.WriteInteger(Section,'MaxConnTime',MaxConnTime);
  for i:=0 to KPs.Count-1 do TItemKP(KPs[i]).SaveCfg(Cfg);
end;

procedure TFrameMain.BtnChangeClick(Sender: TObject);
begin
  Main.ChangeData(BtnChange,Panel);
end;

procedure TFrameMain.cbWorkingClick(Sender: TObject);
begin
  Main.FWorking:=cbWorking.Checked;
end;

function TItemMain.FindKP(Address: Integer; var KP:TTreeItem): INteger;
var
  i:Integer;
begin
  Result:=-1;
  KP:=nil;
  for i:=0 to KPs.Count-1
  do if TItemKP(KPs[i]).Address=Address then begin
    Result:=i;
    KP:=TItemKP(KPs[i]);
    break;
  end;
end;

procedure TItemMain.OnDisconnect;
var
  S:String;
begin
  if OnlineTimer>0
  then S:=Format(
    '(%ds+%ds,R:%.1fK~%db/s,T:%.1fK~%db/s)',
    [ConnectionTimer,OnlineTimer,
     SumI*(1/1024),SumI div OnlineTimer,
     SumO*(1/1024),SumO div OnlineTimer ])
  else S:=Format('(%ds+%ds)',[ConnectionTimer,OnlineTimer]);
  AddEvent(GetMyTime,'Связь разорвана '+S);
  iCurKP:=-1;
  PrtARQ.OnDisconnect;
  ConnectionTimer:=0;
end;

procedure TFrameMain.cbLeasedClick(Sender: TObject);
var
  S:String;
begin
  if Main.LeasedLine=cbLeased.Checked then exit;
  Main.LeasedLine:=cbLeased.Checked;
  if Main.LeasedLine
  then S:='Запрещено'
  else S:='Разрешено';
  Main.AddEvent(GetMyTime,S+' автоматическое разъединение');
end;

procedure TItemMain.OnModemResponse;
begin
  CommEvent('Модем: '+Modem.ResponseInLine);
  if Modem.ResponseCode=mrcRing then begin
    AddEvent(GetMyTime,'Входящий звонок');
    Connect('ata');
  end;
end;

procedure TItemMain.Connect(Cmd: String);
begin
  Modem.Connect(Cmd);
  ConnectionTimer:=0;
  SumI:=0; SumO:=0;
end;

procedure TItemMain.SetLeasedLine(const Value: Boolean);
begin
  FLeasedLine := Value;
  if (FM<>nil) and (Value<>FM.cbLeased.Checked)
  then FM.cbLeased.Checked:=Value;
end;

procedure TItemMain.ProcessIO;
const
  Inside:Boolean=False;
var
  IO:Integer;
  HaveData:Boolean;
begin
  if Inside then exit;
  Inside:=True; IO:=0;
  HaveData:=False;
  repeat
    Application.ProcessMessages;
    if not Modem.Enabled or
      (Modem.State<>msOnline) and (Modem.State<>msDisconnection)
    then break;
    IO:=PrtARQ.ProcessIO;
    HaveData:=ProcessPacket(IO and IO_RX<>0, IO and IO_TX<>0);
  until (IO and IO_RX=0) and (HaveData xor (IO and IO_TX<>0)) or
    Application.Terminated;
  Inside:=False;
end;

procedure TItemMain.sendPacket(const Data:String; SvcID:Integer);
var
  Pack:TPacket;
  Size:Integer;
begin
  Pack.Hdr.FromAddr:=MyAddr;
  Pack.Hdr.ServiceID:=SvcID;
  Move(Data[1],Pack.Data,Length(Data));
  Size:=SizeOf(TPacketHeader)+Length(Data);
  PrtARQ.Tx(Pack,Size);
end;

procedure TItemMain.ShowARQState(TxRd,TxWr,RxRd,RxWr:Integer);
const
  TR:Integer=0;
  TW:Integer=0;
  RR:Integer=0;
  RW:Integer=0;
begin
  if (FM<>nil) and
    ((TR<>TxRd) or (TW<>TxWr) or (RR<>RxRd) or (RW<>RxWr))
  then FM.stARQState.Caption:=
    Format('TxRd=%02X TxWr=%02X   RxRd=%02X RxWr=%02X',[TxRd,TxWr,RxRd,RxWr]);
end;

function TItemMain.GetService(i: Integer): TService;
begin
  Result:=TService(SvcList[i]);
end;

procedure TItemMain.SwitchDumping;
begin
  if SvcDump.Active then begin
    AddEvent(GetMyTime,'СТОП - получение дампа памяти');
    SvcDump.stop;
  end
  else begin
    AddEvent(GetMyTime,'СТАРТ - получение дампа памяти');
    SvcDump.start;
  end;
end;

end.

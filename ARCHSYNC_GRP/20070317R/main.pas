unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  NMUDP, StdCtrls, IniFiles, ExtCtrls, ShellApi, DdhAppX, Psock,
  ArchManThd, Misc, FileMan, Pinger, Common, ComCtrls, Grids, Buttons,
  SensorTypes, UTime;

const
  DefaultDataPort=61978;
  timesection='time';
  RecsPerDay=24*60*60;
  MaxSendDataCnt=60;
  RecommendedMaxPacketSize=1024;

type
  TIPConnection = class;
  TPingerThread = class;

  TResyncState=(rsNone,rsWaitResync,rsResyncInProgress);

  TResyncData = record
    TimeQ,TimeA,TimeR: TDateTime;
  end;

  TPacketType = (ptReqData,ptAnsData,ptReqTime,ptAnsTime,
    ptSensList,ptInitResync,ptDoResync,ptReqUTCTime,ptAnsUTCTime,
    ptGroupReq,ptGroupAns);

  TMyHeader = packed object
    PacketType:TPacketType;
  end;

  TMyHeader_ReqData = packed object(TMyHeader)
    TrackID:Integer;
    LastRecTime:TDateTime;
  end;

  TMyHeader_AnsData = packed object(TMyHeader)
    TrackID:Integer;
    StartTime:TDateTime;
    Count:Integer;
    Data:packed array[0..65535-16] of Byte;
  end;

  TMyHeader_GroupReq = packed object(TMyHeader)
    Count:Word;
    DataReq:array[0..65535] of TMyHeader_ReqData;
  end;

  TMyHeader_GroupAns = packed object(TMyHeader)
    Data:array[0..65535] of Byte; // in format: Size<>0:Word; Data:array; ... ; Size=0
  end;

  TMyHeader_Time = packed object(TMyHeader)
    Time1,Time2:TDateTime;
  end;

  TSensListItem = record
    TrackID:Integer;
    Weight:Integer;
  end;

  TMyHeader_SensData = packed object(TMyHeader)
    Count:Integer;
    Data:packed array[0..65535] of TSensListItem;
  end;

  TFrmMain = class(TForm)
    AppExt: TDdhAppExt;
    Timer: TTimer;
    Splitter1: TSplitter;
    sgTracks: TStringGrid;
    sgConns: TStringGrid;
    Panel1: TPanel;
    SpdBtnResync: TSpeedButton;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MyUDPDataReceived(Sender: TComponent; NumberBytes: Integer;
      FromIP: String; Port: Integer);
    procedure MyUDPInvalidHost(var handled: Boolean);
    procedure TimerTimer(Sender: TObject);
    procedure DefaultHandler(var Message);override;
    procedure sgConnsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure SpdBtnResyncClick(Sender: TObject);
    procedure SendAnswer(MinSendRecs:Integer; const ToIP:String; ToPort:Integer; const Request);
    procedure GetAnswerData(MinSendRecs:Integer; const Req:TMyHeader_ReqData; var Data:PByte; var Size:Word);
  private
    { Private declarations }
    FAM:TArchManThread;
    function Get_AM: TArchManThread;
  public
    { Public declarations }
    MyUDP:TNMUDP;
    IPCons:TStringList;
    SaveTimeDataCounter,SaveTimeDataInterval:Integer;
    GetTimeCounter,GetTimeInterval:Integer;
    GetTimeNdx,GetTimeTimes:Integer;
    TimeRequestTimeout:Integer;
    RD:array[0..1] of TResyncData;
    RefreshInfoCounter:Integer;
    //
    TrkMinSendRecs:Integer;
    //
    TimeServerIP:String;
    TimeServerPort:Integer;
    TimeServerUTC:Boolean;
    //
    ConnectingError:Boolean;
    NeedResyncSlaves:Boolean;
    ResyncState:TResyncState;
    TimerInterval,TimerCounter:Integer;
    TimerCmd:String;
    PingerThd:TPingerThread;
    TimeIni:TIniFile;
    procedure RefreshInfo;
    procedure SendTimeRequest;
    function CalculateTime:Boolean;
    function FindConnByID(ID:Integer):Integer;
    procedure ResyncSlavesIfNeed;
    procedure BeginTimeGetting;
    property AM:TArchManThread read Get_AM;
  end;

  IStringGridRow = interface
    function Get_CellValue(Col:Integer): String;
    property CellValue[Col:Integer]:String read Get_CellValue;
  end;

  TIPConnectionState=(
    ipcsNoConnection,//Нет и не нужно соединение
    ipcsConnecting,//Пытаемся соединиться
    ipcsInConn,//Входящее соединение (установлено удаленной машиной)
    ipcsOutConn//Исходящее соединение (установлено нами)
  );

  TIPConnection = class(TInterfacedObject,IStringGridRow)
  private
    function Get_CellValue(Col:Integer): String;
    function Get_InfoStr: String;
    function Get_ConnectingError: Boolean;
    function Get_Connected: Boolean;
    function Get_LeasedLine: Boolean;
    procedure Set_State(const Value: TIPConnectionState);
    procedure Log(Msg:String);
  public
    ID:Integer;
    ConnName:String;// Название соединения
    IPStr:String;// IP адрес удаленного компьютера
    DataPort:Integer;
    RemoteSensor:CSensor;
    // Группировка запросов
    GrpEnabled:Boolean;
    GrpReqBuf:array of TMyHeader_ReqData;
    GrpLastReqTime:TIME_STAMP;
    GrpReqInterval:TIME_STAMP;
    GrpSendInAnyCase:Boolean;
    // Минимальное количество выдаваемых данных
    TrkMinSendRecs:Integer;
    // Интервал между сеансами связи
    ConnInterval:Integer;
    // Состояние соединения
    FState:TIPConnectionState;
    // Параметры теста на наличие связи
    PingInterval:Integer; // Периодичность теста (мсек)
    PingTimeOut:Integer; // Время ожидания ответа удаленной стороны (мсек)
    PingRetries:Integer; // Количество попыток вызова удаленной стороны
    PingRetryInterval:Integer; // Интервал между попытками вызова (мсек)
    // Параметры установки и разрыва соединения
    ConnectCmd:String;// командная строка установки соединения
    ConnectRetryInterval:Integer;// периодичность попыток установки соединения
    DisconnectCmd:String;// командная строка разрыва соединения
    // other
    PingTimeCounter:Integer; // Счетчик прошедшего времени в тесте наличия соединения
    PingRetriesCounter:Integer; // Счетчик попыток вызова удаленной стороны
    PingOk:Boolean;
    {}PingResult:Integer;
    // methods
    function GrpReqBufSize:Integer;
    procedure SendGroupReq;
    //
    constructor LoadFromIniSection(const Section:String; const Ini:TIniFile);
    procedure OnTimer(Interval:Integer);
    procedure SendDataRequest(TrackID:Integer;
      const LastRecTime:TDateTime; SendInAnyCase:Boolean);
    procedure ReceiveData(const Data);
    procedure ReceiveDataAns(const Buf:TMyHeader_AnsData);
    procedure LoadTimeData(Ini:TIniFile; const Section:String);
    procedure SaveTimeData(Ini:TIniFile; const Section:String);
    destructor Destroy;override;
    function GetMinLastRecTime:TDateTime;
  public
    property InfoStr:String read Get_InfoStr;
    property ConnectingError:Boolean read Get_ConnectingError;
    property Connected:Boolean read Get_Connected;
    property LeasedLine:Boolean read Get_LeasedLine;
    property State:TIPConnectionState read FState write Set_State;
  private
    IP:Cardinal;
    Tracks:TByteStringList;
    ReplyOk:Boolean;
    ConnectingRetriesCounter:Integer;
    TimeCounter:Integer;
    iNextTrack:Integer;
  end;

  TTrack = class(TInterfacedObject,IStringGridRow)
    IPConn:TIPConnection;
    TrackID:Integer;
    LastRecTime:TDateTime;
    LastRequestTime,LastReceiveTime:Integer;
    DataReceived:Boolean;
    LastRecvCnt:Integer;
    constructor LoadFromIniSection(const Section:String; const Ini:TIniFile; const Prefix:String);
    procedure LoadTimeData(Ini:TIniFile; const Section:String);
    procedure SaveTimeData(Ini:TIniFile; const Section:String);
    procedure OnTimer(Interval:Integer);
    procedure ReceiveData(const Time:TDateTime; Count:Integer; const Data:WideString);
    procedure SendDataRequest(SendInAnyCase:Boolean);
  private
    FNeedConnection:Boolean;
    function Get_CellValue(Col:Integer): String;
    function Get_ReplyOk: Boolean;
    function Get_InfoStr: String;
    function Get_TrackIdStr: String;
  public
    property ReplyOk:Boolean read Get_ReplyOk;
    property InfoStr:String read Get_InfoStr;
    property NeedConnection:Boolean read FNeedConnection;
    property TrackIdStr:String read Get_TrackIdStr;
  end;

  TPingerThread=class(TThread)
    IPCons:TStringList;
    constructor Create(IPCons:TStringList);
    procedure Execute;override;
  end;

var
  FrmMain:TFrmMain;

implementation

var
  TimeIsSynchro:Boolean;
  LogFileName:String;

{$R *.DFM}

const
  RequestDataInterval=500;
  MaxReplyTime=3000;
  IfNoReplyInterval=5000;

type
  TFakeCustomControl=class(TCustomControl)
  end;

function BaseStr(P:Integer; Base:Byte; MinLen:Integer):String;
const
  Digit:string[16]='0123456789ABCDEF';
begin
  Result:='';
  repeat
    Result:=Digit[P mod Base+1]+Result;
    P:=P div Base;
    Dec(MinLen);
  until (MinLen<=0) and (P=0);
end;

function IntToIPStr(IP:Integer):String;
var
  R:array[0..3] of Byte absolute IP;
  i:Integer;
begin
  Result:='';
  for i:=3 downto 0 do begin
    Result:=Result+BaseStr(R[i],10,1);
    if i<>0 then Result:=Result+'.';
  end
end;

function IPStrToInt(const IP:String):Cardinal;
const
  Coeff:array[0..2] of Byte=(1,10,100);
var
  i,j,k,m:Integer;
  R:array[0..3] of byte absolute Result;
begin
  k:=1;
  for i:=3 downto 0 do begin
    R[i]:=0;
    j:=k;
    while (j<Length(IP)) and (IP[j]<>'.') do Inc(j);
    if IP[j]='.' then Dec(j);
    for m:=j downto k do begin
      R[i]:=R[i]+(Ord(IP[m])-Ord('0'))*Coeff[j-m];
    end;
    k:=j+2;
  end;
end;

type
  TCharArray = packed array[0..MaxInt-1] of Char;

procedure UDPSendBuffer(
  UDP{eax}:TNMUDP; const Buf{edx}; Length{ecx}:Integer
);assembler;register;
asm
  push   ecx
  dec    ecx
  call   TNMUDP.SendBuffer
end;

{ TFrmMain }

function TFrmMain.CalculateTime;
var
  D1,D2,TimeOfs:TDateTime;
begin
  D1:=RD[0].TimeR-RD[0].TimeQ;
  D2:=RD[1].TimeR-RD[1].TimeQ;
  TimeOfs:=RD[0].TimeA-(RD[0].TimeR+RD[0].TimeQ)*0.5;
  if (abs(D1-D2) <= abs(TimeOfs)) and
     (D1*0.5 <= abs(TimeOfs)) and
     (D2*0.5 <= abs(TimeOfs))
  then begin
    if TimeServerUTC
    then SetUTCTime(GetUTCTime+TimeOfs)
    else SetLocTime(GetLocTime+TimeOfs);
    ResyncSlavesIfNeed;
    ResyncState:=rsNone;
    GetTimeNdx:=0;
    Result:=True;
  end
  else begin
    RD[0]:=RD[1];
    GetTimeNdx:=1;
    Result:=False;
  end
end;

procedure TFrmMain.DefaultHandler(var Message);
var
  Msg:TMessage absolute Message;
  i:Integer;
  Conn:TIPConnection;
begin
  if (Msg.Msg=WM_MYQUERY) and (Msg.Result=0) then begin
    i:=FindConnByID(Msg.WParamLo);
    if i>=0 then begin
      Conn:=TIPConnection(IPCons.Objects[i]);
      case TArchSyncCommand(Msg.WParamHi) of
        ascmdConnect: begin
          if not Conn.Connected then Conn.State:=ipcsConnecting;
          Msg.Result:=101;
        end;
        ascmdCheckConnection: begin
          if Conn.Connected then Msg.Result:=1 else Msg.Result:=100;
        end;
        ascmdDisconnect: begin
          if Conn.State=ipcsOutConn then begin
            Conn.State:=ipcsNoConnection;
            Msg.Result:=101;
          end
          else Msg.Result:=100;
        end;
        ascmdGetState: begin
          Msg.Result:=100+Word(Conn.State);
        end;
        else Msg.Result:=255;
      end;
    end
    else Msg.Result:=255;
  end;
  inherited;
end;

function TFrmMain.FindConnByID(ID: Integer): Integer;
begin
  for Result:=0 to IPCons.Count-1
  do if TIPConnection(IPCons.Objects[Result]).ID=ID then exit;
  Result:=-1;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
const
  Section='config';
var
  Ini:TIniFile;
  Sections:TStringList;
  i,j,v,e,SensCnt:Integer;
  C:TIPConnection;
  T,AllTracks:TByteStringList;
  SGR:IStringGridRow;
  FileName:String;
begin
  InitFormattingVariables;
  MyUDP:=TNMUDP.Create(Self);
  MyUDP.OnDataReceived:=MyUDPDataReceived;
  MyUDP.OnInvalidHost:=MyUDPInvalidHost;
  IPCons:=TStringList.Create;
  IPCons.Sorted:=True;
  IPCons.Duplicates:=dupAccept;
  // Configuration loading
  Sections:=TStringList.Create;
  //
  FileName:=GetModuleFullName;
  LogFileName:=FileName+'.log';
  Ini:=TIniFile.Create(FileName+'.ini');
  MyUDP.LocalPort:=Ini.ReadInteger(Section,'DataPort',DefaultDataPort);
  TimerInterval:=Ini.ReadInteger(Section,'TimerInterval',600)*1000;
  TimerCmd:=Ini.ReadString(Section,'TimerCmd','');
  TimeServerIP:=Ini.ReadString(Section,'UTCTimeServer','');
  if TimeServerIP<>''
  then TimeServerUTC:=True
  else TimeServerIP:=Ini.ReadString(Section,'GetTimeServer','');
  TimeIsSynchro:=Ini.ReadBool(Section,'TimeIsSynchro',True);
  UTime.SetMyTimeType(Ini.ReadInteger(Section,'MyTimeType',0));
  TimeServerPort:=Ini.ReadInteger(Section,'TimeServerPort',DefaultDataPort);
  GetTimeInterval:=Ini.ReadInteger(Section,'GetTimeInterval',60)*1000;
  SaveTimeDataInterval:=Ini.ReadInteger(Section,'SaveTimeDataInterval',300)*1000;
  TrkMinSendRecs:=Ini.ReadInteger(Section,'MinSendRecs',0);
  // Таблицы
  sgConns.Cells[0,0]:='Пункт';
  sgConns.Cells[1,0]:='Состояние связи';
  sgTracks.Cells[0,0]:='Датчик';
  sgTracks.Cells[1,0]:='Последние данные за';
  //
  Ini.ReadSections(Sections);
  SensCnt:=0;
  for i:=1 to Sections.Count-1 do begin
    Val(Sections[i],v,e);
    if e=0 then begin
      C:=TIPConnection.LoadFromIniSection(Sections[i],Ini);
      IPCons.AddObject(C.IPStr,C);
      sgConns.RowCount:=IPCons.Count+1;
      SGR:=IStringGridRow(C);
      SGR._AddRef;
      sgConns.Objects[0,IPCons.Count]:=Pointer(SGR);
      Inc(SensCnt,C.Tracks.Count);
    end;
  end;
  sgTracks.RowCount:=SensCnt+1;
  AllTracks:=TByteStringList.Create;
  AllTracks.Sorted:=True;
  for i:=0 to IPCons.Count-1 do begin
    T:=TIPConnection(IPCons.Objects[i]).Tracks;
    for j:=0 to T.Count-1 do AllTracks.AddObject(T[j],T.Objects[j]);
  end;
  for j:=0 to AllTracks.Count-1 do begin
    SGR:=IStringGridRow(TTrack(AllTracks.Objects[j]));
    SGR._AddRef;
    sgTracks.Objects[0,j+1]:=Pointer(SGR);
  end;
  TimeIni:=TIniFile.Create(Ini.ReadString(Section,'SaveTimeDataFile',FileName+'.tmd'));
  Ini.Free;
  Sections.Free;
  for i:=0 to IPCons.Count-1
  do TIPConnection(IPCons.Objects[i]).LoadTimeData(TimeIni,timesection);
  PingerThd:=TPingerThread.Create(IPCons);
  ConnectingError:=True;
  WriteToLog(LogFileName,LogMsg(GetMyTime,'ЗАПУСК'));
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
var
  i:Integer;
begin
  PingerThd.Free;
  for i:=0 to IPCons.Count-1 do begin
    TIPConnection(IPCons.Objects[i]).SaveTimeData(TimeIni,timesection);
    TIPConnection(IPCons.Objects[i])._Release;
  end;
  IPCons.Free;
  if FAM<>nil then FAM.Free;
  TimeIni.Free;
  MyUDP.Free;
  WriteToLog(LogFileName,LogMsg(GetMyTime,'ОСТАНОВ'));
end;

procedure TFrmMain.MyUDPDataReceived(Sender: TComponent;
  NumberBytes: Integer; FromIP: String; Port: Integer);
var
  Buf:^TCharArray;
  Conn:TIPConnection;
  i,MinSendRecs:Integer;
  DstDataPort:Integer;
  RxPackType:TPacketType;
begin
  if NumberBytes<=0 then exit;
  if IPCons.Find(FromIP,i) then begin
    Conn:=TIPConnection(IPCons.Objects[i]);
    DstDataPort:=Conn.DataPort;
    MinSendRecs:=Conn.TrkMinSendRecs;
  end
  else begin
    Conn:=nil;
    DstDataPort:=DefaultDataPort;
    MinSendRecs:=TrkMinSendRecs;
  end;
  GetMem(Buf,NumberBytes);
  MyUDP.ReadBuffer(Buf^,NumberBytes);
{
  MyUDP.RemoteHost:=FromIP;
  MyUDP.RemotePort:=Port;
  UDPSendBuffer(MyUDP,Buf^,NumberBytes);
  FreeMem(Buf,NumberBytes);
  exit;
//}
  RxPackType:=TMyHeader((@(Buf[0]))^).PacketType;
  case RxPackType of
    // Пришел запрос на получение данных
    ptReqData, ptGroupReq: SendAnswer(MinSendRecs,FromIP,DstDataPort,Buf^);
    // Пришел ответный пакет данных
    ptAnsData,ptGroupAns: if Conn<>nil then Conn.ReceiveData(Buf^);
    // Пришел запрос времени - надо ответить
    ptReqTime,ptReqUTCTime: with TMyHeader_Time((@(Buf[0]))^) do begin
      if RxPackType=ptReqUTCTime then begin
        PacketType:=ptAnsUTCTime;
        Time2:=GetUTCTime;
      end
      else begin
        PacketType:=ptAnsTime;
        Time2:=GetLocTime;
      end;
      MyUDP.RemoteHost:=FromIP;
      MyUDP.RemotePort:=DstDataPort;
      UDPSendBuffer(MyUDP,Buf^,NumberBytes);
    end;
    // Пришел ответ на запрос времени
    ptAnsTime,ptAnsUTCTime:
      if ((RxPackType=ptAnsTime) xor TimeServerUTC) and
        (ResyncState=rsResyncInProgress)
      then with TMyHeader_Time((@(Buf[0]))^) do begin
        RD[GetTimeNdx].TimeQ:=Time1;
        RD[GetTimeNdx].TimeA:=Time2;
        if TimeServerUTC
        then RD[GetTimeNdx].TimeR:=GetUTCTime
        else RD[GetTimeNdx].TimeR:=GetLocTime;
        Inc(GetTimeTimes);
        Inc(GetTimeNdx);
        TimeRequestTimeout:=0;
        if not ((GetTimeNdx=2) and CalculateTime) then SendTimeRequest;
      end;
    //
    ptInitResync: if FromIP<>TimeServerIP then SpdBtnResyncClick(Self);
    //
    ptDoResync: if FromIP=TimeServerIP then begin
      NeedResyncSlaves:=True;
      BeginTimeGetting;
    end;
  end;
  FreeMem(Buf,NumberBytes);
end;

procedure TFrmMain.MyUDPInvalidHost(var handled: Boolean);
begin
  handled:=True;
end;

procedure TFrmMain.RefreshInfo;
var
  i,j:Integer;
  SGRow:IStringGridRow;
  S:String;
begin
  for i:=1 to sgConns.RowCount-1 do begin
    SGRow:=IStringGridRow(Pointer(sgConns.Objects[0,i]));
    if SGRow<>nil then begin
      for j:=0 to sgConns.ColCount-1 do begin
        sgConns.Cells[j,i]:=SGRow.CellValue[j];
      end;
    end;
  end;
  for i:=1 to sgTracks.RowCount-1 do begin
    SGRow:=IStringGridRow(Pointer(sgTracks.Objects[0,i]));
    if SGRow<>nil then begin
      for j:=0 to sgTracks.ColCount-1 do begin
        sgTracks.Cells[j,i]:=SGRow.CellValue[j];
      end;
    end;
  end;
  case ResyncState of
    rsNone: begin
      if TimeServerIP<>'' then begin
        S:='До синхронизации часов осталось '+
          IntToStr(Trunc((GetTimeInterval-GetTimeCounter)*0.001))+' сек.';
      end
      else S:='Работаем помаленьку ... :)';
    end;
    rsWaitResync: S:='Жду разрешения сервера времени на синхронизацию часов';
    rsResyncInProgress: S:='Синхронизация часов: попытка '+IntToStr(GetTimeTimes);
  end;
  StatusBar.SimpleText:=S;
end;

procedure TFrmMain.SendTimeRequest;
var
  TP:TMyHeader_Time;
begin
  if TimeServerIP='' then exit;
  if TimeServerUTC then begin
    TP.PacketType:=ptReqUTCTime;
    TP.Time1:=UTime.GetUTCTime;
  end
  else begin
    TP.PacketType:=ptReqTime;
    TP.Time1:=UTime.GetLocTime;
  end;
  MyUDP.RemoteHost:=TimeServerIP;
  MyUDP.RemotePort:=TimeServerPort;
  UDPSendBuffer(MyUDP,TP,SizeOf(TP));
  GetTimeCounter:=0;
  TimeRequestTimeout:=1;
end;

procedure TFrmMain.TimerTimer(Sender: TObject);
var
  i:Integer;
  Conn:TIPConnection;
  OCE:Boolean;
begin
  // saving time data
  if SaveTimeDataCounter>=SaveTimeDataInterval then begin
    for i:=0 to IPCons.Count-1
    do TIPConnection(IPCons.Objects[i]).SaveTimeData(TimeIni,timesection);
    SaveTimeDataCounter:=0;
  end
  else Inc(SaveTimeDataCounter,Timer.Interval);
  // getting time
  if (ResyncState<>rsResyncInProgress) and (GetTimeCounter>=GetTimeInterval)
  then begin
    ResyncSlavesIfNeed;
    BeginTimeGetting;
  end
  else begin
    Inc(GetTimeCounter,Timer.Interval);
    if TimeRequestTimeout>0 then begin
      if TimeRequestTimeout>3000
      then SendTimeRequest
      else Inc(TimeRequestTimeout,Timer.Interval);
    end;
  end;
  // timer
  if TimerCounter=0 then begin
    TimerCounter:=TimerInterval;
    if TimerCmd<>''
    then ShellExecute(Handle,'open',PChar(TimerCmd),'','',SW_SHOWMINNOACTIVE);
  end
  else Dec(TimerCounter,Timer.Interval);
  // connections
  OCE:=ConnectingError;
  ConnectingError:=False;
  for i:=0 to IPCons.Count-1 do begin
    Conn:=TIPConnection(IPCons.Objects[i]);
    Conn.OnTimer(Timer.Interval);
    ConnectingError:=ConnectingError or Conn.ConnectingError;
  end;
  if RefreshInfoCounter<=0 then begin
    RefreshInfoCounter:=1000;
    RefreshInfo;
  end
  else Dec(RefreshInfoCounter,Timer.Interval);
  if OCE<>ConnectingError then begin
    if ConnectingError then begin
      MessageBeep(MB_ICONEXCLAMATION);
    end
  end;
end;

procedure TFrmMain.ResyncSlavesIfNeed;
var
  P:TMyHeader;
  i:Integer;
  Conn:TIPConnection;
begin
  if not NeedResyncSlaves then exit;
//  ResyncState:=rsNone;
  for i:=0 to IPCons.Count-1 do begin
    Conn:=TIPConnection(IPCons.Objects[i]);
    if Conn.IPStr<>TimeServerIP then begin
      P.PacketType:=ptDoResync;
      MyUDP.RemoteHost:=Conn.IPStr;
      MyUDP.RemotePort:=Conn.DataPort;
      UDPSendBuffer(MyUDP,P,SizeOf(P));
    end;
  end;
  NeedResyncSlaves:=False;
end;

procedure TFrmMain.BeginTimeGetting;
begin
  if TimeServerIP='' then exit;
  GetTimeCounter:=0;
  GetTimeTimes:=0;
  GetTimeNdx:=0;
  ResyncState:=rsResyncInProgress;
  SendTimeRequest;
end;

function TFrmMain.Get_AM: TArchManThread;
begin
  if FAM=nil then begin
    FAM:=TArchManThread.Create;//('127.0.0.1');
    FAM.Resume;
  end;
  Result:=FAM;
end;

procedure TFrmMain.GetAnswerData(MinSendRecs:Integer; const Req:TMyHeader_ReqData; var Data:PByte; var Size:Word);
var
  ReqLRC,MyLRC:TDateTime;
  i,TrkID:Integer;
  W:WideString;
  AnsBuf:^TMyHeader_AnsData;
  Length:Integer;
begin
  ReqLRC:=Req.LastRecTime;
  TrkID:=Req.TrackID;
  AM.setTrackInfo(TrkID,TMySensor.GetRecSize,RecsPerDay);
  AM.getLastRecTime(TrkID,MyLRC);
  Size:=0;
  if MyLRC=0 then exit;
  try
    i:=Round((MyLRC-ReqLRC)*RecsPerDay);
    if i<MinSendRecs then exit;
    if i>0 then begin
      // Подготавливаем и отсылаем данные
      if i>MaxSendDataCnt then i:=MaxSendDataCnt;
      AM.readRecords(TrkID,ReqLRC,i,W);
      Length:=17+System.Length(W)*2;
      GetMem(AnsBuf,Length);
      AnsBuf.PacketType:=ptAnsData;
      AnsBuf.TrackID:=TrkID;
      AnsBuf.StartTime:=ReqLRC;
      AnsBuf.Count:=i;
      Move(W[1],AnsBuf.Data,System.Length(W)*2);
    end
    else begin
      Length:=17;
      GetMem(AnsBuf,Length);
      AnsBuf.PacketType:=ptAnsData;
      AnsBuf.TrackID:=TrkID;
      AnsBuf.StartTime:=ReqLRC;
      AnsBuf.Count:=0;
    end;
    Data:=Pointer(AnsBuf);
    Size:=Length;
  except
  end;
end;

procedure TFrmMain.SendAnswer(MinSendRecs:Integer; const ToIP: String; ToPort:Integer; const Request);
var
  Hdr:TMyHeader absolute Request;
  OneReq:TMyHeader_ReqData absolute Request;
  GrpReq:TMyHeader_GroupReq absolute Request;
  Buf:array of Byte;
  Data:PByte;
  Size:Word;
  MyHdr:^TMyHeader;
  i,j:Integer;
begin
  MyUDP.RemoteHost:=ToIP;
  MyUDP.RemotePort:=ToPort;
  if Hdr.PacketType=ptReqData then begin
    GetAnswerData(MinSendRecs,OneReq,Data,Size);
    if Size<>0 then begin
      UDPSendBuffer(MyUDP,Data^,Size);
      FreeMem(Data,Size);
    end;
  end
  else if Hdr.PacketType=ptGroupReq then begin
    SetLength(Buf,SizeOf(TMyHeader));
    MyHdr:=@(Buf[0]);
    MyHdr.PacketType:=ptGroupAns;
    for i:=GrpReq.Count-1 downto 0 do begin
      GetAnswerData(MinSendRecs,GrpReq.DataReq[i],Data,Size);
      if Size>0 then begin
        j:=Length(Buf);
        SetLength(Buf,j+SizeOf(Word)+Size);
        PWord(@Buf[j])^:=Size;
        Move(Data^,Buf[j+SizeOf(Word)],Size);
        FreeMem(Data,Size);
      end;
      if (Length(Buf)>=RecommendedMaxPacketSize) or (i=0) then begin
        j:=Length(Buf);
        SetLength(Buf,j+SizeOf(Word));
        PWord(@Buf[j])^:=0;
        UDPSendBuffer(MyUDP,Buf[0],Length(Buf));
        SetLength(Buf,SizeOf(TMyHeader));
      end;
    end;
  end;
end;

{ TIPConnection }

destructor TIPConnection.Destroy;
var
  i:Integer;
begin
  for i:=0 to Tracks.Count-1 do TTrack(Tracks.Objects[i])._Release;
  Tracks.Free;
  inherited;
end;

function TIPConnection.Get_Connected: Boolean;
begin
  Result:=(State=ipcsInConn) or (State=ipcsOutConn);
end;

function TIPConnection.Get_ConnectingError: Boolean;
begin
  Result:=ConnectingRetriesCounter>2;
end;

function TIPConnection.Get_InfoStr: String;
begin
  Result:='';
  case State of
  ipcsNoConnection:
    Result:=Result+'нет связи (экономлю деньги :)';
  ipcsConnecting: begin
    if ConnectingError
    then Result:=Result+'пока не удаётся соединиться'
    else Result:=Result+'пытаюсь соединиться';
  end;
  ipcsInConn:
    Result:=Result+'связь инициирована извне';
  ipcsOutConn:
    Result:=Result+'сеанс связи';
  end;
//  Result:=Result+' '+IntToStr(PingResult);
end;

function TIPConnection.Get_LeasedLine: Boolean;
begin
  Result:=ConnInterval=0;
end;

function TIPConnection.Get_CellValue(Col: Integer): String;
begin
  case Col of
    0: Result:=IntToStr(ID)+':'+ConnName;
    1: Result:=InfoStr;
    else Result:='???';
  end;
end;

constructor TIPConnection.LoadFromIniSection(const Section: String;
  const Ini: TIniFile);
var
  i,Cnt:Integer;
  Trk:TTrack;
begin
  ID:=StrToInt(Section);
  ConnName:=Ini.ReadString(Section,'ConnName','');
  IPStr:=Ini.ReadString(Section,'IP','');
  DataPort:=Ini.ReadInteger(Section,'DataPort',DefaultDataPort);
  if Ini.ReadInteger(Section,'NewSensorType',0)<>0
  then RemoteSensor:=TSensorFloat32
  else RemoteSensor:=TSensorFixed24;
  GrpReqInterval:=Ini.ReadInteger(Section,'GrpReqInterval',0);
  GrpEnabled:=GrpReqInterval<>0;
  TrkMinSendRecs:=Ini.ReadInteger(Section,'MinSendRecs',0);
  ConnInterval:=Ini.ReadInteger(Section,'ConnInterval',0)*1000;
  // Параметры теста на наличие связи
  PingInterval:=Ini.ReadInteger(Section,'PingInterval',5000);
  PingTimeout:=Ini.Readinteger(Section,'PingTimeout',250);
  PingRetries:=Ini.ReadInteger(Section,'PingRetries',3);
  PingRetryInterval:=Ini.ReadInteger(Section,'PingRetryInterval',500);
  // Параметры установки и разрыва соединения
  ConnectCmd:=Ini.ReadString(Section,'ConnectCmd','');
  ConnectRetryInterval:=Ini.ReadInteger(Section,'ConnectRetryInterval',20)*1000;
  DisconnectCmd:=Ini.ReadString(Section,'DisconnectCmd','');

  Cnt:=Ini.ReadInteger(Section,'TrackCount',0);
  Tracks:=TByteStringList.Create;
  Tracks.Sorted:=True;
  for i:=0 to Cnt-1 do begin
    Trk:=TTrack.LoadFromIniSection(Section,Ini,'Track'+IntToStr(i+1));
    if Trk<>nil then begin
      Trk.IPConn:=Self;
      Tracks.AddObject(GetInvStrTrackID(Trk.TrackID),Trk);
    end;
  end;
  IP:=IPStrToInt(IPStr);
end;

procedure TIPConnection.LoadTimeData(Ini: TIniFile; const Section: String);
var
  i:Integer;
begin
  for i:=0 to Tracks.Count-1
  do TTrack(Tracks.Objects[i]).LoadTimeData(Ini,Section);
end;

procedure TIPConnection.OnTimer(Interval: Integer);
const
  dtOneMs=1/(24*60*60*1000);
var
  i:Integer;
  Trk:TTrack;
  TmpReplyOk,TmpNeedConn:Boolean;
  OldConErr:Boolean;
begin
  Inc(TimeCounter,Interval);
  case State of
    ipcsNoConnection: begin
//      if TimeCounter>=ConnInterval
      if GetMyTime-GetMinLastRecTime >= ConnInterval*dtOneMs
      then State:=ipcsConnecting
      else if PingOk then begin
//        State:=ipcsInConn;
        State:=ipcsOutConn;
      end;
    end;
    ipcsConnecting: begin
      if PingOk then State:=ipcsOutConn
      else if (ConnectingRetriesCounter=0) or (TimeCounter>=ConnectRetryInterval) then begin
        OldConErr:=ConnectingError;
        Inc(ConnectingRetriesCounter);
        if OldConErr<>ConnectingError
        then Log('НЕТ СВЯЗИ');
        if ConnectCmd<>''
        then ShellExecute(FrmMain.Handle,'open',PChar(ConnectCmd),'','',SW_SHOWMINNOACTIVE);
        TimeCounter:=0;
      end;
    end;
    ipcsInConn, ipcsOutConn: begin
      // Выполняем требуемые действия по передаче данных для каждого канала
      TmpReplyOk:=False;
      TmpNeedConn:=False;
      if Tracks.Count>0 then begin
        i:=iNextTrack;
        repeat
          Trk:=TTrack(Tracks.Objects[i]);
          Trk.OnTimer(Interval);
          TmpReplyOk:=TmpReplyOk or Trk.ReplyOk;
          TmpNeedConn:=TmpNeedConn or Trk.NeedConnection;
          i:=(i+1) mod Tracks.Count;
        until i=iNextTrack;
        iNextTrack:=(iNextTrack+1) mod Tracks.Count;
        // Отправка сгруппированных запросов (при надобности)
        SendGroupReq;
      end;
      ReplyOk:=TmpReplyOk;
      if State=ipcsOutConn then begin
        if not (TmpNeedConn or LeasedLine) then State:=ipcsNoConnection
        else if not (ReplyOk or PingOk) then State:=ipcsConnecting;
      end
      else if State=ipcsInConn then begin
        if not (ReplyOk or PingOk) then begin
          if TmpNeedConn
          then State:=ipcsConnecting
          else State:=ipcsNoConnection;
        end;
      end;
    end;
  end;
end;

procedure TIPConnection.SendGroupReq;
var
  MTS:TIME_STAMP;
  Buf:array of Byte;
  DataSize,Size,i:Integer;
  pGR:^TMyHeader_GroupReq;
begin
  MTS:=MyTimeStamp;
  if GrpSendInAnyCase or (MTS-GrpLastReqTime>=GrpReqInterval) and (Length(GrpReqBuf)>0)
  then begin
    GrpLastReqTime:=MTS;
    DataSize:=Length(GrpReqBuf)*SizeOf(GrpReqBuf[0]);
    Size:=SizeOf(TMyHeader)+SizeOf(Word)+DataSize;
    GetMem(pGR,Size);
    pGR.PacketType:=ptGroupReq;
    pGR.Count:=Length(GrpReqBuf);
    Move(GrpReqBuf[0],pGR.DataReq,DataSize);
    FrmMain.MyUDP.RemoteHost:=IPStr;
    FrmMain.MyUDP.RemotePort:=DataPort;
    UDPSendBuffer(FrmMain.MyUDP,pGR^,Size);
    GrpSendInAnyCase:=False;
  end;
end;

procedure TIPConnection.ReceiveData(const Data);
var
  Hdr:TMyHeader absolute Data;
  GA:TMyHeader_GroupAns absolute Data;
  Buf:^TMyHeader_AnsData;
  Ptr:PByte;
  Size:Word;
begin
  if Hdr.PacketType=ptAnsData
  then begin Buf:=@Hdr; ReceiveDataAns(Buf^); end
  else if Hdr.PacketType=ptGroupAns then begin
    Ptr:=@(GA.Data);
    while PWord(Ptr)^<>0 do begin
      Size:=PWord(Ptr)^;
      Inc(Ptr,2);
      Buf:=Pointer(Ptr);
      ReceiveDataAns(Buf^);
      Inc(Ptr,Size);
    end;
  end;
end;

procedure TIPConnection.SaveTimeData(Ini: TIniFile; const Section: String);
var
  i:Integer;
begin
  for i:=0 to Tracks.Count-1
  do TTrack(Tracks.Objects[i]).SaveTimeData(Ini,Section);
end;

procedure TIPConnection.SendDataRequest(TrackID: Integer;
  const LastRecTime:TDateTime; SendInAnyCase:Boolean);
var
  Buf:TMyHeader_ReqData;
  i:Integer;
begin
  Buf.PacketType:=ptReqData;
  Buf.TrackID:=TrackID;
  Buf.LastRecTime:=LastRecTime;
  if GrpEnabled then begin
    i:=High(GrpReqBuf);
    while i>=0 do begin
      if GrpReqBuf[i].TrackID=TrackID then break;
      Dec(i);
    end;
    if i<0 then begin
      i:=Length(GrpReqBuf);
      SetLength(GrpReqBuf,i+1);
    end;
    GrpReqBuf[i]:=Buf;
    GrpSendInAnyCase:=GrpSendInAnyCase or SendInAnyCase;
  end
  else begin
    FrmMain.MyUDP.RemoteHost:=IPStr;
    FrmMain.MyUDP.RemotePort:=DataPort;
    UDPSendBuffer(FrmMain.MyUDP,Buf,SizeOf(Buf));
  end;
end;

procedure TIPConnection.Set_State(const Value: TIPConnectionState);
begin
  if FState=Value then exit;
  case Value of
    ipcsNoConnection: begin
      if DisconnectCmd<>''
      then ShellExecute(FrmMain.Handle,'open',PChar(DisconnectCmd),'','',SW_SHOWMINNOACTIVE);
      Log('ОТКЛЮЧЕНИЕ');
    end;
    ipcsConnecting:
      ConnectingRetriesCounter:=0;
    ipcsInConn: Log('ВХОДЯЩЕЕ ПОДКЛЮЧЕНИЕ');
    ipcsOutConn: Log('ИСХОДЯЩЕЕ ПОДКЛЮЧЕНИЕ');
  end;
  TimeCounter:=0;
  FState := Value;
end;

procedure TIPConnection.Log(Msg: String);
begin
  WriteToLog(LogFileName,LogMsg(GetMyTime,Msg+' "'+ConnName+'"'));
end;

function TIPConnection.GetMinLastRecTime: TDateTime;
var
  i:Integer;
  Tmp:TDateTime;
begin
  Result:=GetMyTime;
  for i:=0 to Tracks.Count-1 do begin
    Tmp:=TTrack(Tracks[i]).LastRecTime;
    if Tmp<Result then Result:=Tmp;
  end;
end;

procedure TIPConnection.ReceiveDataAns(const Buf: TMyHeader_AnsData);
var
  i,j,Size:Integer;
  SrcW:WideString;
  DstW:WideString;
  TmpAD:TAnalogData;
begin
  if Tracks.Find(GetInvStrTrackID(Buf.TrackID),i) then begin
    if Buf.Count>0 then begin
      Size:=Buf.Count*RemoteSensor.GetRecSize;
      SetLength(SrcW,(Size+1) shr 1);
      Move(Buf.Data,SrcW[1],Size);
      if RemoteSensor<>TMySensor then begin
        SetLength(DstW,(Buf.Count*TMySensor.GetRecSize+1) shr 1);
        for j:=0 to Buf.Count-1 do begin
          RemoteSensor.GetAD(SrcW,j,TmpAD);
          TMySensor.SetAD(DstW,j,TmpAD);
        end;
      end
      else DstW:=SrcW;
    end;
    TTrack(Tracks.Objects[i]).ReceiveData(Buf.StartTime,Buf.Count,DstW);
  end;
end;

function TIPConnection.GrpReqBufSize: Integer;
begin
  Result:=Length(GrpReqBuf)*SizeOf(TMyHeader_ReqData);
end;

{ TTrack }

function TTrack.Get_CellValue(Col: Integer): String;
begin
  case Col of
  0: Result:=TrackIdStr;
  1: Result:=DateToStr(LastRecTime)+' - '+TimeToStr(LastRecTime);
  end;
end;

function TTrack.Get_InfoStr: String;
begin
  Result:=TrackIdStr;
end;

function TTrack.Get_ReplyOk: Boolean;
begin
  Result:=(LastReceiveTime<MaxReplyTime)or
    ((LastRequestTime>=1000)and DataReceived);
end;

function TTrack.Get_TrackIdStr: String;
begin
  Result:=ApplySubstitutions('%NPP_ID%%SectID%%SensID%',TrackID,0)
end;

constructor TTrack.LoadFromIniSection(const Section: String;
  const Ini: TIniFile; const Prefix: String);
begin
  inherited Create;
  FrmMain.AM.StrToTrackID(Ini.ReadString(Section,Prefix+'ID','ZZZ'),TrackID);
  FrmMain.AM.setTrackInfo(TrackID,TMySensor.GetRecSize,RecsPerDay);
  LastReceiveTime:=MaxReplyTime;
  LastRequestTime:=IfNoReplyInterval;
  FNeedConnection:=True;
end;

procedure TTrack.LoadTimeData(Ini: TIniFile; const Section: String);
var
  S:String;
  CurTime:TDateTime;
begin
  S:=Ini.ReadString(Section,TrackIDStr,'');
  CurTime:=GetMyTime;
  try
    LastRecTime:=StrToDateTime(S);
    if (LastRecTime>CurTime) and TimeIsSynchro then LastRecTime:=CurTime;
  except
    LastRecTime:=CurTime;
  end;
end;

procedure TTrack.OnTimer(Interval: Integer);
begin
  if ReplyOk or
//    (DataReceived and (LastRecvCnt=MaxSendDataCnt)) or
    (LastRequestTime>=IfNoReplyInterval)
  then SendDataRequest(False)
  else Inc(LastRequestTime,Interval);
  Inc(LastReceiveTime,Interval);
end;

procedure TTrack.ReceiveData(const Time: TDateTime; Count: Integer;
  const Data: WideString);
begin
  if (Count>0)and (not TimeIsSynchro or (Time<GetMyTime)) then begin
    DataReceived:=True;
    LastRecTime:=Time+Count*(1/RecsPerDay);
    FrmMain.AM.writeRecords(TrackID,Time,Count,Data);
    FNeedConnection:=True;
    LastReceiveTime:=0;
    LastRecvCnt:=Count;
    if Count=MaxSendDataCnt then SendDataRequest(True);
  end
  else FNeedConnection:=False;
end;

procedure TTrack.SendDataRequest(SendInAnyCase:Boolean);
begin
  IPConn.SendDataRequest(TrackID,LastRecTime,SendInAnyCase);
  DataReceived:=False;
  LastRequestTime:=0;
end;

procedure TTrack.SaveTimeData(Ini: TIniFile; const Section: String);
begin
  try
    Ini.WriteString(Section,TrackIdStr,DateTimeToStr(LastRecTime));
  except
  end;
end;

{ TPingerThread }

constructor TPingerThread.Create(IPCons: TStringList);
begin
  inherited Create(False);
  Self.IPCons:=IPCons;
end;

procedure TPingerThread.Execute;
var
  PerfFreq,PerfCnt1,PerfCnt2:Int64;
  i,Interval:Cardinal;
  Coeff:Double;
  C:TIPConnection;
begin
  if IPCons.Count=0 then exit;
  QueryPerformanceFrequency(PerfFreq);
  Coeff:=1000/PerfFreq;
  QueryPerformanceCounter(PerfCnt1);
  repeat
    QueryPerformanceCounter(PerfCnt2);
    Interval:=Round((PerfCnt2-PerfCnt1)*Coeff);
    if Interval<250 then Sleep(250-Interval);
    for i:=0 to IPCons.Count-1 do begin
      C:=TIPConnection(IPCons.Objects[i]);
      Dec(C.PingTimeCounter,Interval);
      if C.PingTimeCounter<=0 then begin
        Inc(C.PingRetriesCounter);
        {}C.PingResult:=Ping(C.IPStr,C.IP,C.PingTimeOut);
        if (C.ReplyOk and C.Connected) or (C.PingResult=0) then begin
          C.PingOk:=True;
          C.PingTimeCounter:=C.PingInterval;
          C.PingRetriesCounter:=0;
        end
        else if C.PingRetriesCounter>=C.PingRetries then begin
          C.PingOk:=False;
          C.PingTimeCounter:=C.PingInterval;
          C.PingRetriesCounter:=0;
        end
        else C.PingTimeCounter:=C.PingRetryInterval;
      end;
    end;
    PerfCnt1:=PerfCnt2;
  until Terminated;
end;

procedure TFrmMain.sgConnsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  C:TCanvas;
  S:String;
  Grid:TStringGrid absolute Sender;
begin
  C:=TFakeCustomControl(Grid).Canvas;
  S:=Grid.Cells[ACol, ARow];
  if ARow=0 then begin
    C.TextRect(
      Rect,
      (Rect.Left+Rect.Right-C.TextWidth(S)) div 2,
      (Rect.Top+Rect.Bottom-C.TextHeight(S)) div 2,
      S
    );
  end
  else begin
    C.TextRect(
      Rect,
      Rect.Left+2,
      (Rect.Top+Rect.Bottom-C.TextHeight(S)) div 2,
      S
    );
  end;
end;

procedure TFrmMain.SpdBtnResyncClick(Sender: TObject);
var
  P:TMyHeader;
begin
  if TimeServerIP<>'' then begin
    GetTimeCounter:=0;
    ResyncState:=rsWaitResync;
    P.PacketType:=ptInitResync;
    MyUDP.RemoteHost:=TimeServerIP;
    MyUDP.RemotePort:=TimeServerPort;
    UDPSendBuffer(MyUDP,P,SizeOf(P));
  end
  else begin
    NeedResyncSlaves:=True;
    ResyncSlavesIfNeed;
  end;
end;

end.

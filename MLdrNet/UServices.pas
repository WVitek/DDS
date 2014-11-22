{.$DEFINE __UseNewTimeSyncAlg}
unit UServices;

interface

uses SysUtils,Windows,IniFiles,Classes, UNetW, UFrameKP, UTime;

type
  TIME_STAMP = Int64;

  TADCServiceInData = packed record
    Time:TIME_STAMP;
    SensQnt:Byte;
    Data:packed array[0..1023] of Word;
  end;

const
  LLTicksProDay=24*60*60*1000;
  dtLLTickPeriod=1/LLTicksProDay;
  dtOneSecond=1/SecsPerDay;
  dtOneMSec=1/MSecsPerDay;
  TPL3=33;
  TPL5=100;

type
  // служба аналоговых датчиков
  TServiceADC = class(TService)
    KP:TItemKP;
    toutPoll:TTimeoutObj;
    DataLag:Integer;
    WasAnswer:Boolean;
  public
    LastDataLen:Integer;
    constructor Create(KP:TItemKP);
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(const Data:String);override;
  end;

  // служба обновления программы контроллера
  TServiceReprog = class(TService)
    KP:TItemKP;
    State:(sNone, sInit, sProg, sReset);
    Stopping:Boolean;
    toutSend:TTimeoutObj;
    LastPos,ReqPos,ImgSize,FileDate:Integer;
    ImgFile:file;
    FileName:String;
  public
    constructor Create(KP:TItemKP);
    procedure startProgramming(FileName:String);
    procedure stopProgramming;
    procedure SendSoftReset;
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(const Data:String);override;
    procedure BeforeDestruction;override;
  end;

  // служба получения дампа памяти контроллера
  TServiceDump = class(TService)
    KP:TItemKP;
    WritePos:Integer;
    DumpFile:file;
    Active,NeedSendCmd:Boolean;
  public
    constructor Create(KP:TItemKP);
    procedure start;
    procedure stop;
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(const Data:String);override;
    procedure BeforeDestruction;override;
  end;

  // служба цифровых входов
  TServiceAlarm = class(TService)
    KP:TItemKP;
    EventMsg:TStringList;
    toutAck:TTimeoutObj;
    constructor Create(KP:TItemKP; Ini:TIniFile);
    destructor Destroy;override;
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(const Data:String);override;
  end;

  // служба сервера времени
  TServiceTimeServer = class(TService)
    KP:TItemKP;
    TimeQueryTx,TimeQueryRx:TIME_STAMP;
    QuerySize:Integer;
  public
    constructor Create(KP:TItemKP);
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(const Data:String);override;
  end;

  TServicePing = class(TService)
    KP:TItemKP;
    NeedPing:Boolean;
  public
    constructor Create(KP:TItemKP);
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(const Data:String);override;
  end;

implementation

uses UTreeItem,UPRT,Misc;

{ TServiceADC }

constructor TServiceADC.Create(KP:TItemKP);
begin
  ID:=2;
  Self.KP:=KP;
  toutPoll.setSignaled();
end;

procedure TServiceADC.getDataToTransmit(var Data: String;
  MaxSize: Integer);
var
  pT:^TIME_STAMP;
begin
  DataLag:=KP.DataLag;
  SetLength(Data,SizeOf(TIME_STAMP));
  pT:=@Data[1];
  pT^:=ToTimeStamp(KP.LastDataTime);
  KP.CommMsg('Data request',-Length(Data));
  if WasAnswer
  then toutPoll.start(toTypeSec or (KP.DataLag+1) shr 1)
  else toutPoll.start(toTypeSec or KP.DataLag);
  WasAnswer:=False;
end;

function TServiceADC.HaveDataToTransmit: Boolean;
begin
  Result:=(KP.DataLag<>DataLag) or toutPoll.IsSignaled();
end;

procedure TServiceADC.receiveData(const Data: String);
var
  Lag:Integer;
begin
  Lag := KP.handleADCService(Data);
  if Lag > 0
  then toutPoll.start(toTypeSec or Lag)
  else toutPoll.setSignaled();
  WasAnswer:=True;
end;

{ TServiceReprog }

type
  FILE_DATA = packed record
    mark:Word;   // $7188 -> is file
    fname:array[1..12] of char;
    year,month,day,hour,minute,sec:Byte;
    size:Cardinal;
    addr:Pointer;
    CRC:Word;
    CRC32:Cardinal;
  end;

procedure TServiceReprog.BeforeDestruction;
begin
  stopProgramming;
  inherited;
end;

constructor TServiceReprog.Create(KP:TItemKP);
begin
  ID:=3;
  Self.KP:=KP;
end;

procedure TServiceReprog.getDataToTransmit(var Data: String; MaxSize: Integer);
const
  PROG_CANCEL   =-1;
  PROG_FILEINFO =-2;
  PROG_SOFTRESET=-6;
type
  TOutData=record
    Offset:Integer;
    Data:array[0..0] of Byte;
  end;
var
  OD:^TOutData;
  Size:Integer;
  StopIt:Boolean;
  pFD:^FILE_DATA;
  ST:TSystemTime;
begin
  StopIt:=False;
  case State of
  sInit:
    begin
      SetLength(Data,4+SizeOf(FILE_DATA));
      OD:=@(Data[1]);
      OD.Offset:=PROG_FILEINFO;
      Pointer(pFD):=@(OD.Data);
      FillChar(pFD^,SizeOf(FILE_DATA),$FF);
      Size:=Length(FileName)+1; if Size>12 then Size:=12;
      Move(FileName[1],pFD.fname,Size);
      DateTimeToSystemTime(FileDateToDateTime(FileDate),ST);
      pFD.mark := $7188;
      pFD.year  := ST.wYear-1980;
      pFD.month := ST.wMonth;
      pFD.day   := ST.wDay;
      pFD.hour  := ST.wHour;
      pFD.minute:= ST.wMinute;
      pFD.sec   := ST.wSecond;
      pFD.size  := ImgSize;
      toutSend.start(toTypeSec or 30);
      KP.CommMsg('invitation to file LOADing',-Length(Data));
    end;
  sProg:
    begin
      if Stopping
      then StopIt:=True
      else
      begin
        Size:=MaxSize-4;
        if ReqPos+Size > ImgSize
        then Size:=ImgSize-ReqPos;
        SetLength(Data,Size+4);
        OD:=@(Data[1]);
        OD.Offset:=ReqPos;
        if Size>0 then begin
          Seek(ImgFile,ReqPos);
          BlockRead(ImgFile,OD.Data,Size);
        end;
      end;
      toutSend.setSignaled(False);
    end;
  sReset:
    begin
      SetLength(Data,4+SizeOf(FILE_DATA));
      OD:=@(Data[1]);
      OD.Offset:=PROG_SOFTRESET;
      State:=sNone;
    end;
  else
    StopIt:=True;
  end;
  if StopIt then
  begin
    SetLength(Data,4);
    OD:=@(Data[1]);
    OD.Offset:=PROG_CANCEL;
  end;
end;

function TServiceReprog.HaveDataToTransmit: Boolean;
begin
  Result:=(State<>sNone) and toutSend.IsSignaled;
end;

procedure TServiceReprog.receiveData(const Data: String);
const
  PROG_CANCEL   =-1;
  PROG_FILEINFO =-2;
  PROG_ERRNAME  =-3;
  PROG_ERRSIZE  =-4;
  PROG_ERRWRITE =-5;
type
  TInData=record
    Offset:Integer;
  end;
var
  ID:^TInData;
  Stop:Boolean;
begin
  toutSend.setSignaled;
  if Length(Data)<>4 then exit;
  ID:=@(Data[1]);
  ReqPos:=ID.Offset;
  Stop:=True;
  case State of
  sInit:
    case ReqPos of
    0:
      begin
        KP.AddEvent(GetMyTime,'Загрузка файла начата');
        State:=sProg;
        LastPos:=0;
        Stop:=False;
      end;
    PROG_ERRNAME:
      KP.AddEvent(GetMyTime,'Контроллеру не нравится имя файла');
    PROG_ERRSIZE:
      KP.AddEvent(GetMyTime,'Файл не поместится в памяти контроллера');
    end;
  sProg:
    begin
      if (0<=ReqPos) and (ReqPos<=ImgSize)
      then begin
        if LastPos shr 11 < ReqPos shr 11
        then KP.CommMsg(Format('LOAD: %05d/%05d',[ReqPos,ImgSize]),Length(Data));
        LastPos:=ReqPos;
        if ReqPos = ImgSize
        then begin
          KP.AddEvent(GetMyTime,'Загрузка файла завершена');
          KP.Alarm:=True;
        end
        else Stop:=False;
      end
      else begin
        case ReqPos of
        PROG_CANCEL:
          KP.AddEvent(GetMyTime,'Загрузка файла отменена');
        PROG_ERRWRITE:
          KP.AddEvent(GetMyTime,'Сбой контроллера при записи');
        end;
      end;
    end;
  else
    Stop:=False;
  end;
  if Stop then begin
    State:=sNone;
    CloseFile(ImgFile);
  end;
end;

procedure TServiceReprog.SendSoftReset;
begin
  if State<>sNone then exit;
  State:=sReset;
  KP.AddEvent(GetMyTime,'Команда перезапуска контроллера!');
  toutSend.setSignaled;
end;

procedure TServiceReprog.startProgramming(FileName:String);
begin
  if State<>sNone then exit;
  Assign(ImgFile,FileName);
  try
    FileDate:=FileAge(FileName); if FileDate=-1 then exit;
    Reset(ImgFile,1);
    ImgSize:=FileSize(ImgFile);
    State:=sInit;
    Stopping:=False;
    toutSend.setSignaled;
    KP.AddEvent(GetMyTime,'Инициирована загрузка файла ['+FileName+']');
    Self.FileName:=ExtractShortPathName(ExtractFileName(FileName));
  except
    on E:Exception do
    KP.CommMsg('! ERROR: Cannot start loading ('+E.Message+')',0);
  end;
end;

procedure TServiceReprog.stopProgramming;
begin
  if (State = sNone) then exit;
  if Stopping then
  begin
    KP.AddEvent(GetMyTime,'Отмена загрузки файла!!!');
    State := sNone;
    CloseFile(ImgFile);
  end
  else begin
    Stopping:=True;
    KP.AddEvent(GetMyTime,'Отмена загрузки файла...');
  end;
end;

{ TServiceAlarm }

constructor TServiceAlarm.Create;
const
  Section='States';
var
  i,Cnt:Integer;
  S:String;
begin
  Self.KP:=KP;
  EventMsg:=TStringList.Create;
  Cnt:=Ini.ReadInteger(Section,'Count',0);
  for i:=1 to Cnt do begin
    S:=Ini.ReadString(Section,'S'+IntToStr(i),'');
    if S<>'' then EventMsg.Add(S);
  end;
  ID:=4;
end;

destructor TServiceAlarm.Destroy;
begin
  EventMsg.Free;
  inherited;
end;

procedure TServiceAlarm.getDataToTransmit(var Data: String;
  MaxSize: Integer);
var
  pT:^TIME_STAMP;
begin
  SetLength(Data,sizeof(TIME_STAMP));
  pT:=@Data[1];
  pT^:=ToTimeStamp(KP.LastEvntTime);
  toutAck.start(toTypeSec or 120);
end;

function TServiceAlarm.HaveDataToTransmit: Boolean;
begin
  Result:=toutAck.IsSignaled;
end;

procedure TServiceAlarm.receiveData(const Data: String);
type
  TInData=packed record
    Time:TIME_STAMP;
    Ch:Byte;
    State:Byte;
  end;
var
  S:String;
  i,Cnt:Integer;
  A:^TInData;
  Time:TDateTime;
  News,Olds:Boolean;
begin
  if Data='' then exit;
  Cnt:=Length(Data) div SizeOf(TInData);
  A:=@(Data[1]);
  Olds:=False;
  News:=False;
  for i:=0 to Cnt-1 do begin
    Time:=ToDateTime(A.Time);
    if Time>KP.LastEvntTime then
    begin
      News:=True;
      KP.LastEvntTime:=Time;
      S:=GetEventMsg(EventMsg,A.Ch,A.State);
      KP.AddEvent(Time,S);
      KP.Alarm:=True;
    end
    else Olds:=True;
    Inc(A);
  end;
  if Olds then KP.CommMsg('old event(s) received',Length(Data));
  if News then KP.CommMsg('new event(s) received',Length(Data));
  if Length(Data)-Cnt*SizeOf(TInData)=1
  then begin
    toutAck.setSignaled(False); // one extra byte -> no more events
    KP.CommMsg('; no more events @ this time',0);
  end
  else toutAck.setSignaled;
end;

{ TServiceTimeServer }

type
  _TimeData=packed record
    TQTx,TQRx,TATx:TIME_STAMP;
  end;

constructor TServiceTimeServer.Create(KP:TItemKP);
begin
  ID:=1;
  Self.KP:=KP;
end;

procedure TServiceTimeServer.getDataToTransmit(var Data: String;
  MaxSize: Integer);
var
  i,Size:Integer;
begin
//  KP.CommMsg('< time answer');
{$IFDEF __UseNewTimeSyncAlg}
  case QuerySize of
    TPL3: Size:=TPL5-PRTDataSize;
    TPL5: Size:=TPL3-PRTDataSize;
    else Size:=0;
  end;
{$ELSE}
  Size:=SizeOf(_TimeData);
{$ENDIF}
  SetLength(Data,Size);
  if Size<>0 then begin
    with _TimeData((@(Data[1]))^) do begin
      TQTx:=TimeQueryTx;
      TQRx:=TimeQueryRx;
      TATx:=MyTimeStamp;
    end;
    for i:=1 to Size do Byte(Data[i]):=Byte(Data[i]) xor (i-1);
  end;
  QuerySize:=0;
end;

function TServiceTimeServer.HaveDataToTransmit: Boolean;
begin
  Result:=QuerySize<>0;
end;

procedure TServiceTimeServer.receiveData(const Data: String);
var
  i:Integer;
  Buf:String;
  PrevTQTx,ClientTime,Delta:TIME_STAMP;
begin
  TimeQueryRx:=MyTimeStamp;
  SetLength(Buf,Length(Data));
  for i:=1 to Length(Buf) do Byte(Buf[i]):=Byte(Data[i]) xor (i-1);
  PrevTQTx:=TimeQueryTx;
  TimeQueryTx:=_TimeData((@(Buf[1]))^).TQTx;
  QuerySize:=Length(Buf);//+PRTDataSize;
//  ItemMain.NoAnswerWatchTimer:=0;
//  ItemMain.CommEvent('time query');
  if TimeQueryTx-PrevTQTx<9000 then
  begin
    ClientTime:=TimeQueryRx-(TimeQueryTx-PrevTQTx) div 3;
    Delta:=ClientTime-TimeQueryTx;
    KP.CommMsg(Format('time request (dT=%dms)',[Delta]),Length(Data));
  end
  else KP.CommMsg('time request',Length(Data));
end;

{ TServiceDump }

procedure TServiceDump.BeforeDestruction;
begin
  stop;
  inherited;
end;

constructor TServiceDump.Create(KP:TItemKP);
begin
  inherited Create;
  ID:=5;
  Self.KP:=KP;
end;

procedure TServiceDump.getDataToTransmit(var Data: String;
  MaxSize: Integer);
var
  OD:^Boolean;
begin
  SetLength(Data,1);
  OD:=@(Data[1]);
  OD^:=Active;
  NeedSendCmd:=False;
end;

function TServiceDump.HaveDataToTransmit: Boolean;
begin
  Result:=NeedSendCmd;
end;

procedure TServiceDump.receiveData(const Data: String);
var
  Show:Boolean;
begin
  if not Active then exit;
  if Length(Data)>0 then begin
    BlockWrite(DumpFile,Data[1],Length(Data));
    Show:=WritePos shr 10 < (WritePos+Length(Data)) shr 10;
    Inc(WritePos,Length(Data));
  end
  else begin
    stop;
    KP.AddEvent(GetMyTime,'Получение дампа завершено');
    Show:=True;
  end;
  if Show
  then KP.CommMsg(Format('DUMP: %3dK',[WritePos shr 10]),Length(Data));
end;

procedure TServiceDump.start;
begin
  Assign(DumpFile,'dump.bin');
  try
    Rewrite(DumpFile,1);
    Active:=True;
    NeedSendCmd:=True;
    WritePos:=0;
  except
//    ItemMain.AddEvent(GetMyTime,'ERROR: Cannot write "dump.bin" file');
  end;
end;

procedure TServiceDump.stop;
begin
  if Active then begin
    Active:=False;
    NeedSendCmd:=True;
    CloseFile(DumpFile);
  end;
end;

{ TServicePing }

constructor TServicePing.Create(KP:TItemKP);
begin
  ID:=0;
  Self.KP:=KP;
end;

procedure TServicePing.getDataToTransmit(var Data: String;
  MaxSize: Integer);
begin
  Data:='';
  NeedPing:=False;
//  KP.CommMsg('< ping echo');
end;

function TServicePing.HaveDataToTransmit: Boolean;
begin
  Result:=NeedPing;
end;

procedure TServicePing.receiveData(const Data: String);
begin
  NeedPing:=True;
  KP.CommMsg('ping',Length(Data));
end;

end.

{.$DEFINE __UseNewTimeSyncAlg}
unit UServices;

interface

uses SysUtils,Windows;

type
  TIME_STAMP = Int64;

  TADCServiceInData = packed record
    SensNum:Byte;
    Time:TIME_STAMP;
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
  TService = class(TObject)
  public
    ID:Byte;
    function HaveDataToTransmit:Boolean;virtual;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);virtual;
    procedure receiveData(FromAddr:Byte; const Data:String);virtual;abstract;
  end;

  // служба аналоговых датчиков
  TServiceADC = class(TService)
    LastDataLen:Integer;
    constructor Create;
    procedure receiveData(FromAddr:Byte; const Data:String);override;
  end;

  // служба обновления программы контроллера
  TServiceReprog = class(TService)
    ProgPos,AckedPos,ImgSize:Integer;
    ImgFile:file;
    Programming:Boolean;
  public
    constructor Create;
    procedure startProgramming;
    procedure stopProgramming;
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(FromAddr:Byte; const Data:String);override;
    procedure BeforeDestruction;override;
  end;

  // служба получения дампа памяти контроллера
  TServiceDump = class(TService)
    WritePos:Integer;
    DumpFile:file;
    Active,NeedSendCmd:Boolean;
  public
    constructor Create;
    procedure start;
    procedure stop;
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(FromAddr:Byte; const Data:String);override;
    procedure BeforeDestruction;override;
  end;

  // служба синхронизации времени
  TServiceTime = class(TService)
    TimeQ:TIME_STAMP;
    constructor Create;
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(FromAddr:Byte; const Data:String);override;
  end;

  // служба цифровых входов
  TServiceAlarm = class(TService)
    constructor Create;
    procedure receiveData(FromAddr:Byte; const Data:String);override;
  end;

  TServiceTimeServer = class(TService)
    TimeQueryTx,TimeQueryRx:TIME_STAMP;
    QuerySize:Integer;
  public
    function HaveDataToTransmit:Boolean;override;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);override;
    procedure receiveData(FromAddr:Byte; const Data:String);override;
  end;

implementation

uses UFrameMain,UFrameKP,UTreeItem,UPRT,UTime;

function MyTimeStamp:TIME_STAMP;
begin
  Result:=Round(GetMyTime*LLTicksProDay);
end;

{ TService }

procedure TService.getDataToTransmit(var Data: String; MaxSize: Integer);
begin
  // do nothing
end;

function TService.HaveDataToTransmit: Boolean;
begin
  Result:=False;
end;

{ TServiceADC }

constructor TServiceADC.Create;
begin
  inherited;
  ID:=2;
end;

procedure TServiceADC.receiveData(FromAddr:Byte; const Data: String);
var
  ID:^TADCServiceInData;
  KP:TItemKP;
begin
  if Data='' then exit;
  LastDataLen:=Length(Data);
  ID:=@(Data[1]);
//{
  ItemMain.CommEvent(
    Format('#%.3d: %s.%.3d AD#%d %d',[
      FromAddr,
      DateTimeToStr(ID.Time*dtLLTickPeriod),
      ID.Time mod 1000,
      ID.SensNum,
      (Length(Data)-1-SizeOf(TIME_STAMP)) div ADCSampleSize]
    )
  );
//}
  ItemMain.FindKP(FromAddr,TTreeItem(KP));
  if KP<>nil
  then KP.handleADCService(Data);
end;

{ TServiceReprog }

procedure TServiceReprog.BeforeDestruction;
begin
  stopProgramming;
  inherited;
end;

constructor TServiceReprog.Create;
begin
  inherited;
  ID:=3;
end;

procedure TServiceReprog.getDataToTransmit(var Data: String; MaxSize: Integer);
type
  TOutData=record
    Offset:Integer;
    Data:array[0..0] of Byte;
  end;
var
  OD:^TOutData;
  Size:Integer;
begin
  Size:=MaxSize-4;
  if ProgPos+Size>ImgSize
  then Size:=ImgSize-ProgPos;
  SetLength(Data,Size+4);
  OD:=@(Data[1]);
  OD.Offset:=ProgPos;
  if Size>0 then begin
    Seek(ImgFile,ProgPos);
    BlockRead(ImgFile,OD.Data,Size);
    Inc(ProgPos,Size);
  end
  else ProgPos:=ImgSize+1;
end;

function TServiceReprog.HaveDataToTransmit: Boolean;
begin
  Result:=Programming and (ProgPos<=ImgSize);
end;

procedure TServiceReprog.receiveData(FromAddr: Byte; const Data: String);
type
  TInData=record
    Offset:Integer;
  end;
var
  ID:^TInData;
  Show:Boolean;
begin
  if not Programming then exit;
  ID:=@(Data[1]);
  Show:=AckedPos shr 10 < ID^.Offset shr 10;
  AckedPos:=ID^.Offset;
  if ID^.Offset=ImgSize then begin
    stopProgramming;
    AckedPos:=0;
    ItemMain.AddEvent(GetMyTime,'Перепрошивка завершена');
    Show:=True;
  end;
  if Show
  then ItemMain.CommEvent(Format('PROG: %05d of %05d',[ID^.Offset,ImgSize]));
end;

procedure TServiceReprog.startProgramming;
begin
  Programming:=False;
  Assign(ImgFile,'rom-disk.img');
  try
    Reset(ImgFile,1);
    ImgSize:=FileSize(ImgFile);
    Programming:=True;
    ProgPos:=AckedPos;
  except
    ItemMain.AddEvent(GetMyTime,'ERROR: Cannot read ROM-disk image');
  end;
end;

procedure TServiceReprog.stopProgramming;
begin
  if Programming then begin
    Programming:=False;
    CloseFile(ImgFile);
  end;
end;

{ TServiceTime }

constructor TServiceTime.Create;
begin
  inherited;
  ID:=1;
end;

procedure TServiceTime.getDataToTransmit(var Data: String; MaxSize: Integer);
type
  TOutData = packed record
    TimeQ,TimeA:TIME_STAMP;
  end;
var
  OD:^TOutData;
begin
  SetLength(Data,SizeOf(TOutData));
  OD:=@(Data[1]);
  OD.TimeQ:=TimeQ;
  OD.TimeA:=MyTimeStamp;
  TimeQ:=0;
end;

function TServiceTime.HaveDataToTransmit: Boolean;
begin
  Result:=TimeQ<>0;
end;

procedure TServiceTime.receiveData(FromAddr: Byte; const Data: String);
type
  TInData = packed record
    TimeQ,Filler:TIME_STAMP;
  end;
var
  ID:^TInData;
begin
  if Data='' then exit;
  ID:=@(Data[1]);
  TimeQ:=ID.TimeQ;
  ItemMain.CommEvent('time query');
end;

{ TServiceAlarm }

constructor TServiceAlarm.Create;
begin
  inherited;
  ID:=4;
end;

procedure TServiceAlarm.receiveData(FromAddr: Byte; const Data: String);
type
  TInData=packed record
    Time:TIME_STAMP;
    Ch:Byte;
    State:Boolean;
  end;
const
  sMsg:array [0..2,Boolean] of String=(
    ('Открыта дверь КП','Закрыта дверь КП'),
    ('Открыта крышка колодца','Закрыта крышка колодца'),
    ('Нет напряжения в сети','Есть напряжение в сети')
  );
  sState:array[Boolean] of String=('разомкнут','замкнут');
var
  KP:TItemKP;
  S:String;
  i,Cnt:Integer;
  A:^TInData;
  Time:TDateTime;
begin
  if Data='' then exit;
  ItemMain.FindKP(FromAddr,TTreeItem(KP));
  Cnt:=Length(Data) div SizeOf(TInData);
  A:=@(Data[1]);
  for i:=0 to Cnt-1 do begin
    Time:=A.Time*dtLLTickPeriod;
    A.State:=not A.State;
    case A.Ch of
      0..High(sMsg):
        S:=Format('%s',[sMsg[A.Ch,A.State]]);
      255:
        S:='Включение контроллера'
      else
        S:=Format('Контакт IN%d %s',[A.Ch+1,sState[A.State]]);
    end;
    if KP<>nil then begin
      KP.AddEvent(Time,S);
      if not ItemMain.NoAlarm then KP.Alarm:=True;
    end
    else ItemMain.AddEvent(Time,Format('На КП №%d %s',[FromAddr,S]));
    Inc(A);
  end;
end;

{ TServiceTimeServer }

type
  _TimeData=packed record
    TQTx,TQRx,TATx:TIME_STAMP;
  end;

procedure TServiceTimeServer.getDataToTransmit(var Data: String;
  MaxSize: Integer);
var
  i,Size:Integer;
begin
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

procedure TServiceTimeServer.receiveData(FromAddr: Byte;
  const Data: String);
var
  i:Integer;
  Buf:String;
begin
  TimeQueryRx:=MyTimeStamp;
  SetLength(Buf,Length(Data));
  for i:=1 to Length(Buf) do Byte(Buf[i]):=Byte(Data[i]) xor (i-1);
  TimeQueryTx:=_TimeData((@(Buf[1]))^).TQTx;
  QuerySize:=Length(Buf)+PRTDataSize;
  ItemMain.NoAnswerWatchTimer:=0;
end;

{ TServiceDump }

procedure TServiceDump.BeforeDestruction;
begin
  stop;
  inherited;
end;

constructor TServiceDump.Create;
begin
  inherited;
  ID:=5;
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

procedure TServiceDump.receiveData(FromAddr: Byte; const Data: String);
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
    ItemMain.AddEvent(GetMyTime,'Получение дампа завершено');
    Show:=True;
  end;
  if Show
  then ItemMain.CommEvent(Format('DUMP: %3dK',[WritePos shr 10]));
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
    ItemMain.AddEvent(GetMyTime,'ERROR: Cannot write "dump.bin" file');
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

end.

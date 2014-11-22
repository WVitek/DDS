unit Main;

interface

uses
  Windows, MMSystem, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IniFiles, Misc, SensorFrame, DdhAppX, Menus, SyncObjs, ConvTP, ExtCtrls,
  NMUDP, DataTypes, SensorTypes, StdCtrls;

type
  TMainThread = class;

  TFormMain = class(TForm)
    AppExt: TDdhAppExt;
    PopupMenu: TPopupMenu;
    pmiClose: TMenuItem;
    pmiAbout: TMenuItem;
    N1: TMenuItem;
    pmiSuspend: TMenuItem;
    pmiResume: TMenuItem;
    NMUDP: TNMUDP;
    N2: TMenuItem;
    pmiShowHide: TMenuItem;
    pmiReadOnly: TMenuItem;
    PnlCmd: TPanel;
    memoEcho: TMemo;
    Timer: TTimer;
    Panel1: TPanel;
    BtnClear: TButton;
    cbShowDataDump: TCheckBox;
    StTxtTrafficIn: TStaticText;
    StTxtTrafficOut: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure pmiCloseClick(Sender: TObject);
    procedure pmiAboutClick(Sender: TObject);
    procedure AppExtTrayDefault(Sender: TObject);
    procedure pmiResumeClick(Sender: TObject);
    procedure pmiSuspendClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure NMUDPInvalidHost(var handled: Boolean);
    procedure NMUDPBufferInvalid(var handled: Boolean;
      var Buff: array of Char; var length: Integer);
    procedure pmiReadOnlyClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure cbShowDataDumpClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    function Get_FrameSensor(i: Integer): TFrameSensor;
    function LogMsg(const DT:TDateTime; const Msg:String):String;
    procedure AddEchoText(const S:String);
    procedure Set_SensorsReadOnly(const Value: Boolean);
    procedure Start;
    procedure Stop;
    procedure WriteToLog(const S:String);
  public
    { Public declarations }
    Ini:TIniFile;
    Thd:TMainThread;
    Sensors:TList;
    StartCnt,OldCnt:Int64;
    StartTime:TDateTime;
    NotFirst:Boolean;
    Period:TDateTime;
    property FrameSensor[i:Integer]:TFrameSensor read Get_FrameSensor;
    property SensorsReadOnly:Boolean write Set_SensorsReadOnly;
  end;

  TServiceHandler = function(const InData:String; var OutData:String):Boolean of object;

  TMainThread=class(TThread)
    Sensors:TList;
    ComPort:String;
    ComSpeed:Integer;
    DialMaxDuration:Integer;
    ClearWatchdog:Boolean;
    CS:TCriticalSection;
    NeedTimeResync:Boolean;
    ShowDataDump:Boolean;
    sCmd,sUserResp,sAutoResp,sDataDump:String;
    sDialCmd:String;
    TrafficIn,TrafficOut:Integer;
    PacketsIn,PacketsOut:Integer;
    constructor Create;
    procedure Execute;override;
    destructor Destroy;override;
  private
    hCom:THandle;
    SvcHandlers:array[0..2] of record SvcID:Byte; Handler:TServiceHandler; end;
    UBuf:array of Byte;
    function readBuf(var Buffer; Len:Integer):Cardinal;
    procedure unreadBuf(var Buffer; Len:Integer);
    procedure putComBuf(const Buffer; Length:Integer);
    procedure putComStr(const S:String);
    function handleTimeSyncService(const InData:String; var OutData:String):Boolean;
    function handleADCService(const InData:String; var OutData:String):Boolean;
    function handleProgService(const InData:String; var OutData:String):Boolean;
  end;

  TPacketHeader = packed record
    Addr,PacketID,ServiceID:Byte;
    DataSize,DataChecksum,Checksum:Word;
  end;

  TIME_STAMP = Int64;

  TADCServiceInData = packed record
    SensNum:Byte;
    Time:TIME_STAMP;
    Data:packed array[0..1023,0..2] of Byte;
  end;

const
  LLTicksProDay=24*60*60*1000;
  dtLLTickPeriod=1/LLTicksProDay;
  dtOneSecond=1/SecsPerDay;
  dtOneMSec=1/MSecsPerDay;

var
  FormMain: TFormMain;

procedure ShowErrorMsg(ErrorId:Cardinal);

implementation

{$R *.DFM}

const
  Section='config';
  Programming:Boolean=FALSE;
  ProgPos:Integer=0;

function getHexDump(const Data; Size:Integer):String;
type
  PByte=^Byte;
var
  i:Integer;
  s:String;
  B:array[0..65535] of Byte absolute Data;
begin
  Result:='';
  for i:=0 to Size-1 do begin
    S:=Format('%x',[B[i]]);
    if Length(S)=1 then S:='0'+S+' ' else S:=S+' ';
    Result:=Result+S;
  end;
end;

procedure FNTimeCallBack(uTimerID,uMessage:UINT;dwUser,dw1,dw2:DWORD);stdcall;
var
  Self:TFormMain absolute dwUser;
begin
  Self.TimerTimer(Self);
end;

function MakeLangId(p,s:Word):Cardinal;
begin
  Result:=(s shl 10) or p;
end;

procedure ShowErrorMsg(ErrorId:Cardinal);
const
  BufSize=1024;
var
  lpMsgBuf:PChar;
begin
  GetMem(lpMsgBuf,BufSize);
  FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM,
    nil,
    ErrorId,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
    lpMsgBuf,
    BufSize,
    nil
  );
  // Display the string.
  Application.MessageBox(lpMsgBuf,'ERROR',MB_OK or MB_ICONINFORMATION);
  // Free the buffer.
  FreeMem(lpMsgBuf,BufSize);
end;

function CalcChecksum(const Data; Size:Cardinal):Word;
type
  PByte = ^Byte;
var
  i:Cardinal;
begin
  Result:=0;
  for i:=0 to Size-1 do Inc(Result,PByte(Cardinal(@Data)+i)^);
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  i,Count,W,H:Integer;
  SF:TFrameSensor;
  hSysMenu:Integer;
begin
  InitFormattingVariables;
  W:=0; H:=0;
  try
    if ParamCount=1
    then Ini:=TIniFile.Create(ExpandFileName(ParamStr(1)))
    else Ini:=TIniFile.Create(Misc.GetModuleFullName+'.ini');
    Sensors:=TList.Create;
    Count:=Ini.ReadInteger(Section,'SensorCount',0);
    for i:=1 to Count do begin
      SF:=TFrameSensor.Create(Self);
      SF.Name:='';
      SF.LoadFromIniSection(Ini,'Sensor'+IntToStr(i));
      Sensors.Add(SF);
      SF.Top:=H;
      SF.Left:=0;
      SF.Parent:=Self;
      W:=SF.Width;
      Inc(H,SF.Height);
    end;
    ClientWidth:=W+PnlCmd.Width;
    ClientHeight:=H;
    pmiReadOnly.Enabled:=Ini.ReadInteger(Section,'ReadOnly',1)=0;
    Caption:=Ini.ReadString(Section,'AppTitle','Ldr7017');
    Application.Title:=Caption;
    AppExt.TrayHint:=Ini.ReadString(Section,'TrayHint','Ldr7017');
    hSysMenu:=GetSystemMenu(Handle,False);
    EnableMenuItem(hSysMenu,SC_CLOSE,MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
    if Ini.ReadInteger(Section,'AutoStart',0)<>0 then begin
      ShowWindow(Application.Handle,0);
      pmiResume.Click;
    end
    else Visible:=True;
    WriteToLog(LogMsg(Now,'ЗАПУСК (Ldr7188)'));
  except
    Application.MessageBox(
      'Исключительная ситуация при инициализации программы опроса I-7188',
      '',MB_ICONHAND or MB_OK
    );
    Application.Terminate;
  end;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
var
  i:Integer;
  SF:TFrameSensor;
begin
  Stop;
  if Sensors<>nil then begin
    for i:=0 to Sensors.Count-1 do begin
      SF:=TFrameSensor(Sensors[i]);
      SF.WriteToIni(Ini);
    end;
    Sensors.Free;
  end;
  Ini.Free;
  WriteToLog(LogMsg(Now,'ОСТАНОВ (Ldr7188)'));
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
  Application.MessageBox(
    'СКУ'#13#13+
    'Интерфейс с контроллером нижнего уровня'#13#13+
    '(c) 2000-2002 ООО "Компания Телекомнур"'#13+
    'e-mail: test@mail.rb.ru',
    'О программе',
    MB_ICONINFORMATION or MB_OK or MB_TOPMOST);
end;

procedure TFormMain.AppExtTrayDefault(Sender: TObject);
begin
  if Application.Active then Visible:=not Visible else Visible:=TRUE;
  SetForegroundWindow(Handle);
end;

procedure TFormMain.Start;
var
  i:Integer;
begin
  if Thd<>nil then exit;
  for i:=0 to Sensors.Count-1 do begin
    if not FrameSensor[i].Validate then begin
      FormMain.Show;
      exit;
    end;
  end;
  Period:=Ini.ReadInteger(Section,'Period',1000)*dtOneMSec;
  Thd:=TMainThread.Create;
  Thd.ComPort:=Ini.ReadString(Section,'ComPort','COM1');
  Thd.ComSpeed:=Ini.ReadInteger(Section,'ComSpeed',19200);
  Thd.sDialCmd:=Ini.ReadString(Section,'DialCmd','');
  Thd.DialMaxDuration:=Ini.ReadInteger(Section,'DialMaxDuration',60);
  Thd.ShowDataDump:=cbShowDataDump.Checked;
  Thd.Sensors:=Sensors;
  Thd.Resume;
end;

procedure TFormMain.Stop;
begin
  if Thd<>nil then begin
    Thd.Terminate;
//    Sleep(1000);
    Thd.WaitFor;
//    TerminateThread(Thd.Handle,0);
    Thd.Free;
    Thd:=nil;
  end;
end;

procedure TFormMain.pmiResumeClick(Sender: TObject);
begin
  Start;
  if Thd<>nil then begin
    pmiResume.Enabled:=False;
    pmiSuspend.Enabled:=True;
  end;
end;

procedure TFormMain.pmiSuspendClick(Sender: TObject);
begin
  Stop;
  pmiSuspend.Enabled:=False;
  pmiResume.Enabled:=True;
end;

procedure TFormMain.TimerTimer(Sender: TObject);
  function GenErrMsg(const DT:TDateTime;Old,New,Bit:Integer;Ch:Byte;Hint:String):String;
  begin
    if (Old xor New) and Bit<>0 then begin
      Result:='#'+IntToStr(Ch);
      if New and Bit<>0
      then Result:=Result+' СБОЙ ('+Hint+')'
      else Result:=Result+' НОРМА ('+Hint+')';
      Result:=LogMsg(DT,Result);
    end
    else Result:='';
  end;
type
  TCharArray=packed array [0..15] of Char;
const
  fMaskError    =$008FFFFF;
  fErrorFlag    =$00800000;
  fErrorComm    =$00400000;
  fErrorADCRange=$00200000;
  fErrorInvData =$00100000;
  Coeff=1/256/32767;
  WDC:Integer=0;
  NoConnection:Boolean=False;
var
  FS:TFrameSensor;
  i,j,k,m,Cnt:Integer;
  Tmp:Cardinal;
  Adr:TAddress;
  CharBuf:TCharArray;
  Buf:TSclRec absolute CharBuf;
  ST:TSystemTime;
  Data:String;
  ToLog:String;
  DataScaleFactor:Double;
  PD:^TADCServiceInData;
  MaxTime,Time:TDateTime;
  AD:TAnalogData;
begin
  if Thd=nil then exit;
  // Вывод результатов опросов
  Thd.CS.Enter;
  stTxtTrafficIn.Caption:=Format('In: %.4d (%.3d)',[Thd.TrafficIn,Thd.PacketsIn]);
  Thd.TrafficIn:=0; Thd.PacketsIn:=0;
  stTxtTrafficOut.Caption:=Format('Out: %.4d (%.3d)',[Thd.TrafficOut,Thd.PacketsOut]);
  Thd.TrafficOut:=0; Thd.PacketsOut:=0;
  if Thd.sUserResp<>'' then begin
    AddEchoText(Thd.sUserResp);
    Thd.sUserResp:='';
  end;
  if Thd.sAutoResp<>'' then begin
    memoEcho.Text:=Thd.sAutoResp;
    Thd.sAutoResp:='';
  end;
  for i:=0 to Sensors.Count-1 do begin
    FS:=TFrameSensor(Sensors[i]);
    FS.TimerProc;
  end;
  Thd.CS.Leave;
  // Если в течении 15 секунд не было нормальной связи или поток опроса "повис",
  // то перезапускаем поток опроса контроллера
  if Thd.ClearWatchdog then begin
    WDC:=0; Thd.ClearWatchdog:=False;
    if NoConnection
    then ToLog:=LogMsg(Now,'НОРМА (Ответ контроллера)');
    NoConnection:=False;
  end
  else begin
    Inc(WDC,Timer.Interval);
    if WDC>15000 then begin
      if NoConnection=False
      then ToLog:=LogMsg(Now,'СБОЙ (Ответ контроллера)');
      NoConnection:=True;
      AddEchoText('Watchdog timeout. Restarting.'#13#10);
      Stop; Start; WDC:=0;
    end;
  end;
//  exit;
  MaxTime:=Now;
  for i:=0 to Sensors.Count-1 do begin
    FS:=TFrameSensor(Sensors[i]);
    Buf.Number:=FS.NetNumber;
    DataScaleFactor:=FS.CoeffK*Coeff;
    for j:=0 to FS.DataList.Count-1 do begin
      FS.CS.Acquire;
      Data:=FS.DataList[j];
      FS.CS.Release;
      PD:=@(Data[1]);
      Cnt:=(Length(Data)-SizeOf(PD.SensNum)-SizeOf(PD.Time)) div 3;
      for k:=0 to Cnt-1 do begin
        Time:=PD.Time*dtLLTickPeriod+k*Period;
        if Time>MaxTime then break;
        DateTimeToSystemTime(Time,ST);
        with Buf.Time do begin
          Year:=ST.wYear-1900;
          Month:=ST.wMonth;
          Day:=ST.wDay;
          Hour:=ST.wHour;
          Min:=ST.wMinute;
          Sec:=ST.wSecond;
          Sec100:=Trunc(ST.wMilliseconds*0.1);
        end;
        Tmp:=0;
        move(PD.Data[k],Tmp,3);
        if Tmp and fMaskError=fErrorFlag then begin // признак сбоя
          SetErrUnknown(AD);
          if not FS.isSensorOn then SetSensorRepair(AD);
          Buf.P:=AD.Value;
        end
        else begin
          if(Tmp and $00800000<>0) then Tmp:=Tmp or $FF000000;
          Buf.P:=Integer(Tmp)*DataScaleFactor+FS.CoeffB;
          Inc(FS.CntP);
          FS.P:=Buf.P;
        end;
        if (Tmp and fMaskError<>fErrorFlag) then Tmp:=0;
        ToLog:=ToLog+
          GenErrMsg(Time,FS.Tag,Tmp,fErrorFlag,i,'Показания датчика')+
          GenErrMsg(Time,FS.Tag,Tmp,fErrorComm,i,'Связь с АЦП')+
          GenErrMsg(Time,FS.Tag,Tmp,fErrorADCRange,i,'Диапазон АЦП')+
          GenErrMsg(Time,FS.Tag,Tmp,fErrorInvData,i,'Данные с АЦП');
        FS.Tag:=Tmp;
        // Рассылка
        for m:=0 to FS.AdrList.Count-1 do begin
          Adr:=TAddress(FS.AdrList[m]);
          NMUDP.RemoteHost:=Adr.Host;
          NMUDP.RemotePort:=Adr.Port;
          NMUDP.SendBuffer(CharBuf,SizeOf(CharBuf));
        end;
      end;
    end;
    FS.CS.Acquire;
    FS.DataList.Clear;
    FS.CS.Release;
  end;
  if ToLog<>'' then WriteToLog(ToLog);
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

function TFormMain.Get_FrameSensor(i: Integer): TFrameSensor;
begin
  Result:=TFrameSensor(Sensors[i]);
end;

procedure TFormMain.pmiReadOnlyClick(Sender: TObject);
var
  ReadOnly:Boolean;
begin
  ReadOnly:=not pmiReadOnly.Checked or
    (Application.MessageBox(
      'Вы хотите изменить настройки опроса датчиков?',
      'Подтверждение',
      MB_ICONQUESTION or MB_YESNO or MB_TOPMOST or MB_DEFBUTTON2
    )<>ID_YES);
  if ReadOnly<>pmiReadOnly.Checked then begin
    pmiReadOnly.Checked:=ReadOnly;
    SensorsReadOnly:=not ReadOnly;
  end;
end;

procedure TFormMain.Set_SensorsReadOnly(const Value: Boolean);
var
  i:Integer;
begin
  for i:=0 to Sensors.Count-1 do FrameSensor[i].Enabled:=Value;
end;

procedure TFormMain.AddEchoText(const S: String);
const
  Cnt:Integer=0;
begin
  if Cnt>32000 then begin
    Cnt:=0;
    memoEcho.Text:='';
  end
  else Inc(Cnt,Length(S));
  memoEcho.SelStart:=0; memoEcho.SelText:=S; memoEcho.SelLength:=0;
end;

procedure TFormMain.BtnClearClick(Sender: TObject);
begin
  memoEcho.Lines.Clear;
end;

{ TMainThread }

constructor TMainThread.Create;
begin
  inherited Create(True);
  Priority:=tpTimeCritical;
  CS:=TCriticalSection.Create;
  // служба синхронизации времени
  SvcHandlers[0].SvcID:=1;
  SvcHandlers[0].Handler:=handleTimeSyncService;
  // служба аналоговых датчиков
  SvcHandlers[1].SvcID:=2;
  SvcHandlers[1].Handler:=handleADCService;
  // служба обновления программы контроллера
  SvcHandlers[2].SvcID:=3;
  SvcHandlers[2].Handler:=handleProgService;
end;

destructor TMainThread.Destroy;
begin
  CloseHandle(hCom);
  CS.Free;
  inherited;
end;

procedure TMainThread.Execute;
type
  EnumError=(eeNoError,eeHdrTimeout,eeHdrCRCError,eeDataTimeout,eeDataCRCError,eePacketSeq);
var
  HdrI,HdrO:TPacketHeader;
  DataI,DataO:String;
  i,Len:Integer;
  dcb:TDCB;
  CTO:COMMTIMEOUTS;
  Error:EnumError;
  ModemStat:Cardinal;
  TimerWaitRLSD:Integer;
begin
  hCom := CreateFile(PChar(ComPort),
    GENERIC_READ or GENERIC_WRITE,
    0,    // comm devices must be opened w/exclusive-access
    nil, // no security attrs
    OPEN_EXISTING, // comm devices must use OPEN_EXISTING
    0,    // not overlapped I/O
    0  // hTemplate must be NULL for comm devices
  );
  FillChar(CTO,SizeOf(CTO),0);
  CTO.ReadIntervalTimeout:=300;
  CTO.ReadTotalTimeoutConstant:=2000;
  CTO.ReadTotalTimeoutMultiplier:=50;
  if (hCom = INVALID_HANDLE_VALUE) or
    not GetCommState(hCom,dcb) or
    not SetCommTimeouts(hCom,CTO)
  then begin
    ShowErrorMsg(GetLastError());
    exit;
  end;
  SetCommTimeouts(hCom,CTO);
  dcb.BaudRate:=ComSpeed;
  dcb.ByteSize:=8;
  dcb.StopBits:=ONESTOPBIT;
  dcb.Flags:=1; // fBinary=1
  dcb.Parity:=NOPARITY;
  SetCommState(hCom,dcb);
  EscapeCommFunction(hCom,SETDTR);
  EscapeCommFunction(hCom,SETRTS);
  HdrO.Addr:=1;
  HdrO.PacketID:=0;
  HdrO.ServiceID:=0;
  HdrO.DataSize:=0;
  HdrO.DataChecksum:=0;
  TimerWaitRLSD:=0;
  repeat
    if sDialCmd<>'' then begin
      GetCommModemStatus(hCom,ModemStat);
      if ModemStat and MS_RLSD_ON=0 then begin
        if TimerWaitRLSD=0 then begin
          sUserResp:='Dialing...'#13#10+sUserResp;
          putComStr(#13);
          sleep(1000);
          putComStr(sDialCmd+#13);
          TimerWaitRLSD:=DialMaxDuration;
        end;
        sleep(1000);
        Dec(TimerWaitRLSD);
        ClearWatchDog:=True;
        continue;
      end
      else TimerWaitRLSD:=0;
    end;
    if HdrO.DataSize>0
    then HdrO.DataChecksum:=CalcChecksum(DataO[1],HdrO.DataSize)
    else HdrO.DataChecksum:=0;
    HdrO.Checksum:=CalcChecksum(HdrO,SizeOf(HdrO)-2);
    putComBuf(HdrO,SizeOf(HdrO));
    if HdrO.DataSize>0 then putComBuf(DataO[1],HdrO.DataSize);
    CS.Enter; Inc(PacketsOut); CS.Leave;
    Error:=eeNoError;
    HdrI.Addr:=0;
    sDataDump:='';
    repeat
      if readBuf(HdrI.Addr,1)=0 then begin
        Error:=eeHdrTimeOut;
        break;
      end;
    until HdrI.Addr=1;
    if Error=eeNoError then begin
      Len:=readBuf(HdrI.PacketID,SizeOf(HdrI)-1);
      if (Len<>SizeOf(HdrI)-1)
        or (CalcChecksum(HdrI,SizeOf(HdrI)-2)<>HdrI.Checksum)
      then unreadBuf(HdrI.PacketID,Len)
      else begin
        CS.Enter; Inc(PacketsIn); CS.Leave;
        if HdrI.PacketID<>(HdrO.PacketID+1)and $FF
        then Error:=eePacketSeq;
        HdrO.PacketID:=(HdrI.PacketID+1) and $FF;
        SetLength(DataI,HdrI.DataSize);
        if HdrI.DataSize<>0
        then begin
          Len:=readBuf(DataI[1],HdrI.DataSize);
          if (Len<>HdrI.DataSize) or
            (CalcChecksum(DataI[1],HdrI.DataSize)<>HdrI.DataChecksum)
          then unreadBuf(DataI[1],Len)
          else begin
            if Error=eeNoError then begin
              DataO:='';
              HdrO.ServiceID:=0;
              for i:=0 to High(SvcHandlers) do begin
                if(HdrI.ServiceID=SvcHandlers[i].SvcID)then begin
                  if SvcHandlers[i].Handler(DataI,DataO)
                  then HdrO.ServiceID:=HdrI.ServiceID;
                  break;
                end;
              end;
              if HdrO.ServiceID=0 then begin
                for i:=0 to High(SvcHandlers) do begin
                  if SvcHandlers[i].Handler('',DataO) then begin
                    HdrO.ServiceID:=SvcHandlers[i].SvcID;
                    break;
                  end;
                end;
              end;
              HdrO.DataSize:=Length(DataO);
            end;
          end;
        end;
      end;
    end;
    if Error<>eeNoError then begin
      if not ShowDataDump then begin
        CS.Enter;
        case Error of
        eeHdrTimeout:sUserResp:='Error: Answer timeout'#13#10+sUserResp;
        eeHdrCRCError:sUserResp:='Error: Header CRC'#13#10+sUserResp;
        eeDataTimeout:sUserResp:='Error: Data timeout'#13#10+sUserResp;
        eeDataCRCError:sUserResp:='Error: Data CRC'#13#10+sUserResp;
        eePacketSeq:sUserResp:='Packets sequence resync'#13#10+sUserResp;
        end;
        CS.Leave;
      end;
      if Error=eePacketSeq then begin
        Sleep(1000);
        PurgeComm(hCom,PURGE_RXCLEAR);
      end;
    end
    else ClearWatchdog:=True;
    if ShowDataDump then begin
      CS.Enter;
      sUserResp:=sDataDump+#13#10+sUserResp;
      CS.Leave;
    end;
  until Terminated;
  EscapeCommFunction(hCom,CLRRTS);
  EscapeCommFunction(hCom,CLRDTR);
  PurgeComm(hCom,PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

function TMainThread.readBuf(var Buffer; Len:Integer):Cardinal;
var
  i,si,di,L:Integer;
  B:array[0..65535] of Byte absolute Buffer;
begin
  Result:=0;
  L:=Length(UBuf);
  if L>0 then begin
    if Len<L then i:=Len else i:=L;
    si:=L-1;
    for di:=0 to i-1 do begin
      B[di]:=UBuf[si]; Dec(si);
    end;
    SetLength(UBuf,L-i);
  end
  else i:=0;
  if i<Len then ReadFile(hCom,B[i],Len-i,Result,nil);
  Inc(Result,i);
  if ShowDataDump and (Result>0)
  then sDataDump:=sDataDump+getHexDump(Buffer,Result);
  CS.Enter; Inc(TrafficIn,Result); CS.Leave;
end;

function TMainThread.handleADCService(const InData: String;
  var OutData: String):Boolean;
type
  TInData=TADCServiceInData;
var
  ID:^TInData;
  FS:TFrameSensor;
begin
  Result:=FALSE;
  if InData='' then exit;
  ID:=@(InData[1]);
  FS:=FormMain.FrameSensor[ID.SensNum];
  FS.CS.Acquire;
  FS.DataList.Add(InData);
  FS.CS.Release;

//  then sDataDump:=getHexDump(InData[1],Length(InData))+#13#10+sUserResp
  if not ShowDataDump then begin
    CS.Acquire;
    sUserResp:=DateTimeToStr(ID.Time*dtLLTickPeriod)+
      Format(' %3dms AD#%d %d'#13#10,[
        ID.Time mod 1000,
        ID.SensNum,
        (Length(InData)-1-SizeOf(TIME_STAMP)) div 3
      ])+sUserResp;
    CS.Release;
  end;
(*
  else sUserResp:=Format('T = %2dH %2dM %2dS %2dhS  AD#%d %d'#13#10,
    [ID.Time div 360000,ID.Tim mod 360000 div 6000,
    ID.Tim mod 6000 div 100,ID.Tim mod 100,
    ID.SensNum,(Length(InData)-5) div 3])+sUserResp;
//*)
end;

function TMainThread.handleProgService(const InData: String;
  var OutData: String): Boolean;
type
  TInData=record
    Offset:Integer;
  end;
  TOutData=record
    Offset:Integer;
    Data:array[0..0] of Byte;
  end;
var
  ID:^TInData;
  OD:^TOutData;
  ImgFile:file;
  FSize,Size:Integer;
begin
  Result:=False;
  if (not Programming) then exit;
  Assign(ImgFile,'rom-disk.img');
  try
    Reset(ImgFile,1);
    CS.Enter;
    try
      FSize:=FileSize(ImgFile);
      if InData<>'' then begin
        ID:=@(InData[1]);
        ProgPos:=ID^.Offset;
        sUserResp:='PROG: '+IntToStr(ProgPos)+' of '+IntToStr(FSize)+#13#10+sUserResp;
      end;
      Size:=128;
      if ProgPos=FSize then begin
        sUserResp:='PROGRAMMING COMPLETED.'#13#10+sUserResp;
        Programming:=FALSE;
        Size:=0;
      end;
      if ProgPos+Size>FSize
      then Size:=FSize-ProgPos;
      SetLength(OutData,Size+4);
      OD:=@(OutData[1]);
      OD.Offset:=ProgPos;
      Seek(ImgFile,ProgPos);
      BlockRead(ImgFile,OD.Data,Size);
      Result:=TRUE;
    finally
      CS.Leave;
      CloseFile(ImgFile);
    end;
  except
    CS.Enter;
    sUserResp:='ERROR: Cannot open ROM-DISK.IMG'#13#10+sUserResp;
    CS.Leave;
    Programming:=FALSE;
  end;
end;

function TMainThread.handleTimeSyncService(const InData: String;
  var OutData: String):Boolean;
type
  TInData = packed record
    TimeQ,Filler:TIME_STAMP;
  end;
  TOutData = packed record
    TimeQ,TimeA:TIME_STAMP;
  end;
var
  ID:^TInData;
  OD:^TOutData;
begin
  Result:=FALSE;
  if InData='' then exit;
  SetLength(OutData,SizeOf(TOutData));
  ID:=@(InData[1]);
  OD:=@(OutData[1]);
  OD.TimeQ:=ID.TimeQ;
  OD.TimeA:=Round(Now*LLTicksProDay);
  CS.Acquire;
  sUserResp:='time sync'#13#10+sUserResp;
  CS.Release;
  Result:=TRUE;
end;

procedure TMainThread.putComBuf(const Buffer; Length: Integer);
var
  i:Cardinal;
begin
  WriteFile(hCom,Buffer,Length,i,nil);
  CS.Enter; Inc(TrafficOut,Length); CS.Leave;
end;

procedure TFormMain.WriteToLog(const S: String);
const
  LogFileName='ldr7188.log';
var
  Log:TextFile;
begin
  try
    AssignFile(Log,LogFileName);
    if not FileExists(LogFileName) then Rewrite(Log) else Append(Log);
    try
      Write(Log,S);
      Flush(Log);
    finally
      CloseFile(Log);
    end;
  except
  end;
end;

function TFormMain.LogMsg(const DT: TDateTime; const Msg: String):String;
begin
  Result:='['+DateTimeToStr(DT)+'] '+Msg+#13#10;
end;

procedure TFormMain.cbShowDataDumpClick(Sender: TObject);
begin
  if Thd<>nil then Thd.ShowDataDump:=cbShowDataDump.Checked;
end;

procedure TMainThread.putComStr(const S: String);
begin
  putComBuf(S[1],Length(S));
end;

procedure TFormMain.FormKeyPress(Sender: TObject; var Key: Char);
const
  Pos:Integer=1;
  Pwd:String='Programming!';
begin
  if Key=Pwd[Pos] then begin
    if Pos<Length(Pwd) then Inc(Pos)
    else begin
      Pos:=1;
      if Programming
      then AddEchoText('WARNING! Programing stopped!'#13#10)
      else AddEchoText('Programming started...'#13#10);
      if Thd<>nil then Thd.CS.Enter;
      ProgPos:=0;
      Programming:=not Programming;
      if Thd<>nil then Thd.CS.Leave;
    end;
  end
  else Pos:=1;
end;

procedure TMainThread.unreadBuf(var Buffer; Len: Integer);
var
  si,di,L:Integer;
  B:array[0..65535] of Byte absolute Buffer;
begin
  L:=Length(UBuf);
  SetLength(UBuf,L+Len);
  di:=L+Len-1;
  for si:=0 to Len-1 do begin
    UBuf[di]:=B[si]; Dec(di);
  end;
end;

end.

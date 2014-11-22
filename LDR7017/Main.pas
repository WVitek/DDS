unit Main;

interface

uses
  Windows, MMSystem, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IniFiles, Misc, SensorFrame, DdhAppX, Menus, SyncObjs, ConvTP, ExtCtrls,
  NMUDP, DataTypes, StdCtrls;

type
  TMainThread = class;

  TFormMain = class(TForm)
    AppExt: TDdhAppExt;
    PopupMenu: TPopupMenu;
    pmiClose: TMenuItem;
    pmiAbout: TMenuItem;
    N1: TMenuItem;
    pmiStop: TMenuItem;
    pmiStart: TMenuItem;
    NMUDP: TNMUDP;
    N2: TMenuItem;
    pmiShowHide: TMenuItem;
    pmiReadOnly: TMenuItem;
    PnlCmd: TPanel;
    memoEcho: TMemo;
    Panel1: TPanel;
    edCmd: TEdit;
    BtnSend: TButton;
    Label1: TLabel;
    pmiRestart: TMenuItem;
    cbUseCheckSum: TCheckBox;
    WatchdogTimer: TTimer;
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
    procedure pmiReadOnlyClick(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure pmiRestartClick(Sender: TObject);
    procedure cbUseCheckSumClick(Sender: TObject);
    procedure ThdTerminated(Sender: TObject);
    procedure WatchdogTimerTimer(Sender: TObject);
    procedure Start(Sender:TObject);
    procedure Stop(Sender:TObject);
  private
    Period,Rate,PeriodMSec:Double;
    Hz:Integer;
    NoDataCounter:Integer;
    ShowInfo:Boolean;
    { Private declarations }
    function Get_FrameSensor(i: Integer): TFrameSensor;
    procedure Set_SensorsReadOnly(const Value: Boolean);
    procedure NextTimeEventAfter(mSecs:Cardinal);
    procedure AddEchoText(const S:String);
    procedure SetCaption(S:TCaption);
    function ReadCaption:TCaption;
  public
    { Public declarations }
    Ini:TIniFile;
    Thd:TMainThread;
    Sensors:TList;
    uTimerID:UINT;
    OldCnt:Int64;
    NotFirst:Boolean;
    LogFileName:String;
    property FrameSensor[i:Integer]:TFrameSensor read Get_FrameSensor;
    property SensorsReadOnly:Boolean write Set_SensorsReadOnly;
  end;

  TMainThread=class(TThread)
    Sensors:TList;
    ComPort:String;
    ComSpeed:Integer;
    DelayBeforeCommandTX:Integer;
    DelayBeforeResultRX:Integer;
    CS:TCriticalSection;
    sCmd,sUserResp:String;
    Completed:Boolean;
    constructor Create;
    procedure Execute;override;
    destructor Destroy;override;
  private
    hCom:THandle;
    dcb:TDCB;
    function getComChar:Char;
    function Query(const Cmd:String):String;
    procedure putComString(const Buffer:String);
    procedure putComBuf(const Buffer; Length:Cardinal);
    procedure ShowUserResp;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.DFM}

const
  dtOneSecond=1/SecsPerDay;

var
  SleepIsPrecise:Boolean;

const
  Section='config';

procedure FNTimeCallBack(uTimerID,uMessage:UINT;dwUser,dw1,dw2:DWORD);stdcall;
var
  Self:TFormMain absolute dwUser;
begin
  Self.TimerTimer(Self);
end;

function CheckSumIsValid(const S:String):Boolean;
var
  SCS:String;
  L:Integer;
begin
  Result:=False; L:=Length(S);
  if L<3 then exit;
  SCS:=StrCheckSum(S[1],L-2);
  Result:=(SCS[1]=S[L-1]) and (SCS[2]=S[L]);
end;

function ascii_to_hex(c:Char):Byte;
begin
  if c<='9' then Result:=Ord(c)-Ord('0')
  else if c<='F' then Result:=10+Ord(c)-Ord('A')
  else Result:=10+Ord(c)-Ord('a');
end;

function FromHexStr(const Hex:String; Digits:Integer):Longword;
var
  i:Integer;
begin
  Result:=0;
  for i:=1 to Digits
  do Result:=(Result shl 4) or ascii_to_hex(Hex[i]);
end;

function MakeLangId(p,s:Word):Cardinal;
begin
  Result:=(s shl 10) or p;
end;

function GetErrorMsg(ErrorId:Cardinal):String;
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
  Result:=lpMsgBuf;
  // Free the buffer.
  FreeMem(lpMsgBuf,BufSize);
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  i,Count,W,H:Integer;
  SF:TFrameSensor;
  hSysMenu:Integer;
  IniFileName:String;
begin
  InitFormattingVariables;
  W:=0;
  H:=0;
  try
    if ParamCount=1
    then IniFileName:=ExpandFileName(ParamStr(1))
    else IniFileName:=Misc.GetModuleFullName+'.ini';
    addEchoText(IniFileName);
    Ini:=TIniFile.Create(IniFileName);
    LogFileName:=ChangeFileExt(IniFileName,'.log');
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
    ClientWidth:=W;
    if H>ClientHeight then ClientHeight:=H;
    pmiReadOnly.Enabled:=Ini.ReadInteger(Section,'ReadOnly',1)=0;
    SetCaption(ReadCaption);
    hSysMenu:=GetSystemMenu(Handle,False);
    EnableMenuItem(hSysMenu,SC_CLOSE,MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
    WriteToLog(LogFileName,LogMsg(Now,'ЗАПУСК Ldr7017'));
    if Ini.ReadInteger(Section,'AutoStart',0)<>0 then begin
      ShowWindow(Application.Handle,0);
      Start(Self);
    end
    else Visible:=True;
  except
    Application.MessageBox(
      'Исключительная ситуация при инициализации программы опроса датчиков',
      '',MB_ICONHAND or MB_OK
    );
    Application.Terminate;
  end;
  NextTimeEventAfter(100);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
var
  i:Integer;
  SF:TFrameSensor;
begin
  Stop(Self);
  timeKillEvent(uTimerID);
  if Sensors<>nil then begin
    for i:=0 to Sensors.Count-1 do begin
      SF:=TFrameSensor(Sensors[i]);
      SF.WriteToIni(Ini);
    end;
    Sensors.Free;
  end;
  WriteToLog(LogFileName,LogMsg(Now,'ОСТАНОВ Ldr7017'));
  Ini.Free;
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
    'Программа опроса модулей аналогового ввода'#13#13+
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
  for i:=0 to Sensors.Count-1 do begin
    if not FrameSensor[i].Validate then begin
      FormMain.Show; exit;
    end;
  end;
  if Thd<>nil then Stop(Self);
  Thd:=TMainThread.Create;
  Thd.ComPort:=Ini.ReadString(Section,'ComPort','COM1');
  Thd.ComSpeed:=Ini.ReadInteger(Section,'ComSpeed',9600);
  Thd.DelayBeforeCommandTX:=Ini.ReadInteger(Section,'DelayBeforeCommandTX',10);
  Thd.DelayBeforeResultRX:=Ini.ReadInteger(Section,'DelayBeforeResultRX',10);
  SleepIsPrecise:=Ini.ReadInteger(Section,'SleepIsPrecise',0)<>0;
  Thd.Sensors:=Sensors;
  Thd.OnTerminate:=ThdTerminated;
  Thd.Resume;
  Hz:=Ini.ReadInteger(Section,'Hz',1);
  Period:=dtOneSecond/Hz;
  Rate:=1/Period;
  PeriodMSec:=Period*MSecsPerDay;
  SetCaption(ReadCaption+' (частота '+IntToStr(Hz)+' Гц)');

  pmiStart.Visible:=False;
  pmiStop.Visible:=True;
  pmiRestart.Visible:=True;
end;

procedure TFormMain.Stop;
begin
  if (Sender<>Thd) and (Thd<>nil) then begin
    if not Thd.Completed then begin
      Thd.Terminate;
      Thd.WaitFor;
      TerminateThread(Thd.Handle,0);
    end;
    Thd.Free;
    Thd:=nil;
  end;
  pmiStart.Visible:=True;
  pmiStop.Visible:=False;
  pmiRestart.Visible:=False;
end;

procedure TFormMain.WatchdogTimerTimer(Sender: TObject);
begin
  // Если более 30-ти секунд нет данных с датчиков, то, возможно, произошел
  // сбой - перезапускаем поток опроса датчиков
  Inc(NoDataCounter);
  if NoDataCounter>=30 then begin
    Stop(Self); Start(Self); 
    NoDataCounter:=0;
//    WriteToLog(LogFileName,LogMsg(Now,'АВТОРЕСТАРТ потока опроса'));
  end;
  ShowInfo:=True; // раз в секунду обновляем экранную информацию
end;

procedure TFormMain.TimerTimer(Sender: TObject);
type
  TCharArray=packed array [0..15] of Char;
const
  FirstTime:Boolean=True;
var
  FS:TFrameSensor;
  i,j:Integer;
  Cnt:Int64;
  fCnt:Double;
  Adr:TAddress;
  CharBuf:TCharArray;
  Buf:TSclRec absolute CharBuf;
  NowTime:TDateTime;
  ST:TSystemTime;
begin
  NowTime:=Now;
  fCnt:=Frac(NowTime)*Rate;
  i:=Round((1-Frac(fCnt))*0.8*PeriodMSec);
  if i=0 then i:=1;
  NextTimeEventAfter(i);
  Cnt:=Trunc(fCnt);//Round
  if NotFirst=False then begin
    NotFirst:=True;
    OldCnt:=Cnt;
    exit;
  end
  else if OldCnt=Cnt then exit;
  OldCnt:=Cnt;
  DateTimeToSystemTime(Trunc(NowTime)+Cnt*Period,ST);
  with Buf.Time do begin
    Year:=ST.wYear-1900;
    Month:=ST.wMonth;
    Day:=ST.wDay;
    Hour:=ST.wHour;
    Min:=ST.wMinute;
    Sec:=ST.wSecond;
    Sec100:=Trunc(ST.wMilliseconds*0.1);
  end;
  for i:=0 to Sensors.Count-1 do begin
    FS:=TFrameSensor(Sensors[i]);
    if FS.MeasureCnt<>0 then NoDataCounter:=0;
    FS.TimerProc(fCnt/FS.Period);
    if ShowInfo then FS.ShowInfo;
  end;
  ShowInfo:=False;
  for i:=0 to Sensors.Count-1 do begin
    FS:=TFrameSensor(Sensors[i]);
    if not FS.ReadyForOutput then continue;
    Buf.Number:=FS.NetNumber;
    Buf.p:=FS.X;
    for j:=0 to FS.AdrList.Count-1 do begin
      Adr:=TAddress(FS.AdrList[j]);
      NMUDP.RemoteHost:=Adr.Host;
      NMUDP.RemotePort:=Adr.Port;
      NMUDP.SendBuffer(CharBuf,SizeOf(CharBuf));
    end;
    FS.ReadyForOutput:=False;
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
      'Вы действительно хотите изменить настройки?',
      'Подтверждение',
      MB_ICONQUESTION or MB_YESNO or MB_TOPMOST or MB_DEFBUTTON2
    )<>ID_YES);
  if ReadOnly<>pmiReadOnly.Checked then begin
    pmiReadOnly.Checked:=ReadOnly;
    SensorsReadOnly:=ReadOnly;
    WriteToLog(LogFileName,LogMsg(Now,'ReadOnly:='+IntToStr(Integer(ReadOnly))));
  end;
end;

procedure TFormMain.Set_SensorsReadOnly(const Value: Boolean);
var
  i:Integer;
begin
  for i:=0 to Sensors.Count-1 do FrameSensor[i].Enabled:=not Value;
  if Value then begin
    PnlCmd.Visible:=False;
    Width:=Width-PnlCmd.Width;
  end
  else begin
    Width:=Width+PnlCmd.Width;
    PnlCmd.Visible:=True;
  end;
end;

procedure TFormMain.NextTimeEventAfter(mSecs: Cardinal);
begin
  uTimerID:=timeSetEvent(mSecs,5,@FNTimeCallBack,Cardinal(Self),TIME_ONESHOT);
end;

procedure TFormMain.BtnSendClick(Sender: TObject);
var
  sCmd:String;
begin
  if Thd<>nil then begin
    Thd.CS.Acquire;
    sCmd:=Thd.sCmd;
    if sCmd='' then begin
      sCmd:=edCmd.Text;
      if cbUseCheckSum.Checked
      then sCmd:=sCmd+StrCheckSum(sCmd[1],Length(sCmd));
      Thd.sCmd:=sCmd;
      AddEchoText('< '+sCmd+#13#10);
    end;
    Thd.CS.Release;
  end;
end;

procedure TFormMain.AddEchoText(const S: String);
begin
  memoEcho.SelStart:=0; memoEcho.SelText:=S; memoEcho.SelLength:=0;
end;

procedure TFormMain.BtnClearClick(Sender: TObject);
begin
  memoEcho.Lines.Clear;
  edCmd.SetFocus;
end;

procedure TFormMain.pmiRestartClick(Sender: TObject);
begin
  if pmiStop.Visible then pmiStop.Click;
  if pmiStart.Visible then pmiStart.Click;
end;

procedure TFormMain.SetCaption(S: TCaption);
begin
  Caption:=S;
  Application.Title:=S;
  AppExt.TrayHint:=S;
end;

function TFormMain.ReadCaption: TCaption;
begin
  Result:=Ini.ReadString(Section,'AppTitle','Ldr7017');
end;

procedure TFormMain.cbUseCheckSumClick(Sender: TObject);
begin
  edCmd.SetFocus;
end;

procedure TFormMain.ThdTerminated(Sender: TObject);
begin
  Stop(Thd);
end;

{ TMainThread }

constructor TMainThread.Create;
begin
  inherited Create(True);
  Priority:=tpTimeCritical;
  CS:=TCriticalSection.Create;
end;

destructor TMainThread.Destroy;
begin
  CloseHandle(hCom);
  CS.Free;
  inherited;
end;

procedure TMainThread.Execute;
var
  i,err:Integer;
  iVal:Integer;
  SF:TFrameSensor;
  sTmp:String;
  Value:Double;
  CTO:COMMTIMEOUTS;
  NoSensorsOn:Boolean;
  ComError:Boolean;
begin
  hCom := CreateFile(PChar(ComPort),
    GENERIC_READ or GENERIC_WRITE,
    0, // comm devices must be opened w/exclusive-access
    nil, // no security attrs
    OPEN_EXISTING, // comm devices must use OPEN_EXISTING
    0, // not overlapped I/O
    0 // hTemplate must be NULL for comm devices
  );
  FillChar(CTO,SizeOf(CTO),0);
  CTO.ReadTotalTimeoutConstant:=100;
  ComError:=(hCom = INVALID_HANDLE_VALUE) or
    not GetCommState(hCom,dcb) or
    not SetCommTimeouts(hCom,CTO);
  if not ComError then begin
    dcb.BaudRate := ComSpeed;
    dcb.ByteSize := 8;
    dcb.StopBits := ONESTOPBIT;
    dcb.Flags := 0;
    dcb.Parity := NOPARITY;
  end;
  if ComError or not SetCommState(hCom,dcb)
  then begin
    sUserResp:=ComPort+' init error : '+GetErrorMsg(GetLastError());
    Synchronize(ShowUserResp);
    Completed:=True;
    exit;
  end;
//  EscapeCommFunction(hCom,SETDTR);
  i:=0;
  NoSensorsOn:=True;
  repeat
    CS.Acquire;
    if sCmd<>'' then begin
      sTmp:=sCmd;
      CS.Release;
      sTmp:=Query(sTmp);
      if sTmp<>'' then begin
        sUserResp:=sTmp+#13#10;
        Synchronize(ShowUserResp);
      end;
      CS.Acquire;
      sCmd:='';
    end;
    CS.Release;
    if i=0 then begin
      i:=Sensors.Count;
      if NoSensorsOn then Sleep(100);
      NoSensorsOn:=True;
    end;
    Dec(i);
    SF:=TFrameSensor(Sensors[i]);
    SF.CS.Acquire;
    if SF.isSensorOn then begin
      NoSensorsOn:=False;
      if SF.CounterPoll=0 then begin
        SF.CounterPoll:=SF.Period;
        sTmp:=SF.QueryCmd;
        SF.CS.Release;
        sTmp:=Query(sTmp);
//        sUserResp:=SF.QueryCmd+'->'+sTmp+#13#10;
//        Synchronize(ShowUserResp);
        SF.CS.Acquire;
        SF.IsErrADCComm:=False;
        SF.IsErrADCRange:=False;
        SF.IsErrAnalog:=False;
        Inc(SF.ShowQueryCnt);
        if CheckSumIsValid(sTmp) and (sTmp[1]='>') then begin
          Inc(SF.ShowResponseCnt);
          if Length(sTmp)=1+4+2 then begin // hexadeciaml format
            iVal:=SmallInt(FromHexStr(Copy(sTmp,2,4),4));
            Value:=iVal*(1/32768)*SF.PhysScale;
            if (iVal=-32768) or (iVal=32767) then err:=-1
            else err:=0;
          end
          else begin
            Val(Copy(sTmp,2,Length(sTmp)-3),Value,err);
            if err=0 then begin
              if (Value<=-SF.PhysScale) or (SF.PhysScale<=Value) then err:=-1;
            end;
          end;
          if err<=0 then begin
            SF.IsErrADCRange:=err=-1;
            Inc(SF.ShowMeasureCnt);
            SF.ShowSumX:=SF.ShowSumX+Value;
          end;
          if err=0 then begin
            Value:=Value*SF.CoeffK+SF.CoeffB;
            if Value<SF.Xm then SF.IsErrAnalog:=True
            else begin
              Inc(SF.MeasureCnt);
              SF.SumX:=SF.SumX+Value;
            end;
          end;
        end
        else if sTmp='' then SF.IsErrADCComm:=True;
      end; // end if CounterPoll=0
      Dec(SF.CounterPoll);
    end;
    SF.CS.Release;
  until Terminated;
//  EscapeCommFunction(hCom,CLRDTR);
  Completed:=True;
end;

function TMainThread.getComChar: Char;
var
  i:Cardinal;
begin
//  EscapeCommFunction(hCom,SETRTS);
  Result:=#0;
  ReadFile(hCom,Result,1,i,nil);
end;

procedure TMainThread.putComBuf(const Buffer; Length: Cardinal);
var
  i:Cardinal;
begin
//  EscapeCommFunction(hCom,CLRRTS);
  WriteFile(hCom,Buffer,Length,i,nil);
end;

procedure TMainThread.putComString(const Buffer: String);
begin
  if Buffer<>'' then putComBuf(Buffer[1],Length(Buffer));
end;

function TMainThread.Query(const Cmd: String): String;
var
  c:Char;
begin
  Result:='';
  Sleep(DelayBeforeCommandTX);
  PurgeComm(hCom,PURGE_TXCLEAR or PURGE_TXABORT);
  putComString(Cmd+#13);
  PurgeComm(hCom,PURGE_RXCLEAR or PURGE_RXABORT);
  Sleep(DelayBeforeResultRX);
  repeat
    c:=getComChar;
    if (c=#13) or (c=#0) or (c=#255) then break
    else Result:=Result+c;
  until False;
end;

procedure TMainThread.ShowUserResp;
begin
  // Вывод результатов опросов
  FormMain.AddEchoText(sUserResp);
  sUserResp:='';
end;

end.

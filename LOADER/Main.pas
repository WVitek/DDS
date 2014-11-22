unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IniFiles, Misc, SensorFrame, DdhAppX, Menus, SyncObjs, ConvTP, ExtCtrls,
  NMUDP, DataTypes;

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
    Timer: TTimer;
    NMUDP: TNMUDP;
    N2: TMenuItem;
    pmiShowHide: TMenuItem;
    pmiReadOnly: TMenuItem;
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
  private
    { Private declarations }
    procedure Start;
    procedure Stop;
    function Get_FrameSensor(i: Integer): TFrameSensor;
    procedure Set_SensorsReadOnly(const Value: Boolean);
  public
    { Public declarations }
    Ini:TIniFile;
    Thd:TMainThread;
    Sensors:TList;
    OldST:TSystemTime;
    TARDir:String;
    property FrameSensor[i:Integer]:TFrameSensor read Get_FrameSensor;
    property SensorsReadOnly:Boolean write Set_SensorsReadOnly;
  end;

  TMainThread=class(TThread)
    Sensors:TList;
    ComPort:String;
    ComSpeed:Integer;
    DelayAfterCharTX:Integer;
    DelayBeforeTXRXSwitch:Integer;
    MeasurementTime:Integer;
    DelayBeforeResultRX:Integer;
    TXParity:Integer;
    RXParity:Integer;
    NoDataCounter:Integer;
    CS:TCriticalSection;
    constructor Create;
    procedure Execute;override;
    destructor Destroy;override;
  private
    hCom:THandle;
    dcb:TDCB;
    function getchar:Char;
    procedure putstring(const s:array of char);
    procedure SwitchToRX;
    procedure SwitchToTX;
  end;

var
  FormMain: TFormMain;

procedure ShowErrorMsg(ErrorId:Cardinal);

implementation

{$R *.DFM}

var
  SleepIsPrecise:Boolean;

const
  Section='config';

procedure PreciseDelay(MSec:Integer);
var
  Freq,Cnt,StopCnt:Int64;
begin
  if SleepIsPrecise then begin
    Sleep(MSec);
    exit;
  end;
  QueryPerformanceCounter(Cnt);
  QueryPerformanceFrequency(Freq);
  StopCnt:=Cnt+Round(MSec*0.001*Freq);
  repeat
    QueryPerformanceCounter(Cnt);
    if Cnt>=StopCnt then break;
    Application.ProcessMessages;
  until False;
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
      SF.Top:=(i-1)*SF.Height;
      SF.Left:=0;
      SF.Parent:=Self;
      W:=SF.Width;
      H:=SF.Height;
    end;
    ClientWidth:=W;
    ClientHeight:=Count*H;
    pmiReadOnly.Enabled:=Ini.ReadInteger(Section,'ReadOnly',1)=0;
    Caption:=Ini.ReadString(Section,'AppTitle','Loader');
    Application.Title:=Caption;
    AppExt.TrayHint:=Ini.ReadString(Section,'TrayHint','Loader');
    TARDir:=Ini.ReadString(Section,'TARDir','');
    hSysMenu:=GetSystemMenu(Handle,False);
    EnableMenuItem(hSysMenu,SC_CLOSE,MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
    if Ini.ReadInteger(Section,'AutoStart',0)<>0 then begin
      pmiResume.Click;
      ShowWindow(Application.Handle,0);
    end
    else Visible:=True;
  except
    Application.MessageBox(
      'Исключительная ситуация при инициализации программы опроса датчиков',
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
    'Программа опроса датчиков давления'#13#13+
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
      FormMain.Show;
      exit;
    end;
  end;
  Thd:=TMainThread.Create;
  Thd.ComPort:=Ini.ReadString(Section,'ComPort','COM1');
  Thd.ComSpeed:=Ini.ReadInteger(Section,'ComSpeed',9600);
  Thd.DelayAfterCharTX:=Ini.ReadInteger(Section,'DelayAfterCharTX',0);
  Thd.DelayBeforeTXRXSwitch:=Ini.ReadInteger(Section,'DelayBeforeTXRXSwitch',3);
  Thd.MeasurementTime:=Ini.ReadInteger(Section,'MeasurementTime',250);
  Thd.DelayBeforeResultRX:=Ini.ReadInteger(Section,'DelayBeforeResultRX',10);
  Thd.TXParity:=Ini.ReadInteger(Section,'TXParity',3);
  Thd.RXParity:=Ini.ReadInteger(Section,'RXParity',4);
  SleepIsPrecise:=Ini.ReadInteger(Section,'SleepIsPrecise',0)<>0;
  Thd.Sensors:=Sensors;
  Thd.Resume;
end;

procedure TFormMain.Stop;
begin
  if Thd<>nil then begin
    TerminateThread(Thd.Handle,0);
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
type
  TCharArray=packed array [0..15] of Char;
const
  FirstTime:Boolean=True;
var
  FS:TFrameSensor;
  i,j:Integer;
  Adr:TAddress;
  CharBuf:TCharArray;
  Buf:TSclRec absolute CharBuf;
  ST:TSystemTime;
begin
  GetLocalTime(ST);
  if (OldST.wSecond=ST.wSecond) or FirstTime then begin
    FirstTime:=False; OldST:=ST;
    exit;
  end;
  with Buf.Time do begin
    Year:=OldST.wYear-1900;
    Month:=OldST.wMonth;
    Day:=OldST.wDay;
    Hour:=OldST.wHour;
    Min:=OldST.wMinute;
    Sec:=OldST.wSecond;
    Sec100:=0;
  end;
  OldST:=ST;
  if Thd=nil then exit;
  Thd.CS.Acquire;
  Inc(Thd.NoDataCounter);
  for i:=0 to Sensors.Count-1 do begin
    FS:=TFrameSensor(Sensors[i]);
    if FS.MeasureCnt>0 then Thd.NoDataCounter:=0;
    FS.TimerProc;
  end;
  Thd.CS.Release;
  // Если более 30-ти секунд нет данных с датчиков, то, возможно, произошел
  // сбой и необходимо перезапустить поток опроса датчиков
  if Thd.NoDataCounter>=30 then begin
    Stop;
    Start;
  end;
  for i:=0 to Sensors.Count-1 do begin
    FS:=TFrameSensor(Sensors[i]);
    if FS.ValidTP then begin
      Buf.Number:=FS.NetNumber;
      Buf.p:=FS.p;
      for j:=0 to FS.AdrList.Count-1 do begin
        Adr:=TAddress(FS.AdrList[j]);
        NMUDP.RemoteHost:=Adr.Host;
        NMUDP.RemotePort:=Adr.Port;
        NMUDP.SendBuffer(CharBuf,SizeOf(CharBuf));
      end;
    end;
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
const
  MReq:array[0..3] of char=('<','M',#255,'>');
  RReq:array[0..3] of char=('<','R',#0,'>');
var
  i:Integer;
  SF:TFrameSensor;
  c1,c2:Char;
  T,P:Word;
  RealT,RealP:Double;
  PerfFreq,PerfStart,PerfEnd:Int64;
  PerfTickMS:Double;
  MT:Integer;
  First,Fail:Boolean;
  CTO:COMMTIMEOUTS;

  procedure MQueryAll;
  var
    i:Integer;
  begin
    //***** Инициализация: начальная команда на измерение
    SwitchToTX;
    putstring(MReq); // Общий запрос
    QueryPerformanceCounter(PerfStart);
{   First:=True;
    for i:=0 to Sensors.Count-1 do begin
      SF:=TFrameSensor(Sensors[i]);
      if not SF.cbOn.Checked then continue;
      MReq[2]:=Char(SF.BusNumber);
      putstring(MReq);
      if First then begin
        QueryPerformanceCounter(PerfStart);
        First:=False;
      end;
    end;
//}
    SwitchToRX;
  end;

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
  CTO.ReadTotalTimeoutConstant:=10;
  if (hCom = INVALID_HANDLE_VALUE) or
    not GetCommState(hCom,dcb) or
    not SetCommTimeouts(hCom,CTO)
  then begin
    ShowErrorMsg(GetLastError());
    exit;
  end;
  SetCommTimeouts(hCom,CTO);
  dcb.BaudRate := 9600;
  dcb.ByteSize := 8;
  dcb.StopBits := ONESTOPBIT;
  QueryPerformanceFrequency(PerfFreq);
  PerfTickMS:=1000/PerfFreq;
  repeat
    MQueryAll;
    // Даем датчикам время на измерение
    QueryPerformanceCounter(PerfEnd);
    MT:=Round(PerfTickMS*(PerfEnd-PerfStart));
    if MT<MeasurementTime
    then sleep(MeasurementTime-MT);
    //***** Цикл опроса датчиков
    First:=True;
    for i:=0 to Sensors.Count-1 do begin
      SF:=TFrameSensor(Sensors[i]);
      if not SF.cbOn.Checked then continue;
      //***** Получить результат предыдущего измерения
      Fail:=True;
      try
//        SwitchToTX;
//        SwitchToRX;
        if not First then begin
          sleep(1);
        end;
        First:=False;
        // Запрос на выдачу результата измерения
        SwitchToTX;
        RReq[2]:=Char(SF.BusNumber);
        putstring(RReq);
        //*** Подготовка к приему результата
        SwitchToRX;
        // Очистка буфера
        PurgeComm(hCom,PURGE_RXCLEAR or PURGE_RXABORT);
        // Задержка перед выдачей датчиком результата
        sleep(DelayBeforeResultRX);
        //*** Принимаем результат
        // Символ начала "<"
        if (getchar='<') then begin
          // Давление
          c1:=getchar; c2:=getchar; P:=ord(c1) shl 8+ord(c2);
          // Температура
          c1:=getchar; c2:=getchar; T:=ord(c1) shl 8+ord(c2);
          // Номер датчика
          if ord(getchar)=SF.BusNumber then begin
            // Символ конца ">"
            if (getchar='>') then begin
              // Расчет значения давления
              try
                func(T,P,realT,realP,SF.tt,SF.pp,SF.xx,SF.yy);
                // Запись в накопитель
                CS.Acquire;
                SF.SumPressure:=SF.SumPressure+realP;
                SF.SumTemperature:=SF.SumTemperature+realT;
                Inc(SF.QueryCnt);
                Inc(SF.MeasureCnt);
                CS.Release;
                Fail:=False;
              except
              end;
            end;
          end;
        end;
      finally
        if Fail then begin
          CS.Acquire;
          Inc(SF.QueryCnt);
          CS.Release;
        end;
      end;
{     //***** Отдать команду на новое измерение
      SwitchToTX;
      MReq[2]:=Char(SF.BusNumber);
      putstring(MReq);
      if First then begin
        QueryPerformanceCounter(PerfStart);
        First:=False;
      end;
//}
    end;
  until Terminated;
end;

function TMainThread.getchar: Char;
var
  i:Cardinal;
begin
  Result:=#0;
  ReadFile(hCom,Result,1,i,nil);
end;

procedure TMainThread.putstring(const s: array of char);
var
  i:Integer;
begin
  for i:=0 to High(s) do begin
    TransmitCommChar(hCom,S[i]);
    PreciseDelay(DelayAfterCharTX);
  end;
end;

procedure TMainThread.SwitchToRX;
begin
  sleep(DelayBeforeTXRXSwitch);
  dcb.Parity := RXParity;
  SetCommState(hCom, dcb);
  EscapeCommFunction(hCom,SETDTR);
  EscapeCommFunction(hCom,SETRTS);
end;

procedure TMainThread.SwitchToTX;
begin
  dcb.Parity := TXParity;
  SetCommState(hCom, dcb);
  EscapeCommFunction(hCom,CLRDTR);
  EscapeCommFunction(hCom,CLRRTS);
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

end.

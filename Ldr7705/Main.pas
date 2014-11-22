unit Main;

interface

uses
  Windows, MMSystem, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IniFiles, Misc, DdhAppX, Menus, SyncObjs, ExtCtrls, NMUDP, DataTypes, StdCtrls,
  UModem, CommInt, UFrameSensor;

type
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
    pmiRestart: TMenuItem;
    Timer: TTimer;
    COM: TModem;
    FrameSensor1: TFrameSensor;
    FrameSensor2: TFrameSensor;
    Label1: TLabel;
    cbGain: TComboBox;
    Label2: TLabel;
    cbClock: TComboBox;
    Label3: TLabel;
    cbUpdateRate: TComboBox;
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
    procedure pmiRestartClick(Sender: TObject);
    procedure WatchdogTimerTimer(Sender: TObject);
    procedure Start(Sender:TObject);
    procedure Stop(Sender:TObject);
    procedure ADCSampleReady(Sender: TObject);
    procedure cbConfigChange(Sender: TObject);
  private
    Period,Rate,PeriodMSec:Double;
    Hz:Integer;
    ResponseOk:Boolean;
    { Private declarations }
    function Get_FrameSensor(i: Integer): TFrameSensor;
    procedure NextTimeEventAfter(mSecs:Cardinal);
    procedure SetCaption(S:TCaption);
    function ReadCaption:TCaption;
    function ReadByte: Byte;
    procedure WriteByte(B: Byte);
    procedure ConfigureAD7705;
  public
    { Public declarations }
    Ini:TIniFile;
    Sensors:TList;
    uTimerID:UINT;
    OldCnt:Int64;
    NotFirst:Boolean;
    CurGainNdx:Integer;
    CurAIN:Byte;
    property FrameSensor[i:Integer]:TFrameSensor read Get_FrameSensor;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.DFM}

const
  //********* AD7705 constants
  //***** COmmunication register
  ADCO_0_NDRDY = $80; // Write = 0, Read = not DRDY
  // Register Select (to communicate with)
  ADCO_RS_MASK = $70;
  ADCO_R_COMM  = $00; // 000 Communications Register 8 Bits
  ADCO_R_SETUP = $10; // 001 Setup Register 8 Bits
  ADCO_R_CLOCK = $20; // 010 Clock Register 8 Bits
  ADCO_R_DATA  = $30; // 011 Data Register 16 Bits
  ADCO_R_TEST  = $40; // 100 Test Register 8 Bits
  ADCO_R_NOP   = $50; // 101 No Operation
  ADCO_R_OFFS  = $60; // 110 Offset Register 24 Bits
  ADCO_R_GAIN  = $70; // 111 Gain Register 24 Bits
  //
  ADCO_RNW     = $08; // Read operation
  ADCO_STBY    = $04; // Standby mode
  // Channel selection
  ADCO_CH_MASK = $03;
  ADCO_CH_AIN1 = $00; // Differential input AIN1+, AIN1-
  ADCO_CH_AIN2 = $01; // Differential input AIN2+, AIN2-
  //***** SEtup register
  // Operating Mode
  ADSE_MD_NORM = $00; // 00 NORmal Mode
  ADSE_MD_SLFC = $40; // 01 SeLF-Calibration
  ADSE_MD_ZSSC = $80; // 10 Zero-Scale System Calibration
  ADSE_MD_FSSC = $C0; // 11 Full-Scale System Calibration
  // Gain Selection
  ADSE_GAINSHIFT=3;
  ADSE_GAIN001 = $00; // 000
  ADSE_GAIN002 = $08; // 001
  ADSE_GAIN004 = $10; // 010
  ADSE_GAIN008 = $18; // 011
  ADSE_GAIN016 = $20; // 100
  ADSE_GAIN032 = $28; // 101
  ADSE_GAIN064 = $30; // 110
  ADSE_GAIN128 = $38; // 111
  //
  ADSE_NBU     = $04; // Not Bipolar / Unipolar mode
  ADSE_BUF     = $02; // Buffered ADC mode (for high impedance sources)
  // Filter synchronization
  ADSE_FSYNC   = $01;
  //***** CLock register
  ADCL_CLKDIS  = $10; // Disable MCLK OUT pin
  // Clock
  ADCL_CLK_MASK= $0C;
  ADCL_CLK_SHIFT=2;
  ADCL_CLKDIV  = $08; // Clock divider enable (clock = MCLK IN/2)
  ADCL_CLK     = $04; // 1, if clock=2.4576; 0, if clock=1.000
  // Filter selection bits
  ADCL_FS_MASK = $03;
  ADCL_FS_SHIFT=0;

const
  dtOneSecond=1/SecsPerDay;

const
  Section='config';
  AD7705Setup = ADSE_NBU or ADSE_BUF;

procedure FNTimeCallBack(uTimerID,uMessage:UINT;dwUser,dw1,dw2:DWORD);stdcall;
var
  Self:TFormMain absolute dwUser;
begin
  Self.TimerTimer(Self);
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  i,Count:Integer;
  SF:TFrameSensor;
  hSysMenu:Integer;
  IniFileName:String;
begin
  InitFormattingVariables;
  try
    if ParamCount=1
    then IniFileName:=ExpandFileName(ParamStr(1))
    else IniFileName:=Misc.GetModuleFullName+'.ini';
    Ini:=TIniFile.Create(IniFileName);
    Sensors:=TList.Create;
    Count:=2;
    for i:=1 to Count do begin
      if i=1 then SF:=FrameSensor1
      else SF:=FrameSensor2;
      SF.LoadFromIniSection(Ini,'Sensor'+IntToStr(i));
      Sensors.Add(SF);
    end;
    cbGain.ItemIndex:=Ini.ReadInteger(Section,'GainNdx',0);
    cbClock.ItemIndex:=Ini.ReadInteger(Section,'ClockNdx',2);
    cbUpdateRate.ItemIndex:=Ini.ReadInteger(Section,'UpdateNdx',0);
    SetCaption(ReadCaption);
    hSysMenu:=GetSystemMenu(Handle,False);
    EnableMenuItem(hSysMenu,SC_CLOSE,MF_BYCOMMAND or MF_DISABLED or MF_GRAYED);
    if Ini.ReadInteger(Section,'AutoStart',0)<>0 then begin
      ShowWindow(Application.Handle,0);
      Start(Self);
    end
    else Visible:=True;
  except
    Application.MessageBox(
      'Исключительная ситуация при инициализации Ldr7705',
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
  Ini.WriteInteger(Section,'GainNdx',cbGain.ItemIndex);
  Ini.WriteInteger(Section,'ClockNdx',cbClock.ItemIndex);
  Ini.WriteInteger(Section,'UpdateNdx',cbUpdateRate.ItemIndex);
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
    'Программа опроса АЦП AD7705'#13#13+
    '(c) 2005 ООО "Компания Телекомнур"'#13+
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
begin
  try
    COM.DeviceName:=Ini.ReadString(Section,'ComPort','COM1');
    COM.Open;
    COM.SetDTRState(False); // CLK high
    COM.SetRTSState(False); // DataIN high
    Hz:=Ini.ReadInteger(Section,'Hz',1);
    Period:=dtOneSecond/Hz;
    Rate:=1/Period;
    PeriodMSec:=Period*MSecsPerDay;
    SetCaption(ReadCaption+' (выдача: '+IntToStr(Hz)+' Гц)');
    ConfigureAD7705;
  except
    on E:Exception
    do Application.MessageBox(PChar(E.Message),'Ldr7705::Start',MB_ICONHAND or MB_OK)
  end;
  pmiStart.Visible:=False;
  pmiStop.Visible:=True;
  pmiRestart.Visible:=True;
end;

procedure TFormMain.Stop;
begin
  if COM.Enabled then COM.Close;
  pmiStart.Visible:=True;
  pmiStop.Visible:=False;
  pmiRestart.Visible:=False;
end;

procedure TFormMain.WatchdogTimerTimer(Sender: TObject);
var
  i:Integer;
begin
  ConfigureAD7705;
  for i:=0 to Sensors.Count-1 do FrameSensor[i].TimerProc;
end;

procedure TFormMain.TimerTimer(Sender: TObject);
type
  TCharArray=packed array [0..15] of Char;
const
  FirstTime:Boolean=True;
var
  FS:TFrameSensor;
  i:Integer;
  Cnt:Int64;
  fCnt:Double;
  CharBuf:TCharArray;
  Buf:TSclRec absolute CharBuf;
  NowTime:TDateTime;
  ST:TSystemTime;
begin
  if not COM.Enabled then exit;
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
  for i:=0 to Sensors.Count-1
  do TFrameSensor(Sensors[i]).LatchData;
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
    FS:=FrameSensor[i];
    Buf.Number:=FS.NetNumber;
    Buf.p:=FS.GetLatchedY.Value;
    try
      NMUDP.RemoteHost:=FS.Host;
      NMUDP.RemotePort:=FS.Port;
      NMUDP.SendBuffer(CharBuf,SizeOf(CharBuf));
    except
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

function TFormMain.Get_FrameSensor(i: Integer): TFrameSensor;
begin
  Result:=TFrameSensor(Sensors[i]);
end;

procedure TFormMain.NextTimeEventAfter(mSecs: Cardinal);
begin
  uTimerID:=timeSetEvent(mSecs,5,@FNTimeCallBack,Cardinal(Self),TIME_ONESHOT);
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
  Result:=Ini.ReadString(Section,'AppTitle','Ldr7705');
end;

function TFormMain.ReadByte: Byte;
var
  i:Integer;
begin
  // emulate SPI read byte (DTR->CLK, CTS<-DOUT, MSB first)
  Result:=0;
  for i:=7 downto 0 do begin
    Result:=Result shl 1;
    COM.SetDTRState(True); // CLK low
    if not COM.CTS // Read inverted DOUT
    then Result:=Result or 1;
    COM.SetDTRState(False); // CLK high
  end;
end;

procedure TFormMain.WriteByte(B: Byte);
var
  i:Integer;
begin
  // emulate SPI write byte (DTR->CLK, RTS->DIN, MSB first)
  for i:=7 downto 0 do begin
    COM.SetDTRState(True); // CLK low
    COM.SetRTSState(B and $80=0); // Set inverted DIN
    COM.SetDTRState(False); // CLK high
    B:=B shl 1;
  end;
end;

procedure TFormMain.ConfigureAD7705;
var
  B:Byte;
  TryNum:Integer;
  ADClock:Byte;
  Gain:Byte;
  ConfigureSR:Boolean;
begin
  if not COM.Enabled then exit;
  ADClock:=
    cbClock.ItemIndex shl ADCL_CLK_SHIFT or
    cbUpdateRate.ItemIndex shl ADCL_FS_SHIFT;
  // Try( check & configure clock register, if needed)
  TryNum:=1;
  ConfigureSR:=False;
  while True do begin
    WriteByte(ADCO_R_CLOCK or ADCO_RNW or CurAIN);
    B:=ReadByte;
    if B=ADClock then break;
    ConfigureSR:=True;
    if TryNum=3 then begin
      // AD7705 not responding
      ResponseOk:=False;
      exit;
    end
    else begin
      if TryNum=2 then begin
        // reset AD7705's serial interface
        for B:=1 to 8 do WriteByte($FF);
        sleep(1);
      end;
      WriteByte(ADCO_R_CLOCK or CurAIN);
      WriteByte(ADClock);
    end;
    Inc(TryNum);
  end;
  // Check & configure Setup Register
  Gain:=cbGain.ItemIndex shl ADSE_GAINSHIFT;
  WriteByte(ADCO_R_SETUP or ADCO_RNW or CurAIN);
  B:=ReadByte;
  if ConfigureSR or (B<>AD7705Setup or Gain) then begin
    // selfcalibrate another channel
    WriteByte(ADCO_R_SETUP or (CurAIN xor 1));
    WriteByte(AD7705Setup or ADSE_MD_SLFC or Gain);
    sleep(100);
    // selfcalibrate current channel
    WriteByte(ADCO_R_SETUP or CurAIN);
    WriteByte(AD7705Setup or ADSE_MD_SLFC or Gain{ or ADSE_FSYNC}); //+ stop & reset ADC
    sleep(100);
    // start ADC
{    WriteByte(ADCO_R_SETUP or CurAIN);
    WriteByte(AD7705Setup or Gain);}
  end;
  CurGainNdx:=cbGain.ItemIndex;
  ResponseOk:=True;
end;

procedure TFormMain.ADCSampleReady(Sender: TObject);
var
  Sample:Integer;
  Quality:TQuality;
  Coeff:Double;
  Gain:Byte;
begin
  if not ResponseOk then exit;
  WriteByte(ADCO_R_DATA or ADCO_RNW or CurAIN);
  Sample := Integer(ReadByte) shl 8 or ReadByte;
  if Sample=65535 then Quality:=qOutOfRange
  else Quality:=qOk;
  Coeff:=1/(65535*(1 shl CurGainNdx));
  FrameSensor[CurAIN].addSample(Sample*Coeff,Quality);
  // select another ADC channel
  if FrameSensor[CurAIN xor 1].isSensorOn then begin
    CurAIN:=CurAIN xor 1;
    Gain:=cbGain.ItemIndex shl ADSE_GAINSHIFT;
//    WriteByte(ADCO_R_SETUP or CurAIN);
//    WriteByte(AD7705Setup or Gain or ADSE_FSYNC); //+ stop & reset ADC
    WriteByte(ADCO_R_SETUP or CurAIN);
    WriteByte(AD7705Setup or Gain); // start ADC
  end;
end;

procedure TFormMain.cbConfigChange(Sender: TObject);
begin
  ConfigureAD7705;
end;

end.

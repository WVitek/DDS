unit UModem;

interface

uses
  Classes,CommInt,SysUtils;

type
  TModemState = (msNotOpen,msNotReady,
    msOffline,msConnection,msOnline,msDisconnection);

  TCustomModem = class (TCustomComm)
  protected
    function GetResponseInLine: String;
    procedure SetState(NewState:TModemState);
  protected
    FState:TModemState;
    FOnConnFailed:TNotifyEvent;
    FOnConnect:TNotifyEvent;
    FOnDisconnect:TNotifyEvent;
    FOnModemRxChar:TCommRxCharEvent;
    FOnModemTxEmpty:TNotifyEvent;
    FOnResponse:TNotifyEvent;
    FResponseCode:Integer;
    FResponse:String;
    LastLine:String;
  protected
    procedure ProcessResponse;
    procedure OnCommStateChange(Sender:TObject);
    procedure OnCommRxChar(Sender: TObject; Count: Integer);
    procedure OnCommTxEmpty(Sender: TObject);
    property OnConnFailed:TNotifyEvent read FOnConnFailed write FOnConnFailed;
    property OnConnect:TNotifyEvent read FOnConnect write FOnConnect;
    property OnDisconnect:TNotifyEvent read FOnDisconnect write FOnDisconnect;
    property OnModemRxChar:TCommRxCharEvent read FOnModemRxChar write FOnModemRxChar;
    property OnModemTxEmpty:TNotifyEvent read FOnModemTxEmpty write FOnModemTxEmpty;
    property OnResponse:TNotifyEvent read FOnResponse write FOnResponse;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Open; reintroduce;
    procedure Close; reintroduce;
    procedure Connect(ConnectCmd:String);
    procedure DoCmd(Cmd:String);
    procedure Disconnect(ReinitCmd:String = '');
    property State:TModemState read FState;
    property Response:String read FResponse;
    property ResponseInLine:String read GetResponseInLine;
    property ResponseCode:Integer read FResponseCode; 
  end;

  TModem = class(TCustomModem)
  published
    // TCustomComm
    property DeviceName;
    property ReadTimeout;
    property WriteTimeout;
    property ReadBufSize;
    property WriteBufSize;
    property MonitorEvents;
    property BaudRate;
    property Parity;
    property Stopbits;
    property Databits;
    property EventChars;
    property Options;
    property FlowControl;
    property OnBreak;
    property OnCts;
    property OnRing;
    property OnError;
    property OnRxFlag;
    // TCustomModem
    property OnConnFailed;
    property OnConnect;
    property OnDisconnect;
    property OnModemRxChar;
    property OnModemTxEmpty;
    property OnResponse;
  end;


const
  mrcUnknown    = -1;
  mrcOk         = 0;
  mrcConnect    = 1;
  mrcRing       = 2;
  mrcNoCarrier  = 3;
  mrcError      = 4;
  mrcNoDialtone = 6;
  mrcBusy       = 7;
  mrcNoAnswer   = 8;
  mrcDtrDropped = 9;
  mrcDsrDropped = 10;
  mrcClosed     = 11;
  ModemResponses:array[-1..11] of String=(
    '???',          // -1
    'OK',           // 0
    'CONNECT',      // 1
    'RING',         // 2
    'NO CARRIER',   // 3
    'ERROR',        // 4
    'connect1200',  // 5 (not used here)
    'NO DIALTONE',  // 6
    'BUSY',         // 7
    'NO ANSWER',    // 8
    'DTR DROPPED',  // 9
    '[Not ready]',  //10
    '[Port closed]' //11
  );
const
  sModemStates:array [TModemState] of String=(
    '- - -',
    'Нет готовности (DSR=0)',
    'Командный режим (CD=0)',
    'Попытка соединения',
    'Есть несущая (CD=1)',
    'Разъединение'
  );

procedure Register;

implementation

uses Windows,Forms;

procedure Register;
begin
  RegisterComponents('W.Vitek', [TModem]);
end;

{ TCustomModem }

procedure TCustomModem.Connect(ConnectCmd: String);
begin
  SetState(msConnection);
  DoCmd(ConnectCmd);
end;

constructor TCustomModem.Create(AOwner: TComponent);
begin
  inherited;
  FState:=msNotOpen;
  FResponseCode:=mrcUnknown;
  OnRLSD:=OnCommStateChange;
  OnDSR:=OnCommStateChange;
  OnRxChar:=OnCommRxChar;
  OnTxEmpty:=OnCommTxEmpty;
end;

procedure TCustomModem.Disconnect(ReinitCmd:String);
const
  PPP:String='+++';
  Inside:Boolean=False;
var
  i:Integer;
  OldState:TModemState;
begin
  if not Enabled or Inside then exit;
  Inside:=True;
  if RLSD then begin
    sleep(250);
    Application.ProcessMessages();
    Write(PPP[1],Length(PPP));
    sleep(250);
    Application.ProcessMessages();
    if ReinitCmd<>'' then DoCmd(ReinitCmd);
    SetRtsState(False);
    SetDtrState(False);
    OldState:=FState;
    FState:=msOffline;
//    OnCommStateChange(Self);
    for i:=1 to 16 do begin
      if not RLSD then break;
      sleep(250);
//      if ReinitCmd<>'' then DoCmd(ReinitCmd);
      Application.ProcessMessages();
    end;
    SetDtrState(True);
    SetRtsState(True);
    FState:=OldState;
    if (FState<>msOnline) and (FState<>msDisconnection)
    then SetState(msOffline)
    else SetState(msDisconnection); // пока не пропадет сигнал CD (RLSD)
  end
  else SetState(msOffline);
  Inside:=False;
end;

procedure TCustomModem.DoCmd(Cmd: String);
var
  S:String;
begin
  S:=Cmd+#13;
  Write(S[1],Length(S));
end;

procedure TCustomModem.OnCommStateChange(Sender: TObject);
const
  NewStates:array [Boolean,Boolean] of TModemState = (
    //RLSD=(0,1)
    (msNotReady,msNotReady ), // DSR=0
    (msOffline, msOnline )  // DSR=1
  );
var
  DSRState:Boolean;
begin
  if coDsrSensitivity in Options then DSRState:=DSR
  else DSRState:=True;
  SetState(NewStates[DSRState,RLSD]);
end;

procedure TCustomModem.OnCommRxChar(Sender: TObject; Count: Integer);
var
  Buf:String;
  i,j:Integer;
  c:Char;
  CR:Boolean;
begin
  if FState = msOnline then begin
    if Assigned(FOnModemRxChar) then FOnModemRxChar(Self,Count);
  end
  else begin
    SetLength(Buf,Count);
    Read(Buf[1],Count);
    CR:=(LastLine<>'') and (LastLine[Length(LastLine)]=#13);
    for i:=1 to Length(Buf) do begin
      c:=Buf[i];
      LastLine:=LastLine+c;
      if CR and (c=#10) then begin
        CR:=False;
        FResponse:=FResponse+LastLine;
        j:=High(ModemResponses);
        while (j>=0) and (Pos(ModemResponses[j],LastLine)<>1) do Dec(j);
        LastLine:='';
        if (j>=0) then begin
          FResponseCode:=j;
          ProcessResponse;
          FResponse:='';
          FResponseCode:=-1;
        end;
      end
      else CR:=c=#13;
    end;
  end;
end;

procedure TCustomModem.OnCommTxEmpty(Sender: TObject);
begin
  if FState = msOnline then begin
    if Assigned(FOnModemTxEmpty) then FOnModemTxEmpty(Self);
  end;
end;

procedure TCustomModem.ProcessResponse;
begin
  if (FState=msConnection) and
    (FResponseCode in [mrcNoCarrier,mrcError,mrcNoDialtone,mrcBusy,mrcNoAnswer])
  then SetState(msOffline);
  if Assigned(FOnResponse) then FOnResponse(Self);
end;

function TCustomModem.GetResponseInLine: String;
var
  i:Integer;
  c:Char;
begin
  Result:='';
  for i:=1 to Length(FResponse) do begin
    c:=FResponse[i];
    if c=#13
    then Result:=Result+'<cr>'
    else if c=#10
    then Result:=Result+'<lf>'
    else if (#0<=c)and(c<' ')
    then Result:=Result+Format('<%d>',[Ord(c)])
    else Result:=Result+c;
  end;
end;

procedure TCustomModem.Open;
begin
  inherited Open;
  FState:=msOffline;
  SetDtrState(True);
  SetRtsState(True);
  OnCommStateChange(Self);
end;

procedure TCustomModem.Close;
begin
  if not Enabled then exit;
  SetRtsState(False);
  SetDtrState(False);
  SetState(msOffline);
  inherited Close;
end;

procedure TCustomModem.SetState(NewState: TModemState);
var
  OldState:TModemState;
begin
  if NewState=FState then exit;
  OldState:=FState;
  FState:=NewState;
  case NewState of
    msNotOpen, msNotReady, msOffline: begin
      case OldState of
        msConnection,msOnline,msDisconnection:
        begin
          case NewState of
            msNotOpen: FResponseCode:=mrcClosed;
            msNotReady: FResponseCode:=mrcDsrDropped;
          end;
          case OldState of
            msConnection:
              if Assigned(FOnConnFailed) then FOnConnFailed(Self);
            msOnline,msDisconnection:
              if Assigned(FOnDisconnect) then FOnDisconnect(Self);
          end;
        end
      end;
    end;
    msOnline:
      if OldState=msDisconnection
      then FState:=msDisconnection
      else if Assigned(FOnConnect) then FOnConnect(Self);
  end;
end;

end.

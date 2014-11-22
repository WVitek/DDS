unit UPRT_COMPORT;

interface

uses
  UPRT, Windows;

type
  TPRT_COMPORT = class(TPRT_ABSTRACT)
  protected
    FComName:String;
    hCom:THandle;
    FBaudRate:Cardinal;
    RxQue,TxQue:Integer;
  private
    procedure SetBaudRate(const Value: Cardinal);
    procedure RebuildDCB;
    procedure SetComName(const Value: String);
    procedure CheckQueues;
  public
    CheckRLSD: Boolean;
    constructor Create;
    destructor Destroy;override;
    function Opened:Boolean;
    property ComName:String read FComName write SetComName;
    property BaudRate:Cardinal read FBaudRate write SetBaudRate;
  public // interface
    function Open:HRESULT;override;
    procedure Close;override;
    function RxSize():Integer;override;
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
  end;

implementation

constructor TPRT_COMPORT.Create();
begin
  hCom:=INVALID_HANDLE_VALUE;
end;

destructor TPRT_COMPORT.Destroy;
begin
  Close;
end;

function TPRT_COMPORT.Opened: Boolean;
begin
  Result := hCom <> INVALID_HANDLE_VALUE;
end;

procedure TPRT_COMPORT.SetBaudRate(const Value: Cardinal);
begin
  FBaudRate := Value;
  if Opened then RebuildDCB;
end;

procedure TPRT_COMPORT.RebuildDCB;
var
  DCB:TDCB;
  CTO:TCommTimeouts;
begin
  if not Opened then exit;
  GetCommState(hCom, DCB);
  DCB.BaudRate := BaudRate;
  DCB.Parity := NOPARITY;
  DCB.Stopbits := ONESTOPBIT;
  DCB.Bytesize := 8;
  DCB.Flags := 0;
  SetCommState(hCom, DCB);
  GetCommTimeouts(hCom, CTO);
  CTO.ReadIntervalTimeout := MAXDWORD;
  CTO.ReadTotalTimeoutMultiplier := 0;
  CTO.ReadTotalTimeoutConstant := 0;
  SetCommTimeouts(hCom, CTO);
end;

//******************** begin of PRT interface

function TPRT_COMPORT.Open:HRESULT;
begin
  if Opened
  then Result:=E_UNEXPECTED
  else begin
    hCom := CreateFile(PCHAR(ComName),
      GENERIC_READ or GENERIC_WRITE, 0, nil,
      OPEN_EXISTING, 0, 0);
    RxQue := 0;
    if Opened
    then Result:=S_OK
    else Result:=GetLastError();
    RebuildDCB;
    EscapeCommFunction(hcom, SETDTR);
    EscapeCommFunction(hcom, SETRTS);
    PurgeComm(hCom,PURGE_RXCLEAR or PURGE_TXCLEAR);
  end;
end;

procedure TPRT_COMPORT.Close;
begin
  if Opened then begin
    EscapeCommFunction(hcom, CLRRTS);
    EscapeCommFunction(hcom, CLRDTR);
    Windows.CloseHandle(hCom);
    hCom:=INVALID_HANDLE_VALUE;
  end;
end;

function TPRT_COMPORT.RxSize:Integer;
begin
  if Opened
  then Result := RxQue
  else Result := -1;
end;

function TPRT_COMPORT.Rx(var Data; MaxSize:Integer):Integer;
var
  N:Cardinal;
begin
  if Opened
  then begin
    Windows.ReadFile(hCom,Data,MaxSize,N,nil);
    Result:=N;
  end
  else
    Result:=-1;
end;

procedure TPRT_COMPORT.Tx(const Data; DataSize:Integer);
var
  N:Cardinal;
begin
  Windows.WriteFile(hCom,Data,DataSize,N,nil);
end;

function TPRT_COMPORT.ProcessIO:Integer;
var
  modemStat: Cardinal;
begin
  Result:=0;
  if not Opened then exit;
  if CheckRLSD
  then begin
    if GetCommModemStatus(hCom, modemStat) and (modemStat and MS_RLSD_ON = 0)
    then exit
    else Result:=Result or IO_UP;
  end
  else Result:=Result or IO_UP;
  CheckQueues;
  if RxQue > 0 then Result:=Result or IO_RX;
  if TxQue <= 16
  then begin
    Result:=Result or IO_TX;
    if TxQue=0 then Result:=Result or IO_TXEMPTY;
  end;
end;

//******************** end of PRT interface

procedure TPRT_COMPORT.SetComName(const Value: String);
begin
  FComName := Value;
  if Opened then begin
    Close; Open;
  end;
end;

procedure TPRT_COMPORT.CheckQueues;
var
  ComStat: TComStat;
  Errors: DWORD;
begin
  if ClearCommError(hCom, Errors, @ComStat)
  then begin
    TxQue:=ComStat.cbOutQue;
    RxQue:=ComStat.cbInQue;
  end
  else begin
    TxQue:=MaxInt;
    RxQue:=-1;
  end;
end;

end.

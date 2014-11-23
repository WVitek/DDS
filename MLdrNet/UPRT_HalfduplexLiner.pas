unit UPRT_HalfduplexLiner;

interface

uses
  UPRT, UTime, UPRT_Liner;

type
  TPRT_HDLINER = class(TPRT_LINER)
  protected
    timeout : TTimeoutObj;
    rx_timeout: TTimeout;
    buf:array[0..LINER_INBSIZE-1] of Byte;
    size:Integer;
  public
    constructor Create(prt:TPRT; rx_timeout:TTimeout);
  public // interface
    function RxSize():Integer;override;
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; Cnt:Integer);override;
    function ProcessIO():Integer;override;
  end;

implementation

uses
  SysUtils, UNetW;

{ TPRT_HDLINER }

constructor TPRT_HDLINER.Create(prt: TPRT; rx_timeout:TTimeout);
begin
  inherited Create(prt);
  self.rx_timeout:=rx_timeout;
  timeout.setSignaled(true);
end;

function TPRT_HDLINER.Rx(var Data; MaxSize:Integer): Integer;
begin
  Result:=size;
  if Result=0 then exit;
  if Result>MaxSize then Result:=MaxSize;
  move(buf,data,Result);
  size:=0;
end;

function TPRT_HDLINER.RxSize: Integer;
begin
  Result:=size;
end;

procedure TPRT_HDLINER.Tx(const Data; Cnt: Integer);
begin
  inherited Tx(Data, Cnt);
  timeout.start(rx_timeout);
end;

function TPRT_HDLINER.ProcessIO: Integer;
begin
  repeat
    Result:=inherited ProcessIO();
    if Result and IO_RX <> 0 then
      size:=inherited Rx(buf, LINER_INBSIZE)
    else break;
  until false;
  if Result and IO_UP = 0 then
    exit;
  if size > 0 then
  begin
    timeout.setSignaled(true);
    Result:=Result or IO_RX;
    ClearInBuf;
  end;
  if not timeout.IsSignaled then
    Result:=Result and not IO_TX;
end;

end.

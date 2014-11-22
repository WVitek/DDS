unit UPRT;

interface

type
  TPRT_STATE = (
    psInitial,
    psStarting,
    psClosed,
    psStopped,
    psClosing,
    pStopping,
    psReqSend,
    psAckRcvd,
    psAckSent,
    psOpened
  );

const
  IO_RX      = $0001;
  IO_TX      = $0002;
  IO_TXEMPTY = $0004;
  IO_UP      = $0008;

type
  TIME_STAMP = Int64;

  TPRT_ABSTRACT = class(TObject) // Packet Receiver-Transmitter (Abstract)
  public
    procedure TxStr(const S:AnsiString);
  public // interface
    function Open:HRESULT;virtual;abstract;
    procedure Close;virtual;abstract;
    function RxSize():Integer;virtual;abstract;
    function Rx(var Data; MaxSize:Integer):Integer;virtual;abstract;
    procedure Tx(const Data; DataSize:Integer);virtual;abstract;
    function ProcessIO:Integer;virtual;abstract;
  end;
  TPRT = TPRT_ABSTRACT;

implementation

uses
  Classes;

procedure TPRT_ABSTRACT.TxStr(const S:AnsiString);
var
  Data:Pointer;
begin
  if Length(S)=0
  then Data:=nil
  else Data:=@S[1];
  Tx(Data,Length(S));
end;

end.

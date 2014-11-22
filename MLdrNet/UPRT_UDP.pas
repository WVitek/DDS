unit UPRT_UDP;

interface

uses
  Classes, NMUDP, UPRT, UTime;

const
  UDPLinkTimeout = toTypeSec or 65;

type
  TPRT_UDP = class(TPRT_ABSTRACT)
  protected
    IP:String;
    Port:Integer;
    UDP:TNMUDP;
    RxQue:TStringList;
    toutLink:TTIMEOUTOBJ;
  public
    constructor Create(UDP:TNMUDP; IP:String; Port:Integer);
    destructor Destroy;override;
    procedure AddToRxQue(Packet:String);
    function LinkTimeout:Boolean;
  public // interface
    function Open:HRESULT;override;
    procedure Close;override;
    function RxSize():Integer;override;
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
  end;

implementation

uses
  Windows;

{ TPRT_UDP }

constructor TPRT_UDP.Create(UDP: TNMUDP; IP: String; Port: Integer);
begin
  Self.UDP:=UDP;
  Self.IP:=IP;
  Self.Port:=Port;
  RxQue:=TStringList.Create;
  toutLink.start(UDPLinkTimeout);
end;

destructor TPRT_UDP.Destroy;
begin
  RxQue.Free;
  inherited;
end;

function TPRT_UDP.Open: HRESULT;
begin
  // dododo
  Result:=S_OK;
end;

procedure TPRT_UDP.Close;
begin
  // dododo
end;

function TPRT_UDP.ProcessIO: Integer;
begin
  Result:=IO_UP or IO_TX;
  if RxQue.Count>0
  then Result:=Result or IO_RX;
end;

function TPRT_UDP.Rx(var Data; MaxSize: Integer): Integer;
var
  S:String;
begin
  Result:=0;
  if RxQue.Count=0 then exit;
  if @Data<>nil then
  begin
    S:=RxQue[0];
    Result:=Length(S);
    if MaxSize<Result then Result:=MaxSize;
    Move(S[1],Data,Result);
  end;
  RxQue.Delete(0);
  toutLink.start(UDPLinkTimeout);
end;

function TPRT_UDP.RxSize: Integer;
begin
  if RxQue.Count>0
  then Result:=Length(RxQue[0])
  else Result:=0;
end;

procedure TPRT_UDP.Tx(const Data; DataSize: Integer);
var
  Buf:array[0..1023] of Char;
begin
  UDP.RemoteHost:=IP;
  UDP.RemotePort:=Port;
  if DataSize>High(Buf)+1 then DataSize:=High(Buf)+1;
  Move(Data,Buf,DataSize);
  UDP.SendBuffer(Buf,DataSize);
end;

procedure TPRT_UDP.AddToRxQue(Packet: String);
begin
  RxQue.Add(Packet);
end;

function TPRT_UDP.LinkTimeout: Boolean;
begin
  Result:=toutLink.IsSignaled();
end;

end.

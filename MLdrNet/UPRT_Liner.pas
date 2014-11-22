unit UPRT_Liner;

interface

uses
  UPRT, UTime;

const
  LINER_TXBSIZE = 400;
  LINER_INBSIZE = 1024;

type
  TPRT_LINER = class(TPRT)
  private
    prt:TPRT;
    InBLen,BufPos:Integer;
    RxReady,NeedXor:Boolean;
    // буфер полученных "сырых" данных
    InB:array[0..LINER_INBSIZE-1] of Byte;
    // буфер для принятого пакета
    Buf:array[0..LINER_INBSIZE-1] of Byte;
  public
    constructor Create(prt:TPRT);
  public // interface
    function Open:HRESULT;override;
    procedure Close;override;
    function RxSize():Integer;override;
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; Cnt:Integer);override;
    function ProcessIO():Integer;override;
  end;

  TLinkStat = object
    BytesI, PacketsI: Cardinal;
    BytesO, PacketsO: Cardinal;
    procedure Add(const Stat:TLinkStat);
    procedure Clear;
    function GetMsg:String;
  end;

// return True if nothing to do
function StdProcessIO(prt:TPRT_LINER; var Stat:TLinkStat):Boolean;

implementation

uses
  SysUtils, UNetW;

function StdProcessIO(prt:TPRT_LINER; var Stat:TLinkStat):Boolean;
var
  IO,i:Integer;
  S:String;
begin
  Result:=True;
  IO:=Prt.ProcessIO;
  if IO and IO_RX <> 0 then
  begin
    Result:=False;
    SetLength(S,prt.RxSize);
    SetLength(S,prt.Rx(S[1],Length(S)));
    if NetW_receive(prt,S[1],Length(S))
    then Inc(Stat.PacketsI);
    Inc(Stat.BytesI,Length(S));
  end;
  if IO and IO_TX <> 0 then
  begin
    SetLength(S,LINER_TXBSIZE);
    i:=NetW_transmit(prt,S[1],Length(S));
    if i>0 then
    begin
      Result:=False;
      SetLength(S,i);
      prt.Tx(S[1],i);
      Inc(Stat.PacketsO); Inc(Stat.BytesO,i);
    end
  end;
end;

const
  RX_TIMEOUT = toTypeSec or 3;

{ TPRT_LINER }

constructor TPRT_LINER.Create(prt: TPRT);
begin
  Self.prt:=prt;
end;

//******************** begin of PRT interface

function TPRT_LINER.Open:HRESULT;
begin
  Result:=prt.Open();
end;

procedure TPRT_LINER.Close;
begin
  prt.Close();
end;

function TPRT_LINER.Rx(var Data; MaxSize:Integer): Integer;
begin
  if RxReady then
  begin
    RxReady := FALSE;
    if MaxSize<BufPos then BufPos:=MaxSize;
    if @Data<>nil then move(Buf[0],Data,BufPos);
    Result:=BufPos; BufPos:=0;
  end
  else Result:=0;
end;

function TPRT_LINER.RxSize: Integer;
begin
  if RxReady
  then Result:=BufPos
  else Result:=0;
end;

procedure TPRT_LINER.Tx(const Data; Cnt: Integer);
var
  TxEOL:Boolean;
  TxBuf:array of Byte;
  Src:^Byte;
  TxPos:Integer;
  c:Byte;
begin
  TxEOL := True;
  SetLength(TxBuf,Cnt*2+1);
  TxPos := 0;
  if Cnt>0 then
  begin
    Src := @Data;
    while Cnt>0 do
    begin
      c := Src^;
      if (c=$0D) or (c=$7D) or (c=$0A) then
      begin
        TxBuf[TxPos] := $7D;
        Inc(TxPos);
        c := c xor $20;
      end;
      TxBuf[TxPos] := c;
      Inc(TxPos);
      Dec(Cnt); Inc(Src);
    end;
  end;
  if TxEOL then
  begin
    TxBuf[TxPos] := $0D;
    Inc(TxPos);
  end;
  if TxPos>0 then prt.Tx(TxBuf[0],TxPos);
end;

function TPRT_LINER.ProcessIO: Integer;
var
  i:Integer;
  c:Byte;
begin
  Result:=prt.ProcessIO();
  if Result and IO_UP = 0 then exit;
  //********** RX
  if (InBLen=0) and (Result and IO_RX<>0) then begin
    InBLen := prt.Rx(InB,LINER_INBSIZE);
  end;
  if not RxReady and (InBLen>0) then
  begin
    i:=0;
    while i<InBLen do
    begin
      c:=InB[i]; Inc(i);
      case c of
      $0D: // Carriage Return
        begin
          RxReady := TRUE;
          break;
        end;
      $7D: // ESC prefix '}'
        NeedXor:=TRUE;
      $0A: // Line Feed
        ; // do nothing
      else
        if BufPos<LINER_INBSIZE then
        begin
          if NeedXor then
          begin
            c := c xor $20;
            NeedXor := FALSE;
          end;
          Buf[BufPos]:=c;
          Inc(BufPos);
        end;
      end;
    end;
    InBLen:=InBLen-i;
    if InBLen>0
    then Move(InB[i],InB[0],InBLen);
    if RxReady then
      NeedXor:=FALSE;
  end;
  if RxReady
  then Result := Result or IO_RX
  else Result := Result and not IO_RX;
end;

//******************** end of PRT interface

{ TLinkStat }

procedure TLinkStat.Add;
begin
  Inc(BytesI,Stat.BytesI); Inc(PacketsI,Stat.PacketsI);
  Inc(BytesO,Stat.BytesO); Inc(PacketsO,Stat.PacketsO);
end;

procedure TLinkStat.Clear;
begin
  BytesI:=0; PacketsI:=0;
  BytesO:=0; PacketsO:=0;
end;

function TLinkStat.GetMsg: String;
begin
  Result:=Format('Rx: %.9d/%.4d; Tx: %.9d/%.4d',[BytesI,PacketsI,BytesO,PacketsO]);
end;

end.

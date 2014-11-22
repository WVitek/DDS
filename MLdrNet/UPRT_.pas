unit UPRT_;

interface

uses
  Classes,
  UModem,UServices;

const
  MyAddr=1;
  IO_RX=$01;
  IO_TX=$02;
  IO_TXEMPTY=$04;
  TxQueSize = 1024;

type
  TIME_STAMP = Int64;

  TPRT = class(TObject) // Packet Receiver-Transmitter (Abstract)
    function Rx(var Data; MaxSize:Integer):Integer;virtual;abstract;
    procedure Tx(const Data; DataSize:Integer);virtual;abstract;
    function RxLength:Integer;virtual;abstract;
    function ProcessIO:Integer;virtual;abstract;
  end;

  TPRT_Test = class(TPRT)
  protected
    Buf:array of Byte;
  public
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
    function RxLength:Integer;override;
  end;

  PWord = ^Word;

  TPRT_Modem = class(TPRT)
  protected
    Modem:TModem;
    procedure ModemTxEmpty(Sender:TObject);
  public
    TxBufEmpty:Boolean;
    constructor Create(Modem:TModem);
    destructor Destroy;override;
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
    function RxLength:Integer;override;
  end;

  TPRT_Packeter = class(TPRT)
    PRT:TPRT;
    BufPos:Integer;
    BufBusy,NeedXor:Boolean;
    Buf:array of Byte;
    HalfDuplex,PauseTx,IsTxPlanned:Boolean;
  public
    constructor Create(PRT:TPRT; HalfDuplex:Boolean);
    destructor Destroy;override;
    function Rx(var Data; MaxSize:Integer):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
    function RxLength:Integer;override;
    procedure SetPause(Pause:Boolean);
  end;

  _THeader = packed record
    Addr:Byte;
    A:Byte;
    B:Byte;
  end;

  _TPacket = packed record
    HdrCRC:Byte;
    Hdr:_THeader;
    Data:Byte;
  end;

const
  LL_PRTDataSize = 4;
  PRTDataSize = LL_PRTDataSize+ARQ_PRTDataSize;
  PRT_BUFSIZE = 256;

var
  PacketsO,BytesO:Cardinal;
  PacketsI,BytesI:Cardinal;

implementation

uses SysUtils,Windows,UCRC,UFrameMain,Misc,UTime;

var
  ASDs:TList;
  CurASD:PARQSysData;

function GetASD(Addr: Integer): PARQSysData;
var
  i:Integer;
begin
  if (CurASD=nil) or (CurASD.Addr<>Addr) then begin
    i:=ASDs.Count-1;
    while 0<=i do begin
      if PARQSysData(ASDs[i]).Addr=Addr then begin
        CurASD:=ASDs[i];
        break;
      end;
      Dec(i);
    end;
    if i<0 then begin
      // Create new ASD
      GetMem(CurASD,SizeOf(TARQSysData));
      FillChar(CurASD^,SizeOf(TARQSysData),0);
      CurASD.Addr:=Addr;
      CurASD.ARQState:=ARQS_RSTQ;
      ASDs.Add(CurASD);
    end;
  end;
  Result:=CurASD;
end;

procedure Log(Msg:String);
begin
  ItemMain.CommEvent(Msg);
end;

{ TPRT_Packeter }

constructor TPRT_Packeter.Create(PRT: TPRT; HalfDuplex:Boolean);
begin
  Self.PRT:=PRT;
  Self.HalfDuplex:=HalfDuplex;
  SetLength(Buf,PRT_BUFSIZE);
end;

destructor TPRT_Packeter.Destroy;
begin
  inherited;
end;

function TPRT_Packeter.ProcessIO: Integer;
label
  EndRX;
var
  i:Integer;
  ClcCRC,SrcCRC:Word;
  c:Byte;
begin
  Result:=PRT.ProcessIO;
  Result:=Result and not IO_RX;
  // RX
  i:=PRT.RxLength;
  if not BufBusy and (i>0) then begin
    PRT.Rx(c,1); Dec(i);
{
    if (BufPos=0) and not NeedXor then begin
//      // skip garbage
//      while (i>0) and (c<>$7E) do begin Modem.Read(c,1); Dec(i); end;
//      if c<>$7E then goto EndRX;
      // skip empty packets & flag
      while (i>0) and (c=$7E) do begin Inc(j); PRT.Rx(c,1); Dec(i); end;
    end;//}
    repeat
      if c=$7D then NeedXor:=True
      else if c=$7E then break
      else begin
        if BufPos=PRT_BUFSIZE then break;
        if NeedXor then begin
          Buf[BufPos]:=c xor $20; NeedXor:=False;
        end
        else Buf[BufPos]:=c;
        Inc(BufPos);
      end;
      if i=0 then break;
      PRT.Rx(c,1); Dec(i);
    until False;
    if c=$7E then begin
      PauseTx:=False;
      NeedXor:=False;
      if BufPos<3 then BufPos:=0
      else begin
        Dec(BufPos,2);
        ClcCRC:=PPP_FCS16(Buf[0],BufPos);
        SrcCRC:=PWord(@(Buf[BufPos]))^;
//        Log(getHexDump(Buf[0],BufPos));
        if ClcCRC <> SrcCRC
        then begin
          Log(Format('Rx: CRC error (%04X<>%04X)',[ClcCRC,SrcCRC]));
          BufPos:=-BufPos;
        end;
      end;
      if BufPos<>0 then BufBusy:=True;
    end;
  end;
  if BufBusy then Result:=Result or IO_RX;
  if IsTxPlanned then begin
    Tx(nil^,0);
    Result:=Result and not IO_TX;
  end
  else if HalfDuplex then begin
    if not PauseTx and (Result and IO_TX<>0)
    then IsTxPlanned:=HalfDuplex
    else Result:=Result and not IO_TX;
  end;
EndRX:
end;

function TPRT_Packeter.Rx(var Data; MaxSize:Integer): Integer;
begin
  if BufBusy and (MaxSize>=abs(BufPos)) then begin
    BufBusy:=False;
    Move(Buf[0],Data,abs(BufPos));
    Result:=BufPos;
    BufPos:=0;
    Inc(BytesI,4+abs(Result));
    Inc(PacketsI);
  end
  else begin
    Result:=0;
    BufPos:=0;
    BufBusy:=False;
  end;
end;

procedure TPRT_Packeter.Tx(const Data; DataSize: Integer);
var
  i:Integer;
  Buf:array of Byte;
  c,flag,esc:Byte;
begin
  if DataSize>0 then begin
    SetLength(Buf,DataSize+2);
    Move(Data,Buf[0],DataSize);
    PWord(@(Buf[DataSize]))^:=PPP_FCS16(Data,DataSize);
  end;
//  Log(getHexDump(Buf[0],Length(Buf)));
  flag:=$7E;
//  PRT.Tx(flag,1);
  esc:=$7D;
  for i:=0 to Length(Buf)-1 do begin
    c:=Buf[i];
    if (c=$7D) or (c=$7E) then begin
      PRT.Tx(esc,1);
      c:=c xor $20;
    end;
    PRT.Tx(c,1);
  end;
  PRT.Tx(flag,1);
  Inc(BytesO,4+DataSize);
  Inc(PacketsO);
  PauseTx:=HalfDuplex;
  IsTxPlanned:=False;
end;

function TPRT_Packeter.RxLength: Integer;
begin
  Result:=BufPos;
end;

procedure TPRT_Packeter.SetPause(Pause: Boolean);
begin
  PauseTx:=Pause;
  IsTxPlanned:=not Pause;
end;

{ TPRT_ARQ }

constructor TPRT_ARQ.Create(PRT: TPRT; Timeout:Integer);
begin
  Self.PRT:=PRT;
  PACKET_TIMEOUT:=Timeout;
end;

function TPRT_ARQ.GetASD(Addr: Integer): PARQSysData;
begin
  Result:=UPRT.GetASD(Addr);
end;

function TPRT_ARQ.get_i_frame(p:PARQSysData): Boolean;
var
  CurTime:TIME_STAMP;
  TxTime:^TIME_STAMP;
  i:Integer;
begin
  CurTime:=UTCTimeStamp;
  i:=p.TxRd;
  while (i<>p.TxWr) do begin
    TxTime:=@(p.TxWin[i and ARQ_WINWRAP].TxTime);
    if TxTime^+PACKET_TIMEOUT < CurTime then begin
      if TxTime^<>0 then Log('ARQ: ACK-TIMEOUT');
      break;
    end;
    i:=(i+1) and ARQ_NUMWRAP;
  end;
  if i<>p.TxWr then begin
    TxHdr.Addr:=MyAddr;
    TxHdr.A:=$00 or i;
    Result:=True;
  end
  else Result:=False;
end;

const
  CODE_RR  =$0;
  CODE_RNR =$2;
  CODE_SREJ=$3;
  CODE_TIMQ=$4;
  CODE_TIMA=$5;
  CODE_RSTQ=$6;
  CODE_RSTA=$7;

function TPRT_ARQ.ProcessIO: Integer;
var
  EM:Integer;
  i,Size:Integer;
  Buf:_TPacket;
  Tmp:String;
  p:PARQSysData;
begin
  EM := PRT.ProcessIO;
  // RX
  if EM and IO_RX<>0 then begin
    Size:=PRT.Rx(Buf,SizeOf(Buf));
    // Frame corrupted?
    if Size<=0 then begin
      // Frame corrupted!
      Log('ARQ-Rx: Corrupted frame');
      // Header is valid and ...
      if(Buf.HdrCRC=Byte(PPP_FCS16(Buf.Hdr,SizeOf(Buf.Hdr)))) and
        (Buf.Hdr.A and BIT_S = 0) //frame is a i-frame?
      then begin // corrupted i-frame received, prepare SREJ-frame
        Log(Format('ARQ-Tx: SREJ(%02X)',[Buf.Hdr.A and ARQ_NUMWRAP]));
        TxHdr.Addr:=MyAddr;
        TxHdr.A:=BIT_S or CODE_SREJ;
        TxHdr.B:=BIT_PF or (Buf.Hdr.A and ARQ_NUMWRAP);
      end
    end
    else begin // Frame valid
      p:=ASD[Buf.Hdr.Addr];
      if(Buf.Hdr.A and BIT_S=0)
      then begin // i-frame
        if p.ARQState = ARQS_NORMAL
        then begin // ARQ in "normal operation" state
          acknowledge(p,Buf.Hdr.B and ARQ_NUMWRAP);
          i:=Buf.Hdr.A;
          if (i-p.RxRd) and ARQ_NUMWRAP < ARQ_WINSIZE then begin
            if (i-p.RxWr) and ARQ_NUMWRAP <= (i-p.RxRd) and ARQ_NUMWRAP
            then p.RxWr:=(i+1) and ARQ_NUMWRAP;
            i:=i and ARQ_WINWRAP;
            p.RxWin[i].DataSize:=Size-ARQ_PRTDataSize;
            p.RxWin[i].Data:=Buf.Data;
          end;
        end;
      end
      else begin // s-frame
        case Buf.Hdr.A and ARQ_NUMWRAP of
        CODE_SREJ:
          begin
            Log(Format('ARQ-Rx: SREJ(%02X)',[Buf.Hdr.B and ARQ_NUMWRAP]));
            // prepare requested i-frame
            TxHdr.Addr:=MyAddr;
            TxHdr.A:=0 or (Buf.Hdr.B and ARQ_NUMWRAP);
          end;
        CODE_RR:
          acknowledge(p,Buf.Hdr.B and ARQ_NUMWRAP);
        CODE_TIMQ:
          if TimeServer<>nil then begin
            Log('ARQ-Rx: Time query');
            SetLength(Tmp,Size-ARQ_PRTDataSize);
            Move(Buf.Data,Tmp[1],Length(Tmp));
            TimeServer.receiveData(Buf.Hdr.Addr,Tmp);
          end;
        CODE_RSTQ:
          begin
            Log('ARQ-Rx: Reset query');
            if p.ARQState=ARQS_NORMAL then reset;
            TxHdr.Addr:=MyAddr;
            TxHdr.A:=BIT_S or CODE_RSTA;
            TxHdr.B:=0;
          end;
        CODE_RSTA:
          begin;
            Log('ARQ-Rx: Reset answer');
            if p.ARQState=ARQS_RSTQ then reset;
            p.ARQState:=ARQS_NORMAL;
          end;
        else; //now i don't know what to do
        end;
      end;
    end;
  end;
  // TX
  if EM and IO_TX<>0 then begin
    Size:=ARQ_PRTDataSize;
    p:=CurASD;
    // We have no frame to transmit?
    if TxHdr.Addr=0 then begin
      if (TimeServer<>nil) and (TimeServer.HaveDataToTransmit) then begin
        if EM and IO_TXEMPTY<>0 then begin
          Log('ARQ-Tx: Time answer');
          TxHdr.Addr:=MyAddr;
          TxHdr.A:=BIT_S or CODE_TIMA;
          TxHdr.B:=0;
          TimeServer.getDataToTransmit(Tmp,MaxARQDataSize);
          Move(Tmp[1],Buf.Data,Length(Tmp));
          Inc(Size,Length(Tmp));
        end;
      end
      else if p<>nil then case p.ARQState of
        ARQS_RSTQ:
          if (p.LastACKTime=0) or (p.LastACKTime+PACKET_TIMEOUT < UTCTimeStamp)
          then begin
            Log('ARQ-Tx: Reset query');
            TxHdr.Addr:=MyAddr;
            TxHdr.A:=BIT_S or CODE_RSTQ;
            TxHdr.B:=0;
            p.LastACKTime:=UTCTimeStamp;
          end;
        ARQS_NORMAL:
          // no (data in tx queue) and (RR-frame needed)?
          if not get_i_frame(p) and
            ( (p.LastACKTime+(PACKET_TIMEOUT div 2) < UTCTimeStamp) or
            ((p.RxWr-p.LastACKNum) and ARQ_NUMWRAP >= ARQ_WINSIZE shr 1) )
          then begin // generate RR frame
            TxHdr.Addr:=MyAddr;
            TxHdr.A:=BIT_S or CODE_RR;
            TxHdr.B:=0 or GetNRx(p) and ARQ_NUMWRAP;
          end;
        else;
      end;
    end;
    if TxHdr.Addr<>0 then begin
      if TxHdr.A and BIT_S=0
      then begin // some actions for i-frame
        TxHdr.B:=0 or (GetNRx(p) and ARQ_NUMWRAP);
        i:=TxHdr.A and ARQ_WINWRAP;
        Inc(Size,p.TxWin[i].DataSize);
        Buf.Data:=p.TxWin[i].Data;
        p.TxWin[i].TxTime:=UTCTimeStamp;
      end;
      Buf.Hdr:=TxHdr;
      sendPacket(Buf,Size);
      TxHdr.Addr:=0;
    end;
  end;
  Result:=0;
  if CurASD<>nil then begin
    p:=CurASD;
    if p.RxWin[p.RxRd and ARQ_WINWRAP].DataSize>0
    then Result:=Result or IO_RX;
    if (p.TxWr-p.TxRd) and ARQ_NUMWRAP < ARQ_WINSIZE
    then Result:=Result or IO_TX;
    ItemMain.ShowARQState(p.TxRd,p.TxWr,p.RxRd,p.RxWr);
  end
  else ItemMain.ShowARQState(0,0,0,0);
end;

function TPRT_ARQ.GetNRx(p:PARQSysData): Integer;
var
  i:Integer;
begin
  i:=p.RxRd;
  while (p.RxWin[i and ARQ_WINWRAP].DataSize<>0) and (i<>p.RxWr) do begin
    i:=(i+1) and ARQ_NUMWRAP;
  end;
  Result:=i;
  p.LastACKTime:=UTCTimeStamp;
  p.LastACKNum:=i;
end;

procedure TPRT_ARQ.acknowledge(p:PARQSysData; R: Integer);
begin
  if (R-p.TxRd) and ARQ_NUMWRAP <= (p.TxWr-p.TxRd) and ARQ_NUMWRAP
  then p.TxRd:=R;
end;

function TPRT_ARQ.Rx(var Data; MaxSize:Integer): Integer;
var
  i:Integer;
  p:PARQSysData;
begin
  p:=CurASD;
  i:=p.RxRd and ARQ_WINWRAP;
  Result:=p.RxWin[i].DataSize;
  Move(p.RxWin[i].Data,Data,Result);
  p.RxWin[i].DataSize:=0;
  p.RxRd:=(p.RxRd+1) and ARQ_NUMWRAP;
end;

function TPRT_ARQ.RxLength:Integer;
begin
  Result:=CurASD.RxWin[CurASD.RxRd and ARQ_WINWRAP].DataSize;
end;

procedure TPRT_ARQ.sendPacket(var P: _TPacket; Size: Integer);
begin
  P.HdrCRC:=Byte(PPP_FCS16(P.Hdr,SizeOf(P.Hdr)));
  PRT.Tx(P,Size);
end;

procedure TPRT_ARQ.Tx(const Data; DataSize: Integer);
var
  i:Integer;
  p:PARQSysData;
begin
  p:=CurASD;
  i:=p.TxWr and ARQ_WINWRAP;
  p.TxWin[i].TxTime:=0;
  p.TxWin[i].DataSize:=DataSize;
  Move(Data,p.TxWin[i].Data,DataSize);
  p.TxWr:=(p.TxWr+1) and ARQ_NUMWRAP;
end;

function TPRT_ARQ.CanRX: Boolean;
begin
  if CurASD<>nil
  then Result:=CurASD.RxWin[CurASD.RxRd and ARQ_WINWRAP].DataSize>0
  else Result:=False;
end;

function TPRT_ARQ.CanTX: Boolean;
begin
  if CurASD<>nil
  then Result:=(CurASD.TxWr-CurASD.TxRd) and ARQ_NUMWRAP < ARQ_WINSIZE
  else Result:=False;
end;

procedure TPRT_ARQ.reset;
var
  i:Integer;
  p:PARQSysData;
begin
  p:=CurASD;
  p.RxRd:=0; p.RxWr:=0; p.TxRd:=0; p.TxWr:=0; p.LastACKNum:=0;
  p.LastACKTime:=UTCTimeStamp;
  for i:=0 to ARQ_WINSIZE-1 do p.RxWin[i].DataSize:=0;
end;

procedure TPRT_ARQ.OnDisconnect;
begin
  CurASD:=nil;
end;

{ TPRT_Test }

function TPRT_Test.ProcessIO: Integer;
begin
  if Length(Buf)>0 then Result:=IO_RX else Result:=IO_TX;
end;

function TPRT_Test.Rx(var Data; MaxSize:Integer): Integer;
begin
  Result:=RxLength;
  Move(Buf[0],Data,Result);
  SetLength(Buf,0);
  Inc(BytesI,Result);
  Inc(PacketsI);
end;

function TPRT_Test.RxLength: Integer;
begin
  Result:=Length(Buf);
end;

procedure TPRT_Test.Tx(const Data; DataSize: Integer);
begin
  SetLength(Buf,DataSize);
  Move(Data,Buf[0],DataSize);
  Inc(BytesO,DataSize);
  Inc(PacketsO);
end;

{ TPRT_Modem }

constructor TPRT_Modem.Create(Modem: TModem);
begin
  Self.Modem:=Modem;
  Modem.OnModemTxEmpty:=ModemTxEmpty;
end;

destructor TPRT_Modem.Destroy;
begin
  Modem.OnModemTxEmpty:=nil;
  inherited;
end;

procedure TPRT_Modem.ModemTxEmpty(Sender: TObject);
begin
  TxBufEmpty:=True;
end;

function TPRT_Modem.ProcessIO: Integer;
var
  OQC:Integer;
begin
  Result:=0;
  // RX
  if Modem.InQueCount>0 then Result:=Result or IO_RX;
  // TX
  OQC:=Modem.OutQueCount;
  if TxQueSize-OQC > TxQueSize shr 1 then begin
    Result:=Result or IO_TX;
    if TxBufEmpty then Result:=Result or IO_TXEMPTY;
  end;
end;

function TPRT_Modem.Rx(var Data; MaxSize:Integer): Integer;
begin
  Result:=RxLength;
  if MaxSize<Result then Result:=MaxSize;
  Modem.Read(Data,Result);
end;

function TPRT_Modem.RxLength: Integer;
begin
  Result:=Modem.InQueCount;
end;

procedure TPRT_Modem.Tx(const Data; DataSize: Integer);
begin
  Modem.Write(Data,DataSize);
end;

procedure Finalize;
var
  i:Integer;
begin
  for i:=0 to ASDs.Count-1 do FreeMem(ASDs[i],SizeOf(TARQSysData));
  ASDs.Free;
  ASDs:=nil;
end;

initialization
  ASDs:=TList.Create;
finalization
  Finalize;
end.

//{$DEFINE UseHDLC}
unit UPRT;

interface

uses
  Classes,
  UModem,UServices;

const
  MyAddr=1;
  IO_RX=$01;
  IO_TX=$02;
  IO_TXEMPTY=$04;
  MaxARQDataSize=128;
  PACKET_TIMEOUT = 2000;
  ARQ_WINSIZE=8;
  ARQ_WINWRAP=ARQ_WINSIZE-1;
  ARQ_NUMWRAP=$7F;
  BIT_S = $80;
  BIT_PF = $80;
  TxQueSize = 1024;

type
  TIME_STAMP = Int64;

  TPRT_Abstract = class // Packet Receiver-Transmitter (Abstract)
    function Rx(var Data):Integer;virtual;abstract;
    procedure Tx(const Data; DataSize:Integer);virtual;abstract;
    function ProcessIO:Integer;virtual;abstract;
  end;

  TPRT_Test = class(TPRT_Abstract)
  protected
    Buf:array of Byte;
  public
    function Rx(var Data):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
  end;

{$IFDEF UseHDLC}
  PWord = ^Word;
{$ELSE}
  _TLLHdr = packed record
    DataSize,CRC:Byte;
  end;
{$ENDIF}

  TPRT_Modem = class(TPRT_Abstract)
    Modem:TModem;
{$IFDEF UseHDLC}
    BufPos:Integer;
    BufBusy,NeedXor:Boolean;
    Buf:array of Byte;
{$ELSE}
    RxState:(RX_FLAG, RX_HDR, RX_DATA, RX_READY);
    DataSize:Byte;
{$ENDIF}
    procedure ModemTxEmpty(Sender:TObject);
  public
    TxBufEmpty:Boolean;
    constructor Create(Modem:TModem);
    destructor Destroy;override;
    function Rx(var Data):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
  end;

  _TARQData = packed array[0..MaxARQDataSize-1] of Byte;

  _TARQTxWinItem = packed record
    TxTime:TIME_STAMP;
    DataSize:Byte;
    Data:_TARQData;
  end;

  _TARQRxWinItem = packed record
    DataSize:Byte;
    Data:_TARQData;
  end;

  _THeader = packed record
    Addr:Byte;
    A:Byte;
    B:Byte;
  end;

  _TPacket = packed record
{$IFNDEF UseHDLC}
    CRC:Word;
{$ENDIF}
    HdrCRC:Byte;
    Hdr:_THeader;
    Data:_TARQData;
  end;

  TARQSysData = record
    Addr:Integer;
    RxWin:array[0..ARQ_WINSIZE-1] of _TARQRxWinItem;
    TxWin:array[0..ARQ_WINSIZE-1] of _TARQTxWinItem;
    RxRd,RxWr:Integer;
    TxRd,TxWr:Integer;
    LastACKTime:TIME_STAMP;
    LastACKNum:Integer;
    ARQState:(ARQS_RSTQ,ARQS_RSTA,ARQS_NORMAL);
  end;

  PARQSysData = ^TARQsysData;

  TPRT_ARQ = class(TPRT_Abstract)
    PRT:TPRT_Abstract;
    TxHdr:_THeader;
    ASDs:TList;
    CurASD:PARQSysData;
  private
    function GetASD(Addr: Integer): PARQSysData;
  protected
    property ASD[Addr:Integer]:PARQSysData read GetASD;
    procedure sendPacket(var P:_TPacket; Size:Integer);
    procedure acknowledge(p:PARQSysData; R:Integer);
    function GetNRx(p:PARQSysData):Integer;
    function get_i_frame(p:PARQSysData):Boolean;
    procedure reset;
  public
    TimeServer:TService;
    constructor Create(PRT:TPRT_Abstract);
    destructor Destroy; override;
    function Rx(var Data):Integer;override;
    procedure Tx(const Data; DataSize:Integer);override;
    function ProcessIO:Integer;override;
    procedure OnDisconnect;
  public
    function CanTX:Boolean;
    function CanRX:Boolean;
  end;

const
{$IFDEF UseHDLC}
  LL_PRTDataSize = 4;
{$ELSE}
  LL_PRTDataSize = 1+SizeOf(_TLLHdr)+1;
{$ENDIF}
  ARQ_PRTDataSize = SizeOf(_TPacket)-SizeOf(_TARQData);
  PRTDataSize = LL_PRTDataSize+ARQ_PRTDataSize;
  PRT_COM_BUFSIZE = 256;

var
  PacketsO,BytesO:Cardinal;
  PacketsI,BytesI:Cardinal;

function UTCTimeStamp:TIME_STAMP;

implementation

uses SysUtils,Windows,UCRC,UFrameMain,Misc,UTime;

function UTCTimeStamp:TIME_STAMP;
begin
  Result:=Round(GetUTCTime*LLTicksProDay);
end;

procedure Log(Msg:String);
begin
  ItemMain.CommEvent(Msg);
end;

{ TPRT_Modem }

constructor TPRT_Modem.Create(Modem: TModem);
begin
  Self.Modem:=Modem;
  Modem.OnModemTxEmpty:=ModemTxEmpty;
{$IFDEF UseHDLC}
  SetLength(Buf,PRT_COM_BUFSIZE);
{$ENDIF}
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

{$IFDEF UseHDLC}

function TPRT_Modem.ProcessIO: Integer;
label
  EndRX;
var
  i,OQC:Integer;
  ClcCRC,SrcCRC:Word;
  c:Byte;
begin
  Result:=0;
  // RX
  i:=Modem.InQueCount;
  if not BufBusy and (i>0) then begin
    Modem.Read(c,1); Dec(i);
    if (BufPos=0) and not NeedXor then begin
//      // skip garbage
//      while (i>0) and (c<>$7E) do begin Modem.Read(c,1); Dec(i); end;
//      if c<>$7E then goto EndRX;
      // skip empty packets & flag
      while (i>0) and (c=$7E) do begin Modem.Read(c,1); Dec(i); end;
    end;
    repeat
      if c=$7D then NeedXor:=True
      else if c=$7E then break
      else begin
        if BufPos=PRT_COM_BUFSIZE then break;
        if NeedXor then begin
          Buf[BufPos]:=c xor $20; NeedXor:=False;
        end
        else Buf[BufPos]:=c;
        Inc(BufPos);
      end;
      if i=0 then break;
      Modem.Read(c,1); Dec(i);
    until False;
    if c=$7E then begin
      NeedXor:=False;
      if BufPos<3 then BufPos:=0
      else begin
        Dec(BufPos,2);
        ClcCRC:=PPP_FCS16(Buf[0],BufPos);
        SrcCRC:=PWord(@(Buf[BufPos]))^;
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
EndRX:
  // TX
  OQC:=Modem.OutQueCount;
  if TxQueSize-OQC >= PRT_COM_BUFSIZE+4 then begin
    Result:=Result or IO_TX;
    if TxBufEmpty or (OQC=0) then Result:=Result or IO_TXEMPTY;
  end;
end;

function TPRT_Modem.Rx(var Data): Integer;
begin
  if BufBusy then begin
    BufBusy:=False;
    Move(Buf[0],Data,abs(BufPos));
    Result:=BufPos;
    BufPos:=0;
    Inc(BytesI,4+abs(Result));
    Inc(PacketsI);
  end
  else Result:=0;
end;

procedure TPRT_Modem.Tx(const Data; DataSize: Integer);
var
  i:Integer;
  Buf:array of Byte;
  c,flag,esc:Byte;
begin
  SetLength(Buf,DataSize+2);
  Move(Data,Buf[0],DataSize);
  PWord(@(Buf[DataSize]))^:=PPP_FCS16(Data,DataSize);
//  Log(getHexDump(Buf[0],Length(Buf)));
  flag:=$7E;
  Modem.Write(flag,1);
  esc:=$7D; 
  for i:=0 to Length(Buf)-1 do begin
    c:=Buf[i];
    if (c=$7D) or (c=$7E) then begin
      Modem.Write(esc,1);
      c:=c xor $20;
    end;
    Modem.Write(c,1);
  end;
  Modem.Write(flag,1);
  Inc(BytesO,4+DataSize);
  Inc(PacketsO);
  TxBufEmpty:=False;
end;

{$ELSE UseHDLC}

function TPRT_Modem.ProcessIO: Integer;
var
  Process:Boolean;
  c:Char;
  Hdr:_TLLHdr;
  OQC:Integer;
begin
  Result:=0;
  // RX
  Process:=TRUE;
  while (Modem.InQueCount<>0) and Process do begin
    case RxState of
      RX_FLAG:
        while Modem.InQueCount<>0 do begin
          Modem.Read(c,1);
          if c='W' then begin
            RxState:=RX_HDR;
            break;
          end;
        end;
      RX_HDR:
        if Modem.InQueCount >= SizeOf(Hdr) then begin
          Modem.Read(Hdr,SizeOf(Hdr));
          if Byte(ModBus_CRC16(Hdr,SizeOf(Hdr)-1))=Hdr.CRC then begin
            DataSize:=Hdr.DataSize;
            RxState:=RX_DATA;
          end
          else begin
          //  Modem.unread(&hdr,sizeof(hdr));
            RxState:=RX_FLAG;
          end;
        end
        else Process:=False;
      RX_DATA:
        begin
          if Modem.InQueCount >= DataSize+1 then begin
            RxState:=RX_READY;
            Result:=Result or IO_RX;
          end;
          Process:=False;
        end;
    end;
  end;
  // TX
  OQC:=Modem.OutQueCount;
  if TxQueSize-OQC >= SizeOf(_TLLHdr)+ SizeOf(_TPacket) then begin
    Result:=Result or IO_TX;
    if TxBufEmpty then Result:=Result or IO_TXEMPTY;
  end;
end;

function TPRT_Modem.Rx(var Data): Integer;
begin
  if RxState=RX_READY then begin
    RxState:=RX_FLAG;
    Modem.Read(Data,DataSize);
    Result:=DataSize;
    Inc(BytesI,2+SizeOf(_TLLHdr)+Result);
    Inc(PacketsI);
  end
  else Result:=0;
end;

procedure TPRT_Modem.Tx(const Data; DataSize: Integer);
var
  Hdr:_TLLHdr;
  Flag:Char;
begin
  Hdr.DataSize:=DataSize;
  Hdr.CRC:=Byte(ModBus_CRC16(Hdr,SizeOf(Hdr)-1));
  Flag:='W';
  Modem.Write(Flag,1);
  Modem.Write(Hdr,SizeOf(Hdr));
  Modem.Write(Data,Hdr.DataSize);
  Flag:='V';
  Modem.Write(Flag,1);
  Inc(BytesO,2+SizeOf(_TLLHdr)+DataSize);
  Inc(PacketsO);
  TxBufEmpty:=False;
end;
{$ENDIF UseHDLC}

{ TPRT_ARQ }

constructor TPRT_ARQ.Create(PRT: TPRT_Abstract);
begin
  Self.PRT:=PRT;
  ASDs:=TList.Create;
end;

destructor TPRT_ARQ.Destroy;
var
  i:Integer;
begin
  for i:=0 to ASDs.Count-1 do FreeMem(ASDs[i],SizeOf(TARQSysData));
  ASDs.Free;
  ASDs:=nil;
  inherited;
end;

function TPRT_ARQ.GetASD(Addr: Integer): PARQSysData;
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
    end;
  end;
  Result:=CurASD;
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
    Size:=PRT.Rx(Buf);
    // Frame corrupted?
{$IFDEF UseHDLC}
    if Size<0 then begin
{$ELSE}
    if Buf.CRC<>ModBus_CRC16(Ptr(Cardinal(@Buf)+2)^,Size-2) then begin
{$ENDIF}
      // Frame corrupted!
      Log('ARG-Rx: Corrupted frame');
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

function TPRT_ARQ.Rx(var Data): Integer;
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

procedure TPRT_ARQ.sendPacket(var P: _TPacket; Size: Integer);
begin
  P.HdrCRC:=Byte(PPP_FCS16(P.Hdr,SizeOf(P.Hdr)));
{$IFNDEF UseHDLC}
  P.CRC:=ModBus_CRC16(Ptr(Cardinal(@P)+2)^,Size-2);
{$ENDIF}
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
  p.LastACKTime:=0;
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

function TPRT_Test.Rx(var Data): Integer;
begin
  Result:=Length(Buf);
  Move(Buf[0],Data,Result);
  SetLength(Buf,0);
  Inc(BytesI,Result);
  Inc(PacketsI);
end;

procedure TPRT_Test.Tx(const Data; DataSize: Integer);
begin
  SetLength(Buf,DataSize);
  Move(Data,Buf[0],DataSize);
  Inc(BytesO,DataSize);
  Inc(PacketsO);
end;

end.

unit UNetW;

interface

uses
  Classes;

const
  MyAddr = 1;
  MaxPacketDataSize = 1000;

// Обработка пакета, полученного по соединению Conn
function NetW_receive(Conn:Pointer; const Data; DataSize:Integer):Boolean;

// Получение пакета для передачи по соединению Conn
function NetW_transmit(Conn:Pointer; var Buf; BufSize:Integer):Integer;

// Принудительное ассоциирование соединения с адресом/адресами
procedure NetW_assocConn(Conn:Pointer; Addr:Byte);

// Освобождение ресурсов, ассоциированных с соединением Conn
procedure NetW_remConn(Conn:Pointer);

type
  TService = class(TObject)
  public
    ID:Byte;
    function HaveDataToTransmit:Boolean;virtual;
    procedure getDataToTransmit(var Data:String; MaxSize:Integer);virtual;
    procedure receiveData(const Data:String);virtual;abstract;
  end;

  FProcessIO = procedure of object;

procedure NetW_addProcessIO(IO:FProcessIO);
procedure NetW_remProcessIO(IO:FProcessIO);
procedure NetW_ProcessIO;

procedure NetW_addService(Addr:Byte; Svc:TService);
procedure NetW_remService(Addr:Byte; Svc:TService);

function CreateSortedStringList:TStringList;

implementation

uses
  SysUtils, Contnrs, UCRC;

var
  // для каждого сетевого адреса [0..255] список сервисов (TService)
  SvcList: array[0..255] of TStringList;
  // справочник соответствия [соединение -> сетевой адрес]
  // ключ: адрес объекта "соединение"
  // значение: сетевой адрес удалённого устройства
  ConnList: TStringList;
  // перечень методов-обработчиков ввода-вывода FProcessIO
  // ключ: хеш-код метода
  // значение: метод
  ListIO: TStringList;

function PtrToHex(Ptr:Pointer):String;
begin
  Result:=IntToHex(Integer(Ptr),8);
end;

function MethodToHex(pMethod:Pointer):String;
type
  PI64 = ^Int64;
begin
  Result:=IntToHex(PI64(pMethod)^,SizeOf(TMethod)*2);
end;

function CreateSortedStringList:TStringList;
begin
  Result:=TStringList.Create;
  Result.Duplicates:=dupAccept; // to enable duplicated Objects???
  Result.Sorted:=True;
end;

type
  PFProcessIO = ^FProcessIO;

procedure NetW_addProcessIO(IO:FProcessIO);
var
  P:PFProcessIO;
  M:TMethod absolute IO;
begin
  GetMem(P,SizeOf(FProcessIO));
  P^:=IO;
  ListIO.AddObject(MethodToHex(@M),Pointer(P));
end;

procedure NetW_remProcessIO(IO:FProcessIO);
var
  S:String;
  i:Integer;
  P:PFProcessIO;
  M:TMethod absolute IO;
begin
  S:=MethodToHex(@M);
  if not ListIO.Find(S,i) then exit;
  P:=Pointer(ListIO.Objects[i]);
  FreeMem(P);
  ListIO.Delete(i);
end;

procedure NetW_ProcessIO;
var
  i:Integer;
begin
  i:=ListIO.Count-1;
  while i>=0 do
  begin
    PFProcessIO(ListIO.Objects[i])^();
    Dec(i);
  end;
end;

procedure NetW_addService(Addr:Byte; Svc:TService);
var
  L:TStringList;
begin
  L:=TStringList(SvcList[Addr]);
  if L=nil then begin L:=CreateSortedStringList; SvcList[Addr]:=L; end;
  L.AddObject(Chr(Svc.ID),Svc);
end;

procedure NetW_remService(Addr:Byte; Svc:TService);
var
  L:TStringList;
  i:Integer;
begin
  L:=TStringList(SvcList[Addr]);
  if (L<>nil) and L.Find(Chr(Svc.ID),i)
  then L.Delete(i);
end;

function NetW_getService(Addr,SvcID:Byte):TService;
var
  L:TStringList;
  i:Integer;
begin
  L:=TStringList(SvcList[Addr]);
  if (L<>nil) and L.Find(Chr(SvcID),i)
  then Result:=TService(L.Objects[i])
  else Result:=nil;
end;

procedure NetW_remConn(Conn:Pointer);
var
  i:Integer;
  S:String;
begin
  //exit;
  S:=PtrToHex(Conn);
  if not ConnList.Find(S,i) then exit;
  TList(ConnList.Objects[i]).Free;
  ConnList.Delete(i);
end;

procedure NetW_assocConn(Conn:Pointer; Addr:Byte);
var
  i:Integer;
  S:String;
  addrs:TList;
begin
  S:=PtrToHex(Conn);
  if not ConnList.Find(S,i)
  then begin
    addrs:=TList.Create();
    i:=ConnList.AddObject(S,addrs);
  end;
  addrs:=TList(ConnList.Objects[i]);
  if addrs.IndexOf(Pointer(Addr))<0
  then addrs.Add(Pointer(Addr));
end;

function SetConnAssoc(Conn:Pointer; Addr, SvcID:Byte):TService;
begin
  NetW_assocConn(Conn,Addr);
  Result:=NetW_getService(Addr,SvcID);
end;

function GetConnSvcToTx(Conn:Pointer; var Addr, SvcID:Byte):TService;
var
  iConn,iSvc,iAddr,tmpAddr:Integer;
  L:TStringList;
  addrs:TList;
  NoSvc:Boolean;
begin
  Result:=nil;
  if not ConnList.Find(PtrToHex(Conn),iConn) then exit;
  addrs:=TList(ConnList.Objects[iConn]);
  for iSvc:=0 to 255 do
  begin
    NoSvc:=true;
    for iAddr:=addrs.Count-1 downto 0 do
    begin
      tmpAddr:=Byte(addrs[iAddr]);
      L:=TStringList(SvcList[tmpAddr]);
      if iSvc>=L.Count then continue;
      NoSvc:=false;
      if TService(L.Objects[iSvc]).HaveDataToTransmit() then
      begin
        Result:=TService(L.Objects[iSvc]);
        Addr:=tmpAddr;
        SvcID:=Result.ID;
        addrs.Move(iAddr,0);
        exit;
      end;
    end;
    if NoSvc
    then break;
  end;
end;

{ TService }

procedure TService.getDataToTransmit(var Data: String; MaxSize: Integer);
begin
  // do nothing
end;

function TService.HaveDataToTransmit: Boolean;
begin
  Result:=False;
end;

//*****************

type
  TPacketHeader = packed record
    ToAddr,FromAddr,ServiceID:Byte;
  end;

  TPacket=record
    Hdr:TPacketHeader;
    Data:packed array[0..MaxPacketDataSize-1] of Byte;
  end;

  PPacket = ^TPacket;

function NetW_receive(Conn:Pointer; const Data; DataSize:Integer):Boolean;
var
  p:PPacket;
  s:String;
  Svc:TService;
begin
  if(DataSize<=0) then
  begin
    Result:=False;
    exit;
  end;
  if FCS_is_OK(Data,DataSize) then
  begin
    Result:=True;
    p := PPacket(@Data);
    if (p.Hdr.ToAddr = MyAddr) or (p.Hdr.ToAddr = 0) then
    begin
      Svc:=SetConnAssoc(Conn,p.Hdr.FromAddr,p.Hdr.ServiceID);
      if Assigned(Svc) then
      begin
        Dec(DataSize,(SizeOf(TPacketHeader)+2));
        SetLength(s,DataSize);
        if(DataSize>0) then Move(P.Data,s[1],DataSize);
        Svc.receiveData(S);
      end;
    end;
  end
  else
    Result:=False; //dododo
end;

function NetW_transmit(Conn:Pointer; var Buf; BufSize:Integer):Integer;
type
  PWord = ^Word;
var
  Svc:TService;
  S:String;
  P:PPacket;
begin
  Result:=0;
  P:=@Buf;
  Svc:=GetConnSvcToTx(Conn,P.Hdr.ToAddr,P.Hdr.ServiceID);
  if Assigned(Svc) then begin
    Svc.getDataToTransmit(S,BufSize-(SizeOf(TPacketHeader)+2));
    Result:=SizeOf(TPacketHeader)+Length(S);
    P:=@Buf;
    P.Hdr.FromAddr:=MyAddr;
    if Length(S)>0 then Move(S[1],P.Data,Length(S));
    PWord(Integer(@Buf)+Result)^ := PPP_FCS16(Buf,Result);
    Inc(Result,2);
  end;
end;

initialization
  ConnList:=CreateSortedStringList;
  ListIO:=CreateSortedStringList;
finalization
  ListIO.Free;
  ConnList.Free;
end.

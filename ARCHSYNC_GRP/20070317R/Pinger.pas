unit Pinger;

interface

uses SysUtils,WinSock,Windows;

type
  ip_option_information = record
    // ���������� ��������� IP (����������
    // ���� ��������� � ������ ����� ������ � RFC791.
    Ttl : u_char;           // ����� ����� (������������ traceroute-��)
    Tos : u_char;           // ��� ������������, ������ 0
    Flags : u_char;         // ����� ��������� IP, ������ 0
    OptionsSize : u_char;   // ������ ������ � ���������, ������ 0, �������� 40
    OptionsData : PChar;    // ��������� �� ������
  end;

  icmp_echo_reply = record
    Address : DWORD;     // ����� �����������
    Status : u_long;     // IP_STATUS (��. ����)
    RTTime : u_long;     // ����� ����� ���-�������� � ���-�������
    // � �������������
    DataSize : u_short;  // ������ ������������ ������
    Reserved : u_short;  // ���������������
    Data : Pointer;      // ��������� �� ������������ ������
    Options : ip_option_information; // ���������� �� ��������� IP
  end;

  PIPINFO = ^ip_option_information;
  PVOID = Pointer;

  function Ping(const IPStr:AnsiString; IP,Timeout:Cardinal):Integer;
  function IcmpCreateFile() : THandle; stdcall; external 'ICMP.DLL' name 'IcmpCreateFile';
  function IcmpCloseHandle(IcmpHandle : THandle) : BOOL; stdcall; external 'ICMP.DLL'
                  name 'IcmpCloseHandle';
  function IcmpSendEcho(
    IcmpHandle : THandle;    // handle, ������������ IcmpCreateFile()
    DestAddress : u_long;    // ����� ���������� (� ������� �������)
    RequestData : PVOID;     // ��������� �� ���������� ������
    RequestSize : Word;      // ������ ���������� ������
    RequestOptns : PIPINFO;  // ��������� �� ���������� ���������
                             // ip_option_information (����� ���� nil)
    ReplyBuffer : PVOID;     // ��������� �� �����, ���������� ������.
    ReplySize : DWORD;       // ������ ������ �������
    Timeout : DWORD          // ����� �������� ������ � �������������
  ) : DWORD; stdcall; external 'ICMP.DLL' name 'IcmpSendEcho';

implementation

//���� ������ � ���� Status ��������� icmp_echo_reply, ���� ����� �� �������� "���-�������"
//(IP_STATUS):
const
  IP_STATUS_BASE = 11000;
  IP_SUCCESS = 0;
  IP_BUF_TOO_SMALL = 11001;
  IP_DEST_NET_UNREACHABLE = 11002;
  IP_DEST_HOST_UNREACHABLE = 11003;
  IP_DEST_PROT_UNREACHABLE = 11004;
  IP_DEST_PORT_UNREACHABLE = 11005;
  IP_NO_RESOURCES = 11006;
  IP_BAD_OPTION = 11007;
  IP_HW_ERROR = 11008;
  IP_PACKET_TOO_BIG = 11009;
  IP_REQ_TIMED_OUT = 11010;
  IP_BAD_REQ = 11011;
  IP_BAD_ROUTE = 11012;
  IP_TTL_EXPIRED_TRANSIT = 11013;
  IP_TTL_EXPIRED_REASSEM = 11014;
  IP_PARAM_PROBLEM = 11015;
  IP_SOURCE_QUENCH = 11016;
  IP_OPTION_TOO_BIG = 11017;
  IP_BAD_DESTINATION = 11018;
  IP_ADDR_DELETED = 11019;
  IP_SPEC_MTU_CHANGE = 11020;
  IP_MTU_CHANGE = 11021;
  IP_UNLOAD = 11022;
  IP_GENERAL_FAILURE = 11050;
  MAX_IP_STATUS = IP_GENERAL_FAILURE;
  IP_PENDING = 11255;

function Ping(const IPStr:AnsiString; IP,Timeout:Cardinal):Integer;
type
  T4Byte=packed array[0..3] of Byte;
var
  WrapIP:T4Byte absolute IP;
  hIP : THandle;
  pingBuffer : array [0..31] of Char;
  pIpe : ^icmp_echo_reply;
  pHostEn : PHostEnt;
  wVersionRequested : WORD;
  lwsaData : WSAData;
  error : DWORD;
  destAddress : In_Addr;

begin
  Result:=0;
  pIpe:=nil;
  hIP:=0;
  try
    GetMem( pIpe, sizeof(icmp_echo_reply) + sizeof(pingBuffer));
    // ������� handle
    hIP := IcmpCreateFile();

    pIpe.Data := @pingBuffer;
    pIpe.DataSize := sizeof(pingBuffer);

    wVersionRequested := MakeWord(1,1);
    error := WSAStartup(wVersionRequested,lwsaData);
    if (error <> 0) then exit;

    try
      pHostEn := gethostbyname(PChar(IPStr));
      error := WSAGetLastError();
      Result:=error;
      if (error <> 0) then exit;
      destAddress := PInAddr(pHostEn^.h_addr_list^)^;
      // �������� ping-�����
      IcmpSendEcho(hIP,
        destAddress.S_addr,
        @pingBuffer,
        sizeof(pingBuffer),
        Nil,
        pIpe,
        sizeof(icmp_echo_reply) + sizeof(pingBuffer),
        Timeout
      );
      error := GetLastError();
      if (error <> 0) or
        (WrapIP[0]<>T4Byte(pIpe.Address)[3]) or
        (WrapIP[1]<>T4Byte(pIpe.Address)[2]) or
        (WrapIP[2]<>T4Byte(pIpe.Address)[1]) or
        (WrapIP[3]<>T4Byte(pIpe.Address)[0])
      then error:=IP_DEST_HOST_UNREACHABLE;
      Result:=error;
    finally
      WSACleanup();
    end;
  finally
    if hIP<>0 then IcmpCloseHandle(hIP);
    if pIpe<>nil then FreeMem(pIpe);
  end;
end;

end.

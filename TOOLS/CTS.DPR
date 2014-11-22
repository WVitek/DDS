program CTS;
{$APPTYPE CONSOLE}
uses
  SysUtils,
  Windows;

var
  hCom:THandle;
  ModemStatus:Cardinal;

begin
  hCom := CreateFile(PChar(ParamStr(1)),
    GENERIC_READ or GENERIC_WRITE,
    0,    // comm devices must be opened w/exclusive-access
    nil, // no security attrs
    OPEN_EXISTING, // comm devices must use OPEN_EXISTING
    0,    // not overlapped I/O
    0  // hTemplate must be NULL for comm devices
  );
  if (hCom = INVALID_HANDLE_VALUE) then Halt(255);
  GetCommModemStatus(hCom,ModemStatus);
  CloseHandle(hCom);
  if ModemStatus and MS_RLSD_ON <> 0
  then Halt(1)
  else Halt(0);
end.

program Delay;
{$APPTYPE CONSOLE}
uses
  Windows,
  SysUtils;

begin
  // Insert user code here
  Sleep(StrToInt(ParamStr(1)));
end. 
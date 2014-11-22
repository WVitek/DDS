program Minute;
{$APPTYPE CONSOLE}
uses
  Windows;
var
  ST0,ST1:TSystemTime;
begin
  GetLocalTime(ST0);
  repeat
    Sleep(1000);
    GetLocalTime(ST1);
  until ST0.wMinute<>ST1.wMinute;
end.

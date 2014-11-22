program Connect;
{$APPTYPE CONSOLE}
uses
  Common;
begin
  Halt(SendASCmd(ascmdConnect,IntParam(ParamStr(1))));
end.


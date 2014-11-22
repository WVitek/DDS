program ChkConn;
{$APPTYPE CONSOLE}
uses
  Common;
begin
  Halt(SendASCmd(ascmdCheckConnection,IntParam(ParamStr(1))));
end.


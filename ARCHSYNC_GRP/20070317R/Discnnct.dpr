program Discnnct;
{$APPTYPE CONSOLE}
uses
  Common;
begin
  Halt(SendASCmd(ascmdDisconnect,IntParam(ParamStr(1))));
end.


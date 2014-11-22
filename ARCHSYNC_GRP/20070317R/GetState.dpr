program GetState;
{$APPTYPE CONSOLE}
uses
  Common;
begin
  Halt(SendASCmd(ascmdGetState,IntParam(ParamStr(1))));
end.


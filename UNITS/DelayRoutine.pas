unit DelayRoutine;

interface

uses Windows,Forms;

procedure Delay(MSec:Integer);

implementation

procedure Delay(MSec:Integer);
var
  Freq,Cnt,StopCnt:Int64;
begin
  QueryPerformanceCounter(Cnt);
  QueryPerformanceFrequency(Freq);
  StopCnt:=Cnt+Trunc(MSec*0.001*Freq);
  repeat
    QueryPerformanceCounter(Cnt);
    if Cnt>=StopCnt then break;
    Application.ProcessMessages;
  until False;
end;

end.
 
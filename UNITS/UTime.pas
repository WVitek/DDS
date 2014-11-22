unit UTime;

interface

type
  TIME_STAMP = Int64;

var
  GetMyTime:function:TDateTime;

function MyTimeStamp:TIME_STAMP;
function UTCTimeStamp:TIME_STAMP;

procedure SetMyTimeType(MTT:Integer);
function GetLocTime:TDateTime;
function GetUTCTime:TDateTime;
function GetMSKTime:TDateTime;
function GetNullTime:TDateTime;

procedure SetUTCTime(Time:TDateTime);
procedure SetLocTime(Time:TDateTime);

function ToTimeStamp(const Time:TDateTime):TIME_STAMP;
function ToDateTime(const Time:TIME_STAMP):TDateTime;

const
  nSecsPerDay=24*60*60;
  LLTicksPerSec=1000;
  LLTicksPerDay=nSecsPerDay*LLTicksPerSec;
  dtLLTickPeriod=1/LLTicksPerDay;
  dtOneSecond=1/nSecsPerDay;
//  dtOneMSec=1/MSecsPerDay;
  mttLocal=0;
  mttUTC=1;
  mttMSK=2;
  mttNull=High(Integer);

const
// Timeouts
  toTypeMask  = $C0000000;
{
  toTypeNext  = 0xC000
  toNext10ms  = 0xC001
  toNext100ms = 0xC002
  toNextSecond= 0xC003
//}
  toTypeMs    = $00000000;
  toTypeSec   = $40000000;

type
  TTimeout = type Cardinal;

  TTimeoutObj = object
  protected
    StopTime:TIME_STAMP;
  public
    procedure start(Timeout:TTimeout);
    procedure stop();
    procedure setSignaled(Signaled:Boolean = True);
    function IsSignaled():Boolean;
    function wait(Timeout:TTimeout):Boolean;
  end;

implementation

uses Windows,SysUtils;

var
  MSKTZI:TIME_ZONE_INFORMATION;

function ToDateTime(const Time:TIME_STAMP):TDateTime;
begin
  Result:=Time*dtLLTickPeriod;
end;

function ToTimeStamp(const Time:TDateTime):TIME_STAMP;
begin
  Result:=Round(Time*LLTicksPerDay);
end;

//***************** TTimeoutObj

procedure TTimeoutObj.setSignaled(Signaled:Boolean = True);
begin
  if Signaled
  then StopTime := 0
  else StopTime := High(TIME_STAMP);
end;

procedure TTimeoutObj.start(Timeout: TTimeout);
var
  T:TTimeout;
begin
  T:=Timeout and not toTypeMask;
  case Timeout and toTypeMask of
  toTypeMs:
    StopTime := UTCTimeStamp+T;
  toTypeSec:
    StopTime := UTCTimeStamp+T*LLTicksPerSec;
  end;
end;

procedure TTimeoutObj.stop;
begin
  setSignaled(False);
end;

function TTimeoutObj.IsSignaled():Boolean;
begin
  Result:=StopTime <= UTCTimeStamp;
end;

function TTimeoutObj.wait(Timeout: TTimeout): Boolean;
var
  too:TTimeoutObj;
begin
  Result:=False;
  too.start(Timeout);
  while True do begin
    Result := IsSignaled();
    if Result or too.IsSignaled() then break;
    Windows.Sleep(1);
  end;
end;

// ****************************************

function UTCTimeStamp:TIME_STAMP;
begin
  Result:=Round(GetUTCTime*LLTicksPerDay);
end;

function MyTimeStamp:TIME_STAMP;
begin
  Result:=Round(GetMyTime*LLTicksPerDay);
end;

procedure SetMyTimeType(MTT:Integer);
begin
  case MTT of
  mttLocal:GetMyTime:=Now;
  mttUTC:  GetMyTime:=GetUTCTime;
  mttMSK:  GetMyTime:=GetMSKTime;
  else     GetMyTime:=GetNullTime;
  end;
end;

function GetNullTime:TDateTime;
begin
  Result:=0;
end;

function GetMSKTime:TDateTime;
var
  UTC,MSK:TSystemTime;
begin
  GetSystemTime(UTC);
  SystemTimeToTzSpecificLocalTime(@MSKTZI,UTC,MSK);
  Result:=SystemTimeToDateTime(MSK);
end;

function GetUTCTime:TDateTime;
var
  ST:TSystemTime;
begin
  GetSystemTime(ST);
  Result:=SystemTimeToDateTime(ST);
end;

procedure SetUTCTime(Time:TDateTime);
var
  ST:TSystemTime;
begin
  DateTimeToSystemTime(Time,ST);
  SetSystemTime(ST);
end;

function GetLocTime:TDateTime;
begin
  Result:=Now;
end;

procedure SetLocTime(Time:TDateTime);
var
  ST:TSystemTime;
begin
  DateTimeToSystemTime(Time,ST);
  SetLocalTime(ST);
end;

initialization
  MSKTZI.Bias:=-180;
//  TZI.StandardName:='Московское время (зима)';
  MSKTZI.StandardDate.wMonth:=10;
  MSKTZI.StandardDate.wDay:=5;
  MSKTZI.StandardDate.wHour:=3;
  MSKTZI.StandardBias:=0;
//  TZI.DaylightName:='Московское время (лето)';
  MSKTZI.DaylightDate.wMonth:=3;
  MSKTZI.DaylightDate.wDay:=5;
  MSKTZI.DaylightDate.wHour:=2;
  MSKTZI.DaylightBias:=-60;
  SetMyTimeType(mttNull);
end.

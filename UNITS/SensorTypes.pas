unit SensorTypes;

interface

uses
  Classes;

type
  CSensor = class of TSensor;

  TSensorFixed24=class;
  TSensorFloat32=class;
{$IFDEF Sensor24}
  TMySensor = TSensorFixed24;
{$ENDIF}
{$IFDEF Sensor32}
  TMySensor = TSensorFloat32;
{$ENDIF}

  TAnalogData=record
    case Cardinal of
    0:(Value:Single);
    1:(Flags:Cardinal);
  end;

  TSensor=class(TObject)
    Num:Byte;
    TrackID:Integer;
    constructor CreateSensor(aNum:Byte;aTrackID:Integer);virtual;
    constructor Create(aNum:Byte;aTrackID:Integer;ARecsPerDay:Integer);virtual;abstract;
    function FormatDataN(const SrcBuf; var DstBuf; SrcSize:Integer):TDateTime;virtual;abstract;
    function FormatData(const SrcBuf; var DstBuf):TDateTime;virtual;abstract;
    function GetRecsPerDay:Integer;virtual;abstract;
    class function GetRecSize:Integer;virtual;abstract;
    class procedure GetAD(const Data:WideString; i:Integer;
      var AD:TAnalogData);virtual;abstract;
    class procedure SetAD(var Data:WideString; i:Integer;
      const AD:TAnalogData);virtual;abstract;
  end;

  TSensorFixed24=class(TSensor)
    V2,V1:Single;
    NotFirst:Boolean;
    RecsPerDay:Integer;
    constructor Create(aNum:Byte;aTrackID:Integer;ARecsPerDay:Integer);override;
    function GetRecsPerDay:Integer;override;
    function FormatData(const SrcBuf; var DstBuf):TDateTime;override;
    function FormatDataN(const SrcBuf; var DstBuf; Cnt:Integer):TDateTime;override;
    class function GetRecSize:Integer;override;
    class procedure GetAD(const Data:WideString; i:Integer;
      var AD:TAnalogData);override;
    class procedure SetAD(var Data:WideString; i:Integer;
      const AD:TAnalogData);override;
  private
    class procedure SingleToFixed24(Src:Single; var Dst);
  end;

  TSensorFloat32=class(TSensor)
    V2,V1:Single;
    NotFirst:Boolean;
    RecsPerDay:Integer;
    constructor Create(aNum:Byte;aTrackID:Integer;ARecsPerDay:Integer);override;
    function FormatData(const SrcBuf; var DstBuf):TDateTime;override;
    function FormatDataN(const SrcBuf; var DstBuf; Cnt:Integer):TDateTime;override;
    class function GetRecSize:Integer;override;
    function GetRecsPerDay:Integer;override;
    class procedure GetAD(const Data:WideString; i:Integer;
      var AD:TAnalogData);override;
    class procedure SetAD(var Data:WideString; i:Integer;
      const AD:TAnalogData);override;
  end;

  TEventData=packed record
    TimeOffsetMs:Cardinal;
    Channel:Word;
    State:Byte;
  end;
  PEventData=^TEventData;

  TEventSource=class(TObject)
    Num:Byte;
    TrackID:Integer;
    RecsPerDay:Integer;
    constructor Create(aNum:Byte;aTrackID:Integer;ARecsPerDay:Integer);
    function GetRecsPerDay:Integer;
    class function GetRecSize:Integer;
    class procedure GetED(const Data:WideString; i:Integer;
      var ED:TEventData);
    class procedure SetED(var Data:WideString; i:Integer;
      const ED:TEventData);
  end;

  TPipTime = packed record
    Year,Month,Day,Hour,Min,Sec,Sec100:Byte;
  end;
  TLdrData=packed record
    Number:Byte;
    Time:TPipTime;
    p:Single;
  end;
  TLdrDataN=packed record
    Number:Byte;
    Time:TPipTime;
    p:array[0..255] of Single;
  end;

function ValidAD(const AD:TAnalogData):Boolean;
procedure SetSensorRepair(var AD:TAnalogData);
procedure SetErrUnknown(var AD:TAnalogData);
procedure SetErrAnalog(var AD:TAnalogData);
procedure SetErrADCRange(var AD:TAnalogData);
procedure SetErrADCComm(var AD:TAnalogData);
function GetADMsg(const AD:TAnalogData):String;

const
  MemSignedZero:Cardinal=$80000000;
  // constansts for Single
  smUnknown=0;
  smExpMask=$7FC00000;
  smSNaN   =$7F800000;
  smErrMask     =smExpMask or $0D;
  smErrUnknown  =smSNaN or $01 or $00;
  smErrADCComm  =smSNaN or $01 or $04;
  smErrADCRange =smSNaN or $01 or $08;
  smErrAnalog   =smSNaN or $01 or $0C;
  smSensorRepair=smSNaN or $02;
var
  JumpLimit:Single;
  SignedZero:Single absolute MemSignedZero;

implementation

uses Windows,SysUtils;

const
  // Fixed24 flags
  sfStateMask   =$F00000;
  sfUnknown     =$000000;
  sfRepair      =$C00000;
  sfNormal      =$800000;
  sfError       =$400000;
  sfErrUnknown  =$400000;
  sfErrADCComm  =$500000;
  sfErrADCRange =$600000;
  sfErrAnalog   =$700000;

function ValidAD(const AD:TAnalogData):Boolean;
begin
  Result:=(AD.Flags<>0) and (AD.Flags and smExpMask<>smSNaN);
end;

function GetADMsg(const AD:TAnalogData):String;
begin
  if ValidAD(AD) then Result:=FloatToStr(AD.Value)
  else if AD.Flags and smSensorRepair=smSensorRepair
  then Result:='ремонт'
  else begin
    case AD.Flags and smErrMask of
    smErrUnknown: Result:='сбой';
    smErrADCComm: Result:='сбой связи с АЦП';
    smErrADCRange:Result:='перегрузка АЦП';
    smErrAnalog:  Result:='аналоговый сбой';
    else Result:='нет данных'
    end;
  end;
end;

procedure SetSensorRepair(var AD:TAnalogData);
begin
  AD.Flags:=AD.Flags or smSensorRepair;
end;

procedure SetErrUnknown(var AD:TAnalogData);
begin
  AD.Flags:=smErrUnknown;
end;

procedure SetErrAnalog(var AD:TAnalogData);
begin
  AD.Flags:=smErrAnalog;
end;

procedure SetErrADCRange(var AD:TAnalogData);
begin
  AD.Flags:=smErrADCRange;
end;

procedure SetErrADCComm(var AD:TAnalogData);
begin
  AD.Flags:=smErrADCComm;
end;

{ TSensorFixed24 }

constructor TSensorFixed24.Create(aNum: Byte; aTrackID,
  ARecsPerDay: Integer);
begin
  CreateSensor(aNum,aTrackID);
  RecsPerDay:=aRecsPerDay;
end;

function TSensorFixed24.FormatData;
const
  Scale=1 shl 10;
type
  TOutData=Byte;
var
  LdrData:^TLdrData;
  OutData:^TOutData;
  OD:Cardinal;
  ST:TSystemTime;
  V0:Single;
  FlagsV0:Cardinal absolute V0;
begin
  LdrData:=@SrcBuf;
  OutData:=@DstBuf;
  ST.wYear:=LdrData.Time.Year+1900;
  ST.wMonth:=LdrData.Time.Month;
  ST.wDay:=LdrData.Time.Day;
  ST.wHour:=LdrData.Time.Hour;
  ST.wMinute:=LdrData.Time.Min;
  ST.wSecond:=LdrData.Time.Sec;
  ST.wMilliseconds:=LdrData.Time.Sec100*10;
  Result:=SystemTimeToDateTime(ST);
  V0:=LdrData.p;
  if FlagsV0 and smExpMask=smSNAN
  then SingleToFixed24(V0,OD)
  else begin
    try
      if NotFirst=False then begin
        V2:=V0; V1:=V0; NotFirst:=True;
      end;
      OD:=(Round(V1*Scale) and $03FFFF);
      if (Abs(V2-V1)>JumpLimit) and (Abs(V2-V0)<JumpLimit)
      then OD:=OD or sfUnknown
      else begin
        OD:=OD or sfNormal;
        V2:=V1;
      end;
      V1:=V0;
    except
      NotFirst:=False;
    end;
  end;
  Move(OD,OutData^,3);
end;

class procedure TSensorFixed24.GetAD(const Data: WideString;
  i: Integer; var AD: TAnalogData);
var
  P:PInteger;
  ip:Integer absolute P;
  V:Integer;
begin
  P:=PInteger(@(Data[1]));
  Inc(ip,i*3);
  V:=P^ and $00FFFFFF;
  if V and sfStateMask=sfNormal then begin
    V:=V and $3FFFF;
    if V and $20000<>0 // если установлен знаковый бит
    then V:=V or Integer($FFFC0000); // то расширяем его
    AD.Value:=V*(1/(1 shl 10));
    if AD.Flags=0 then AD.Value:=SignedZero;
  end
  else begin
    case V and sfStateMask of
    sfErrADCComm:  AD.Flags:=smErrADCComm;
    sfErrADCRange: AD.Flags:=smErrADCRange;
    sfErrAnalog:   AD.Flags:=smErrAnalog;
    sfUnknown:     AD.Flags:=smUnknown;
    else AD.Flags:=smErrUnknown;
    end;
    if V and sfRepair=sfRepair
    then AD.Flags:=AD.Flags or smSensorRepair;
  end;
end;

class function TSensorFixed24.GetRecSize: Integer;
begin
  Result:=3;
end;

class procedure TSensorFixed24.SingleToFixed24(Src: Single;
  var Dst);
var
  iSrc:Cardinal absolute Src;
  V:Integer;
begin
  if iSrc and smExpMask<>smSNaN then begin
    try
      if Src<-128 then Src:=-128
      else if 128<Src then Src:=128;
      V:=Trunc(Src*(1 shl 10));
    except
      V:=0;
    end;
    V:=sfNormal or (V and $03FFFF);
  end
  else begin
    V:=0;
    case iSrc and smErrMask of
    smErrADCComm:  V:=sfErrADCComm;
    smErrADCRange: V:=sfErrADCRange;
    smErrAnalog:   V:=sfErrAnalog;
    else V:=sfErrUnknown;
    end;
//    if iSrc and smSensorRepair<>0 then V:=sfRepair;
  end;
  Move(V,Dst,3);
end;

function TSensorFixed24.GetRecsPerDay: Integer;
begin
  Result:=RecsPerDay;
end;

class procedure TSensorFixed24.SetAD(var Data: WideString;
  i: Integer; const AD: TAnalogData);
var
  P:Pointer;
  ip:Integer absolute P;
begin
  P:=@(Data[1]);
  Inc(ip,i*3);
  SingleToFixed24(AD.Value,P^);
end;

function TSensorFixed24.FormatDataN(const SrcBuf; var DstBuf;
  Cnt: Integer): TDateTime;
const
  Scale=1 shl 10;
type
  TOutData=Byte;
var
  LdrData:^TLdrDataN;
  OutData:^TOutData;
  OD:Cardinal;
  ST:TSystemTime;
  V0:Single;
  FlagsV0:Cardinal absolute V0;
  i:Integer;
begin
  LdrData:=@SrcBuf;
  OutData:=@DstBuf;
  ST.wYear:=LdrData.Time.Year+1900;
  ST.wMonth:=LdrData.Time.Month;
  ST.wDay:=LdrData.Time.Day;
  ST.wHour:=LdrData.Time.Hour;
  ST.wMinute:=LdrData.Time.Min;
  ST.wSecond:=LdrData.Time.Sec;
  ST.wMilliseconds:=LdrData.Time.Sec100*10;
  Result:=SystemTimeToDateTime(ST);
  for i:=0 to Cnt-1 do
  begin
    V0:=LdrData.p[i];
    if FlagsV0 and smExpMask=smSNAN
    then SingleToFixed24(V0,OD)
    else begin
      try
        if NotFirst=False then begin
          V2:=V0; V1:=V0; NotFirst:=True;
        end;
        OD:=(Round(V1*Scale) and $03FFFF);
        if (Abs(V2-V1)>JumpLimit) and (Abs(V2-V0)<JumpLimit)
        then OD:=OD or sfUnknown
        else begin
          OD:=OD or sfNormal;
          V2:=V1;
        end;
        V1:=V0;
      except
        NotFirst:=False;
      end;
    end;
    Move(OD,OutData^,3);
    Inc(OutData,3);
  end;
end;

{ TSensorFloat32 }

constructor TSensorFloat32.Create(aNum: Byte; aTrackID,
  ARecsPerDay: Integer);
begin
  CreateSensor(aNum,aTrackID);
  RecsPerDay:=aRecsPerDay;
end;

function TSensorFloat32.FormatData(const SrcBuf; var DstBuf): TDateTime;
var
  LdrData:^TLdrData;
  ST:TSystemTime;
  OD:^Single;
  MemOD:^Cardinal absolute OD;
  V0:Single;
  MemV0:Cardinal absolute V0;
begin
  LdrData:=@SrcBuf;
  OD:=@DstBuf;
  ST.wYear:=LdrData.Time.Year+1900;
  ST.wMonth:=LdrData.Time.Month;
  ST.wDay:=LdrData.Time.Day;
  ST.wHour:=LdrData.Time.Hour;
  ST.wMinute:=LdrData.Time.Min;
  ST.wSecond:=LdrData.Time.Sec;
  ST.wMilliseconds:=LdrData.Time.Sec100*10;
  Result:=SystemTimeToDateTime(ST);
  V0:=LdrData.p;
  if MemV0 and smExpMask<>smSNAN then begin
    if V0=0 then V0:=1.5e-45;
    if NotFirst=False then begin
      V2:=V0; V1:=V0; NotFirst:=True;
    end;
    if (Abs(V2-V1)>JumpLimit) and (Abs(V2-V0)<JumpLimit)
    then MemOD^:=smErrUnknown
    else begin
      OD^:=V1;
      V2:=V1;
    end;
    V1:=V0;
  end
  else OD^:=V0;
end;

function TSensorFloat32.FormatDataN(const SrcBuf; var DstBuf;
  Cnt: Integer): TDateTime;
var
  LdrData:^TLdrDataN;
  ST:TSystemTime;
  OD:^Single;
  MemOD:^Cardinal absolute OD;
  V0:Single;
  MemV0:Cardinal absolute V0;
  i:Integer;
begin
  LdrData:=@SrcBuf;
  OD:=@DstBuf;
  ST.wYear:=LdrData.Time.Year+1900;
  ST.wMonth:=LdrData.Time.Month;
  ST.wDay:=LdrData.Time.Day;
  ST.wHour:=LdrData.Time.Hour;
  ST.wMinute:=LdrData.Time.Min;
  ST.wSecond:=LdrData.Time.Sec;
  ST.wMilliseconds:=LdrData.Time.Sec100*10;
  Result:=SystemTimeToDateTime(ST);
  for i:=0 to Cnt-1 do begin
    V0:=LdrData.p[i];
    if MemV0 and smExpMask<>smSNAN then begin
      if V0=0 then V0:=1.5e-45;
      if NotFirst=False then begin
        V2:=V0; V1:=V0; NotFirst:=True;
      end;
      if (Abs(V2-V1)>JumpLimit) and (Abs(V2-V0)<JumpLimit)
      then MemOD^:=smErrUnknown
      else begin
        OD^:=V1;
        V2:=V1;
      end;
      V1:=V0;
    end
    else OD^:=V0;
    Inc(OD);
  end;
end;

class procedure TSensorFloat32.GetAD(const Data: WideString;
  i: Integer; var AD: TAnalogData);
var
  P:PSingle;
begin
  P:=PSingle(@(Data[1]));
  Inc(P,i);
  AD.Value:=P^;
end;

class function TSensorFloat32.GetRecSize: Integer;
begin
  Result:=4;
end;

function TSensorFloat32.GetRecsPerDay: Integer;
begin
  Result:=RecsPerDay;
end;

class procedure TSensorFloat32.SetAD(var Data: WideString;
  i: Integer; const AD: TAnalogData);
var
  P:PSingle;
begin
  P:=PSingle(@(Data[1]));
  Inc(P,i);
  P^:=AD.Value;
end;

{ TSensor }

constructor TSensor.CreateSensor(aNum: Byte; aTrackID: Integer);
begin
  inherited Create;
  Num:=aNum;
  TrackID:=aTrackID;
end;

{ TEventSource }

constructor TEventSource.Create(aNum: Byte; aTrackID,
  ARecsPerDay: Integer);
begin
  Num:=aNum;
  TrackID:=aTrackID;
  RecsPerDay:=ARecsPerDay;
end;

class procedure TEventSource.GetED(const Data: WideString; i: Integer;
  var ED: TEventData);
var
  P:PEventData;
begin
  P:=PEventData(@(Data[1]));
  Inc(P,i);
  Move(P^,ED,SizeOf(ED));
end;

class function TEventSource.GetRecSize: Integer;
begin
  Result:=SizeOf(TEventData);
end;

function TEventSource.GetRecsPerDay: Integer;
begin
  Result:=RecsPerDay;
end;

class procedure TEventSource.SetED(var Data: WideString; i: Integer;
  const ED: TEventData);
var
  P:PEventData;
begin
  P:=PEventData(@(Data[1]));
  Inc(P,i);
  Move(ED,P^,SizeOf(ED));
end;

end.

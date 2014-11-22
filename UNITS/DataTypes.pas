unit DataTypes;

interface

const
  dtOneSecond=1/(24*60*60);
  dtOneMinute=1/(24*60);
  dtOneHour=1/24;
  dtOneDay=1;
  dtY2K=36526.0;
const
  // PIP-file flags
  pfOkData=$02;
  pfNoCarr=$04;
  pfEndDay=$80;

type
  TPipFileTime = packed object
    Year,Month,Day,Hour,Min,Sec:Byte;
  end;

  TPipTime = packed object(TPipFileTime)
    Sec100:Byte;
  end;

  TSclRec=packed record
    Number:Byte;
    Time:TPipTime;
    p:Single;
  end;

  TSclRecN=packed record
    Number:Byte;
    Time:TPipTime;
    p:array[0..255] of Single;
  end;

  TPipFileRec = packed record
    F1,F2:Byte;
    Time:TPipFileTime;
    p1,p2:Single;
  end;

  TPressure=packed record
    Flags:Byte;
    Pressure:Single;
  end;
  PPressure=^TPressure;

procedure NextPipTime(var PT:TPipTime; const Step:TPipTime);

implementation

procedure NextPipTime(var PT:TPipTime; const Step:TPipTime);
var
  Tmp:Integer;
begin
  // Sec100
  Tmp:=PT.Sec100+Step.Sec100;
  if Tmp<100 then begin PT.Sec100:=Tmp; Tmp:=0; end
  else begin PT.Sec100:=Tmp-100; Tmp:=1; end;
  // Sec
  Inc(Tmp,PT.Sec+Step.Sec);
  if Tmp<60 then begin PT.Sec:=Tmp; Tmp:=0; end
  else begin PT.Sec:=Tmp-60; Tmp:=1; end;
  // Min
  Inc(Tmp,PT.Min+Step.Min);
  if Tmp<60 then begin PT.Min:=Tmp; Tmp:=0; end
  else begin PT.Min:=Tmp-60; Tmp:=1; end;
  // Hour
  Inc(Tmp,PT.Hour+Step.Hour);
  if Tmp<60 then begin PT.Hour:=Tmp; Tmp:=0; end
  else begin PT.Min:=Tmp-60; Tmp:=1; end;
  // Day
  Inc(PT.Day,Step.Day+Tmp);
end;

end.

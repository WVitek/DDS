{$DEFINE UseDiff}
{.$DEFINE UseCorrelation}
unit UWaveFormComputer;

interface

uses
  Windows,
  Misc;

type
  TWaveFormComputer=object
  protected
    tf1,Int1:Double;
    tf2,Int2:Double;
    D1,A2,D2:PSingle;
    Data1,Appr2,Data2:TArrayOfSingle;
    Size:Integer;
    function CalcP2(const t,P1:Double):Double;
  public
    Alpha1,Alpha2:Double;
    procedure Init(
      const MaxTimeDelta, TimeDelta: Double;
      Src1,Src2:PSingle; ASize:Integer);
    function CalcCorrelation:Double;
    procedure GetDrawData(var dA2,dD2:TArrayOfSingle);
  public
    property pA2:PSingle read A2;
    property pD2:PSingle read D2;
  end;

implementation

{
Based on sample program for the book
NUMERICAL RECIPES IN PASCAL: THE ART OF SCIENTIFIC COMPUTING
by William H. Press, Saul A. Teukolsky, Brian P. Flannery,
and William T. Vetterling
Cambridge University Press, New York, 1989.
}
FUNCTION BesselI1(x: Double): Double;
CONST
  KA01=1/2.;
  KA03=1/16.;
  KA05=1/384.;
  KA07=1/18432.;
  KA09=1/1474560.;
  KA11=1/176947200.;
  KA13=1/29727129600.;
  KA15=1/6658877030400.;
VAR
  ax: double;
  y: double;
BEGIN
  IF (abs(x) < 3.75) THEN BEGIN
    y:=x*x;
    Result:=x*(KA01+y*(KA03+y*(KA05+y*(KA07+y*(KA09+y*(KA11+y*(KA13+y*KA15)))))));
  END
  ELSE BEGIN
    ax := abs(x); y := 3.75/ax;
    Result := exp(ax)/sqrt(ax) * (
      0.39894228 + y*(-0.3988024e-1 + y*(-0.362018e-2 + y*(
      0.163801e-2 + y*(-0.1031555e-1 + y*(0.2282967e-1 + y*(
      -0.2895312e-1 + y*(0.1787654e-1 - y*0.420059e-2)
      )))))));
    IF (x<0.0) THEN Result:=-Result
  END;
END;

procedure compensate(D:PSingle; n:Integer; Delta:Single);
begin
  while n>0 do begin
    D^:=D^+Delta;
    Inc(D); Dec(n);
  end;
end;

function Distance(D1,D2:PSingle; n:Integer):Double;
var
  i:Integer;
begin
  Result:=0;
  i:=n;
  while i>0 do begin
//    Result:=Result+D1^*D2^;
    Result:=Result+Sqr(D1^-D2^);
//    Result:=Result+Sqr(Sqr(D1^-D2^));
    dec(i); Inc(D1); Inc(D2);
  end;
  if Result>1e-16
//  then Result:=n/Sqrt(Sqrt(Result))
  then Result:=n/Sqrt(Result)
  else Result:=1e+4;
{
  if Result>0
  then Result:=n/Result
  else Result:=0;
}
end;

{$IFDEF UseDiff}
procedure CalcWaveData(Src,Dst:PSingle; n:Integer);
var
  S:PSingle;
  V0,DV,dDV:Double;
begin
  assert(n>1,'CalcWaveData: n<=1');
  S:=Src; Inc(S,n-1);
  V0:=Src^; dDV:=(S^-V0)/(n-1);
  DV:=0;
  while n>0 do begin
    Dst^:=Src^-(V0+DV);
    DV:=DV+dDV;
    Inc(Src); Inc(Dst); Dec(n);
  end;
end;
{$ELSE}
procedure CalcWaveData(Src,Dst:PSingle; n:Integer);
var
  P0:Single;
begin
  P0:=Src^;
  while n>0 do begin
    Dst^:=Src^-P0;
    Inc(Src); Inc(Dst); Dec(n);
  end;
end;
{$ENDIF}

function TWaveFormComputer.CalcP2(const t,P1:Double):Double;
var
  st,step,P0:Double;
begin
  if t=0 then begin
    Int1:=0;
    Int2:=0;
//    Result:=P1/exp(-Alpha2*tf1)*exp(-Alpha1*tf2));
    Result:=P1*exp(Alpha2*tf1 - Alpha1*tf2);
  end
  else begin
    st:=sqrt(2.*tf1*t+t*t);
    step:=Alpha2*tf1 * exp(-Alpha2*(tf1+t)) * BesselI1(Alpha2*st) / st;
    P0:=(P1-Int1)/(exp(-Alpha2*tf1)+step);
    Int1:=Int1+step*P0;
    //
    st:=sqrt(2.*tf2*t+t*t);
    step:=Alpha1*tf2 * exp(-Alpha1*(tf2+t)) * BesselI1(Alpha1*st) / st;
    Int2:=Int2+step*P0;
    Result:=P0*exp(-Alpha1*tf2) + Int2;
  end;
end;

function TWaveFormComputer.CalcCorrelation;
var
  t:Double;
  PU,PV:PSingle;
  n:Integer;
  Mu1,Sigma1:Double;
  Mu2,Sigma2:Double;
begin
  // Calculate A2 waveform
  PU:=D1; PV:=A2; n:=Size; t:=0;
  while n>0 do begin
    PV^:=CalcP2(t,PU^);
    t:=t+1.0; inc(PV); inc(PU); dec(n);
  end;
  // Compute similarity :-)
{$IFDEF UseCorrelation}
  CalcMuSigma(A2,Size,Mu1,Sigma1);
  CalcMuSigma(D2,Size,Mu2,Sigma2);
  if (Sigma1>0) and (Sigma2>0)
  then Result:=Cov(A2,D2,Mu1,Mu2,Size)/(Sigma1*Sigma2)
  else Result:=0;
{$ELSE}
  CalcMuSigma(A2,Size,Mu1,Sigma1); compensate(A2,Size,-Mu1);
  CalcMuSigma(D2,Size,Mu2,Sigma2); compensate(D2,Size,-Mu2);
  Result:=Distance(A2,D2,Size);
{$ENDIF}
end;

procedure TWaveFormComputer.Init(
  const MaxTimeDelta, TimeDelta: Double;
  Src1,Src2:PSingle; ASize:Integer);
begin
  tf2:=(TimeDelta + MaxTimeDelta)*0.5; if tf2<0 then tf2:=0;
  tf1:=MaxTimeDelta - tf2;  if tf1<0 then tf1:=0;
  Size:=ASize; //Inc(ASize);
  SetLength(Data1,ASize); D1:=@(Data1[0]);
  SetLength(Data2,ASize); D2:=@(Data2[0]);
  SetLength(Appr2,ASize); A2:=@(Appr2[0]);
  CalcWaveData(Src1,D1,ASize);
  CalcWaveData(Src2,D2,ASize);
//  Inc(D1); Inc(A2); Inc(D2);
end;

procedure TWaveFormComputer.GetDrawData(var dA2, dD2: TArrayOfSingle);
var
  i:Integer;
  p1,p2:PSingle;
begin
  SetLength(dA2,Size);
  SetLength(dD2,Size);
  p1:=A2; p2:=D2;
  for i:=0 to Size-1 do begin
    dA2[i]:=p1^; dD2[i]:=p2^;
    Inc(p1); Inc(p2);
  end;
end;

end.


unit UWaveFormComputer;

interface

uses
  Windows,
  Misc;

type
  TWaveP2Calculator=object
    tf1,Int1:Double;
    tf2,Int2:Double;
    Alpha1,Alpha2:Double;
    function iCalcP2(const t,P1: Double): Double;
    function CalcP2(const t,P1:Double):Double;
  end;

  TWaveFormComputer=object
  protected
    D1,A2,D2:PSingle;
    Data1,Appr2,Data2:TArrayOfSingle;
    Size:Integer;
  public
    P2C:TWaveP2Calculator;
    FilterShoulder:Integer;
    NeedAdvInfo:Boolean;
    AdvInfo:String;
    procedure Init(
      const MaxTimeDelta, TimeDelta: Double;
      const Src1,Src2:TArrayOfSingle; i1,i2,ASize:Integer);
    procedure CalcSimilarity(Sim1,Sim2:PDouble);
    procedure GetDrawData(var dA2,dD2:TArrayOfSingle);
  public
    property pA2:PSingle read A2;
    property pD2:PSingle read D2;
  end;

function LinearCompensatedDistance(D1,D2:PSingle; n:Integer):Double;
function ShiftCompensatedDistance(D1,D2:PSingle; n:Integer):Double;
procedure ExtractImpulse(Src,Dst:PSingle; n:Integer);
function SpecCorr(D1,D2:PSingle; n:Integer):Double;
function LinearCompensatedSpecCorr(D1,D2:PSingle; n:Integer):Double;
procedure MakeHorizontal(pY:PSingle; n:Integer);
procedure DifferenceFromLine(Data:PSingle; n:Integer; LMean,RMean,Max:PDouble);
procedure CalcP2(tf1,tf2:Integer; P1,P2:PSingle; Len:Integer);

implementation

uses UFFT;

function GetAlpha(n:Integer):Double;
begin
  Result:=Exp(-4.60517/n);
end;

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

function Correl(D1,D2:PSingle; n:Integer):Double;
var
  S1,M1,S2,M2:Double;
begin
  CalcMuSigma(D1,n,M1,S1);
  CalcMuSigma(D2,n,M2,S2);
  if (S1>0) and (S2>0)
  then Result:=Cov(D1,D2,M1,M2,n)/(S1*S2)
  else Result:=0;
end;

procedure GetMinMax(Data:PSingle; n:Integer; pMin,pMax:PDouble);
var
  Min,Max:Double;
begin
  Min:=Data^; Max:=Data^; Inc(Data); Dec(n);
  while n>0 do begin
    if Data^<Min then Min:=Data^ else if Max<Data^ then Max:=Data^;
    Inc(Data); Dec(n);
  end;
  if pMin<>nil then pMin^:=Min;
  if pMax<>nil then pMax^:=Max;
end;

procedure DifferenceFromLine(Data:PSingle; n:Integer; LMean,RMean,Max:PDouble);
var
  K,B,Sum,Mx,Tmp:Double;
  i,i1:Integer;
begin
  i1:=(n+1) shr 1;
  CalcKB(Data,0,i1,@K,@B);
  Sum:=0;
  for i:=0 to i1 do begin
    Sum:=Sum+Abs(K*i+B-Data^);
    Inc(Data);
  end;
  if LMean<>nil then LMean^:=Sum/(i1+1);
  Sum:=0; Mx:=0;
  for i:=i1+1 to n-1 do begin
    Tmp:=Abs(K*i+B-Data^);
    if Mx<Tmp then Mx:=Tmp;
    Sum:=Sum+Tmp;
    Inc(Data);
  end;
  if RMean<>nil then RMean^:=Sum/(n-i1-1);
  if Max<>nil then Max^:=Mx;
end;

procedure GetDiff(Src,Dst:PSingle; n:Integer);
var
  PS1,PS2:PSingle;
begin
  Dst^:=0; Inc(Dst);
  PS2:=Src; Inc(Src); PS1:=Src; Inc(Src);
  Dec(n,2);
  while n>0 do begin
    Dst^:=Src^-PS2^;
    PS2:=PS1; PS1:=Src; Inc(Src); Inc(Dst);
    Dec(n);
  end;
  Dst^:=0;
end;

function LinearCompensatedSpecCorr(D1,D2:PSingle; n:Integer):Double;
var
  i:Integer;
  SumA,SumB,A,B:Double;
  K1,B1,T1,K2,B2,T2:Double;
begin
  CalcKB(D1,0,n-1,@K1,@B1);
  CalcKB(D2,0,n-1,@K2,@B2);
  SumA:=0; SumB:=0;
  for i:=0 to n-1 do begin
    T1:=D1^-(K1*i+B1);
    T2:=D2^-(K2*i+B2);
    A:=Sqr(T1-T2);
    B:=Sqr(T1+T2);
    SumA:=SumA+A;
    SumB:=SumB+B;
    Inc(D1); Inc(D2);
  end;
//  SumA:=Sqrt(SumA); SumB:=Sqrt(SumB);
  Result:=SumA+SumB;
  if Result>1e-66
  then Result:=(SumB-SumA)/Result
  else Result:=0;
end;

function SpecCorr(D1,D2:PSingle; n:Integer):Double;
var
  i:Integer;
  SumA,SumB,A,B:Double;
begin
  SumA:=0; SumB:=0;
  i:=n-1;
  while i>=0 do begin
    A:=Sqr(D1^-D2^);
    B:=Sqr(D1^+D2^);
    SumA:=SumA+A;
    SumB:=SumB+B;
    dec(i); Inc(D1); Inc(D2);
  end;
//  SumA:=Sqrt(SumA); SumB:=Sqrt(SumB);
  Result:=SumA+SumB;
  if Result>1e-66
  then Result:=(SumB-SumA)/Result
  else Result:=0;
end;

function ShiftCompensatedDistance(D1,D2:PSingle; n:Integer):Double;
var
  i:Integer;
  B:Double;
  DD:array[0..511] of Single;
begin
  B:=0;
  for i:=0 to n-1 do begin
    DD[i]:=D1^-D2^; B:=B+DD[i];
    Inc(D1); Inc(D2);
  end;
  B:=B/n;
  Result:=0;
  for i:=0 to n-1 do Result:=Result+Sqr(DD[i]-B);
  Result:=Sqrt(Result);
end;

function ScaleCompensatedDistance(D1,D2:PSingle; n:Integer):Double;
var
  i:Integer;
  K:Double;
  DD:array[0..511] of Single;
begin
  for i:=0 to n-1 do begin
    DD[i]:=D1^-D2^;
    Inc(D1); Inc(D2);
  end;
  CalcK(@DD[0],0,n-1,@K);
  Result:=0;
  for i:=0 to n-1 do Result:=Result+Sqr(K*i-DD[i]);
  Result:=Sqrt(Result);
end;

function LinearCompensatedDistance(D1,D2:PSingle; n:Integer):Double;
var
  i,i1,i2:Integer;
  K,B:Double;
  DD:array[0..511] of Single;
begin
  for i:=0 to n-1 do begin
    DD[i]:=D1^-D2^;
    Inc(D1); Inc(D2);
  end;
  i1:=-(n shr 1); i2:=n+i1-1;
  CalcKB(@DD[0],i1,i2,@K,@B);
  Result:=0;
  for i:=0 to n-1 do Result:=Result+Sqr(K*(i1+i)+B-DD[i]);
  Result:=Sqrt(Result);
end;

function InvDistance(D1,D2:PSingle; n:Integer):Double;
begin
  Result:=LinearCompensatedDistance(D1,D2,n);
  if Result>1e-4
  then Result:=1/Result
  else Result:=1e+4;
end;

function Similarity(S1,S2:PSingle; n:Integer):Double;
var
  i:Integer;
  P1,P2:PSingle;
  DD:array[0..511] of Single;
begin
  P1:=S1; P2:=S2;
  for i:=0 to n-1 do begin
    DD[i]:=P2^-P1^;
    Inc(P1); Inc(P2);
  end;
  Result:=SpecCorr(S1,@DD[0],n);
end;

procedure MakeHorizontal(pY:PSingle; n:Integer);
var
  K,B:Double;
  i:Integer;
begin
  if CalcKB(pY,0,n-1,@K,@B) then begin
    for i:=0 to n-1 do begin
      pY^:=pY^-(K*i+B);
      Inc(pY);
    end;
  end;
end;

procedure DifferencesFromLine(const K,B:Double; Src,Dst:PSingle; i0,i1:Integer);
var
  i:Integer;
begin
  for i:=i0 to i1 do begin
    Dst^:=Src^-(K*i+B);
    Inc(Dst); Inc(Src);
  end;
end;

procedure ExtractImpulse(Src,Dst:PSingle; n:Integer);
var
  P0:Single;
  iSrc:Cardinal absolute Src;
//  A:Double;
//  K,B:Double;
begin
//  CalcKB(Src,0,n shr 1,@K,@B);
//  DifferenceFromLine(K,B,Src,Dst,0,n-1);
//{
//  A:=GetAlpha(n);
  P0:=Src^;
  while n>0 do begin
    Dst^:=Src^-P0;
//    P0:=P0*A+Src^*(1-A);
    Inc(Src); Inc(Dst); Dec(n);
  end;
//}
end;

procedure TWaveFormComputer.CalcSimilarity(Sim1,Sim2:PDouble);
const
  nCutOff=10;
var
  t:Double;
  PU,PV:PSingle;
  n:Integer;
  Tmp:TArrayOfSingle;
begin
  // Calculate A2 waveform
  PU:=D1; PV:=A2; n:=Size; t:=0;
//(*
  CalcP2(Round(P2C.tf1),Round(P2C.tf2),PU,PV,Size);
{*)
  while n>0 do begin
    PV^:=P2C.CalcP2(t,PU^);
    t:=t+1.0; inc(PV); inc(PU); dec(n);
  end;
//}
  // Compute similarity :-)
  MakeHorizontal(A2,Size);
  MakeHorizontal(D2,Size);
  Tmp:=nil;
  n:=Size;
{
  SetLength(Tmp,n);
  MyFFT(@Appr2[0],@Tmp[0],n,nCutOff); Move(Tmp[0],Appr2[0],n*4);
  MyFFT(@Data2[0],@Tmp[0],n,nCutOff); Move(Tmp[0],Data2[0],n*4);
//}
  if FilterShoulder>0 then begin
    SetLength(Tmp,n);
    DataAvgFilter(Appr2,Tmp,FilterShoulder); Move(Tmp[0],Appr2[0],n*4);
    DataAvgFilter(Data2,Tmp,FilterShoulder); Move(Tmp[0],Data2[0],n*4);
  end;
//  if Sim1<>nil then Sim1^:=Similarity(A2,D2,Size);
  if Sim1<>nil then Sim1^:=LinearCompensatedSpecCorr(A2,D2,Size);
//  if Sim1<>nil then Sim1^:=SpecCorr(A2,D2,Size);
  if Sim2<>nil then Sim2^:=InvDistance(A2,D2,Size);
//  if Sim2<>nil then Sim2^:=InvDistance(A2,D2,Size);
end;

procedure TWaveFormComputer.Init(
  const MaxTimeDelta, TimeDelta: Double;
  const Src1,Src2:TArrayOfSingle; i1,i2,ASize:Integer);
var
  K,B:Double;
  Len,SL,SR:Integer;
begin
  P2C.tf2:=(TimeDelta + MaxTimeDelta)*0.5; if P2C.tf2<0 then P2C.tf2:=0;
  P2C.tf1:=MaxTimeDelta - P2C.tf2;  if P2C.tf1<0 then P2C.tf1:=0;
  Size:=ASize; //Inc(ASize);
  SetLength(Data1,ASize); D1:=@(Data1[0]);
  SetLength(Data2,ASize); D2:=@(Data2[0]);
  SetLength(Appr2,ASize); A2:=@(Appr2[0]);
  SL:=Size shr 1; SR:=Size-SL-1;
{
  Len:=ASize*3 shr 1;
  CalcKB(@Src1[i1-Len],i1-Len,i1,@K,@B);
  DifferenceFromLine(K,B,@Src1[i1-SL],D1,i1-SL,i1+SR);
  CalcKB(@Src2[i2-Len],i2-Len,i2,@K,@B);
  DifferenceFromLine(K,B,@Src2[i2-SL],D2,i2-SL,i2+SR);
//}
//{
  ExtractImpulse(@(Src1[i1-SL]),D1,ASize);
  ExtractImpulse(@(Src2[i2-SL]),D2,ASize);
//}
end;

procedure TWaveFormComputer.GetDrawData(var dA2, dD2: TArrayOfSingle);
var
  i:Integer;
  p1,p2:PSingle;
begin
//  MakeHorizontal(A2,Size);
//  MakeHorizontal(D2,Size);
  SetLength(dA2,Size);
  SetLength(dD2,Size);
  p1:=A2; p2:=D2;
  for i:=0 to Size-1 do begin
    dA2[i]:=p1^; dD2[i]:=p2^;
    Inc(p1); Inc(p2);
  end;
end;

{ TWaveP2Calculator }

type
  TCoeffArray = array[0..255,0..1] of Double;
var
  //[itf,t,...]
  CoeffsCache:array[0..255] of TCoeffArray;
  ExpTfCache:array[0..255] of Double;

procedure InitCoeffsCache(const Alpha:Double);
var
  st,step:Double;
  it,itf:Integer;
begin
  for itf:=0 to High(CoeffsCache) do begin
    ExpTfCache[itf]:=exp(-Alpha*itf);
    for it:=1 to High(CoeffsCache[0]) do begin
      st:=sqrt(2.*itf*it+it*it);
      step:=Alpha*itf * exp(-Alpha*(itf+it)) * BesselI1(Alpha*st) / st;
      CoeffsCache[itf,it,0]:=1/(exp(-Alpha*itf)+step);
      CoeffsCache[itf,it,1]:=step;
    end;
  end;
end;

procedure CalcP2(tf1,tf2:Integer; P1,P2:PSingle; Len:Integer);
var
  Int1,Int2,P0,kE:Double;
  FP1:Single;
  t:Integer;
  Coeff1,Coeff2:^TCoeffArray;
begin
  Coeff1:=@CoeffsCache[tf1]; Int1:=0;
  Coeff2:=@CoeffsCache[tf2]; Int2:=0;
  kE:=ExpTfCache[tf2];
  FP1:=P1^; P2^:=0;
  for t:=1 to Len-1 do begin
    Inc(P1); Inc(P2);
    P0:=(P1^-FP1-Int1)*Coeff1[t,0];
    Int1:=Int1+P0*Coeff1[t,1];
    Int2:=Int2+P0*Coeff2[t,1];
    P2^:=P0*kE+Int2;
  end;
end;

function TWaveP2Calculator.iCalcP2(const t, P1: Double): Double;
var
  st,step,P0:Double;
  it,itf1,itf2:Integer;
begin
  it:=Round(t); itf1:=Round(tf1); itf2:=Round(tf2);
  if it=0 then begin
    Int1:=0; Int2:=0;
    Result:=P1*exp(Alpha2*itf1 - Alpha1*itf2);
  end
  else begin
    P0:=(P1-Int1)*CoeffsCache[itf1,it,0];
    Int1:=Int1+P0*CoeffsCache[itf1,it,1];
    //
    Int2:=Int2+P0*CoeffsCache[itf2,it,1];
    Result:=P0*ExpTfCache[itf2] + Int2;
  end;
end;

function TWaveP2Calculator.CalcP2(const t, P1: Double): Double;
var
  st,step,P0:Double;
begin
  if t=0 then begin
    Int1:=0; Int2:=0;
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
//*)

initialization
  InitCoeffsCache(0.018);
end.

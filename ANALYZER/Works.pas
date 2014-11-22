unit Works;

interface

uses
  Classes,Sequences;

type
  TFinder=class(TObject)
    // in data
    S1,S2:TSequence;
    BlockLen:Integer;
    Damping,Smoothing:Double;
    // out data
    wFound,wAvg:Double;
    iFound:Integer;
    // events
    // methods
    function Work2(T:Integer):Boolean;
    procedure CalcParams(DT:Integer);
  end;

implementation

uses Minimize;

function CalcDistance(dP1,dP2:PSingle; Trend1,Trend2:Single; const Count:Integer;
  const kp1,ks1,kp2,ks2:Single):Double;
var
  i:Integer;
  dP,DD,P,Coeff:Double;
  O1,S1,_ks1,Sum1:Double;
  O2,S2,_ks2,Sum2:Double;
  PrevP,Sum:Double;
begin
  Coeff:=1/(ks1+kp1); _ks1:=1-ks1; _ks2:=1-ks2;
  Result:=0;
  S1:=0; O1:=dP1^; PrevP:=0;
  S2:=0; O2:=dP2^;
  Sum1:=0; Sum2:=0; Sum:=0;
  for i:=Count-1 downto 0 do begin
    DD:=S1*_ks1;
    P:=dP1^-O1;
    dP:=(2*(P-PrevP)-DD)*Coeff; PrevP:=P;
    S1:=DD+dP*ks1;
    S2:=S2*_ks2+dP*ks2;
    DD:=(dP*kp2+S2)*0.5; // calculated dP2
    Sum:=Sum+DD;
{
    Sum1:=Sum1+Sum;
    Sum2:=Sum2+(dP2^-O2);
    Result:=Result+Sqr(Sum1-Sum2);
}
    Result:=Result+Sqr(Sum-(dP2^-O2));
//    Result:=Result+Sqr(DD-dP2^);
    Inc(dP1); O1:=O1+Trend1;
    Inc(dP2); O2:=O2+Trend2;
  end;
//  Result:=Abs(Sum1-Sum2);
  Result:=Sqrt(Result);
end;

var
  GDamping,GSmoothing:Double;
  GDT:Double;
  GdP1,GdP2:PSingle;
  GTrend1,GTrend2:Single;
  GBlockLen:Integer;

function MyFunc:Double;
begin
  Result:=CalcDistance(GdP1,GdP2,GTrend1,GTrend2,GBlockLen,
    1,1,GDamping,1-GSmoothing
  );
end;

{ TFinder }

procedure TFinder.CalcParams(DT: Integer);
begin
  GdP1:=S1.PItems[0];  GTrend1:=S1.Trend[0];
  GdP2:=S2.PItems[DT]; GTrend2:=S2.Trend[DT];
  GBlockLen:=BlockLen;
  GDT:=DT;
  MinimizeFunc(MyFunc,[@GDamping,@GSmoothing],[0.1,0.1],[0.99,0.999],1e-12);
  Damping:=GDamping;
  Smoothing:=GSmoothing;
end;

function TFinder.Work2(T: Integer):Boolean;
var
  Tau1,Tau2:Single;
  Alpha,Beta:Double;
  i,DT,MaxDT:Integer;
  W:Double;
  wSum:Extended;
begin
  Result:=
    Abs(S1.Items[3]-S1.Items[6])
    -
    Abs(S1.Items[0]-S1.Items[3])
    >0.04;
{
  Result:=False;
  Alpha:=0; for i:=0 to 4 do Alpha:=Alpha+S1.Items[i];
  Alpha:=Abs(Alpha)/5;
  Beta:=0;
  for i:=5 to 9 do begin
    Beta:=Beta+S1.Items[i];
    if (Abs(Beta)>0.01) and (Abs(Beta)/(i-4)>10*Alpha) then begin
      Result:=True; break;
    end;
  end;
  Result:=True;
//}
  if not Result then exit;
  Alpha:=-Ln(Damping)/T;
  Beta:=-Ln(1-Smoothing)/T;
  MaxDT:=S1.ItemsLength-BlockLen; if MaxDT>T then MaxDT:=T;
  iFound:=0; wFound:=1.7E+308;
  wSum:=0;
  for DT:=0 to MaxDT do begin
    Tau1:=(T-DT)*0.5;
    Tau2:=(T+DT)*0.5;
    W:=CalcDistance(
      S1.PItems[0],S2.PItems[DT],
      0,0,
//      S1.Trend[0], S2.Trend[DT],
      BlockLen,
      Exp(-Alpha*Tau1),(Exp(-Beta*Tau1)),
      Exp(-Alpha*Tau2),(Exp(-Beta*Tau2))
    );
    wSum:=wSum+W;
    if wFound>W then begin
      wFound:=W;
      iFound:=DT;
    end
  end;
  wAvg:=wSum/(MaxDT+1);
end;

end.

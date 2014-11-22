unit Sequences;

interface

uses Classes;

type
  PSingle=^Single;
  TDynamicArrayOfSingle=array of Single;

  TSequence=class(TObject)
  private
    FItems:TDynamicArrayOfSingle;
    function Get_LastValue: Single;
    function Get_Items(i: Integer): Single;
    function Get_PItems(i: Integer): PSingle;
    function Get_ItemsLength: Integer;
    function Get_Trend(i: Integer): Single;
  public
    LastTrendItem:Integer;
    constructor Create(aSize:Integer; TrendWindowSize:Integer=15);
    procedure Add(Value:Single);
    property LastValue:Single read Get_LastValue;
    property PItems[i:Integer]:PSingle read Get_PItems;
    property Items[i:Integer]:Single read Get_Items;
    property ItemsLength:Integer read Get_ItemsLength;
    property Trend[i:Integer]:Single read Get_Trend;
  protected
    function Next(Value:Single):Single;virtual;abstract;
  end;

  TDiffSequence=class(TSequence)
    constructor Create(Size:Integer; Alpha1,Alpha2:Double);
  protected
    FAlpha1,S1:Double;
    FAlpha2,S2:Double;
    PrevValue:Double;
    NotFirst:Boolean;
    function Next(Value:Single):Single;override;
  end;

  TDispSequence=class(TSequence)
    constructor Create(Size:Integer; Samples:Integer);
  protected
    Samples:array of Single;
    PrevValue:Single;
    NotFirst:Boolean;
    function Next(Value:Single):Single;override;
  end;

implementation

uses Student;

procedure CalcKB(Src:PSingle; n: Integer; var K,B:Double);
var
  i:Integer;
  Xi,Yi:Single;
  p,q,r,s:Double;
begin
  p:=0; q:=0; r:=0; s:=0;
  for i:=0 to n-1 do begin
    Xi:=i; Yi:=Src^; Inc(Src);
    p:=p+Xi*Xi;
    q:=q+Xi;
    r:=r+Xi*Yi;
    s:=s+Yi;
  end;
  try K:=(n*r-q*s)/(n*p-q*q); except K:=0; end;
  B:=(s-K*q)/n;
end;

{ TSequence }

procedure TSequence.Add(Value: Single);
var
  L1:Integer;
begin
  L1:=Length(FItems)-1;
  Move(FItems[1],FItems[0],L1*SizeOf(Single));
  FItems[L1]:=Next(Value);
end;

constructor TSequence.Create(aSize: Integer; TrendWindowSize:Integer=15);
begin
  inherited Create;
  LastTrendItem:=TrendWindowSize-1;
  SetLength(FItems,TrendWindowSize+aSize);
end;

function TSequence.Get_Items(i: Integer): Single;
begin
  Result:=FItems[LastTrendItem+i];
end;

function TSequence.Get_LastValue: Single;
begin
  Result:=FItems[Length(FItems)-1];
end;

function TSequence.Get_ItemsLength: Integer;
begin
  Result:=Length(FItems)-LastTrendItem-1;
end;

function TSequence.Get_PItems(i: Integer): PSingle;
begin
  Result:=@(FItems[LastTrendItem+i]);
end;

function TSequence.Get_Trend(i: Integer): Single;
begin
  Result:=(FItems[LastTrendItem+i]-FItems[i])/LastTrendItem;
end;

{ TDiffSequence }

function TDiffSequence.Next(Value: Single):Single;
var
  D:Double;
begin
  if NotFirst then begin
{
    S2:=S2*FAlpha2+Value*(1-FAlpha2);
    Value:=Value-S2;
    D:=(Value-PrevValue); PrevValue:=Value;
    S1:=S1*FAlpha1+D*(1-FAlpha1);
    Result:=S1;
  end
  else begin
    NotFirst:=True; S2:=Value; S1:=0; PrevValue:=0;
    Result:=0;
  end;
(*}
    D:=Value;//-PrevValue;
    S1:=S1*FAlpha1+D*(1-FAlpha1);
    S2:=S2*FAlpha2+D*(1-FAlpha2);
    D:=S1;//-S2;
    Result:=D;//-PrevValue; PrevValue:=D;
  end
  else begin
    NotFirst:=True; S2:=Value; S1:=Value; PrevValue:=0;
    Result:=0;
  end;
//*)
end;

constructor TDiffSequence.Create(Size: Integer; Alpha1,Alpha2: Double);
begin
  inherited Create(Size);
  FAlpha1:=Alpha1;
  FAlpha2:=Alpha2;
end;

{ TDispSequence }

constructor TDispSequence.Create(Size, Samples: Integer);
begin
  inherited Create(Size);
  SetLength(Self.Samples,Samples);
end;

function TDispSequence.Next(Value: Single): Single;
var
  i,n0,n:Integer;
  Sum,Avg:Double;
  K,B,X:Double;
begin
  if NotFirst then begin
    Move(Samples[0],Samples[1],(Length(Samples)-1)*SizeOf(Single));
    Samples[0]:=Value;
  end
  else begin
    for i:=High(Samples) downto 0 do Samples[i]:=Value;
    NotFirst:=True; PrevValue:=0;
  end;
{
  Sum:=0;
  for i:=High(Samples) downto 0 do Sum:=Sum+Samples[i];
  Avg:=Sum/Length(Samples);
  Sum:=0;
  for i:=High(Samples) downto 0 do Sum:=Sum+Sqr(Avg-Samples[i]);
  X:=Sqrt(Sum/Length(Samples))*10;
  Result:=X-PrevValue;
  PrevValue:=X;
(*
//}
  CalcKB(@(Samples[0]),Length(Samples),K,B);
  Sum:=0; X:=B;
  n:=Length(Samples);
  for i:=0 to n-1 do begin
    Sum:=Sum+Sqr(X-Samples[i]);
    X:=X+K;
  end;
  Result:=Sqrt(Sum)/n*10;
//*)
end;

end.

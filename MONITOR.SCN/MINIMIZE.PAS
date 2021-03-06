//************************************************
//*
//* ����� �������� ������� ���������� ����������
//*
//* ���-�� ����� ������������ ������
//*
//************************************************
unit Minimize;

interface

uses Math;

type
  TDoubleFunction=function:Double of object;
  PDouble=^Double;

procedure MinimizeFunc(Func:TDoubleFunction;
  X:array of PDouble; const Xmin,Xmax:array of Double;
  Epsilon:Double; MaxIterations:Integer=1 shl 12);

implementation

procedure MinimizeFunc;
var
  i,Count:Integer;
  Min,Value,Tmp,StepLen,Alpha:Double;
  Step,OldX:array of Double;
  Iteration:LongInt;
  Flag:Boolean;
  h:Double;
begin
  Count:=Length(X);
  SetLength(Step,Count);
  SetLength(OldX,Count);
  Flag:=True;
  Min:=1.7E+308;
  { ������ �������, ���� �����-������ :) }
  for Iteration:=0 to MaxIterations div 2 do begin
    for i:=0 to Count-1 do X[i]^:=Xmin[i]+Random*(Xmax[i]-Xmin[i]);
    Value:=Func;
    if {IsAN(Value) and} (Flag or (Value<Min)) then begin
      for i:=0 to Count-1 do OldX[i]:=X[i]^;
      Min:=Value;
      Flag:=False;
    end;
  end;
  if Flag
  then for i:=0 to Count-1 do OldX[i]:=0;
  {�������}
  for i:=0 to Count-1 do X[i]^:=OldX[i];
//  Value:=Min;
  {������� �������� ������������ �� ������ ������������}
  Iteration:=MaxIterations;
  {�������������� ����� ����}
  Alpha:=1;
  repeat
    Dec(Iteration);
    {������������ ���������� ��������� (���-�� ����� ����������� ����)}
    StepLen:=0;
    for i:=0 to Count-1 do begin
      h:=(Xmax[i]-Xmin[i])*0.01*Alpha;
      OldX[i]:=X[i]^; X[i]^:=OldX[i]+h;
      Value:=Func;
      if Min<>Value
      then Tmp:=h/(Min-Value)
      else Tmp:=h;
      StepLen:=StepLen+Tmp*Tmp;
      Step[i]:=Tmp;
      X[i]^:=OldX[i];
    end;
    StepLen:=Sqrt(StepLen);
    {������ ���}
    for i:=0 to Count-1 do begin
      Tmp:=X[i]^+Step[i]*Alpha;
      if Tmp<Xmin[i] then Tmp:=Xmin[i]
      else if Xmax[i]<Tmp then Tmp:=Xmax[i];
      X[i]^:=Tmp;
    end;
    {��������� �������� ������� ����� ����}
    Value:=Func;
    if {IsAN(Value) and} (Value<Min)
    then Min:=Value
    else begin {undo step}
      for i:=0 to Count-1 do X[i]^:=OldX[i];
      Alpha:=0.618*Alpha;
    end;
    {���� �����������, �� ������������ ����� � ��������� ����� ����}
    {���� ����� ���� �� ������ ����� ��������� ���
     �� ���������� ���������� ����� ��������}
  until (Alpha*StepLen<Epsilon)or(Iteration<=0);
  for i:=0 to Count-1 do if Step[i]=0 then X[i]^:=0;
end;

end.

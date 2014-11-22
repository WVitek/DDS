
(**********************************************)
(* Проверка правильности задания и вычисление *)
(* значений функций нескольких переменных     *)
(* Function Analizer 32 bit                   *)
(* (c) Вшивцев Виктор (W. Vitek)              *)
(**********************************************)

unit FA32;

interface

uses SysUtils;

const
  ferUnknownId   =1;
  ferRightBracket=2;
  ferComma       =3;
  ferLeftBracket =4;
  ferNumFormat   =5;
  ferNumValue    =6;
  ferNothing     =7;
  ferEOL         =8;
  ferSyntax      =9;
  ferMessage:array[1..9] of String=(
    'Неизвестный идентификатор',
    'Ожидается закрывающая скобка ")"',
    'Ожидается запятая',
    'Ожидается открывающая скобка "("',
    'Неправильный формат числа',
    'Неподдерживаемое значение числа',
    'Отсутствует выражение',
    'Ожидается конец выражения',
    'Синтаксическая ошибка');
  DigitsSet:set of char=['0'..'9'];
  CharsSet:set of char=['A'..'Z','a'..'z','А'..'Я','а'..'я','_'];

type
  E_FA32_Error=class(Exception);
  TExtendedFunction=function:Extended;
  TDynamicSizeBuffer=object
    Addr:pointer;
    Size,Pos,Delta:Integer;
    constructor Init(ADelta:Integer);
    procedure Write(var B; W:Integer);
    destructor Done;
    procedure GrowBuffer;
  end;
  PVariableRecord=^TVariableRecord;
  { В записи TVariableRecord запоминается
    имя (Name) и адрес (Addr) переменной }
  TVariableRecord=record
    Next:PVariableRecord;
    Addr:pointer;
    Name:PString;
  end;
  PFunctionRecord=^TFunctionRecord;
  { В записи TFunctionRecord запоминается идентификатор (Name) функции, }
  { ее адрес(Addr) и количество аргументов (ArgCnt) }
  TFunctionRecord=record
    Next:PFunctionRecord;
    Addr:pointer;
    Name:PString;
    ArgCnt:Integer;
  end;
  {Объект "Функция"}
  TFunction=object
    private
      Code:TDynamicSizeBuffer;
      VariablesList:PVariableRecord;
      function GetFunPtr(var s:string;var i:Integer):PFunctionRecord;
      function GetVarPtr(var s:string;var i:Integer):PVariableRecord;
      function GetVariable(const Name:String):PVariableRecord;
      procedure PushValue(X:Extended);
      procedure PushMemoryReference(var X:Extended);
      procedure CallFunction(P:Pointer);
      procedure GenerateOpCode(c:Char);
    public
      ErrorCode:integer;
      GetValue:TExtendedFunction;
      constructor Init;
      function Compile(var s:string):Integer;
      procedure AssignVar(const Name:String;var m:Extended);
      destructor Done;
  end;

{ Регистрирует функцию в списке }
{ Если функция незарегистрирована, то ее использование }
{ приведет к ошибке 'Неизвестный идентификатор' }
procedure RegisterFunction(const Name:String;ArgCnt:Integer;Addr:pointer);

procedure MakeUpCase(var Str:String);

{ Удаляет все пробелы из строки }
procedure DeleteSpaces(var Str:String);

{Удаляет "мусор" из строки (повторяющиеся знаки '+' и '-' и т.п.)}
procedure CheckSignes(var S:string);

implementation

uses Math;

// TDynamicSizeBuffer
constructor TDynamicSizeBuffer.Init;
begin
  FillChar(Self,SizeOf(Self),0);
  Delta:=ADelta;
end;

procedure TDynamicSizeBuffer.Write;
begin
  while Pos+W>Size do GrowBuffer;
  Move(B,Ptr(Integer(Addr)+Pos)^,W);
  Inc(Pos,W);
end;

destructor TDynamicSizeBuffer.Done;
begin
  if Addr<>nil then FreeMem(Addr,Size);
  Size:=0;
  Pos:=0;
  Addr:=nil;
end;

procedure TDynamicSizeBuffer.GrowBuffer;
var
  P:Pointer;
begin
  GetMem(P,Size+Delta);
  Move(Addr^,P^,Pos);
  FreeMem(Addr,Size);
  Addr:=P;
  Inc(Size,Delta);
end;

const
  OpersSet:set of char=['+','-','/','*'];

var
  FunctionsList:PFunctionRecord; { Указатель на список известных функций }
  PiValue:Extended;
  Tmp:PFunctionRecord absolute PiValue;

procedure MakeUpCase(var Str:String);
var
  i:Integer;
begin
  for i:=1 to Length(Str) do Str[i]:=UpCase(Str[i]);
end;

procedure DeleteSpaces(var Str:String);
var
  i:Integer;
begin
  i:=1;
  while i<=Length(Str)
  do begin
    if Str[i]=' ' then Delete(Str,i,1) else Inc(i);
  end;
end;

procedure CheckSignes(var S:string);
const
  Sgns:set of char=['-','+'];
var
  q:boolean;
  i:Integer;
begin
  repeat
    q:=True;
    i:=1;
    while i<Length(S) do
      begin
      if (s[i] in Sgns) and (s[succ(i)] in Sgns) then
        begin
        q:=False;
        if s[i]=s[succ(i)] then
          begin
          Delete(s,i,2);
          if (i>1) AND (s[i-1] in (CharsSet+DigitsSet+[')'])) then
            Insert('+',s,i);
          end
        else if s[i]='+' then
          Delete(s,i,1)
        else
          Delete(s,succ(i),1);
        end
      else
        Inc(i);
      end;
  until q;
end;

procedure RegisterFunction(const Name:String;ArgCnt:Integer;Addr:pointer);
var
  p:PFunctionRecord;
begin
  New(p); p^.Next:=FunctionsList; FunctionsList:=p;
  p^.Name:=NewStr(Name); MakeUpCase(p^.Name^);
  p^.Addr:=Addr; p^.ArgCnt:=ArgCnt;
end;

function Angle(X,Y: Extended): Extended;
asm
  FLD     Y
  FLD     X
  FPATAN
  FWAIT
end;
function mNegate(x:Extended):Extended;assembler;
asm
  fld   x
  fchs
end;
function mSIN(r:Extended):Extended;
begin
  mSIN:=sin(r);
end;
function mCOS(r:Extended):Extended;
begin
  mCOS:=cos(r);
end;
function mArcTg(r:Extended):Extended;
begin
  mArcTg:=arctan(r);
end;
function mEXP(r:Extended):Extended;
begin
  mEXP:=EXP(r);
end;
function mABS(r:Extended):Extended;
begin
  mABS:=abs(r);
end;
function mLN(r:Extended):Extended;
begin
  mLN:=ln(r);
end;
function mSqrt(r:Extended):Extended;
begin
  mSqrt:=Sqrt(r);
end;
function mSqr(r:Extended):Extended;
begin
  mSqr:=Sqr(r);
end;
function mArcTan(r:Extended):Extended;
begin
  mArcTan:=ArcTan(r);
end;
function Power(r1,r2:Extended):Extended;
begin
  if r1=0
  then Power:=0
  else Power:=Exp(r2*ln(Abs(r1)));
end;
function Sign(r:Extended):Extended;
begin
  if r<0
  then Sign:=-1
  else if r=0
  then Sign:=0
  else Sign:=1;
end;

{Если функция с именем Name найдена в списке регистрации,}
{  то возвращает указатель на ее регистрационную запись}
{  иначе возвращает NIL}
function GetFunction(const Name:String):PFunctionRecord;
var
  p:PFunctionRecord;
begin
  p:=FunctionsList;
  while (p<>nil) and (p^.Name^<>Name) do
    p:=p^.Next;
  GetFunction:=p;
end;

function NotCompiled:Extended;
begin
  raise E_FA32_Error.Create('FA32: Function not compiled');
end;

function ToStr(var P; Size:Integer):String;
var
  i:Integer;
begin
  Result:='';
  for i:=0 to Size-1
  do Result:=Result+Char(Ptr(Integer(Addr(P))+i)^);
end;

(* TFunction *)
constructor TFunction.Init;
begin
  VariablesList:=nil;
  Code.Init(32);
  GetValue:=NotCompiled;
  AssignVar('pi',PiValue);
end;

{Формирует код помещения в стек значения типа Extended}
procedure TFunction.PushValue;
var
  w:array[0..2] of Integer absolute X;
  k:Integer;
  s:String;
begin
  s:='';
  for k:=2 downto 0
  do s:=s+#$68+ToStr(w[k],4); { push immed32 }
  Code.Write(s[1],Length(s));
end;

{Формирует код помещения в стек значения переменной типа Extended}
procedure TFunction.PushMemoryReference;
var
  k,P:integer;
  t:String;
begin
  P:=Integer(Addr(X))+8;
  t:='';
  for k:=0 to 2
  do begin
    t:=t+#$FF#$35 + ToStr(P,4); { push dword ptr [P-k*4] }
    Dec(P,4);
  end;
  Code.Write(t[1],Length(t));
end;

{Формирует код обращения к функции и помещения в стек}
{полученного значения типа Extended (из регистра ST(0) FPU)}
procedure TFunction.CallFunction;
var
  s:String;
begin
  s:=
    #$B8+ToStr(P,4) + { mov  eax,P          }
    #$FF#$D0        + { call eax            }
    #$83#$EC#$0C    + { sub esp,12          }
    #$89#$E5        + { mov ebp,esp         }
    #$DB#$7D#$00;     { fstp Extended([bp]) }
  Code.Write(s[1],Length(s));
end;

function TFunction.GetVarPtr(var s:string;var i:Integer):PVariableRecord;
var
  Name:String absolute s;
  p:PVariableRecord;
  c:Integer;
begin
  GetVarPtr:=nil;
  if i>Length(S) then exit;
  c:=i;
  while (c<=Length(S)) and (s[c] in (CharsSet+DigitsSet)) do Inc(c);
  s:=Copy(s,i,c-i);
  p:=GetVariable(Name);
  if p<>nil
  then begin
    i:=pred(c);
    GetVarPtr:=p;
  end;
end;

function TFunction.GetFunPtr;
var
  p:PFunctionRecord;
  Name:String;
  c:Integer;
begin
  GetFunPtr:=nil;
  if i>Length(S) then exit;
  c:=i;
  while (c<=Length(S)) and (s[c] in (CharsSet+DigitsSet)) do Inc(c);
  Name:=Copy(s,i,c-i);
  p:=GetFunction(Name);
  if p<>nil then
  begin
    if (s[c]<>'(') or (c>Length(S))
    then begin
      Inc(c); ErrorCode:=ferRightBracket;
    end;
    i:=pred(c);
    GetFunPtr:=p;
  end;
end;

function TFunction.GetVariable;
var
  p:PVariableRecord;
begin
  p:=VariablesList;
  while (p<>nil) and (p^.Name^<>Name) do p:=p^.Next;
  GetVariable:=p;
end;

procedure TFunction.AssignVar;
var
  p:PVariableRecord;
begin
  New(p); p^.Next:=VariablesList; VariablesList:=p;
  p^.Name:=NewStr(Name); MakeUpCase(p^.Name^); p^.Addr:=Addr(m);
end;

destructor TFunction.Done;
var
  pl:PVariableRecord;
begin
  Code.Done;
  while VariablesList<>nil do
  begin
    pl:=VariablesList;
    VariablesList:=pl^.Next;
    Dispose(pl);
  end;
end;

procedure TFunction.GenerateOpCode;
var
  s:String;
  o:Char;
begin
  s:=#$89#$E5;     { mov ebp,esp }
  if c<>'_'
  then s:=s+#$DB#$6D#$0C; { fld Extended([ebp+12]) }
  s:=s+#$DB#$6D#$00;      { fld Extended([ebp])    }
  if c='_'
  then begin
    s:=s+#$D9#$E0; {fchs}
  end
  else begin
    case c of
      '+':o:=#$C1; {fadd}
      '-':o:=#$E9; {fsub}
      '*':o:=#$C9; {fmul}
      else{'/':}o:=#$F9; {fdiv}
    end;
    s:=s+#$DE+o;
  end;
  if c<>'_'
  then begin
    s:=s+#$83#$C4#$0C+ { add esp,12 }
         #$DB#$7D#$0C  { fstp Extended([ebp+12]) }
  end
  else s:=s+#$DB#$7D#$00;  { fstp Extended([bp]) }
  Code.Write(s[1],Length(s));
end;

function TFunction.Compile(var S:String):Integer;
var
  Pos,Error:Integer;

  function NextChar:Char;
  begin
    if Pos>Length(S)
    then NextChar:=#0
    else NextChar:=S[Pos];
  end;

  procedure AcceptChar;
  begin
    Inc(Pos);
  end;

  function T:Boolean;forward;
  function F:Boolean;forward;

  { E = T [+T|-T] }
  function E:Boolean;
  var
    c:Char;
  begin
    if T
    then begin
      repeat
        c:=NextChar;
        if (c='-')or(c='+')
        then begin
          AcceptChar;
          if T then GenerateOpCode(c);
        end
        else c:=#0;
      until (c=#0) or (Error<>0);
    end;
    E:=Error=0;
  end;

  { T = F [*F|/F] }
  function T:Boolean;
  var
    c:Char;
  begin
    if F
    then begin
      repeat
        c:=NextChar;
        if (c='*')or(c='/')
        then begin
          AcceptChar;
          if F then GenerateOpCode(c);
        end
        else c:=#0;
      until (c=#0) or (Error<>0);
    end;
    T:=Error=0;
  end;


  function IsDigit(c:Char):Boolean;
  begin
    IsDigit:=('0'<=c)and(c<='9');
  end;

  function Number:Boolean;

    function Digits:Boolean;
    begin
      if IsDigit(NextChar)
      then begin
        repeat
          AcceptChar;
        until not IsDigit(NextChar);
        Digits:=True;
      end
      else begin
        Error:=ferNumFormat;
        Digits:=False;
      end;
    end;

  var
    Value:Extended;
    ErrPos:Integer;
    b:Integer;
    c:Char;
    Sign:Boolean;
  begin
    b:=Pos;
    Sign:=NextChar='-';
    if Sign then AcceptChar;
    if Digits
    then begin
      if NextChar='.'
      then begin
        AcceptChar;
        Digits;
      end;
      if (Error=0)and(NextChar='E')
      then begin
        AcceptChar;
        c:=NextChar;
        if (c='-') or (c='+')
        then begin
          AcceptChar;
          Digits;
        end
        else Error:=ferNumFormat;
      end;
      if Error=0
      then begin
        Val(Copy(S,b,Pos-b),Value,ErrPos);
        if ErrPos<>0
        then begin
          Error:=ferNumValue;
          Pos:=b;
        end
        else begin
          PushValue(Value); Sign:=True;
        end;
      end;
    end
    else begin
      if Sign then Dec(Pos);
      Sign:=False; Error:=0;
    end;
    Number:=(Error=0)and Sign;
  end;

  function IsFunction:Boolean;
  var
    P:PFunctionRecord;
    b:Integer;
  begin
    P:=nil;
    b:=Pos;
    while IsDigit(NextChar) or (NextChar in CharsSet) do AcceptChar;
    if Pos-b>0
    then begin
      P:=GetFunction(Copy(s,b,Pos-b));
      if P<>nil
      then begin
        if P^.ArgCnt=0
        then
        else if NextChar='('
        then begin
          AcceptChar;
          for b:=P^.ArgCnt downto 1
          do begin
            if E
            then begin
              if (b>1)
              then begin
                if (NextChar<>',')
                then begin
                  Error:=ferComma; break;
                end
                else AcceptChar;
              end;
            end
            else break;
          end;
          if Error=0
          then begin
            if NextChar=')'
            then begin
              AcceptChar;
              CallFunction(P^.Addr);
            end
            else Error:=ferRightBracket;
          end;
        end
        else Error:=ferLeftBracket;
      end
      else Pos:=b;
    end;
    IsFunction:=(P<>nil)and(Error=0);
  end;

  function IsVariable:Boolean;
  var
    P:PVariableRecord;
    b:Integer;
  begin
    P:=nil;
    b:=Pos;
    while IsDigit(NextChar) or (NextChar in CharsSet) do AcceptChar;
    if Pos-b>0
    then begin
      P:=GetVariable(Copy(s,b,Pos-b));
      if P<>nil
      then PushMemoryReference(Extended(P^.Addr^))
      else Pos:=b;
    end;
    IsVariable:=P<>nil;
  end;

  function F:Boolean;
  var
    c:Char;
  begin
    c:=NextChar;
    if c='('
    then begin
      AcceptChar;
      if E
      then begin
        if NextChar=')'
        then AcceptChar
        else Error:=ferRightBracket
      end;
    end
    else if (not Number) and (Error=0)
    then begin
      if (c='-')
      then begin
        AcceptChar;
        if F then GenerateOpCode('_');
      end
      else if c in CharsSet
      then begin
        if (not IsFunction) and (Error=0) and not IsVariable
        then Error:=ferUnknownId;
      end
      else Error:=ferSyntax;
    end;
    F:=Error=0;
  end;

var
  ts:String;
begin
  Code.Done;
  GetValue:=NotCompiled;
  Pos:=1;
  if NextChar<>#0
  then begin
    Error:=0;
    MakeUpCase(S); DeleteSpaces(S); CheckSignes(S);
    ts:=
      #$55 +   { push ebp }
      #$DB#$E3;{ finit   }
    Code.Write(ts[1],Length(ts));
    if E
    then begin
      if (NextChar=#0)
      then begin
        Pos:=0;
        ts:=
          #$89#$E5     + { mov ebp,esp         }
          #$DB#$6D#$00 + { fld Extended([ebp]) }
          #$83#$C4#$0C + { add esp,12          }
          #$5D         + { pop ebp             }
          #$C3;          { ret                 }
        Code.Write(ts[1],Length(ts));
        @GetValue:=Code.Addr;
      end
      else Error:=ferEOL;
    end;
  end
  else Error:=ferNothing;
  ErrorCode:=Error;
  if Error<>0
  then Code.Done;
  Compile:=Pos;
end;

initialization

FunctionsList:=nil;
{ Регистрируем стандартные функции в списке }
RegisterFunction('sin',1,@mSIN);
RegisterFunction('cos',1,@mCOS);
RegisterFunction('tan',1,@Tan);
RegisterFunction('cotan',1,@Cotan);
RegisterFunction('arctan',1,@mArcTg);
RegisterFunction('angle',2,@Angle);
RegisterFunction('arcsin',1,@ArcSin);
RegisterFunction('arccos',1,@ArcCos);
RegisterFunction('length',2,@Hypot);
RegisterFunction('exp',1,@mEXP);
RegisterFunction('abs',1,@mABS);
RegisterFunction('sqr',1,@mSqr);
RegisterFunction('sqrt',1,@mSqrt);
RegisterFunction('ln',1,@mLN);
RegisterFunction('power',2,@Power);
RegisterFunction('sign',1,@Sign);
PiValue:=Pi;

finalization

while FunctionsList<>nil
do begin
  Tmp:=FunctionsList;
  FunctionsList:=Tmp^.Next;
  DisposeStr(Tmp^.Name);
  Dispose(Tmp);
end;

end.


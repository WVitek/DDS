unit Misc;

interface

uses
  Windows,Classes,Controls,Graphics,Menus;

const
  GoldRatio=1.618033989;

type
  float=double;
  TArrayOfSingle=array of Single;

  TDblPoint=packed record
    x,y:float;
  end;
  TDblRect=packed record
    case Integer of
    0: (x1,y1,x2,y2:float);
    1: (P1,P2:TDblPoint);
  end;

  TByteStringList=class(TStringList)
    function Find(const S: string; var Index: Integer): Boolean; override;
  end;

  TScaleParamsRec=record
    Base,Min,Max:Integer;
  end;

function GetModuleFullName:String;
function Power(x:float; n:Integer):float;
procedure CalcScaleParams(
  const Start,Length:float; MaxScCount:Integer;
  const Steps:array of TScaleParamsRec;
  var ScStart,ScStep:float; var Digits,ScCount:Integer);

procedure InitFormattingVariables;
function GetTextExtent(Font:TFont; const Text:String):TSize;
function MakeLangId(p,s:Word):Cardinal;
function HighWord(c:Cardinal):Word;
function LowWord(c:Cardinal):Word;
function GetErrorMsg(ErrorId:Cardinal):String;
procedure ErrorMsg(const Msg:String; RaiseEx:Boolean=TRUE);
procedure LastErrorMsg(RaiseEx:Boolean=TRUE);
procedure CheckMinMax(var Value:Double; Min,Max:Double; ed:TWinControl);
function LogMsg(const DT: TDateTime; const Msg: String):String;
procedure WriteToLog(const LogFileName,S: String);
procedure DrawHeaderMenuItem(Item: TMenuItem;
  C: TCanvas; R: TRect; State: TOwnerDrawState);
function StrCheckSum(const Data; Size:Integer):String;
procedure CalcMuSigma(Data:PSingle; n:Integer; var Mu,Sigma:Double);
function Cov(D1,D2:PSingle; Mu1,Mu2:Double; n:Integer):Double;
function GetFileBuildInfo:String;
function getHexDump(const Data; Size:Integer):String;
procedure ShiftArrFw(var A:TArrayOfSingle; Count:Integer);
procedure ShiftArrBk(var A:TArrayOfSingle; Count:Integer);
procedure DataAvgFilter(const Src:TArrayOfSingle; var Dst:TArrayOfSingle; n:Integer);
function CalcK(pY:PSingle; i0,i1:Integer; pK:PDouble):Boolean;
function CalcKB(pY:PSingle; i0,i1:Integer; pK,pB:PDouble):Boolean;
function MinInt64(const Vals:array of Int64):Int64;
function MaxInt64(const Vals:array of Int64):Int64;
function GetEventMsg(MsgList:TStringList; Ch, Value: Integer): String;
function GetUserName: String;

implementation

uses SysUtils,Forms,Math;

var
  userName:String;

function GetUserName:string;
var
  Buffer: array[0..MAX_PATH] of Char;
  sz:DWord;
begin
  if Length(userName)=0
  then begin
    sz:=MAX_PATH-1;
    if Windows.GetUserName(Buffer,sz) then begin
      if sz>0 then dec(sz);
      SetString(userName,Buffer,sz);
    end
    else userName:='?';
  end;
  Result:=userName;
end;

type
  TWinControlHack=class(TControl)
    property Text;
  end;

  TDoubleMemInts=packed record
    i0,i1:Integer;
  end;

function GetEventMsg(MsgList:TStringList; Ch, Value: Integer): String;
var
  i,j,k:Integer;
  S,S1:String;
begin
  Result:='';
  k:=1; j:=1;
  S1:=IntToStr(Ch);
  i:=MsgList.Count-1;
  while i>=0 do begin
    S:=MsgList[i];
    j:=Pos(';',S);
    if j>0 then begin
      k:=1;
      // compare S1 and head of S (chars before first ';')
      while (k<j) and (k<=Length(S1)) and (S[k]=S1[k]) do Inc(k);
      if k=Length(S1)+1 then break;
    end;
    Dec(i);
  end;
  if i>=0 then begin
    S1:=IntToStr(Value);
    i:=k;
    while i<Length(S) do begin
      if S[i]=';' then begin
        j:=i+1;
        while (j<=Length(S)) and (S[j]<>':') do Inc(j);
        if (j<=Length(S)) and (S1=Copy(S,i+1,j-(i+1)))
        then break;
        i:=j;
      end;
      Inc(i);
    end;
    if i<Length(S) then begin
      k:=j+1;
      while (k<=Length(S)) and (S[k]<>';') do Inc(k);
      Result:=Copy(S,j+1,k-j);
    end
  end;
  if Result='' then Result:='Канал #'+IntToStr(Ch)+'='+IntToStr(Value);
end;

function MinInt64(const Vals:array of Int64):Int64;
var
  i:Integer;
begin
  Result:=Vals[0];
  for i:=1 to High(Vals) do if Vals[i]<Result then Result:=Vals[i];
end;

function MaxInt64(const Vals:array of Int64):Int64;
var
  i:Integer;
begin
  Result:=Vals[0];
  for i:=1 to High(Vals) do if Result<Vals[i] then Result:=Vals[i];
end;

function CalcK(pY:PSingle; i0,i1:Integer; pK:PDouble):Boolean;
var
  i:Integer;
  xy,xx:Double;
begin
  xy:=0; xx:=0;
  for i:=i0 to i1 do begin
    xy:=xy+i*pY^; xx:=xx+i*i;
    Inc(pY);
  end;
  if xx>0 then begin
    if pK<>nil then pK^:=xy/xx;
    Result:=True;
  end
  else Result:=False;
end;

function CalcKB(pY:PSingle; i0,i1:Integer; pK,pB:PDouble):Boolean;
var
  i,n:Integer;
  sxx,sx,sxy,sy,K,B:Double;
begin
  Result:=False;
  sxx:=0; sx:=0; sxy:=0; sy:=0;
  for i:=i0 to i1 do begin
    sxx:=sxx+Sqr(i); sx:=sx+i;
    sxy:=sxy+i*pY^; sy:=sy+pY^;
    Inc(pY);
  end;
  n:=i1-i0+1;
  if n>1 then begin
    try
      K:=(n*sxy-sx*sy)/(n*sxx-sx*sx);
      Result:=True;
    except
      K:=0;
    end;
    B:=(sy-K*sx)/n;
  end
  else begin
    K:=0; B:=0;
  end;
  if pK<>nil then pK^:=K;
  if pB<>nil then pB^:=B;
end;

procedure DataAvgFilter(const Src:TArrayOfSingle; var Dst:TArrayOfSingle; n:Integer);
var
  i,j:Integer;
  K,B:Double;
begin
  SetLength(Dst,Length(Src));
  for i:=n to High(Src)-n do begin
    if CalcKB(@Src[i-n],i-n,i+n-1,@K,@B)
    then Dst[i]:=K*i+B
    else Dst[i]:=Src[i];
  end;
  j:=High(Dst)-n;
  for i:=0 to n-1 do begin
    Dst[i]:=0;//Dst[n];
    Dst[j+i+1]:=0;//Dst[j];
  end;
end;

procedure ShiftArrFw(var A:TArrayOfSingle; Count:Integer);
var
  Size:Integer;
begin
  Size:=Length(A);
  if Count>=Size then FillChar(A[0],Size*SizeOf(Single),0)
  else if Count>0 then begin
    Move(A[Count],A[0],(Size-Count)*SizeOf(Single));
    FillChar(A[Size-Count],Count*SizeOf(Single),0);
  end
end;

procedure ShiftArrBk(var A:TArrayOfSingle; Count:Integer);
var
  Size:Integer;
begin
  Size:=Length(A);
  if Count>=Size then FillChar(A[0],Size*SizeOf(Single),0)
  else if Count>0 then begin
    Move(A[0],A[Count],(Size-Count)*SizeOf(Single));
    FillChar(A[0],Count*SizeOf(Single),0);
  end
end;

function getHexDump(const Data; Size:Integer):String;
type
  PByte=^Byte;
var
  i:Integer;
  s:String;
  B:array[0..65535] of Byte absolute Data;
begin
  Result:=IntToStr(Size)+': ';
  for i:=0 to Size-1 do begin
    S:=Format('%x',[B[i]]);
    if Length(S)=1 then S:='0'+S+' ' else S:=S+' ';
    Result:=Result+S;
  end;
end;

function GetFileBuildInfo:String;
var
  Buf:array[0..65535] of Char;
  lpFFI:^VS_FIXEDFILEINFO;
  Len:Cardinal;
begin
  if GetFileVersionInfo(PChar(GetModuleFullName+'.exe'),0,SizeOf(Buf),@Buf)
    and VerQueryValue(@Buf,'\',Pointer(lpFFI),Len)
  then begin
    Result:=
      'Build № '+IntToStr(LowWord(lpFFI.dwFileVersionLS));
  end
  else Result:=GetErrorMsg(GetLastError);
end;

procedure InitFormattingVariables;
begin
  Application.UpdateFormatSettings:=False;
  DecimalSeparator:='.';
  DateSeparator:='-';
  ShortDateFormat:='yyyy/mm/dd';
  LongDateFormat:='yyyy/mm/dd';
  LongTimeFormat:='hh:mm:ss';
end;

procedure CalcMuSigma(Data:PSingle; n:Integer; var Mu,Sigma:Double);
var
  i:Integer;
  S1,S2:Double;
  D:PSingle;
begin
  S1:=0; D:=Data;
  for i:=0 to n-1 do begin
    S1:=S1+D^; Inc(D);
  end;
  S2:=0; D:=Data;
  for i:=0 to n-1 do begin
    S2:=S2+Sqr(D^); Inc(D);
  end;
  Mu:=S1/n;
//  Sigma:=Sqrt(n*S2-Sqr(S1))/n;
  Sigma:=Sqrt((n*S2-Sqr(S1))/(n*(n-1)));
end;

function Cov(D1,D2:PSingle; Mu1,Mu2:Double; n:Integer):Double;
var
  i:Integer;
  S:Double;
begin
  S:=0;
  for i:=0 to n-1 do begin
    S:=S+(D1^-Mu1)*(D2^-Mu2);
    Inc(D1); Inc(D2);
  end;
  Result:=S/n;
end;

function StrCheckSum(const Data; Size:Integer):String;
var
  i,Sum:Integer;
  P:^Byte;
begin
  P:=@Data;
  Sum:=0;
  for i:=0 to Size-1 do begin Inc(Sum,P^); Inc(P); end;
  Result:=Format('%2x',[Sum and $FF]);
  if Result[1]=' ' then Result[1]:='0';
end;

procedure DrawHeaderMenuItem(Item: TMenuItem;
  C: TCanvas; R: TRect; State: TOwnerDrawState);
begin
  if not Item.Checked then Dec(R.Bottom,3);
  C.Brush.Color:=clInfoBk;
  C.Brush.Style:=bsSolid;
  C.FillRect(R);
  if Item.Checked then Dec(R.Bottom,3);
  C.Brush.Style:=bsClear;
  C.Font.Color:=clInfoText;
  C.Font.Style:=C.Font.Style+[fsBold];
  C.TextOut(
    R.Left+(R.Right-R.Left-C.TextWidth(Item.Caption)) div 2,
    R.Top+(R.Bottom-R.Top-C.TextHeight(Item.Caption)) div 2,
    Item.Caption
  );
//  if not Item.Checked then begin
    C.Pen.Width:=1; C.Pen.Style:=psSolid;
    C.Pen.Color:=clBtnShadow;
    C.MoveTo(R.Left,R.Bottom+1); C.LineTo(R.Right,R.Bottom+1);
    C.Pen.Color:=clBtnHighlight;
    C.MoveTo(R.Left,R.Bottom+2); C.LineTo(R.Right,R.Bottom+2);
//  end;
end;

function GetTextExtent(Font:TFont; const Text:String):TSize;
var
  DC:HDC;
  SaveFont:HFont;
begin
  DC:=GetDC(0);
  SaveFont:=SelectObject(DC, Font.Handle);
  GetTextExtentPoint32(DC, PChar(Text), Length(Text), Result);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
end;

procedure WriteToLog(const LogFileName,S: String);
var
  Log:TextFile;
begin
  try
    AssignFile(Log,LogFileName);
    if not FileExists(LogFileName) then Rewrite(Log) else Append(Log);
    try
      Write(Log,S);
      Flush(Log);
    finally
      CloseFile(Log);
    end;
  except
  end;
end;

function LogMsg(const DT: TDateTime; const Msg: String):String;
begin
  Result:=DateTimeToStr(DT)+#9+Msg+#13#10;
end;

function HighWord(c:Cardinal):Word;
begin
  Result:=c shr 16;
end;

function LowWord(c:Cardinal):Word;
begin
  Result:=c and $FFFF;
end;

function MakeLangId(p,s:Word):Cardinal;
begin
  Result:=(s shl 10) or p;
end;

function GetErrorMsg;
const
  BufSize=4096;
var
  lpMsgBuf:PChar;
begin
  GetMem(lpMsgBuf,BufSize);
  FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM,
    nil,
    ErrorId,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
    lpMsgBuf,
    BufSize,
    nil
  );
  Result:=lpMsgBuf;
  // Free the buffer.
  FreeMem(lpMsgBuf,BufSize);
end;

procedure LastErrorMsg(RaiseEx:Boolean=TRUE);
begin
  ErrorMsg(GetErrorMsg(GetLastError),RaiseEx);
end;

procedure ErrorMsg(const Msg:String; RaiseEx:Boolean=TRUE);
begin
  Application.MessageBox(
    PChar(Msg),
    PChar('Ошибка в ['+GetModuleFullName+'.exe]'),
    MB_ICONINFORMATION or MB_OK
  );
  if RaiseEx then raise Exception.Create(Msg);
end;

procedure CheckMinMax(var Value:Double; Min,Max:Double; ed:TWinControl);
begin
  try
    Value:=StrToFloat(TWinControlHack(ed).Text);
    if (Value<Min) or (Max<Value) then begin
      ErrorMsg('Значение не в диапазоне от '+
        Format('%g',[Min])+' до '+Format('%g',[Max])
      );
    end;
  except
    ed.SetFocus;
    raise;
  end;
end;

function TByteStringList.Find(const S: string;
  var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := CompareStr(Self[I], S);
    if C < 0 then L := I + 1 else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        if Duplicates <> dupAccept then L := I;
      end;
    end;
  end;
  Index := L;
end;

function GetModuleFullName:String;
const
  MFN:String='';
var
  P:PChar;
  ModuleName:array[0..255] of Char;
begin
  if MFN = '' then
  begin
    GetModuleFileName(MainInstance,ModuleName,SizeOf(ModuleName));
    OemToAnsi(ModuleName,ModuleName);
    P:=AnsiStrRScan(ModuleName,'.');
    if P<>nil then P^:=#0;
    MFN:=ModuleName;
  end;
  Result:=MFN;
end;

procedure CalcScaleParams(
  const Start,Length:float; MaxScCount:Integer;
  const Steps:array of TScaleParamsRec;
  var ScStart,ScStep:float; var Digits,ScCount:Integer);
var
  i:Integer;
  LgStep:Integer;
  tScCount:Integer;
  tScStep:Float;
begin
  ScCount:=0;
  for i:=0 to High(Steps) do begin
    LgStep:=Ceil(Ln(Length/MaxScCount)/Ln(Steps[i].Base));
    if LgStep<Steps[i].Min then LgStep:=Steps[i].Min
    else if Steps[i].Max<LgStep then continue;
    tScStep:=Power(Steps[i].Base,LgStep);
    tScCount:=Trunc(Length/tScStep)+1;
    if ScCount<tScCount then begin
      ScCount:=tScCount;
      ScStep:=tScStep;
      if tScStep<1 then Digits:=-LgStep else Digits:=0;
      ScStart:=(Trunc(Start/ScStep))*ScStep;
    end;
  end;
end;

function Power(x:float; n:Integer):float;
begin
  Result:=1.0;
  if n<0 then begin
    n:=-n; x:=1/x;
  end;
  while n>0 do begin Result:=Result*x; Dec(n); end;
end;

end.

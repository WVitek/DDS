{$OPTIMIZATION ON}
{$RANGECHECKS OFF}
unit DblGraphics;

interface

uses Windows,Classes,Graphics,Misc;

const
  BMP256InfoStatSize=SizeOf(TDblPoint);

type
  TCanvasWrapper=class(TObject)
  protected
    FCanvas:TCanvas;
    FDstShift:TPoint;
    FSrcShift:TDblPoint;
    FSrcScale:TDblPoint;
  private
    function  GetBrush: TBrush;
    function  GetFont: TFont;
    function  GetPen: TPen;
    procedure SetPenWidth(const Value: float);
    procedure SetFontHeight(const Value: float);
    function GetOptScale: float;
  public
    procedure SetConversion(const Src:TDblRect; const Dst:TRect);virtual;
    procedure Convert(const Src:TDblPoint; var Dst:TPoint);overload;
    procedure Convert(const Src:TPoint; var Dst:TDblPoint);overload;
    procedure ConvertToFix(const Src:TDblPoint; var Dst:TPoint);overload;
    constructor Create(Canvas:TCanvas);
    procedure FillRect(const R: TDblRect);
    procedure FrameRect(const R: TDblRect);
    procedure LineTo(const P:TDblPoint);
    procedure MoveTo(const P:TDblPoint);
    procedure Rectangle(const R: TDblRect);
    procedure StretchDraw(const R: TDblRect; Graphic: TGraphic);
    function  TextExtent(const Text: string): TDblPoint;
    procedure TextOut(const P:TDblPoint; const Text: string);
  public
    property DstShift:TPoint read FDstShift;
    property SrcShift:TDblPoint read FSrcShift;
    property SrcScale:TDblPoint read FSrcScale;
    property Brush:TBrush read GetBrush;
    property Pen:TPen read GetPen;
    property PenWidth:float write SetPenWidth;
    property Font:TFont read GetFont;
    property FontHeight:float write SetFontHeight;
    property OptScale:float read GetOptScale;
  end;

  TByteArray = packed array[0..MaxInt-1] of Byte;
  PByteArray = ^TByteArray;

  PBMP256Info = ^TBMP256Info;
  TBMP256Info = packed record
    Limit:TPoint;
    L:array[0..(MaxInt-BMP256InfoStatSize) div SizeOf(Pointer)-1] of PByteArray;
  end;

  TBMP256CanvasWrapper=class(TCanvasWrapper)
  private
    PenPos:TPoint;
    BI:PBMP256Info;
    function GetPenIntPos: TPoint;
  public
    property PenIntPos:TPoint read GetPenIntPos;
    constructor Create(BM:TBitmap);
    procedure AAMoveTo(const P:TDblPoint);
    procedure AALineTo(const P:TDblPoint);
    destructor Destroy;override;
  end;

  TPalEntry=packed record
    R,G,B,Flags:Byte;
  end;

  TPalette=packed record
    Ver,Num:word;
    Entry:array[0..255] of TPalEntry;
  end;

  PPalette=^TPalette;

function CreateBMP256Info(BM:TBitmap):PBMP256Info;
procedure FreeBMP256Info(BI:PBMP256Info);

type
  TColorMixTbl=packed array[0..3,0..255] of Byte;
var
  MixTbl:array[0..255] of TColorMixTbl;

implementation

type
  fix=Integer;
  TAntiAliasCoeffTbl=packed array[-1..1] of Byte;
  TLineTripTbl=array[0..3] of TAntiAliasCoeffTbl;
var
  TripTbl:array[-3..3] of TLineTripTbl;

function float_fix(const x:Single):fix;
const
  max:single=+32767;
  min:single=-32767;
begin
  if      x<min then Result:=-MaxInt
  else if max<x then Result:=+MaxInt
  else Result:=Trunc(x*65536);
end;

function fix_float(x:fix):Float;
const
  Coeff=1/65536;
begin
  Result:=x*Coeff;
end;

function int_fix(x:Integer):Integer;
begin
  Result:=x shl 16;
end;

function fix_cint(x:fix):Integer;register;
asm
  add eax,65535
  sar eax,16
end;

function fix_int(x:fix):Integer;register;
asm
  sar eax,16
end;

function fix_fint(x:fix):Integer;register;
asm
  dec eax
  sar eax,16
end;

procedure AntiAliazedLine(const BI:TBMP256Info; p1,p2:TPoint; Color:Byte);
var
  i,ei,iv,ivLimit:Integer;
  v,dv:fix;
  fdv:Single;
  fv:Byte;
  TmpP:TPoint;
  LTT:^TLineTripTbl;
  AAC:^TAntiAliasCoeffTbl;
  ColorMix:^TColorMixTbl;
begin
  ColorMix:=@(MixTbl[Color]);
  if Abs(p1.x-p2.x)>Abs(p1.y-p2.y) then begin
    if p1.x>p2.x then begin
      TmpP:=p1; p1:=p2; p2:=TmpP;
    end;
    i:=fix_cint(p1.x);
    if BI.Limit.x<i then exit else if i<0 then i:=0;
    ei:=fix_fint(p2.x);
    if ei<0 then exit else if BI.Limit.x<ei then ei:=BI.Limit.x;
    if p1.x<p2.x then fdv:=(p1.y-p2.y)/(p1.x-p2.x) else fdv:=0;
    dv:=float_fix(fdv);
    LTT:=@(TripTbl[Round(fdv*3)]);
    v:=p1.y+trunc(dv*fix_float(int_fix(i)-p1.x));
    ivLimit:=BI.Limit.y;
    while i<=ei do begin
      iv:=fix_int(v);
      fv:=v shr 14 and 3;
      AAC:=@(LTT[fv]);
      if (0<=iv) and (iv<=ivLimit) then begin
        if 0<iv then BI.L[iv-1][i]:=ColorMix[ AAC[-1], BI.L[iv-1][i] ];
        BI.L[iv][i]:=ColorMix[ AAC[0], BI.L[iv][i] ];
        if iv<ivLimit then BI.L[iv+1][i]:=ColorMix[ AAC[+1], BI.L[iv+1][i] ];
      end;
      inc(v,dv);
      inc(i);
    end;
  end
  else begin
    if p1.y>p2.y then begin
      TmpP:=p1; p1:=p2; p2:=TmpP;
    end;
    i:=fix_cint(p1.y);
    if BI.Limit.y<i then exit else if i<0 then i:=0;
    ei:=fix_fint(p2.y);
    if ei<0 then exit else if BI.Limit.y<ei then ei:=BI.Limit.y;
    if p1.y<p2.y then fdv:=(p1.x-p2.x)/(p1.y-p2.y) else fdv:=0;
    dv:=float_fix(fdv);
    LTT:=@(TripTbl[Round(fdv*3)]);
    v:=p1.x+trunc(dv*fix_float(int_fix(i)-p1.y));
    ivLimit:=BI.Limit.x;
    while i<=ei do begin
      iv:=fix_int(v);
      fv:=v shr 14 and 3;
      AAC:=@(LTT[fv]);
      if (0<=iv) and (iv<=ivLimit) then begin
        if 0<iv then BI.L[i][iv-1]:=ColorMix[ AAC[-1], BI.L[i][iv-1] ];
        BI.L[i][iv]:=ColorMix[ AAC[0], BI.L[i][iv] ];
        if iv<ivLimit then BI.L[i][iv+1]:=ColorMix[ AAC[+1], BI.L[i][iv+1] ];
      end;
      inc(v,dv);
      inc(i);
    end;
  end;
end;

function CreateBMP256Info(BM:TBitmap):PBMP256Info;
var
  i:Integer;
begin
  GetMem(Result,BMP256InfoStatSize+BM.Height*SizeOf(Pointer));
  Result.Limit.x:=BM.Width-1;
  Result.Limit.y:=BM.Height-1;
  for i:=0 to BM.Height-1 do Result.L[i]:=BM.ScanLine[i];
end;

procedure FreeBMP256Info(BI:PBMP256Info);
begin
  FreeMem(BI,BMP256InfoStatSize+(BI.Limit.Y+1)*SizeOf(Pointer));
end;

{ TCanvasWrapper }

procedure TCanvasWrapper.Convert(const Src: TDblPoint; var Dst: TPoint);
begin
  Dst.x:=Trunc((Src.x+SrcShift.x)*SrcScale.x)+DstShift.x;
  Dst.y:=Trunc((Src.y+SrcShift.y)*SrcScale.y)+DstShift.y;
end;

procedure TCanvasWrapper.Convert(const Src: TPoint; var Dst: TDblPoint);
begin
  Dst.x:=(Src.x-DstShift.x)/SrcScale.x-SrcShift.x;
  Dst.y:=(Src.y-DstShift.y)/SrcScale.y-SrcShift.y;
end;

procedure TCanvasWrapper.ConvertToFix(const Src: TDblPoint; var Dst: TPoint);
begin
  Dst.x:=float_fix((Src.x+SrcShift.x)*SrcScale.x)+int_fix(DstShift.x);
  Dst.y:=float_fix((Src.y+SrcShift.y)*SrcScale.y)+int_fix(DstShift.y);
end;

constructor TCanvasWrapper.Create(Canvas: TCanvas);
begin
  inherited Create;
  FCanvas:=Canvas;
  FSrcScale.x:=1.0;
  FSrcScale.y:=1.0;
end;

procedure TCanvasWrapper.FillRect(const R: TDblRect);
var
  DR:TRect;
begin
  Convert(R.P1,DR.TopLeft);
  Convert(R.P2,DR.BottomRight);
  FCanvas.FillRect(DR);
end;

procedure TCanvasWrapper.FrameRect(const R: TDblRect);
var
  DR:TRect;
begin
  Convert(R.P1,DR.TopLeft);
  Convert(R.P2,DR.BottomRight);
  FCanvas.FrameRect(DR);
end;

function TCanvasWrapper.GetBrush: TBrush;
begin
  Result:=FCanvas.Brush;
end;

function TCanvasWrapper.GetFont: TFont;
begin
  Result:=FCanvas.Font;
end;

function TCanvasWrapper.GetOptScale: float;
begin
  if SrcScale.x<SrcScale.y
  then Result:=SrcScale.x
  else Result:=SrcScale.y;
//  Result:=(SrcScale.x+SrcScale.y)*0.5;
end;

function TCanvasWrapper.GetPen: TPen;
begin
  Result:=FCanvas.Pen;
end;

procedure TCanvasWrapper.LineTo(const P: TDblPoint);
var
  DP:TPoint;
begin
  Convert(P,DP);
  FCanvas.LineTo(DP.x,DP.y);
end;

procedure TCanvasWrapper.MoveTo(const P: TDblPoint);
var
  DP:TPoint;
begin
  Convert(P,DP);
  FCanvas.MoveTo(DP.x,DP.y);
end;

procedure TCanvasWrapper.Rectangle(const R: TDblRect);
var
  DR:TRect;
begin
  Convert(R.P1,DR.TopLeft);
  Convert(R.P2,DR.BottomRight);
  FCanvas.Rectangle(DR);
end;

procedure TCanvasWrapper.SetConversion(const Src: TDblRect;
  const Dst: TRect);
begin
  FSrcShift.x:=-Src.P1.x;
  FSrcShift.y:=-Src.P1.y;
  FDstShift:=Dst.TopLeft;
  FSrcScale.x:=(Dst.Right-Dst.Left)/(Src.x2-Src.x1);
  FSrcScale.y:=(Dst.Bottom-Dst.Top)/(Src.y2-Src.y1);
end;

procedure TCanvasWrapper.SetFontHeight(const Value: float);
var
  h:Integer;
begin
  h:=Round(Value*OptScale);
  if h<1 then h:=1;
  FCanvas.Font.Height:=h;
end;

procedure TCanvasWrapper.SetPenWidth(const Value: float);
var
  w:Integer;
begin
  w:=Round(Value*OptScale);
  if w<1 then w:=1;
  FCanvas.Pen.Width:=w
end;

procedure TCanvasWrapper.StretchDraw(const R: TDblRect; Graphic: TGraphic);
var
  DR:TRect;
begin
  Convert(R.P1,DR.TopLeft);
  Convert(R.P2,DR.BottomRight);
  FCanvas.StretchDraw(DR,Graphic);
end;

function TCanvasWrapper.TextExtent(const Text: string): TDblPoint;
var
  S:TSize;
  P:TPoint;
begin
  S:=FCanvas.TextExtent(Text);
  P.x:=S.cx; P.y:=S.cy;
  Convert(P,Result);
end;

procedure TCanvasWrapper.TextOut(const P: TDblPoint; const Text: string);
var
  DP:TPoint;
begin
  Convert(P,DP);
  FCanvas.TextOut(DP.x,DP.y,Text);
end;

{ TBMP256CanvasWrapper }

constructor TBMP256CanvasWrapper.Create(BM: TBitmap);
begin
  inherited Create(BM.Canvas);
  BI:=CreateBMP256Info(BM);
end;

destructor TBMP256CanvasWrapper.Destroy;
begin
  FreeBMP256Info(BI);
  inherited;
end;

procedure TBMP256CanvasWrapper.AALineTo(const P: TDblPoint);
var
  NewPos:TPoint;
begin
  ConvertToFix(P,NewPos);
  AntiAliazedLine(BI^,PenPos,NewPos,Pen.Color and $FF);
  PenPos:=NewPos;
end;

procedure TBMP256CanvasWrapper.AAMoveTo(const P: TDblPoint);
begin
  ConvertToFix(P,PenPos);
end;

function TBMP256CanvasWrapper.GetPenIntPos: TPoint;
begin
  Result.x:=fix_int(PenPos.x);
  Result.y:=fix_int(PenPos.y);
end;


procedure Initialize;
const
  Inv3=1/3;
  Inv9=1/9;
var
  i,j,k:Integer;
  CA:^TAntiAliasCoeffTbl;
  fill,fj:Single;
begin
  for i:=0 to 3 do begin
    fill:=(Sqrt(1+Inv9*i*i)-1)*0.5+0.17;
    for j:=0 to 3 do begin
      CA:=@(TripTbl[i,j]);
      fj:=j*Inv3;
      if fj<fill then begin
        CA[-1]:=Round(fill*3);
        CA[ 0]:=3;
      end
      else begin
        CA[-1]:=0;
        CA[ 0]:=Round((1-fj+fill)*3);
      end;
      CA[+1]:=Round((fj+fill)*3);
    end;
  end;

  for i:=0 to 3 do for j:=0 to 3 do for k:=-1 to 1
  do if TripTbl[i,j,k]>3 then TripTbl[i,j,k]:=3;

  for i:=-3 to -1 do TripTbl[i]:=TripTbl[-i];
  // mix tbl
  for i:=0 to 255 do for j:=0 to 3 do for k:=0 to 255
  do MixTbl[i,j,k]:=Trunc((i*j+k*(3-j))*Inv3);
end;

initialization
  Initialize;
end.

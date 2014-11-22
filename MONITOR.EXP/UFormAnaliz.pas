unit UFormAnaliz;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls,
  Misc,UFrameGraph,DataTypes2,SensorTypes,UFormPipe,UWaveFormComputer;

type
  TFormAnaliz = class(TForm)
    pbGraphs: TPaintBox;
    pbCorrGraph: TPaintBox;
    cbCorrBlock: TComboBox;
    cbSetVisir: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure pbCorrGraphPaint(Sender: TObject);
    procedure pbGraphsPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure pbCorrGraphMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure miCalculateClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure cbCorrBlockChange(Sender: TObject);
    procedure cbSetVisirClick(Sender: TObject);
    procedure pbGraphsDblClick(Sender: TObject);
  private
    { Private declarations }
    Pipe:TFormPipe;
    Graph1,Graph2:TFrameGraph;
    ReadyCnt:Integer;
    MaxDT:Integer;
    LabelTime1:TDateTime;
    SrcData1,DrawData1:TArrayOfSingle;
    SrcData2,DrawData2:TArrayOfSingle;
    GoodnessGraph:TArrayOfSingle;
    FVisir:Integer;
    ChangeTimer:Cardinal;
    SourceChanged:Boolean;
    procedure InitRefresh;
    procedure DoneRefresh;
    procedure OnDataUpdate(Sender:TAnalogDataTrack; FromRec:Int64;
      const Data:TADDynamicArray);
    function NotReadyToDraw:Boolean;
    procedure Set_Visir(const Value: Integer);
    function CalcCorrelation(PRE,DT,BlockSize:Integer; WaveAlpha:Double):Double;
    function GetCorrBlock: Integer;
    function GetRecsPerSec: Integer;
    procedure SetVisirOnMax;
  private
    wfc:TWaveFormComputer;
    TmpWaveAlpha:Double;
    WaveAlpha1,WaveAlpha2:Double;
    Preload:Integer;
    function CalcCorr2:Double;
    property Visir:Integer read FVisir write Set_Visir;
    property CorrBlock:Integer read GetCorrBlock;
  public
    { Public declarations }
    procedure TimerProc(Interval:Cardinal);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    function CalcAlpha:Double;
    property RecsPerSec:Integer read GetRecsPerSec;
  end;

var
  FormAnaliz: TFormAnaliz;

implementation

{$R *.DFM}

uses
  Main,UFrameGroup,Minimize;

const
  MaxCorrBlockInSec=120;
  WaveAlpha=0.017457;//0.02122;
  Alpha1=0.9;//0.8;
  Alpha2=0.0;//0.7;
  PreloadInSec=90+44;//21;// 90+Ln(0.01)/Ln(max(Alpha1,Alpha2));
  //SecPerDay=86400;

var
  FuncOptimizationSubj:function:Double of object;

function CallFuncOptimizationSubj:Double;
begin
  Result:=FuncOptimizationSubj;
end;

procedure FindMinMax(Data:PSingle; Count:Integer; var Min,Max:Single);
var
  Tmp:Float;
begin
  Min:=Data^; Max:=Data^; Dec(Count); Inc(Data);
  while Count>0 do begin
    Tmp:=Data^;
    if Tmp<Min then Min:=Tmp
    else if Max<Tmp then Max:=Tmp;
    Inc(Data);
    Dec(Count);
  end;
end;

procedure DrawGraph(C:TCanvas; Data:PSingle; Count:Integer;
  Min,Max:Single; W,H:Integer; DrawZeroLine:Boolean=False);
var
  OfsY,SclY,SclX:Single;
  First:Boolean;
  i,X,Y:Integer;
  clrSaved:TColor;
begin
  if Min=Max then begin Min:=Min-1; Max:=Max+1; end;
  SclY:=H/(Min-Max); OfsY:=-SclY*Max;
  SclX:=W/(Count-1);
  if DrawZeroLine and (Min<0) and (0<Max) then begin
    clrSaved:=C.Pen.Color; C.Pen.Color:=clSilver;
    Y:=Round(OfsY);
    C.MoveTo(0,Y); C.LineTo(W-1,Y);
    C.Pen.Color:=clrSaved;
  end;
  First:=True;
  for i:=0 to Count-1 do begin
    X:=Round(i*SclX);
    Y:=Round(Data^*SclY+OfsY);
    if First then C.MoveTo(X,Y)
    else C.LineTo(X,Y);
    First:=False;
    Inc(Data);
  end;
end;

//***** TFormAnaliz

procedure TFormAnaliz.pbCorrGraphMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Shift=[ssLeft] then begin
    Visir:=Round(X*(Length(GoodnessGraph)-1)/pbGraphs.Width);
    Invalidate;
  end
  else if Shift=[ssRight] then begin
    if GoodnessGraph<>nil
    then FillChar(GoodnessGraph[0],Length(GoodnessGraph)*SizeOf(GoodnessGraph[0]),0);
  end;
end;

procedure TFormAnaliz.miCalculateClick(Sender: TObject);
begin
  if Pipe<>nil
  then Pipe.ActiveGroup.SpdBtnCalculation.Click;
end;

procedure TFormAnaliz.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FormMain.FlashAnalizForm;
end;

function TFormAnaliz.IsShortCut(var Message: TWMKey): Boolean;
begin
  Result:=(Pipe<>nil) and Pipe.menuSys.IsShortCut(Message) or
    inherited IsShortCut(Message);
end;

procedure TFormAnaliz.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Pipe<>nil
  then Pipe.FormKeyPress(Sender,Key);
  Key:=#0;
end;

procedure TFormAnaliz.FormCreate(Sender: TObject);
begin
  DoubleBuffered:=True;
  Left:=0;
  Top:=GetSystemMetrics(SM_CYFULLSCREEN)+GetSystemMetrics(SM_CYCAPTION)-Height;
  if Screen.ActiveForm is TFormPipe
  then Pipe:=TFormPipe(Screen.ActiveForm);
end;

procedure TFormAnaliz.TimerProc(Interval:Cardinal);
var
  Group:TFrameGroup;
  G1,G2:TFrameGraph;
  W:Double;
begin
  if Screen.ActiveForm is TFormPipe
  then Pipe:=TFormPipe(Screen.ActiveForm)
  else if (Screen.ActiveForm<>Self) or (Pipe=nil)
  then exit;
  if Pipe.SpyMode then begin
    if Visible then Hide;
  end
  else begin
    Group:=Pipe.ActiveGroup;
    G1:=Group.ActiveGraph2;
    G2:=Group.ActiveGraph1;
    if G1.Kilometer<G2.Kilometer then begin
      WaveAlpha1:=Group.WaveAlpha1;
      WaveAlpha2:=Group.WaveAlpha2;
    end
    else begin
      WaveAlpha1:=Group.WaveAlpha2;
      WaveAlpha2:=Group.WaveAlpha1;
    end;
    Inc(ChangeTimer,Interval);
    if not Visible then Show;
    if SourceChanged and ((MaxDT=0) or (ChangeTimer>=500)) then begin
      SourceChanged:=False;
      W:=Group.WaveSpeed*0.001;
      if W<=0 then W:=1.150;
      MaxDT:=Round(Abs(G1.Kilometer-G2.Kilometer)/W*1.1*RecsPerSec);
      if G1.RecsPerDay<=86400
      then ClientWidth:=Round(MaxDT)*2
      else ClientWidth:=Round(MaxDT);
      if MaxDT>0 then InitRefresh;
    end;
    if (G1<>Graph1) or (G2<>Graph2) or (G1.LabelTime<>LabelTime1)
    then begin
      SourceChanged:=True; ChangeTimer:=0;
      Graph1:=G1; Graph2:=G2;
      LabelTime1:=G1.LabelTime;
    end;
  end;
end;

procedure TFormAnaliz.pbCorrGraphPaint(Sender: TObject);
var
  PB:TPaintBox absolute Sender;
  C:TCanvas;
  W,H,X:Integer;
  R:TRect;
  Min,Max,D:Single;
begin
  W:=PB.Width; H:=PB.Height;
  C:=PB.Canvas;
  R.Top:=0; R.Left:=0; R.Right:=W-1; R.Bottom:=H-1;
  C.Brush.Color:=clWhite;
  C.Brush.Style:=bsSolid;
  C.FillRect(R);
  if NotReadyToDraw then exit;
  C.Pen.Color:=clRed;
  X:=Round(W*Visir/(Length(GoodnessGraph)-1));
  C.MoveTo(X,0); C.LineTo(X,H-1);
  C.Pen.Color:=clBlack;
  FindMinMax(@(GoodnessGraph[0]),Length(GoodnessGraph),Min,Max);
//  {$IFDEF UseCorrelation}
  if Max-Min<1 then begin
    D:=(1-(Max-Min))*0.5;
  end
  else {.$ENDIF} D:=(Max-Min)*0.05;
  DrawGraph(C,@(GoodnessGraph[0]),Length(GoodnessGraph),Min-D,Max+D,W,H,True);
end;

procedure TFormAnaliz.pbGraphsPaint(Sender: TObject);
var
  PB:TPaintBox absolute Sender;
  C:TCanvas;
  W,H,n:Integer;
  R:TRect;
{$IFNDEF _UseCorrelation}
  Mn,Mx:Single;
{$ENDIF}
  Min,Max,D:Single;
begin
  W:=PB.Width; H:=PB.Height;
  C:=PB.Canvas;
  R.Top:=0; R.Left:=0; R.Right:=W-1; R.Bottom:=H-1;
  C.Brush.Color:=clDkGray;
  C.Brush.Style:=bsSolid;
  C.FillRect(R);
  if NotReadyToDraw then exit;
  CalcCorrelation(0,Visir,CorrBlock,WaveAlpha);
  wfc.GetDrawData(DrawData1,DrawData2);
  n:=Length(DrawData1);// div 4;
//  if n>60 then n:=60;
{$IFDEF _UseCorrelation}
  FindMinMax(@(DrawData1[0]),n,Min,Max); D:=(Max-Min)*0.05;
  C.Pen.Color:=clAqua;
  DrawGraph(C,@(DrawData1[0]),n,Min-D,Max+D,W,H);
  FindMinMax(@(DrawData2[0]),n,Min,Max); D:=(Max-Min)*0.05;
  C.Pen.Color:=clLime;
  DrawGraph(C,@(DrawData2[0]),n,Min-D,Max+D,W,H);
{$ELSE}
{
  FindMinMax(@(DrawData1[0]),n,Mn,Max);
  FindMinMax(@(DrawData2[0]),n,Min,Mx);
  if Mn<Min then Min:=Mn;
  if Max<Mx then Max:=Mx;
  D:=(Max-Min)*0.05;
}
  FindMinMax(@(DrawData1[0]),n,Min,Max);
  D:=(Max-Min);
//
  Min:=Min-D; Max:=Max+D;
  C.Pen.Color:=clAqua;
  DrawGraph(C,@(DrawData1[0]),n,Min,Max,W,H);
  C.Pen.Color:=clLime;
  DrawGraph(C,@(DrawData2[0]),n,Min,Max,W,H);
{$ENDIF}
end;

function TFormAnaliz.GetCorrBlock: Integer;
begin
  if cbCorrBlock.ItemIndex=-1 then cbCorrBlock.ItemIndex:=4;
  Result:=StrToInt(cbCorrBlock.Text)*RecsPerSec;
end;

procedure TFormAnaliz.FormResize(Sender: TObject);
var
  CH:Integer;
begin
  CH:=ClientHeight-cbCorrBlock.Height;
  pbGraphs.Width:=ClientWidth;
  pbGraphs.Height:=CH div 2;
  pbCorrGraph.Width:=ClientWidth;
  pbCorrGraph.Top:=pbGraphs.Top+pbGraphs.Height;
  pbCorrGraph.Height:=CH-pbGraphs.Height;
end;

procedure TFormAnaliz.InitRefresh;
var
  StartRec:Int64;
  Count:Integer;
  RPS:Integer;
begin
  ReadyCnt:=0;
  RPS:=RecsPerSec;
  Preload:=PreloadInSec*RPS;
  StartRec:=Trunc(Graph1.LabelTime*Graph1.RecsPerDay)-Preload;
  Count:=Round(Preload+MaxCorrBlockInSec*RecsPerSec);
  Graph1.ADTrack.requestData(StartRec,Count,OnDataUpdate);
  Count:=Count+MaxDT;
  Graph2.ADTrack.requestData(StartRec,Count,OnDataUpdate);
end;

procedure TFormAnaliz.OnDataUpdate(Sender: TAnalogDataTrack;
  FromRec: Int64; const Data: TADDynamicArray);
var
  i:Integer;
  Dst:TArrayOfSingle;
  F1Value,F2Value,SValue:Single;
  First:Boolean;
begin
  SetLength(Dst,Length(Data));
  F1Value:=0; F2Value:=0; First:=True;
  for i:=0 to High(Dst) do begin
    if ValidAD(Data[i]) then begin
      SValue:=Data[i].Value;
      if First then begin
        F1Value:=SValue; F2Value:=SValue; First:=False;
      end
      else begin
        F1Value:=F1Value*Alpha1+SValue*(1-Alpha1);
        F2Value:=F2Value*Alpha2+SValue*(1-Alpha2);
      end;
    end;
    Dst[i]:=F2Value;//-F1Value;
  end;
  if Sender=Graph1.ADTrack
  then begin SrcData1:=Dst; Inc(ReadyCnt); end
  else if Sender=Graph2.ADTrack
  then begin SrcData2:=Dst; Inc(ReadyCnt); end;
  if ReadyCnt=2 then DoneRefresh;
end;

procedure TFormAnaliz.DoneRefresh;
var
  DT:Integer;
  P,PS:Double;
  CorrBlockLen:Integer;
begin
  SetLength(GoodnessGraph,MaxDT);
  FillChar(GoodnessGraph[0],MaxDT*SizeOf(GoodnessGraph[0]),0);
//  for DT:=0 to MaxDT-1 do GoodnessGraph[DT]:=CalcCorrelation(DT,CorrBlock,WaveAlpha);
//{
  CorrBlockLen:=CorrBlock;
  P:=CorrBlockLen-1;
  PS:=P*0.1;
  if PS<1 then PS:=1;
  while P>=0 do begin
    for DT:=0 to MaxDT-1 do GoodnessGraph[DT]:=GoodnessGraph[DT]+
      CalcCorrelation(Round(P),DT,CorrBlockLen,WaveAlpha);
    P:=P-PS;
  end;
//}
  if cbSetVisir.Checked then SetVisirOnMax;
  Invalidate;
end;

function TFormAnaliz.NotReadyToDraw: Boolean;
begin
  Result:=(ReadyCnt<2) or (Length(GoodnessGraph)=0) or (Visir<0);
end;

procedure TFormAnaliz.Set_Visir(const Value: Integer);
begin
  FVisir := Value;
  Graph2.LabelTime:=Graph1.LabelTime+FVisir*Graph1.Period;
  Graph2.View1ChangeViewState;
  Caption:=Format('Z[%.1f]=%.5f (Анализатор)',[FVisir/RecsPerSec,GoodnessGraph[FVisir]]);
end;

function TFormAnaliz.CalcCorrelation(PRE, DT, BlockSize:Integer; WaveAlpha:Double):Double;
var
  LdW:Single;
begin
  LdW:=(Graph2.Kilometer-Graph1.Kilometer) /
    (TFrameGroup(Graph1.Parent).WaveSpeed * 0.001);
  if LdW<0 then LdW:=-LdW;
  wfc.Alpha1:=WaveAlpha1;
  wfc.Alpha2:=WaveAlpha2;
  wfc.Init(LdW,DT,@(SrcData1[Preload-PRE]),@(SrcData2[Preload-PRE+DT]),BlockSize);
  Result:=wfc.CalcCorrelation;
end;

procedure TFormAnaliz.cbCorrBlockChange(Sender: TObject);
begin
  DoneRefresh;
end;

procedure TFormAnaliz.cbSetVisirClick(Sender: TObject);
begin
  if cbSetVisir.Checked then SetVisirOnMax;
end;

procedure TFormAnaliz.SetVisirOnMax;
var
  DT,DTbest:Integer;
  Val,Best:Double;
begin
  Best:=GoodnessGraph[0];
  DTbest:=0;
  for DT:=1 to MaxDT-1 do begin
    Val:=GoodnessGraph[DT];
    if Best<Val then begin DTbest:=DT; Best:=Val; end;
  end;
  Visir:=DTbest;
  Invalidate;
end;

procedure TFormAnaliz.pbGraphsDblClick(Sender: TObject);
begin
  Application.MessageBox( PChar(Format('Alpha = %g',[CalcAlpha])),
    'Optimal Alpha calculated',MB_OK or MB_ICONINFORMATION );
end;

function TFormAnaliz.CalcCorr2: Double;
begin
  wfc.Alpha1:=TmpWaveAlpha;
  wfc.Alpha2:=1;
  Result:=-wfc.CalcCorrelation;
end;

function TFormAnaliz.CalcAlpha: Double;
begin
  // find optimal TmpWaveAlpha
  FuncOptimizationSubj:=CalcCorr2;
  MinimizeFunc(CallFuncOptimizationSubj,[@TmpWaveAlpha],[0.005],[0.95],1e-9);
  Result:=TmpWaveAlpha;
end;

function TFormAnaliz.GetRecsPerSec: Integer;
const
  OneDivSecPerDay = 1.0/86400;
begin
  Result:=Trunc(Graph1.RecsPerDay*OneDivSecPerDay);
end;

end.



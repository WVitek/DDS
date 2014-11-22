unit UFormAnaliz;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls,
  Misc,UFrameGraph,DataTypes2,SensorTypes,UFormPipe;

type
  TFormAnaliz = class(TForm)
    pbGraphs: TPaintBox;
    pbCorrGraph: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure pbCorrGraphPaint(Sender: TObject);
    procedure pbGraphsPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure pbCorrGraphMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure miCalculateClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    Pipe:TFormPipe;
    Graph1,Graph2:TFrameGraph;
    ReadyCnt:Integer;
    MaxDT:Integer;
    LabelTime1:TDateTime;
    SrcData1,Data1:TArrayOfSingle;
    SrcData2,Data2:TArrayOfSingle;
    CorrGraph:TArrayOfSingle;
    FVisir:Integer;
    CurSubDelta:Integer;
    ChangeTimer:Cardinal;
    SourceChanged:Boolean;
    procedure InitRefresh;
    procedure DoneRefresh;
    procedure OnDataUpdate(Sender:TAnalogDataTrack; FromRec:Int64;
      const Data:TADDynamicArray);
    function NotReadyToDraw:Boolean;
    procedure Set_Visir(const Value: Integer);
    procedure CalcCorrGraph(SubDelta,CorrBlock:Integer);
    function GetRecsPerSec: Integer;
    procedure CalcSubData(const Src:TArrayOfSingle; var Dst:TArrayOfSingle;
      SubDelta:Integer);
  private
    MinSubDelta, MaxSubDelta, MinCorrBlock, MaxCorrBlock: Integer;
    property Visir:Integer read FVisir write Set_Visir;
  public
    { Public declarations }
    procedure TimerProc(Interval:Cardinal);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    property RecsPerSec:Integer read GetRecsPerSec;
  end;

var
  FormAnaliz: TFormAnaliz;

implementation

{$R *.DFM}

uses
  Main,UFrameGroup,Minimize;

const
  MinSubDeltaSec=10;
  MaxSubDeltaSec=30;
  MinCorrBlockSec=30;
  MaxCorrBlockSec=90;
const
  Alpha=0.0;
var
  FCorrBlock,FSubDelta:Double;

function MyFunc:Double;
var
  DT:Integer;
  G:TArrayOfSingle;
  Min,Max:Double;
begin
  FormAnaliz.CalcCorrGraph(Trunc(FSubDelta),Trunc(FCorrBlock));
  G:=FormAnaliz.CorrGraph;
  Min:=G[0]; Max:=G[0];
  for DT:=1 to High(G) do begin
    if Max<G[DT] then Max:=G[DT]
    else if G[DT]<Min then Min:=G[DT];
  end;
  Result:=Min-Max;
end;

procedure TFormAnaliz.CalcSubData(const Src:TArrayOfSingle; var Dst:TArrayOfSingle;
  SubDelta:Integer);
var
  i:Integer;
begin
  for i:=0 to High(Dst)
  do Dst[i]:=Src[MaxSubDelta+i]-Src[MaxSubDelta+i-SubDelta];
end;

procedure FindMinMax(Data:PSingle; Count:Integer; var Min,Max:Single);
begin
  Min:=Data^; Max:=Data^; Dec(Count); Inc(Data);
  while Count>0 do begin
    if Data^<Min then Min:=Data^
    else if Max<Data^ then Max:=Data^;
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
  SclX:=W/Count;
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
    Inc(ChangeTimer,Interval);
    if not Visible then Show;
    if SourceChanged and ((MaxDT=0) or (ChangeTimer>=500)) then begin
      W:=Group.WaveSpeed*0.001;
      if W<=0 then W:=1.150;
      MaxDT:=Round(Abs(G1.Kilometer-G2.Kilometer)/W*1.1*RecsPerSec);
      ClientWidth:=Round(MaxDT);//*2;
      if MaxDT>0 then InitRefresh;
      SourceChanged:=False;
      ChangeTimer:=0;
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
  X:=W*Visir div Length(CorrGraph);
  C.MoveTo(X,0); C.LineTo(X,H-1);
  FindMinMax(@(CorrGraph[0]),Length(CorrGraph),Min,Max);
  C.Pen.Color:=clBlack;
  D:=(Max-Min)*0.1;
  DrawGraph(C,@(CorrGraph[0]),Length(CorrGraph),Min-D,Max+D,W,H,True);
end;

procedure TFormAnaliz.pbGraphsPaint(Sender: TObject);
var
  PB:TPaintBox absolute Sender;
  C:TCanvas;
  W,H,n:Integer;
  R:TRect;
  Min,Max:Single;
begin
  W:=PB.Width; H:=PB.Height;
  C:=PB.Canvas;
  R.Top:=0; R.Left:=0; R.Right:=W-1; R.Bottom:=H-1;
  C.Brush.Color:=clDkGray;
  C.Brush.Style:=bsSolid;
  C.FillRect(R);
  if NotReadyToDraw then exit;
  C.Pen.Color:=clAqua;
  n:=Length(Data1);// div 4;
  FindMinMax(@(Data1[0]),n,Min,Max);
  DrawGraph(C,@(Data1[0]),n,Min,Max,W,H);
  //
  FindMinMax(@(Data2[Visir]),n,Min,Max);
  C.Pen.Color:=clLime;
  DrawGraph(C,@(Data2[Visir]),n,Min,Max,W,H);
end;

procedure TFormAnaliz.FormResize(Sender: TObject);
begin
  pbGraphs.Width:=ClientWidth;
  pbGraphs.Height:=ClientHeight div 2;
  pbCorrGraph.Width:=ClientWidth;
  pbCorrGraph.Top:=pbGraphs.Height;
  pbCorrGraph.Height:=ClientHeight-pbGraphs.Height;
end;

procedure TFormAnaliz.InitRefresh;
var
  StartRec:Int64;
  Count:Integer;
  RPS:Integer;
begin
  RPS:=RecsPerSec;
  MinSubDelta:=MinSubDeltaSec*RPS;
  MaxSubDelta:=MaxSubDeltaSec*RPS;
  MinCorrBlock:=MinCorrBlockSec*RPS;
  MaxCorrBlock:=MaxCorrBlockSec*RPS;
  //
  ReadyCnt:=0;
  StartRec:=Trunc(Graph1.LabelTime*Graph1.RecsPerDay);
  Count:=MaxSubDelta+MaxCorrBlock;
  Graph1.ADTrack.requestData(StartRec,Count,OnDataUpdate);
  Count:=MaxDT+MaxSubDelta+MaxCorrBlock;
  Graph2.ADTrack.requestData(StartRec,Count,OnDataUpdate);
end;

procedure TFormAnaliz.OnDataUpdate(Sender: TAnalogDataTrack;
  FromRec: Int64; const Data: TADDynamicArray);
var
  i:Integer;
  Dst:TArrayOfSingle;
  Value:Single;
  First:Boolean;
begin
  SetLength(Dst,Length(Data));
  Value:=0; First:=True;
  for i:=0 to High(Dst) do begin
    if ValidAD(Data[i]) then begin
      if First
      then begin Value:=Data[i].Value; First:=False; end
      else Value:=Value*Alpha+Data[i].Value*(1-Alpha);
    end;
    Dst[i]:=Value;
  end;
  if Sender=Graph1.ADTrack
  then begin SrcData1:=Dst; Inc(ReadyCnt); end
  else if Sender=Graph2.ADTrack
  then begin SrcData2:=Dst; Inc(ReadyCnt); end;
  if ReadyCnt=2 then DoneRefresh;
end;

procedure TFormAnaliz.DoneRefresh;
var
  DT,DTmax:Integer;
  SubDelta:Integer;
  DeltaStep:Integer;
  CorrBlock:Integer;
  Count:Integer;
  Val,Max:Double;
  Graph:array of Double;
begin
  SetLength(Data1,Length(SrcData1)-MaxSubDelta);
  SetLength(Data2,Length(SrcData2)-MaxSubDelta);
  SetLength(CorrGraph,MaxDT);
  SetLength(Graph,MaxDT);
  FillChar(Graph[0],Length(Graph)*SizeOf(Double),0);
//{
  Count:=0;
  CurSubDelta:=0;
  SubDelta:=MinSubDelta;
  DeltaStep:=5*RecsPerSec;
  while True do begin
    CorrBlock:=MinCorrBlock;
    while True do begin
      Inc(Count);
      CalcCorrGraph(SubDelta,CorrBlock);
      for DT:=0 to MaxDT-1 do Graph[DT]:=Graph[DT]+CorrGraph[DT];
      if CorrBlock=MaxCorrBlock then break;
      Inc(CorrBlock,Trunc(CorrBlock*0.2));
      if CorrBlock>MaxCorrBlock then CorrBlock:=MaxCorrBlock;
    end;
    if SubDelta=MaxSubDelta then break;
    Inc(SubDelta,DeltaStep);
    if SubDelta>MaxSubDelta then SubDelta:=MaxSubDelta;
  end;
  Val:=1/Count;
  for DT:=0 to MaxDT-1 do CorrGraph[DT]:=Graph[DT]*Val;
(*}
  MinimizeFunc(MyFunc,[@FCorrBlock,@FSubDelta],
    [MinCorrBlock,MinSubDelta],[MaxCorrBlock,MaxSubDelta],
    1,250);
//*)
  Max:=-1.7E+308; DTmax:=0;
  for DT:=0 to MaxDT-1 do begin
    Val:=CorrGraph[DT];
    if Max<Val then begin
      DTmax:=DT; Max:=Val;
    end;
  end;
  Visir:=DTmax;
  Repaint;
end;

function TFormAnaliz.NotReadyToDraw: Boolean;
begin
  Result:=(ReadyCnt<2) or (Length(CorrGraph)=0) or (Visir<0);
end;

procedure TFormAnaliz.pbCorrGraphMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Visir:=X*Length(CorrGraph) div pbGraphs.Width;
  Repaint;
end;

procedure TFormAnaliz.miCalculateClick(Sender: TObject);
begin
  if Pipe<>nil
  then Pipe.ActiveGroup.SpdBtnCalculation.Click;
end;

procedure TFormAnaliz.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
  FormAnaliz:=nil;
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
end;

procedure TFormAnaliz.Set_Visir(const Value: Integer);
begin
  FVisir := Value;
  Graph2.LabelTime:=Graph1.LabelTime+FVisir*Graph1.Period;
  Graph2.View1ChangeViewState;
  Caption:=Format('Ro(%.1f)=%.2f (Коррелятор)',[FVisir/RecsPerSec,CorrGraph[FVisir]]);
end;

procedure TFormAnaliz.CalcCorrGraph(SubDelta, CorrBlock: Integer);
var
  DT:Integer;
  D1,D2:PSingle;
  Mu1,Sigma1:Double;
  Mu2,Sigma2:Double;
begin
  if CurSubDelta<>SubDelta then begin
    CalcSubData(SrcData1,Data1,SubDelta);
    CalcSubData(SrcData2,Data2,SubDelta);
    CurSubDelta:=SubDelta;
  end;
  D1:=@(Data1[0]);
  CalcMuSigma(D1,CorrBlock,Mu1,Sigma1);
  if Sigma1=0
  then for DT:=0 to MaxDT-1 do CorrGraph[DT]:=0
  else begin
    for DT:=0 to MaxDT-1 do begin
      D2:=@(Data2[DT]);
      CalcMuSigma(D2,CorrBlock,Mu2,Sigma2);
      if Sigma2>0
      then CorrGraph[DT]:=Cov(D1,D2,Mu1,Mu2,CorrBlock)/(Sigma1*Sigma2)
      else CorrGraph[DT]:=0;
    end;
  end;
end;

function TFormAnaliz.GetRecsPerSec: Integer;
const
  OneDivSecPerDay = 1/86400;
begin
  Result:=Round(Graph1.RecsPerDay*OneDivSecPerDay);
end;

end.

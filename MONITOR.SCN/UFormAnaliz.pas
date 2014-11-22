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
    cbFilterLen: TComboBox;
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
    procedure cbFilterLenChange(Sender: TObject);
    procedure pbGraphsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    Pipe:TFormPipe;
    Graph1,Graph2:TFrameGraph;
    ReadyCnt:Integer;
    MaxDT:Integer;
    LabelTime1:TDateTime;
    SrcData1,DrawData1:TArrayOfSingle;
    SrcData2,DrawData2:TArrayOfSingle;
    SimilarityGraph,SimilGraph2:TArrayOfSingle;
    FVisir:Integer;
    ChangeTimer:Cardinal;
    SourceChanged:Boolean;
    procedure InitRefresh;
    procedure DoneRefresh;
    procedure OnDataUpdate(Sender:TAnalogDataTrack; FromRec:Int64;
      const Data:TADDynamicArray);
    function NotReadyToDraw:Boolean;
    procedure Set_Visir(const Value: Integer);
    procedure SetupWFC(PRE,DT,BlockSize:Integer; WaveAlpha:Double);
    function GetCorrBlock: Integer;
    procedure SetVisirOnMax;
    function GetFilterLen: Integer;
  private
    wfc:TWaveFormComputer;
    TmpWaveAlpha:Double;
    WaveAlpha1,WaveAlpha2:Double;
    function CalcCorr2:Double;
    property Visir:Integer read FVisir write Set_Visir;
    property CorrBlock:Integer read GetCorrBlock;
    property FilterLen:Integer read GetFilterLen;
  public
    { Public declarations }
    procedure TimerProc(Interval:Cardinal);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    function CalcAlpha:Double;
  end;

var
  FormAnaliz: TFormAnaliz;

implementation

{$R *.DFM}

uses
  Main,UFrameGroup,Minimize;

const
  WaveAlpha=0.017457;//0.02122;
  Alpha1=0.9;//0.8;
  Alpha2=0.0;//0.7;
  Preload=200;//21;// 90+Ln(0.01)/Ln(max(Alpha1,Alpha2));
  Afterload=200;

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
    Visir:=Round(X*(Length(SimilarityGraph)-1)/pbGraphs.Width);
    Invalidate;
  end
  else if Shift=[ssRight] then begin
    if SimilarityGraph<>nil
    then FillChar(SimilarityGraph[0],Length(SimilarityGraph)*SizeOf(SimilarityGraph[0]),0);
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
    if SourceChanged and (ChangeTimer>=250) then begin
      W:=Group.WaveSpeed*0.001;
      if W<=0 then W:=1.150;
      MaxDT:=Round(Abs(G1.Kilometer-G2.Kilometer)/W*1.1);
      ClientWidth:=Round(MaxDT)*2;
      if MaxDT>0 then InitRefresh;
      SourceChanged:=False;
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
  // Graph2
  FindMinMax(@(SimilGraph2[0]),Length(SimilGraph2),Min,Max);
  if Max-Min<1 then begin  D:=(1-(Max-Min))*0.5; end
  else D:=(Max-Min)*0.05;
  C.Pen.Color:=clGray;
  DrawGraph(C,@(SimilGraph2[0]),Length(SimilGraph2),Min-D,Max+D,W,H,True);
  // Graph1
  FindMinMax(@(SimilarityGraph[0]),Length(SimilarityGraph),Min,Max);
  if Max-Min<1 then begin  D:=(1-(Max-Min))*0.5; end
  else D:=(Max-Min)*0.05;
  C.Pen.Color:=clBlack;
  DrawGraph(C,@(SimilarityGraph[0]),Length(SimilarityGraph),Min-D,Max+D,W,H,True);
  // Visir
  C.Pen.Color:=clRed;
  X:=Round(W*Visir/(Length(SimilarityGraph)-1));
  C.MoveTo(X,0); C.LineTo(X,H-1);
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
  SetupWFC(0,Visir,CorrBlock,WaveAlpha);
  wfc.CalcSimilarity(nil,nil);
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
//{
  FindMinMax(@(DrawData1[0]),n,Mn,Max);
  FindMinMax(@(DrawData2[0]),n,Min,Mx);
  if Mn<Min then Min:=Mn;
  if Max<Mx then Max:=Mx;
  D:=(Max-Min)*0.05;
//}
{
  FindMinMax(@(DrawData1[0]),n,Min,Max);
  D:=(Max-Min);
//}
  Min:=Min-D; Max:=Max+D;
  C.Pen.Color:=clAqua;
  DrawGraph(C,@(DrawData1[0]),n,Min,Max,W,H);
  C.Pen.Color:=clLime;
  DrawGraph(C,@(DrawData2[0]),n,Min,Max,W,H);
{$ENDIF}
end;

function TFormAnaliz.GetCorrBlock: Integer;
begin
  if cbCorrBlock.ItemIndex=-1 then cbCorrBlock.ItemIndex:=2;
  Result:=StrToInt(cbCorrBlock.Text);
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
begin
  ReadyCnt:=0;
  StartRec:=Trunc(Graph1.LabelTime*Graph1.RecsPerDay)-Preload;
  Count:=Preload+AfterLoad;
  Graph1.ADTrack.requestData(StartRec,Count,OnDataUpdate);
  Count:=Preload+MaxDT+AfterLoad;
  Graph2.ADTrack.requestData(StartRec,Count,OnDataUpdate);
end;

procedure TFormAnaliz.OnDataUpdate(Sender: TAnalogDataTrack;
  FromRec: Int64; const Data: TADDynamicArray);
var
  i,fi:Integer;
  Dst:TArrayOfSingle;
  F1Value,F2Value,SValue:Single;
  First:Boolean;
begin
  SetLength(Dst,Length(Data));
  F1Value:=0; F2Value:=0; First:=True;
  fi:=0;
  for i:=0 to High(Dst) do begin
    if ValidAD(Data[i]) then begin
      SValue:=Data[i].Value;
      if First then begin
        F1Value:=SValue; F2Value:=SValue; First:=False;
        fi:=i;
      end
      else begin
        F1Value:=F1Value*Alpha1+SValue*(1-Alpha1);
        F2Value:=F2Value*Alpha2+SValue*(1-Alpha2);
      end;
    end;
    Dst[i]:=F2Value;//-F1Value;
  end;
  for i:=0 to fi-1 do Dst[i]:=Dst[fi];
  if Sender=Graph1.ADTrack
  then begin SrcData1:=Dst; Inc(ReadyCnt); end
  else if Sender=Graph2.ADTrack
  then begin SrcData2:=Dst; Inc(ReadyCnt); end;
  if ReadyCnt=2 then DoneRefresh;
end;

procedure TFormAnaliz.DoneRefresh;
var
  DT,CB,FL:Integer;
  P,PS:Double;
  Tmp:TArrayOfSingle;
begin
  SetLength(SimilarityGraph,MaxDT);
  SetLength(SimilGraph2,MaxDT);
  FillChar(SimilarityGraph[0],MaxDT*SizeOf(Single),0);
  FillChar(SimilGraph2[0],MaxDT*SizeOf(Single),0);
  wfc.FilterShoulder:=-1;
  for DT:=0 to MaxDT-1 do begin
    SetupWFC(0,DT,CorrBlock,WaveAlpha);
    wfc.CalcSimilarity(@P,@PS);
    SimilarityGraph[DT]:=P;
    SimilGraph2[DT]:=PS;
  end;
{
  CB:=CorrBlock;
  P:=CB-1;
  PS:=P*0.1;
  if PS<1 then PS:=1;
  while P>=0 do begin
    for DT:=0 to MaxDT-1 do SimilarityGraph[DT]:=SimilarityGraph[DT]+
      CalcCorrelation(Round(P),DT,CB,WaveAlpha);
    P:=P-PS;
  end;
//}
  if cbSetVisir.Checked then SetVisirOnMax;
  Invalidate;
end;

function TFormAnaliz.NotReadyToDraw: Boolean;
begin
  Result:=(ReadyCnt<2) or (Length(SimilarityGraph)=0) or (Visir<0);
end;

procedure TFormAnaliz.Set_Visir(const Value: Integer);
begin
  FVisir := Value;
  Graph1.FrameEnter(Graph1);
  Graph2.LabelTime:=Graph1.LabelTime+FVisir*Graph1.Period;
  Graph2.View1ChangeViewState;
  Caption:=Format('Z[%d]=%.5f (Анализатор)',[FVisir,SimilarityGraph[FVisir]]);
end;

procedure TFormAnaliz.SetupWFC(PRE, DT, BlockSize:Integer; WaveAlpha:Double);
var
  LdW:Single;
begin
  if wfc.FilterShoulder<0
  then wfc.FilterShoulder:=FilterLen shr 1;
  LdW:=(Graph2.Kilometer-Graph1.Kilometer) /
    (TFrameGroup(Graph1.Parent).WaveSpeed * 0.001);
  if LdW<0 then LdW:=-LdW;
  wfc.P2C.Alpha1:=WaveAlpha1;
  wfc.P2C.Alpha2:=WaveAlpha2;
  wfc.Init(LdW,DT,SrcData1,SrcData2,Preload,Preload+DT,BlockSize);
end;

procedure TFormAnaliz.cbCorrBlockChange(Sender: TObject);
begin
  InitRefresh;
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
  Best:=SimilarityGraph[0];
  DTbest:=0;
  for DT:=1 to MaxDT-1 do begin
    Val:=SimilarityGraph[DT];
    if Best<Val then begin DTbest:=DT; Best:=Val; end;
  end;
  Visir:=DTbest;
  Invalidate;
end;

function TFormAnaliz.CalcCorr2: Double;
begin
  wfc.P2C.Alpha1:=TmpWaveAlpha;
  wfc.P2C.Alpha2:=1;
  wfc.CalcSimilarity(@Result,nil);
  Result:=-Result;
end;

function TFormAnaliz.CalcAlpha: Double;
begin
  // find optimal TmpWaveAlpha
  MinimizeFunc(CalcCorr2,[@TmpWaveAlpha],[0.005],[0.95],1e-9);
  Result:=TmpWaveAlpha;
end;

function TFormAnaliz.GetFilterLen: Integer;
begin
  if cbFilterLen.ItemIndex=-1 then cbFilterLen.ItemIndex:=0;
  Result:=StrToInt(cbFilterLen.Text);
end;

procedure TFormAnaliz.cbFilterLenChange(Sender: TObject);
begin
  InitRefresh;
end;

procedure TFormAnaliz.pbGraphsMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then begin
    wfc.NeedAdvInfo:=True;
    wfc.CalcSimilarity(nil,nil);
    wfc.NeedAdvInfo:=False;
    Application.MessageBox(PChar(wfc.AdvInfo),'Adv.Info',MB_ICONINFORMATION or MB_OK);
  end
  else if Button=mbRight then begin
    Application.MessageBox( PChar(Format('Alpha = %g',[CalcAlpha])),
      'Optimal Alpha calculation',MB_OK or MB_ICONINFORMATION );
  end
end;

end.



{.$DEFINE ShowDrawCnt}
{$DEFINE UseFilters}
unit UFrameGraph;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ActnList, AppEvnts, ExtCtrls, Buttons, StdCtrls, Scroller, DblGraphics, Misc,
  DataTypes, Menus, SensorTypes, IniFiles, DataTypes2;

type
  TADLArray=array[1..2] of TAnalogDataList;
  PADLArray=^TADLArray;

  TFrameGraph = class(TFrame)
    PopupMenu: TPopupMenu;
    miCopy: TMenuItem;
    View1: TUniViewer;
    PnlTools: TPanel;
    Panel: TPanel;
    SpdBtnZoomOut: TSpeedButton;
    SpdBtnZoomIn: TSpeedButton;
    SpdBtnAutoZoom: TSpeedButton;
    SpdBtnOptions: TSpeedButton;
    PnlData: TPanel;
    PnlTime: TPanel;
    SBtnRed: TSpeedButton;
    SBtnOrange: TSpeedButton;
    SBtnYellow: TSpeedButton;
    SBtnGreen: TSpeedButton;
    SBtnWhite: TSpeedButton;
    SBtn3Color: TSpeedButton;
    miAutoCenterHelp: TMenuItem;
    procedure View1Render(Sender: TBufferedScroller);
    function View1GetRegionRect(BS: TBufferedScroller; RegionNum: Integer;
      var dx, dy: Integer; var R: TRect): Integer;
    procedure View1Resize(Sender: TObject);
    procedure SpdBtnAutoZoomClick(Sender: TObject);
    procedure SpdBtnZoomInClick(Sender: TObject);
    procedure SpdBtnZoomOutClick(Sender: TObject);
    procedure View1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure View1MouseLeave(Sender: TObject);
    procedure SpdBtnOptionsClick(Sender: TObject);
    procedure View1Click(Sender: TObject);
    procedure View1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure miCopyClick(Sender: TObject);
    procedure FrameEnter(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure FrameClick(Sender: TObject);
    procedure SBtnColorClick(Sender: TObject);
    procedure FrameMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FrameExit(Sender: TObject);
  //***** IMonitorSlave
  protected
    procedure Set_ArcEndTime(const Value:TDateTime);
    function Get_ArcEndTime:TDateTime;
    function Get_SpyEndTime: TDateTime;
    procedure Set_SpyMode(const Value:Boolean);
    function Get_SpyMode:Boolean;
    procedure Set_TimeCapacity(const Value: TDateTime);
    function Get_TimeCapacity: TDateTime;
    procedure Set_Negative(const Value:Boolean);
  public
    procedure MyPaintTo(dc:HDC; X,Y:Integer);
    property SpyMode:Boolean read Get_SpyMode write Set_SpyMode;
    property ArcEndTime:TDateTime read Get_ArcEndTime write Set_ArcEndTime;
    property SpyEndTime:TDateTime read Get_SpyEndTime;
    property TimeCapacity:TDateTime read Get_TimeCapacity write Set_TimeCapacity;
    property Negative:Boolean write Set_Negative;
    procedure TimerProc;
    procedure QueryArcView(Time:TDateTime);
  //*****
  private
    { Private declarations }
{$IFDEF ShowDrawCnt}
    RCnt:Integer;
{$ENDIF}
    NoDataCnt,MaxNoDataCnt:Integer;
    MouseShowDataTicks:Integer;
    MouseDownPos,LastMousePos:TPoint;
    MouseMovedAfterDown:Boolean;
    LastMousePosF:Single;
    AutoCenterPos:Single;
    FNegative,NeedRedraw:Boolean;
    function Get_DataNotChanged: Boolean;
    function PaletteIndex(i: Word): COLORREF;
    function Get_Period: TDateTime;
    function Get_RecsPerDay: Integer;
    procedure Set_DDSLineLen(const Value: Integer);
    function MyADToStr(const AD:TAnalogData):String;
    function MyTimeToStr(const T:TDateTime):String;
    function GetDataColor:TColor;
    function GetTimeColor:TColor;
    function Get_LabelTime: TDateTime;
    procedure Set_LabelTime(const Value: TDateTime);
    function GroupActive:Boolean;
    function Get_Active: Boolean;
    procedure Set_Active(const Value: Boolean);
  public
    { Public declarations }
    LockViewState:Boolean;
    ADTrack:TAnalogDataTrack;
    L,SpyL:TAnalogDataList;
    NL,SpyNL,ArcNL:TADL_SrcData;
{$IFDEF UseFilters}
    SpyFL,ArcFL:TADLArray;
    FL:PADLArray;
{$ENDIF}
    ScrL:TADLF_Screen;
    MinViewP,MaxViewP:Double;
    MinViewI,MaxViewI:Integer;
    Kilometer:Double;
    Section,Caption:String;
    // Простая СКУ
    MinGraphHeight:Double;
    AvgP:Double;
    DDSAlarm:Boolean;
    DDSHigh,DDSAlarmHigh:Boolean;
    DDSLow,DDSAlarmLow:Boolean;
    ValueHigh,ValueLow:Double;
    FDDSLineLen:Integer;
    // Auto High
    HighAutoOn:Boolean;
    HighAlpha,HighScale,HighMin,HighMax,HighAutoV:Double;
    // Auto Low
    LowAutoOn:Boolean;
    LowAlpha,LowScale,LowMin,LowMax,LowAutoV:Double;
    //
    MinValidP1,AvgP1,MaxValidP1:Double;
    MinValidP2,AvgP2,MaxValidP2:Double;
    //
    LabelPosF:TDateTime;
    LabelActive:Integer;
    //
    constructor CreateFromIniSection(Owner:TComponent; Ini,Cfg:TIniFile; const Section:String);
    destructor Destroy;override;
    procedure SaveCfg(Cfg:TIniFile);
    procedure FindMinMaxPressure(I1,I2:Integer; var mn,mx:Double;
      CheckMinMax:Boolean);
    procedure View1AutoZoomV;
    procedure View1CenteringV;
    procedure View1ChangeViewState;
    procedure ZoomInV;
    procedure ZoomOutV;
    procedure CalculateLastMousePos;
    procedure ShowDataAndTime(F:Single);
    procedure DDSCheck;
    function CalcAvg(i1,i2:Integer; DDS:Boolean): Double;
    procedure CalcKB(i1,i2:Integer; DDS:Boolean; var K,B:Double);
    procedure OnChangeData(Sender:TObject; var LCA:TListChangeAction);
    procedure Set_TimeBegAndCap(var Beg:TDateTime; const Cap:TDateTime; UseBeg:Boolean);
  public
    property DDSLineLen:Integer write Set_DDSLineLen;
    property DataNotChanged:Boolean read Get_DataNotChanged;
    property Period:TDateTime read Get_Period;
    property RecsPerDay:Integer read Get_RecsPerDay;
    property LabelTime:TDateTime read Get_LabelTime write Set_LabelTime;
    property Active:Boolean read Get_Active write Set_Active;
  end;

const
  MaxScaleFactor=1/86400*(1e+7);
  MinScaleFactor=1/86400;//*(5e+4);

implementation

uses UFrameGroup,SensorOptions, Main;

{$R *.DFM}

const
  ScaleStep=1.25;

constructor TFrameGraph.CreateFromIniSection(Owner:TComponent;
  Ini,Cfg: TIniFile; const Section:String);
var
  SID:String;
  RPD:Integer;
  Delta:TPoint;
begin
  Create(Owner);
  Self.Section:=Section;
  View1.lockRender;
  SID:=Section;
  RPD:=Ini.ReadInteger(Section,'RecsPerDay',86400);
  ADTrack:=TAnalogDataTrack.Create(SID, RPD);
  // normal
  ArcNL:=TADL_SrcData.Create(ADTrack,False);
  SpyNL:=TADL_SrcData.Create(ADTrack,True);
  SpyL:=SpyNL;
  NL:=SpyNL;
{$IFDEF UseFilters}
  SBtnRed.Visible:=True;
  SBtnOrange.Visible:=True;
  //***** фильтры режима слежения
//  SpyFL[1]:=TADLF_Liner.Create(SpyNL,1);
//  SpyFL[2]:=TADLF_Liner.Create(SpyNL,16);
//{
  SpyFL[1]:=TADLF_ExpAvg.Create(SpyNL,FormMain.Alpha1);
  SpyFL[2]:=TADLF_ExpAvg.Create(SpyNL,FormMain.Alpha2);
//  SpyFL[2]:=TADLF_Krivizna.Create(SpyNL,0.9,0.7);
//}
  //***** фильтры режима просмотра архива
//  ArcFL[1]:=TADLF_Liner.Create(ArcNL,1);
//  ArcFL[2]:=TADLF_Liner.Create(ArcNL,16);
//{
  ArcFL[1]:=TADLF_ExpAvg.Create(ArcNL,FormMain.Alpha1);
  ArcFL[2]:=TADLF_ExpAvg.Create(ArcNL,FormMain.Alpha2);
//  ArcFL[2]:=TADLF_Krivizna.Create(ArcNL,0.9,0.7);
//}
  //
  FL:=@SpyFL;
{$ENDIF}
  // screen
  ScrL:=TADLF_Screen.Create(SpyNL);
  MinGraphHeight:=0.5;
//*****  LoadFromIniSection;
  Caption:=Ini.ReadString(Section,'Caption','');
  Kilometer:=Ini.ReadFloat(Section,'Km',0);
  // Read configuration
  MaxNoDataCnt:=Cfg.ReadInteger(Section,'MaxNoDataTime',60);
  View1.ScaleY:=Cfg.ReadFloat(Section,'ScaleY',View1.ScaleY);
  Delta:=View1.Delta;
  Delta.y:=Cfg.ReadInteger(Section,'DeltaY',Delta.y);
  View1.Delta:=Delta;
  DDSHigh:=Cfg.ReadBool(Section,'DDSHigh',False);
  ValueHigh:=Cfg.ReadFloat(Section,'ValueHigh',0.05);
  DDSLow:=Cfg.ReadBool(Section,'DDSLow',False);
  ValueLow:=Cfg.ReadFloat(Section,'ValueLow',0.05);
  // Параметры автомата, определяющего допустимые отклонения
  // High
  HighAutoOn:=Cfg.ReadBool(Section,'HighAutoOn',False);
  HighAlpha:=Cfg.ReadFloat(Section,'HighAlpha',0.9);
  HighScale:=Cfg.ReadFloat(Section,'HighScale',3);
  HighMin:=Cfg.ReadFloat(Section,'HighMin',0.01);
  HighMax:=Cfg.ReadFloat(Section,'HighMax',0.1);
  HighAutoV:=ValueHigh/HighScale;
  // Low
  LowAutoOn:=Cfg.ReadBool(Section,'LowAutoOn',False);
  LowAlpha:=Cfg.ReadFloat(Section,'LowAlpha',0.9);
  LowScale:=Cfg.ReadFloat(Section,'LowScale',3);
  LowMin:=Cfg.ReadFloat(Section,'LowMin',0.01);
  LowMax:=Cfg.ReadFloat(Section,'LowMax',0.1);
  LowAutoV:=ValueLow/LowScale;
  //
  MinGraphHeight:=Cfg.ReadFloat(Section,'MinGraphHeight',0.5);
//*****
  SpyNL.addUpdateNotifier(OnChangeData);
  PnlTools.DoubleBuffered:=True;
  PnlData.DoubleBuffered:=True;
  PnlTime.DoubleBuffered:=True;
  AutoCenterPos:=1;
end;

procedure TFrameGraph.View1Render(Sender: TBufferedScroller);
const
  PressureScaleParams:array[0..3] of TScaleParamsRec=(
    (Base:10; Min:-MaxInt; Max:+MaxInt),
    (Base:2; Min:-2; Max:-1),
    (Base:5; Min:-1; Max:+MaxInt),
    (Base:4; Min:-1; Max:+MaxInt)
  );
  TimeScaleParams:array[0..11] of TScaleParamsRec=(
    (Base:2; Min:-2; Max:+2),
    (Base:3; Min:-1; Max:-1),
    (Base:6; Min:-1; Max:-1),
    (Base:5; Min:+1; Max:+1),
    (Base:12;Min:-1; Max:-1),
    (Base:15;Min:+1; Max:+1),
    (Base:20;Min:+1; Max:+1),
    (Base:30;Min:-1; Max:+1),
    (Base:60;Min:-1; Max:+1),
    (Base:120;Min:+1; Max:+1),
    (Base:240;Min:+1; Max:+1),
    (Base:360;Min:+1; Max:+1)
  );
  Spectrum:array[1..7] of Byte=($30,$38,$3C,$0C,$0B,$03,$23);
var
  BS:TUniViewer absolute Sender;
  i,x,dx,dy,ts:Integer;
  D:TPoint;
  C:TCanvas;
  CW:TBMP256CanvasWrapper;
  CR,R:TRect;
  SrcRect:TDblRect;
  MinVis,MaxVis,RCSize,DP:TDblPoint;
  Value:Double;
  SPP,SPT:record StartValue,Step,EndValue:Double; Count,Digits:Integer; end;
  ST:TSystemTime;
  S:String;
  NeedMoveTo:Boolean;
  ShowHour:Boolean;
  StartTime:TDateTime;

  procedure DrawPressureGraph(const ADL:TAnalogDataList;
    K,B:Double;
    C1,C2:TColor);
  var
    i:Integer;
    L:TADDynamicArray;
    Period:TDateTime;
    Offs:TDateTime;
  begin
    L:=ADL.I;
    Period:=ADL.Period;
    // График давления
    C.Pen.Color:=C1;
    DP.x:=0;
    NeedMoveTo:=True;
    Offs:=ADL.BegTime-StartTime;
    for I:=0 to High(L) do begin
      if ValidAD(L[i]) then begin
        DP.x:=Offs+I*Period;
        DP.y:=MaxViewP-(L[i].Value*K+B);
        if NeedMoveTo then CW.AAMoveTo(DP);
        CW.AALineTo(DP);
        NeedMoveTo:=False;
        C.Pen.Color:=C1;
      end
      else C.Pen.Color:=C2;
    end;
  end;

begin
  if (csLoading in ComponentState) or (Parent=nil) then exit;
  with BS as TUniViewer do begin
    C:=Buffer.Canvas;
    D:=Delta;
    CR:=ClientRect;
  end;
  MinVis:=BS.RealDelta;
  RCSize:=BS.RealClientSize;
  MaxVis.x:=MinVis.x+RCSize.x;
  MaxVis.y:=MinVis.y+RCSize.y;
  StartTime:=ScrL.BegTime;

//***** Очистка фона
  C.Brush.Style:=bsSolid;
  C.Brush.Color:=PaletteIndex(0);
  C.FillRect(CR);
  C.Brush.Style:=bsClear;
  C.Pen.Width:=1;
  C.Font.Assign(Font);
//***** Линии шкалы давления
  R:=CR;
  Sender.OnGetRegionRect(BS,2,dx,dy,R);
  // Рассчитывем параметры
  ts:=C.TextHeight('0')*3 div 4;
  CalcScaleParams(
    (MaxViewP-MinVis.y), RCSize.y, (R.Bottom-R.Top) div ts+1,
    PressureScaleParams,
    SPP.StartValue,SPP.Step,SPP.Digits,SPP.Count);
  SPP.EndValue:=MinViewP-SPP.Step;
  Value:=SPP.StartValue;
  // Рисуем
  C.Pen.Color:=PaletteIndex($14);
  for I:=0 to SPP.Count do begin
    D.y:=Trunc((MaxViewP-Value-MinVis.y)*BS.Scale.y);
    C.MoveTo(R.Left,D.y); C.LineTo(CR.Right,D.y);
    Value:=Value-SPP.Step;
    if Value<SPP.EndValue then break;
  end;

//***** Шкала времени
  R:=CR;
  Sender.OnGetRegionRect(BS,3,dx,dy,R);
  C.Pen.Color:=PaletteIndex($16);//010111
  C.Font.Color:=PaletteIndex($16);//101011
  ts:=C.TextWidth('00_00_ ');
  // Рассчитывем параметры шкалы
  CalcScaleParams(
    (StartTime+MinVis.x)*24*60, RCSize.x*24*60, (R.Right-R.Left) div ts+1,
    TimeScaleParams,
    SPT.StartValue,SPT.Step,SPT.Digits,SPT.Count);
  ts:=C.TextWidth('00_00_');
  SPT.EndValue:=ScrL.EndTime*24*60+SPT.Step;
  Value:=SPT.StartValue;
  ShowHour:=SPT.Step>0.999;
  // Рисуем
  for I:=0 to SPT.Count+1 do begin
    D.x:=R.Left+Trunc((Value*dtOneMinute-MinVis.x-StartTime)*BS.Scale.x);
    C.MoveTo(D.x,CR.Top); C.LineTo(D.x,R.Top);
    DateTimeToSystemTime(Value*dtOneMinute,ST);
    if ShowHour
    then C.TextOut(D.x-ts,R.Top-1,Format('%.2dЧ%.2dМ',[ST.wHour,ST.wMinute]))
    else C.TextOut(D.x-ts,R.Top-1,Format('%.2dМ%.2dС',[ST.wMinute,ST.wSecond]));
    Value:=Value+SPT.Step;
    if Value>SPT.EndValue then break;
  end;

//*** Цифровые отметки на шкале давления
  R:=CR;
  Sender.OnGetRegionRect(BS,2,dx,dy,R);
//  C.Font.Assign(Font);
  C.Pen.Color:=PaletteIndex($15);
  ts:=C.TextHeight('0');
  // Рисуем
  Value:=SPP.StartValue;
  for I:=0 to SPP.Count do begin
    D.y:=Trunc((MaxViewP-Value-MinVis.y)*BS.Scale.y);
    if SPP.Digits>0
    then Str(Value:SPP.Digits+3:SPP.Digits,S)
    else Str(Value:2:0,S);
    if S[Length(S)]='0'
    then C.Font.Color:=PaletteIndex($3C)
    else C.Font.Color:=PaletteIndex($28);
    C.TextOut(R.Left,D.y-ts shr 1,S);
    Value:=Value-SPP.Step;
    if Value<SPP.EndValue then break;
  end;

//***** График давления
  R:=CR;
  Sender.OnGetRegionRect(BS,1,dx,dy,R);
  SrcRect.x1:=MinVis.x;
  SrcRect.y1:=MinViewP+MinVis.y;
  SrcRect.x2:=MaxVis.x;
  SrcRect.y2:=MinViewP+MaxVis.y;

  CW:=TBMP256CanvasWrapper.Create(BS.Buffer);
  try
    CW.SetConversion(SrcRect,R);
    if SpyMode then begin
      if DDSHigh then begin
        // Верхняя ограничивающая линия
        if DDSAlarmHigh
        then C.Pen.Color:=PaletteIndex($30)
        else C.Pen.Color:=PaletteIndex($0C);
        DP.x:=High(ScrL.I)*ScrL.Period;
        DP.y:=MaxViewP-(MaxValidP2-MinViewP);
        CW.AAMoveTo(DP);
        DP.x:=DP.x-FDDSLineLen*Period;
        DP.y:=MaxViewP-(MaxValidP1-MinViewP);
        CW.AALineTo(DP);
      end;
      if DDSLow then begin
        // Нижняя ограничивающая линия
        if DDSAlarmLow
        then C.Pen.Color:=PaletteIndex($30)
        else C.Pen.Color:=PaletteIndex($0C);
        DP.x:=MaxVis.x;//High(ScrL.I)*ScrL.Period;
        DP.y:=MaxViewP-(MinValidP2-MinViewP);
        CW.AAMoveTo(DP);
        DP.x:=DP.x-FDDSLineLen*Period;
        DP.y:=MaxViewP-(MinValidP1-MinViewP);
        CW.AALineTo(DP);
      end;
    end
    else if GroupActive then begin
      // Вертикальная метка
      case LabelActive of
      1,2: C.Pen.Color:=PaletteIndex($35);
      else C.Pen.Color:=PaletteIndex($10);
      end;
      DP.x:=LabelPosF*ScrL.Period;
      DP.y:=SrcRect.y1; CW.AAMoveTo(DP);
      DP.y:=SrcRect.y2; CW.AALineTo(DP);
    end;
    // Надпись (название)

    if SpyMode
    then S:=Caption
    else S:=Caption+' ('+Format('%g',[Kilometer])+' км)';
    if Focused
    then C.Font.Color:=PaletteIndex($3F)
    else C.Font.Color:=PaletteIndex($2A);
    i:=C.TextWidth(S);
    x:=CR.Right-i shr 1;
    if View1.Left+x+i>PnlData.Left
    then x:=PnlData.Left-View1.Left-i;
    if x<1 then x:=1;
    C.TextOut(x,1,S);
{
    // Средняя линия
    C.Pen.Color:=PaletteIndex($20);
    DP.x:=MinVis.x;
    DP.y:=(MaxViewP+MinViewP)*0.5;
    CW.AAMoveTo(DP);
    DP.x:=MaxVis.x;
    CW.AALineTo(DP);
}
    // Собственно, графики
    if SBtnWhite.Down
    then DrawPressureGraph(ScrL,1,-MinViewP,
      PaletteIndex($3F),PaletteIndex($3A));
{$IFDEF UseFilters}
    if SBtnRed.Down
    then DrawPressureGraph(FL[1],1,-MinViewP,
      PaletteIndex(Spectrum[1]), PaletteIndex(Spectrum[1]) );
    if SBtnOrange.Down
    then DrawPressureGraph(FL[2],1,{RCSize.y*0.5,//}-MinViewP,
      PaletteIndex(Spectrum[2]), PaletteIndex(Spectrum[2]) );
{$ENDIF}
  finally
    CW.Free;
  end;
{$IFDEF ShowDrawCnt}
  Inc(RCnt);
  C.Font.Color:=PaletteIndex($30);
  C.TextOut(0,0,IntToStr(RCnt));
{$ENDIF}
end;

function TFrameGraph.View1GetRegionRect(BS: TBufferedScroller;
  RegionNum: Integer; var dx, dy: Integer; var R: TRect): Integer;
var
  FF:TPoint;
begin
  Result:=4;
  FF:=BS.FixedField;
  case RegionNum of
    1:begin
      Inc(R.Left,FF.x);
      Dec(R.Bottom,FF.y);
    end;
    2:begin
      R.Right:=R.Left+FF.x;
      Dec(R.Bottom,FF.y);
      dx:=0;
    end;
    3:begin
      Inc(R.Left,FF.x);
      R.Top:=R.Bottom-FF.y;
      dy:=0;
    end;
    4:begin
      R.Right:=R.Left+FF.x;
      R.Top:=R.Bottom-FF.y;
      dx:=0;
      dy:=0;
    end;
  end;
end;

destructor TFrameGraph.Destroy;
{$IFDEF UseFilters}
var
  i:Integer;
{$ENDIF}
begin
  ScrL.Free;
{$IFDEF UseFilters}
  for i:=High(ArcFL) downto 1 do begin
    ArcFL[i].Free; SpyFL[i].Free;
  end;
{$ENDIF}
  ArcNL.Free; SpyNL.Free;
  inherited;
end;

procedure TFrameGraph.FindMinMaxPressure(I1, I2: Integer;
  var mn,mx:Double; CheckMinMax:Boolean);
var
  i:Integer;
  First:Boolean;
  val,mid:Double;
begin
  First:=True;
  mn:=0; mx:=0;
  for i:=I1 to I2 do begin
    if not ValidAD(ScrL.I[i]) then continue;
    val:=ScrL.I[i].Value;
    if First then begin
      mn:=val; mx:=mn; First:=False;
    end
    else if val<mn
    then mn:=val
    else if mx<val
    then mx:=val;
  end;
  val:=(mx-mn)*0.4; mx:=mx+val; //mn:=mn-val;
  if CheckMinMax and (mx-mn<MinGraphHeight) then begin
    mid:=(mn+mx)*0.5;
    mn:=mid-0.5*MinGraphHeight;
    mx:=mid+0.5*MinGraphHeight;
  end;
end;

procedure TFrameGraph.View1AutoZoomV;
begin
  try
    View1.ScaleY:=(View1.ClientHeight-View1.FixedField.y)/View1.RealSize.y;
  except
    Application.MessageBox('','Сбой в программе',MB_OK);
  end;
end;

procedure TFrameGraph.View1Resize(Sender: TObject);
var
  W:Integer;
  RS:TDblPoint;
begin
  W:=View1.ClientWidth;
  ScrL.Capacity:=W;
  RS:=View1.RealSize;
  RS.x:=ScrL.ScrTimeCapacity;
  View1.RealSize:=RS;
  View1.ScaleX:=W/RS.x;
  View1ChangeViewState;
end;

procedure TFrameGraph.View1CenteringV;
const
  OneHalf=1/6;
var
  i,i1,i2,Cnt:Integer;
  mp:Double;
  RCH2:Double;
  Delta:TPoint;
begin
  Cnt:=MaxViewI-MinViewI;
  i1:=MinViewI+Round((AutoCenterPos-OneHalf)*Cnt);
  if i1<MinViewI then i1:=MinViewI;
  i2:=MinViewI+Round((AutoCenterPos+OneHalf)*Cnt);
  if MaxViewI<i2 then i2:=MaxViewI;
  mp:=0;
  Cnt:=0;
  for i:=i1 to i2 do begin
    if not ValidAD(ScrL.I[i]) then continue;
    Inc(Cnt);
    mp:=mp+ScrL.I[i].Value;
  end;
  if Cnt>0 then mp:=mp/Cnt;
  Delta:=View1.Delta;
  RCH2:=View1.RealClientSize.y*0.5;
  Delta.y:=Round((View1.RealSize.y-(mp-{}MinViewP)-RCH2)*View1.Scale.y);
  View1.Delta:=Delta;
end;

procedure TFrameGraph.View1ChangeViewState;
var
  MinVis,MaxVis,RC,RS:TDblPoint;
begin
  if LockViewState then exit;
  View1.lockRender;
  View1.HorzSB.lockRedraw;
  View1.VertSB.lockRedraw;
  LockViewState:=True;
  MinVis:=View1.RealDelta;
  RC:=View1.RealClientSize;
  RS:=View1.RealSize;
  MaxVis.x:=MinVis.x+RC.x;
  MaxVis.y:=MinVis.y+RC.y;
  MinViewI:=0;
  MaxViewI:=ScrL.Capacity-1;

  FindMinMaxPressure(MinViewI,MaxViewI,MinViewP,MaxViewP,True);
  RS.y:=MaxViewP-MinViewP;
  View1.RealSize:=RS;
  if SpdBtnAutoZoom.Down
  then View1AutoZoomV
  else View1CenteringV;

  LockViewState:=False;
  View1.VertSB.unlockRedraw;
  View1.HorzSB.unlockRedraw;
  View1.unlockRender;
end;

procedure TFrameGraph.SpdBtnAutoZoomClick(Sender: TObject);
begin
  View1ChangeViewState;
  SpdBtnZoomIn.Enabled:=True;
  SpdBtnZoomOut.Enabled:=True;
end;

procedure TFrameGraph.ZoomInV;
var
  S:Double;
begin
  SpdBtnZoomOut.Enabled:=True;
  View1.lockRender;
  S:=View1.ScaleY;
  S:=S*ScaleStep;
  if S>99999 then begin
    S:=99999;
    SpdBtnZoomIn.Enabled:=False;
  end;
  View1.ScaleY:=S;
  View1ChangeViewState;
  View1.unlockRender;
end;

procedure TFrameGraph.ZoomOutV;
var
  S:Double;
begin
  SpdBtnZoomIn.Enabled:=True;
  View1.lockRender;
  S:=View1.ScaleY;
  S:=S/ScaleStep;
  if S<0.5 then begin
    S:=0.5;
    SpdBtnZoomOut.Enabled:=False;
  end;
  View1.ScaleY:=S;
  View1ChangeViewState;
  View1.unlockRender;
end;

procedure TFrameGraph.SpdBtnZoomInClick(Sender: TObject);
begin
  SpdBtnAutoZoom.Down:=False;
  ZoomInV;
end;

procedure TFrameGraph.SpdBtnZoomOutClick(Sender: TObject);
begin
  SpdBtnAutoZoom.Down:=False;
  ZoomOutV;
end;

procedure TFrameGraph.View1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if (ssLeft in Shift) and ((MouseDownPos.x<>X) or (MouseDownPos.y<>Y))
  then MouseMovedAfterDown:=True;
  LastMousePos.X:=X;
  LastMousePos.Y:=Y;
  CalculateLastMousePos;
  if LastMousePosF>=0 then begin
    MouseShowDataTicks:=5;
    ShowDataAndTime(LastMousePosF);
    if (ssCtrl in Shift) then begin
      AutoCenterPos:=X/View1.Width;
      if not SpdBtnAutoZoom.Down then View1ChangeViewState;
    end;
  end;
end;

procedure TFrameGraph.CalculateLastMousePos;
var
  f:Single;
begin
  f:=ScrL.Capacity*View1.RealDelta.X/View1.RealSize.X +
    LastMousePos.x/(ScrL.Period*View1.Scale.x);
  if (f<0) or (ScrL.Capacity<=f) then begin f:=-1; end;
  LastMousePosF:=f;
end;

procedure TFrameGraph.TimerProc;
var
  SSR:Int64;
{$IFDEF UseFilters}
  FSR:Int64;
{$ENDIF}
  NeedShow:Boolean;
begin
  NeedShow:=False;
try
  SSR:=ScrL.StartRec;
{$IFDEF UseFilters}
  FSR:=FL[1].StartRec;
{$ENDIF}
  if not ADTrack.OnTimer then begin
    if NoDataCnt<=MaxNoDataCnt then begin
      Inc(NoDataCnt);
      if DataNotChanged and SpyMode then begin
        NeedShow:=True;
        NeedRedraw:=True;
      end;
    end;
  end
  else if SpyMode then begin
    NoDataCnt:=0;
{$IFDEF UseFilters}
    NeedRedraw:=(ScrL.StartRec<>SSR) or (FL[1].StartRec<>FSR);
{$ELSE}
    NeedRedraw:=(ScrL.StartRec<>SSR);
{$ENDIF}
    if MouseShowDataTicks=0 then NeedShow:=True;
  end;
  if SpyMode and (MouseShowDataTicks>0) then begin
    Dec(MouseShowDataTicks);
    if MouseShowDataTicks=0 then NeedShow:=True;
  end;
  if NeedShow then ShowDataAndTime(ScrL.Capacity-1);
  if NeedRedraw then begin
     NeedRedraw:=False;
     View1ChangeViewState;
  end;
except
end;
end;

procedure TFrameGraph.ShowDataAndTime(F:Single);
var
  s2,s1:String;
  i,W:Integer;
begin
  s1:=' ';
  i:=Trunc(f);
  if (0<=i) and (i<ScrL.Capacity) then begin
    s2:=MyTimeToStr(ScrL.BegTime+f*ScrL.Period);
    s1:=MyADToStr(ScrL.I[i]);
  end
  else MouseShowDataTicks:=0;
  // Set PnlData
  PnlData.Font.Color:=GetDataColor;
  W:=GetTextExtent(PnlData.Font,s1).cx;
  if W<PnlData.Constraints.MinWidth
  then W:=PnlData.Constraints.MinWidth;
  PnlData.Left:=ClientWidth-W;
  PnlData.Width:=W;
  PnlData.Caption:=s1;
  // Set PnlTime
  PnlTime.Font.Color:=GetTimeColor;
  W:=GetTextExtent(PnlTime.Font,s2).cx;
  if W<PnlTime.Constraints.MinWidth
  then W:=PnlTime.Constraints.MinWidth;
  PnlTime.Left:=ClientWidth-W;
  PnlTime.Width:=W;
  PnlTime.Caption:=s2;
end;

procedure TFrameGraph.SaveCfg(Cfg: TIniFile);
begin
  Cfg.WriteFloat(Section,'ScaleY',View1.ScaleY);
  Cfg.WriteInteger(Section,'DeltaY',View1.Delta.y);
  Cfg.WriteInteger(Section,'DDSHigh',Integer(DDSHigh));
  Cfg.WriteFloat(Section,'ValueHigh',ValueHigh);
  Cfg.WriteInteger(Section,'DDSLow',Integer(DDSLow));
  Cfg.WriteFloat(Section,'ValueLow',ValueLow);
  // Auto High
  Cfg.WriteInteger(Section,'HighAutoOn',Integer(HighAutoOn));
  Cfg.WriteFloat(Section,'HighScale',HighScale);
  Cfg.WriteFloat(Section,'HighAlpha',HighAlpha);
  Cfg.WriteFloat(Section,'HighMin',HighMin);
  Cfg.WriteFloat(Section,'HighMax',HighMax);
  // Auto Low
  Cfg.WriteInteger(Section,'LowAutoOn',Integer(LowAutoOn));
  Cfg.WriteFloat(Section,'LowScale',LowScale);
  Cfg.WriteFloat(Section,'LowAlpha',LowAlpha);
  Cfg.WriteFloat(Section,'LowMin',LowMin);
  Cfg.WriteFloat(Section,'LowMax',LowMax);
  //
  Cfg.WriteFloat(Section,'MinGraphHeight',MinGraphHeight);
  Cfg.WriteInteger(Section,'MaxNoDataTime',MaxNoDataCnt);
end;

procedure TFrameGraph.View1MouseLeave(Sender: TObject);
begin
  MouseShowDataTicks:=0;
  ShowDataAndTime(ScrL.Capacity-1)
end;

procedure TFrameGraph.SpdBtnOptionsClick(Sender: TObject);
var
  FDO:TFormSensorOptions;
  MR:TModalResult;
begin
  FDO:=TFormSensorOptions.Create(Owner);
  FDO.Caption:=TForm(Owner).Caption+' : Датчик '+ADTrack.StrTrackID;
  // High
  FDO.rbtnHighManual.Checked:=not HighAutoOn;
  FDO.cbHigh.Checked:=DDSHigh;
  FDO.edHigh.Text:=Format('%g',[ValueHigh]);
  FDO.rbtnHighAuto.Checked:=HighAutoOn;
  FDO.edHighAlpha.Text:=Format('%g',[HighAlpha]);
  FDO.edHighScale.Text:=Format('%g',[HighScale]);
  FDO.edHighMin.Text:=Format('%g',[HighMin]);
  FDO.edHighMax.Text:=Format('%g',[HighMax]);
  // Low
  FDO.rbtnLowManual.Checked:=not LowAutoOn;
  FDO.cbLow.Checked:=DDSLow;
  FDO.edLow.Text:=Format('%g',[ValueLow]);
  FDO.rbtnLowAuto.Checked:=LowAutoOn;
  FDO.edLowAlpha.Text:=Format('%g',[LowAlpha]);
  FDO.edLowScale.Text:=Format('%g',[LowScale]);
  FDO.edLowMin.Text:=Format('%g',[LowMin]);
  FDO.edLowMax.Text:=Format('%g',[LowMax]);
  //
  FDO.edAlphaSpy.Text:=Format('%g',[0.9{SpyFL.Alpha}]);
  FDO.edAlphaArc.Text:=Format('%g',[0.9{ArcFL.Alpha}]);
  FDO.edMinGraphHeight.Text:=Format('%g',[MinGraphHeight]);
  FDO.edMaxNoDataTime.Text:=IntToStr(MaxNoDataCnt);
  FDO.edKilometer.Text:=Format('%g',[Kilometer]);
  repeat
    MR:=FDO.ShowModal;
    if MR<>mrCancel then begin
      // High
      HighAutoOn:=FDO.rbtnHighAuto.Checked;
      DDSHigh:=FDO.cbHigh.Checked;
      ValueHigh:=FDO.HighValue;
      HighAlpha:=FDO.HighAlpha;
      HighScale:=FDO.HighScale;
      HighMin:=FDO.HighMin;
      HighMax:=FDO.HighMax;
      // Low
      LowAutoOn:=FDO.rbtnLowAuto.Checked;
      DDSLow:=FDO.cbLow.Checked;
      ValueLow:=FDO.LowValue;
      LowAlpha:=FDO.LowAlpha;
      LowScale:=FDO.LowScale;
      LowMin:=FDO.LowMin;
      LowMax:=FDO.LowMax;
      //
      MinGraphHeight:=FDO.MinGraphHeight;
//      SpyFL.Alpha:=FDO.AlphaSpy;
//      ArcFL.Alpha:=FDO.AlphaArc;
      MaxNoDataCnt:=FDO.MaxNoDataTime;
      Kilometer:=FDO.Kilometer;
      DDSCheck;
      View1ChangeViewState
    end;
  until MR<>mrRetry;
  FDO.Free;
end;

procedure TFrameGraph.DDSCheck;
var
  CntBelow,CntAbove:Integer;
  cur,val,K,B,H,L:Double;
  Delta,DeltaAbove,DeltaBelow:Double;
  PrevBelowMin,PrevAboveMax:Boolean;
  AlarmHigh,AlarmLow:Boolean;
  i,i1,imid,i2:Integer;
begin
  i1:=SpyNL.Capacity-FDDSLineLen; if i1<0 then i1:=0;
  i2:=SpyNL.Capacity-1;
  AvgP:=CalcAvg(i1,i2,False);
  AlarmHigh:=False;
  AlarmLow:=False;
  CalcKB(i1,i2,True,K,B);
  AvgP1:=K*i1+B;
  AvgP2:=K*i2+B;
  // Определяем допустимые отклонения от линейной аппроксимации
  if HighAutoOn then begin
    H:=HighAutoV*HighScale;
    if H<HighMin then H:=HighMin else if HighMax<H then H:=HighMax;
  end
  else H:=ValueHigh;
  if LowAutoOn then begin
    L:=LowAutoV*LowScale;
    if L<LowMin then L:=LowMin else if LowMax<L then L:=LowMax;
  end
  else L:=ValueLow;
  MinValidP1:=-MaxInt; MaxValidP1:=+MaxInt;
  MinValidP2:=-MaxInt; MaxValidP2:=+MaxInt;
  if DDSHigh then begin
    MaxValidP1:=AvgP1+H;
    MaxValidP2:=AvgP2+H;
  end;
  if DDSLow then begin
    MinValidP1:=AvgP1-L;
    MinValidP2:=AvgP2-L;
  end;
  PrevBelowMin:=True;
  PrevAboveMax:=True;
  cur:=AvgP1;
  CntBelow:=0; DeltaBelow:=0;
  CntAbove:=0; DeltaAbove:=0;
  imid:=(i1+i2) div 2;
  for i:=i1 to i2 do begin
    if ValidAD(SpyL.I[i]) then begin
      val:=SpyL.I[i].Value;
      Delta:=val-cur;
      if Delta<0 then begin
        Inc(CntBelow);
        DeltaBelow:=DeltaBelow-Delta;
      end
      else begin
        Inc(CntAbove);
        DeltaAbove:=DeltaAbove+Delta;
      end;
      if Delta<-L then begin
        if DDSLow and not PrevBelowMin and (i>imid)
        then AlarmLow:=true;
        PrevBelowMin:=True;
        PrevAboveMax:=False;
      end
      else if +H<Delta then begin
        if DDSHigh and not PrevAboveMax and (i>imid)
        then AlarmHigh:=true;
        PrevBelowMin:=False;
        PrevAboveMax:=True;
      end
      else begin
        PrevBelowMin:=False;
        PrevAboveMax:=False;
      end;
    end;
    cur:=cur+K;
  end;
  if CntAbove>0
  then HighAutoV:=HighAutoV*HighAlpha+DeltaAbove*(1-HighAlpha)/CntAbove;
  if CntBelow>0
  then LowAutoV :=LowAutoV*LowAlpha+DeltaBelow*(1-LowAlpha)/CntBelow;
  if DDSHigh or DDSLow then begin
    DDSAlarm:=DDSAlarm or
      (AlarmHigh and not DDSAlarmHigh) or
      (AlarmLow and not DDSAlarmLow);
    DDSAlarmHigh:=AlarmHigh;
    DDSAlarmLow:=AlarmLow;
  end;
end;

function TFrameGraph.Get_DataNotChanged: Boolean;
begin
  Result:=NoDataCnt>MaxNoDataCnt;
end;

function TFrameGraph.Get_SpyMode: Boolean;
begin
  Result:=NL=SpyNL;
end;

procedure TFrameGraph.Set_SpyMode(const Value: Boolean);
begin
  if Value = SpyMode then exit;
  if Value then begin
    NL:=SpyNL;
{$IFDEF UseFilters}
    FL:=@SpyFL;
{$ENDIF}
    ScrL.SrcData:=SpyNL;
    View1ChangeViewState;
    ShowDataAndTime(ScrL.Capacity-1);
  end
  else ArcEndTime:=ArcNL.EndTime; // refresh :)
end;

procedure TFrameGraph.Set_ArcEndTime(const Value: TDateTime);
begin
  ArcNL.EndTime:=Value;
  NL:=ArcNL;
{$IFDEF UseFilters}
  FL:=@ArcFL;
{$ENDIF}
  ScrL.SrcData:=ArcNL;
  View1ChangeViewState;
  if (MouseShowDataTicks>0) and (LastMousePosF>0)
  then ShowDataAndTime(LastMousePosF)
  else ShowDataAndTime(ScrL.Capacity-1);
end;

procedure TFrameGraph.View1Click(Sender: TObject);
begin
  View1.lockRender;
  SetFocus;
  LabelPosF:=LastMousePosF;
  if SpyMode
  then QueryArcView(SpyEndTime)
  else View1ChangeViewState;
  View1.unlockRender;
end;

procedure TFrameGraph.View1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then begin
    MouseDownPos.X:=X;
    MouseDownPos.Y:=Y;
    MouseMovedAfterDown:=False;
  end;
end;

function TFrameGraph.PaletteIndex(i: Word): COLORREF;
begin
  if FNegative then i:=(not i) and $3F;
  Result := $01000000 or i;
end;

procedure TFrameGraph.miCopyClick(Sender: TObject);
var
  R:TRect;
  B:TBitmap;
begin
  B:=View1.Buffer;
  R.Top:=0; R.Left:=0; R.Bottom:=B.Height; R.Right:=B.Width;
  CopyToClipboard(B.Canvas,R);
end;

function TFrameGraph.CalcAvg(i1, i2:Integer; DDS:Boolean): Double;
var
  i,Cnt:Integer;
  avg,val:Double;
begin
  avg:=0; Cnt:=0;
  for i:=i1 to i2 do begin
    if not ValidAD(SpyL.I[i]) then continue;
    val:=SpyL.I[i].Value;
    avg:=avg+val;
    Inc(Cnt);
  end;
  if Cnt>0 then avg:=avg/Cnt else avg:=Self.AvgP;
  Result:=avg;
end;

procedure TFrameGraph.CalcKB(i1, i2: Integer; DDS:Boolean; var K,B:Double);
var
  i,n:Integer;
  Xi,Yi:Double;
  p,q,r,s:Double;
begin
  p:=0; q:=0; r:=0; s:=0;
  n:=0;
  for i:=i1 to i2 do begin
    if not ValidAD(SpyL.I[i]) then continue;
    Yi:=SpyL.I[i].Value;
    Xi:=i;
    p:=p+Xi*Xi;
    q:=q+Xi;
    r:=r+Xi*Yi;
    s:=s+Yi;
    Inc(n);
  end;
  if n>1 then begin
    try
      K:=(n*r-q*s)/(n*p-q*q);
    except
      K:=0;
    end;
    B:=(s-K*q)/n;
  end
  else begin
    K:=0; B:=0;
  end;
end;

function TFrameGraph.Get_Period: TDateTime;
begin
  Result:=NL.Period;
end;

function TFrameGraph.Get_RecsPerDay: Integer;
begin
  Result:=NL.RecsPerDay;
end;

function TFrameGraph.Get_ArcEndTime: TDateTime;
begin
  Result:=ArcNL.EndTime;
end;

function TFrameGraph.Get_SpyEndTime: TDateTime;
begin
  Result:=SpyNL.EndTime;
end;

procedure TFrameGraph.OnChangeData(Sender: TObject;
  var LCA: TListChangeAction);
begin
  NeedRedraw:=SpyMode;
  if LCA.Action=lcaUpdate then DDSCheck;
end;

procedure TFrameGraph.Set_TimeCapacity(const Value: TDateTime);
var
  RS:TDblPoint;
begin
  View1.lockRender;
  ScrL.TimeCapacity:=Value;
  RS.x:=ScrL.ScrTimeCapacity;
  RS.y:=View1.RealSize.y;
  View1.RealSize:=RS;
  View1.ScaleX:=View1.ClientSize.x/RS.x;
  View1ChangeViewState;
  View1.unlockRender;
end;

function TFrameGraph.Get_TimeCapacity: TDateTime;
begin
  Result:=ScrL.TimeCapacity;
end;

procedure TFrameGraph.Set_DDSLineLen(const Value: Integer);
begin
  FDDSLineLen:=Round(Value*dtOneSecond/Period);
end;

procedure TFrameGraph.Set_TimeBegAndCap(var Beg: TDateTime;
  const Cap: TDateTime; UseBeg:Boolean);
var
  MidTime:TDateTime;
begin
  View1.lockRender;
  MidTime:=ScrL.BegTime+ScrL.ScrTimeCapacity*0.5;
  if not UseBeg then begin
    if (ScrL.BegTime<=LabelTime) and (LabelTime<=ScrL.EndTime)
    then MidTime:=LabelTime;
  end;
  TimeCapacity:=Cap;
  if not UseBeg then Beg:=MidTime-ScrL.ScrTimeCapacity*0.5;
  ScrL.BegTime:=Beg;
  View1.unlockRender;
end;

procedure TFrameGraph.Set_Negative(const Value: Boolean);
var
  clStTxt:TColor;
begin
  if FNegative=Value then exit;
  FNegative := Value;
  View1ChangeViewState;
  if Value then clStTxt:=clWhite else clStTxt:=clBlack;
  PnlTime.Color:=clStTxt;
  PnlData.Color:=clStTxt;
end;

procedure TFrameGraph.FrameEnter(Sender: TObject);
begin
  PnlTools.Color:=clYellow;
  Active:=True;
end;

procedure TFrameGraph.FrameExit(Sender: TObject);
begin
  PnlTools.Color:=clBlack;
end;

procedure TFrameGraph.MyPaintTo(dc: HDC; X, Y: Integer);
begin
  View1.PaintTo(dc,X,Y+View1.Top);
  PnlData.PaintTo(dc,X+PnlData.Left,Y+PnlData.Top);
  PnlTime.PaintTo(dc,X+PnlTime.Left,Y+PnlTime.Top);
end;

function TFrameGraph.MyTimeToStr(const T: TDateTime): String;
const
  OneDivSecond=1/dtOneSecond;
begin
  if Int(T)<>Int(Now)
  then Result:=DateToStr(T)+' '
  else Result:='';
  Result:=' '+Result+TimeToStr(T)+'.'+IntToStr(Abs(Round(Frac(T*OneDivSecond)*10)) mod 10);
end;

function TFrameGraph.MyADToStr(const AD: TAnalogData): String;
begin
  if ValidAD(AD)
  then Result:=Format('%2.3f',[AD.Value])
  else Result:=GetADMsg(AD);
end;

function TFrameGraph.GetDataColor: TColor;
begin
  if MouseShowDataTicks>0
  then Result:=clYellow
  else if SpyMode then begin
    if DataNotChanged
    then Result:=clRed
    else Result:=clLime
  end
  else Result:=clOlive;
end;

function TFrameGraph.GetTimeColor: TColor;
begin
  if MouseShowDataTicks>0
  then Result:=clYellow
  else if SpyMode then begin
    if DataNotChanged
    then Result:=clFuchsia
    else Result:=clAqua
  end
  else Result:=clSilver;
end;

procedure TFrameGraph.FrameResize(Sender: TObject);
begin
  PnlData.Left:=ClientWidth-PnlData.Width;
  PnlTime.Left:=ClientWidth-PnlTime.Width;
  PnlTime.Top:=ClientHeight-PnlTime.Height;
end;

procedure TFrameGraph.FrameClick(Sender: TObject);
begin
  SetFocus;
end;

procedure TFrameGraph.SBtnColorClick(Sender: TObject);
begin
  if not (SBtnRed.Down or SBtnOrange.Down or
    SBtnYellow.Down or SBtnGreen.Down or SBtn3Color.Down)
  then SBtnWhite.Down:=True;
  View1ChangeViewState;
end;

function TFrameGraph.Get_LabelTime: TDateTime;
begin
  Result:=ScrL.BegTime+LabelPosF*ScrL.Period;
end;

procedure TFrameGraph.Set_LabelTime(const Value: TDateTime);
begin
  LabelPosF:=(Value-ScrL.BegTime)*ScrL.RecsPerDay;
end;

procedure TFrameGraph.FrameMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if ssCtrl in Shift then begin
    Handled:=True;
    if WheelDelta<0 then begin
      if SpdBtnZoomOut.Enabled then SpdBtnZoomOut.Click;
    end
    else if WheelDelta>0 then begin
      if SpdBtnZoomIn.Enabled then SpdBtnZoomIn.Click;
    end;
  end;
end;

procedure TFrameGraph.QueryArcView(Time: TDateTime);
begin
  TFrameGroup(Parent).QueryArcView(Time);
end;

function TFrameGraph.GroupActive: Boolean;
begin
  Result:=TFrameGroup(Parent).Active;
end;

function TFrameGraph.Get_Active: Boolean;
begin
  Result:=(Tag and 1)<>0;
end;

procedure TFrameGraph.Set_Active(const Value: Boolean);
begin
  if Value xor ((Tag and 1)<>0) then begin
    View1.lockRender;
    if Value then begin
      Tag:=Tag or 1;
      TFrameGroup(Parent).NotifyActivity(Self);
    end
    else begin
      Tag:=Tag and not 1;
    end;
    View1.Render(True);
    View1.unlockRender;
  end;
end;

end.

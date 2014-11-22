unit UFrameGroup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Math,
  Dialogs, Buttons, ExtCtrls, UFrameGraph, SensorTypes,
  IniFiles, Misc, ArchManThd, Menus, DataTypes, DataTypes2, ShellAPI, FileCtrl,
  SyncObjs, DblGraphics, UGroupOptions, StdCtrls, MessageForm, ActnList;

type
  TFrameGroup = class(TFrame)
    pmenuGenPip: TPopupMenu;
    miGenPipAnyday: TMenuItem;
    miRunPipViewer: TMenuItem;
    miViewPipLast10Minutes: TMenuItem;
    miViewPipLastHour: TMenuItem;
    miViewPipToday: TMenuItem;
    miViewPipYesterday: TMenuItem;
    miViewPipAnyDay: TMenuItem;
    miViewPip: TMenuItem;
    miGenPipYesterday: TMenuItem;
    miGenPip: TMenuItem;
    miLine2: TMenuItem;
    miLine1: TMenuItem;
    PopupMenu: TPopupMenu;
    miCaption: TMenuItem;
    PnlTools: TPanel;
    PnlTools2: TPanel;
    SpdBtnGeneratePip: TSpeedButton;
    SpdBtnOptions: TSpeedButton;
    SpdBtnROffGOn: TSpeedButton;
    SpdBtnROnGOn: TSpeedButton;
    SpdBtnSetArcTime: TSpeedButton;
    SpdBtnCalculation: TSpeedButton;
    SpdBtnScrollLock: TSpeedButton;
    SpdBtnZoomIn: TSpeedButton;
    SpdBtnZoomOut: TSpeedButton;
    SpdBtnDecSec: TSpeedButton;
    stSec: TStaticText;
    SpdBtnIncSec: TSpeedButton;
    SpdBtnDecMin: TSpeedButton;
    stMin: TStaticText;
    SpdBtnIncMin: TSpeedButton;
    SpdBtnDecHour: TSpeedButton;
    stHour: TStaticText;
    SpdBtnIncHour: TSpeedButton;
    SpdBtnSpyMode: TSpeedButton;
    menuCapacity: TPopupMenu;
    miCapacity: TMenuItem;
    miDecCapacity: TMenuItem;
    miIncCapacity: TMenuItem;
    miSep1: TMenuItem;
    miCap001: TMenuItem;
    miCap005: TMenuItem;
    miCap015: TMenuItem;
    miCap030: TMenuItem;
    miCap060: TMenuItem;
    miCap120: TMenuItem;
    miCap240: TMenuItem;
    miCopy: TMenuItem;
    procedure FrameResize(Sender: TObject);
    procedure FrameConstrainedResize(Sender: TObject; var MinWidth,
      MinHeight, MaxWidth, MaxHeight: Integer);
    procedure SpdBtnScrollLockClick(Sender: TObject);
    procedure SpdBtnGeneratePipClick(Sender: TObject);
    procedure miViewLastNMinutesPipClick(Sender: TObject);
    procedure miViewLastNthDayPipClick(Sender: TObject);
    procedure miGeneratePipClick(Sender:TObject);
    procedure miRunPipViewerClick(Sender: TObject);
    procedure SpdBtnOptionsClick(Sender: TObject);
    procedure SpdBtnSignalClick(Sender: TObject);
    procedure miViewPipAdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; State: TOwnerDrawState);
    procedure miViewPipAnyDayClick(Sender: TObject);
    procedure SpdBtnSetArcTimeClick(Sender: TObject);
    procedure SpdBtnCalculationClick(Sender: TObject);
    procedure miCopyClick(Sender: TObject);
    procedure SpdBtnAlarmDblClick(Sender: TObject);
    procedure FrameEnter(Sender: TObject);
    procedure FrameExit(Sender: TObject);
    procedure FrameClick(Sender: TObject);
    procedure AnyArcViewClick(Sender: TObject);
    procedure SpdBtnSpyModeClick(Sender: TObject);
    procedure miAnyCapacityClick(Sender: TObject);
    procedure miDecCapacityClick(Sender: TObject);
    procedure miIncCapacityClick(Sender: TObject);
  //***** IMonitorMaster
  public
    procedure QueryArcView(Time:TDateTime);
    procedure NotifyActivity(Sender:TObject);
  //***** IMonitorSlave
  private
    procedure Set_ArcEndTime(const Value:TDateTime);
    function Get_ArcEndTime:TDateTime;
    function Get_SpyEndTime: TDateTime;
    procedure Set_SpyMode(const Value:Boolean);
    function Get_SpyMode:Boolean;
    procedure Set_TimeCapacity(const Value: TDateTime);
    function Get_TimeCapacity: TDateTime;
    procedure Set_Negative(const Value:Boolean);
    function Get_ArcPipFilePath: String;
    function Get_PipViewerPath(TrackID: Integer): String;
    function Get_TmpPipFilePath: String;
  public
    procedure MyPaintTo(dc:HDC; X,Y:Integer);
    property SpyMode:Boolean read Get_SpyMode write Set_SpyMode;
    property ArcEndTime:TDateTime read Get_ArcEndTime write Set_ArcEndTime;
    property SpyEndTime:TDateTime read Get_SpyEndTime;
    property TimeCapacity:TDateTime read Get_TimeCapacity write Set_TimeCapacity;
    property Negative:Boolean write Set_Negative;
    procedure TimerProc;
  //*****
  private
    { Private declarations }
    LockSynchronize:Boolean;
    Canvas:TControlCanvas;
    function Get_FPG(i: Integer): TFrameGraph;
    function Get_LastRecTime: TDateTime;
    function Get_ScrollLock: Boolean;
    property PipViewerPath[TrackID:Integer]:String read Get_PipViewerPath;
    property ArcPipFilePath:String read Get_ArcPipFilePath;
    property TmpPipFilePath:String read Get_TmpPipFilePath;
  public
    { Public declarations }
    Graphs:TList;
    ActiveGraph1,ActiveGraph2:TFrameGraph;
    LastScroll:TObject;
    MaxTime:TDateTime;
    Section:String;
    TimerCounter:Integer;
    // DDS
    DDSLineLen:Integer;
    WaveSpeed:Double;
    TimeDelta:Double;
    // Alarm
    AlarmNoSound,AlarmSingle,AlarmNoData,AlarmSpeaker,AlarmMedia:Boolean;
    AlarmConfirm,AlarmConfirmed:Boolean;
    AlarmActive,UserAlarm:Boolean;
    MediaFile:String;
    //
    procedure SynchronizeGraphs(L:TFrameGraph);
    procedure LoadFromIniSection(Ini,Cfg:TIniFile; const Section:String);
    procedure SaveCfg(Cfg:TIniFile);
    procedure LockGraphs;
    procedure UnlockGraphs;
    function GeneratePipFile(StartDT, Len:TDateTime;
      const PathTemplate:WideString):WideString;
    procedure RunPipViewer(const Params:String);
    procedure SetDDS_LL(LL:Integer);
    procedure DDSSignal(SignalOn,ReqLight:Boolean);
    function QueryDate(var Date:TDateTime):Boolean;
    function CalculateWaveSpeed:Double;
    procedure CalculateDrainKm;
    procedure GetActiveGraphs(var F1,F2:TFrameGraph);
    constructor CreateFromIniSection(AOwner:TComponent; Ini,Cfg:TIniFile;
      const Section:String);
    destructor Destroy;override;
  public
    property Caption;
    property Graph[i:Integer]:TFrameGraph read Get_FPG;
    property ActiveGraph:TFrameGraph read ActiveGraph2;
    property ScrollLock:Boolean read Get_ScrollLock;
    property LastRecTime:TDateTime read Get_LastRecTime;
  end;

var
  FrameGroup: TFrameGroup;

procedure CopyToClipboard(C:TCanvas; R:TRect);

implementation

uses Clipbrd, DaySelect, DateTimeSelect, Main, UFormPipe;

{$R *.DFM}

type
  TGPFHelper=object
    Cnt:Integer;
    Sum,Last:Double;
    Data:WideString;
    procedure GetAvgData(var F:Byte; var P:Single);
    procedure Zero;
    procedure Process(i:Integer);
  end;

procedure CopyToClipboard(C:TCanvas; R:TRect);
var
  BM:TBitmap;
  Dest:TRect;
begin
  BM:=TBitmap.create;
  Dest.Top:=0; Dest.Left:=0;
  Dest.Right:=R.Right-R.Left;
  Dest.Bottom:=R.Bottom-R.Top;
  BM.Width:=Dest.Right+1;
  BM.Height:=Dest.Bottom+1;
  try
    BM.Canvas.CopyRect(Dest,C,R);
    Clipboard.Assign(BM);
  finally
    BM.Free;
  end;
end;

procedure TFrameGroup.FrameResize(Sender: TObject);
var
  i:Integer;
  MinX,H,W:Integer;
begin
  if Graphs.Count=0 then exit;
  MinX:=PnlTools.Width+1;
  W:=ClientWidth-MinX;
  H:=ClientHeight div Graphs.Count;
  LockGraphs;
  for i:=0 to Graphs.Count-1 do Graph[i].SetBounds(MinX,i*H,W,H);
  UnlockGraphs;
end;

procedure TFrameGroup.FrameConstrainedResize(Sender: TObject; var MinWidth,
  MinHeight, MaxWidth, MaxHeight: Integer);
var
  F:TFrameGraph;
begin
  F:=Graph[0];
  MinHeight:=Graphs.Count*F.Constraints.MinHeight+(Height-ClientHeight+2);
  MinWidth:=PnlTools.Width+F.Constraints.MinWidth+(Width-ClientWidth+2);
end;

procedure TFrameGroup.SpdBtnScrollLockClick(Sender: TObject);
begin
  if SpyMode
  then SynchronizeGraphs(LastScroll as TFrameGraph);
end;

procedure TFrameGroup.SynchronizeGraphs(L: TFrameGraph);
var
  i:Integer;
  Graph:TFrameGraph;
  D:TPoint;
begin
  if LockSynchronize then exit;
  LockSynchronize:=True;
  if L=nil then L:=Graphs[0];
  for i:=0 to Graphs.Count-1 do begin
    Graph:=Graphs[i];
    if L<>Graph then begin
      D:=Graph.View1.Delta;
      D.X:=L.View1.Delta.X;
      Graph.View1.Delta:=D;
    end;
  end;
  LockSynchronize:=False;
end;

procedure TFrameGroup.TimerProc;
var
  i:Integer;
  Graph:TFrameGraph;
  FPGAlarmCnt:Integer;
  NewAlarm,Alarm,NoData:Boolean;
begin
  LockGraphs;
  FPGAlarmCnt:=0;
  NoData:=False;
  for i:=0 to Graphs.Count-1 do begin
    Graph:=Graphs[i];
    Graph.TimerProc;
    if Graph.DDSAlarm then Inc(FPGAlarmCnt);
    NoData:=NoData or Graph.DataNotChanged;
    Graph.DDSAlarm:=False;
  end;
  UnlockGraphs;
  if AlarmSingle
  then Alarm:=(FPGAlarmCnt>0)
  else Alarm:=FPGAlarmCnt=Graphs.Count;
  Alarm:=UserAlarm or (Alarm or (NoData and AlarmNoData)) and (TimerCounter>1);
  if Alarm or AlarmActive then begin
    if AlarmConfirm then begin
      AlarmConfirmed:=True;
      AlarmConfirm:=False;
    end
    else begin
      NewAlarm:=UserAlarm or not AlarmActive and Alarm;
      UserAlarm:=False;
      if NewAlarm then AlarmConfirmed:=False;
      if not AlarmConfirmed then DDSSignal(True,NewAlarm);
      AlarmActive:=True;
    end;
    if not Alarm and AlarmActive and AlarmConfirmed then begin
      AlarmActive:=False;
      AlarmConfirmed:=False;
    end;
  end;
  Inc(TimerCounter);
end;

procedure TFrameGroup.LoadFromIniSection(Ini,Cfg: TIniFile;
  const Section: String);

  procedure SetActiveGraph(var AF:TFrameGraph; F:TFrameGraph; LA:Integer);
  begin
    AF:=F;
    F.LabelActive:=LA;
  end;

var
  Graph:TFrameGraph;
  i,Cnt:Integer;
  L,T,W,H,MinH:Integer;
  FF:TPoint;
  S:String;
begin
  Self.Section:=Section;
  Caption:=Ini.ReadString(Section,'Caption','');
  Cnt:=Ini.ReadInteger(Section,'SensorCount',0);
  FF.x:=0;
  FF.y:=Canvas.TextHeight('0');
  // Read configuration
  DDSLineLen:=Cfg.ReadInteger(Section,'DDSLineLen',50);
  AlarmNoSound:=Cfg.ReadBool(Section,'AlarmNoSound',False);
  AlarmSingle:=Cfg.ReadBool(Section,'AlarmSingle',True);
  AlarmNoData:=Cfg.ReadBool(Section,'AlarmNoData',False);
  AlarmSpeaker:=Cfg.ReadBool(Section,'AlarmSpeaker',True);
  AlarmMedia:=Cfg.ReadBool(Section,'AlarmMedia',False);
  MediaFile:=Cfg.ReadString(Section,'MediaFile','');
  WaveSpeed:=Cfg.ReadFloat(Section,'WaveSpeed',1000);
  TimeDelta:=Cfg.ReadFloat(Section,'TimeDelta',0.5);
  L:=Cfg.ReadInteger(Section,'Left',Left);
  T:=Cfg.ReadInteger(Section,'Top',Top);
  W:=Cfg.ReadInteger(Section,'Width',Width);
  H:=Cfg.ReadInteger(Section,'Height',Height);
  MinH:=0;
  for i:=1 to Cnt do begin
    S:=Ini.ReadString(Section,Format('Sensor%.2d',[i]),'');
    if S='' then continue;
    Graph:=TFrameGraph.CreateFromIniSection(Self,Ini,Cfg,S);
    Graph.Parent:=Self;
    Graph.DDSLineLen:=DDSLineLen;
    Graph.Name:='';
    Graph.View1.FixedField:=FF;
    Graph.View1.Buffer.Palette:=CreatePalette(TLogPalette(Pointer(Palette256)^));
    Graph.View1ChangeViewState;
    Graph.View1.UnlockRender;
    Inc(MinH,Graph.Constraints.MinHeight);
    Graphs.Add(Graph);
  end;
  Constraints.MinHeight:=MinH+(Height-ClientHeight)+2;
  SetActiveGraph(ActiveGraph1,Self.Graph[Cnt-1],1);
  SetActiveGraph(ActiveGraph2,Self.Graph[0],    2);
  TimeCapacity:=1*dtOneMinute;
  SetBounds(L,T,W,H);
end;

procedure TFrameGroup.SaveCfg(Cfg: TIniFile);
var
  i:Integer;
  Graph:TFrameGraph;
begin
  Cfg.WriteInteger(Section,'DDSLineLen',DDSLineLen);
  Cfg.WriteBool(Section,'AlarmNoSound',AlarmNoSound);
  Cfg.WriteBool(Section,'AlarmSingle',AlarmSingle);
  Cfg.WriteBool(Section,'AlarmNoData',AlarmNoData);
  Cfg.WriteBool(Section,'AlarmSpeaker',AlarmSpeaker);
  Cfg.WriteBool(Section,'AlarmMedia',AlarmMedia);
  Cfg.WriteString(Section,'MediaFile',MediaFile);
  Cfg.WriteFloat(Section,'WaveSpeed',WaveSpeed);
  Cfg.WriteFloat(Section,'TimeDelta',TimeDelta);
  for i:=0 to Graphs.Count-1 do begin
    Graph:=Graphs[i];
    Graph.SaveCfg(Cfg);
  end;
end;

procedure TFrameGroup.LockGraphs;
var
  i:Integer;
begin
  for i:=0 to Graphs.Count-1 do Graph[i].View1.lockRender;
end;

procedure TFrameGroup.UnlockGraphs;
var
  i:Integer;
begin
  for i:=0 to Graphs.Count-1 do Graph[i].View1.unlockRender;
end;

procedure TFrameGroup.SpdBtnGeneratePipClick(Sender: TObject);
var
  P:TPoint;
  F1,F2:TFrameGraph;
begin
  GetCursorPos(P);
  GetActiveGraphs(F1,F2);
  miCaption.Caption:='      Участок "'+F1.Caption+' - '+F2.Caption+'"      ';
  pmenuGenPip.Popup(P.x,P.y);
end;

procedure GetPipFileTime(const Time:TDateTime;var PipTime:TPipFileTime);
var
  ST:TSystemTime;
begin
  DateTimeToSystemTime(Time,ST);
  with PipTime do begin
    Year:=ST.wYear-1900;
    Month:=ST.wMonth;
    Day:=ST.wDay;
    Hour:=ST.wHour;
    Min:=ST.wMinute;
    Sec:=ST.wSecond;
  end;
end;

function TFrameGroup.GeneratePipFile(StartDT, Len: TDateTime;
  const PathTemplate: WideString):WideString;
{
begin
  Result:='';
end;
}
const
  OutBufSize=1 shl 14;
  OutBufMask=OutBufSize-1;
  InBufSize=1 shl 15;
  InBufMask=InBufSize-1;
var
  ID1,ID2:Integer;
  F1,F2:TFrameGraph;
  DT,NextDT:TDateTime;
  PFT,PFTPeriod:TPipTime;
  PipFile:File;
  Path:WideString;
  i,BlockSize,RecCount,nRec:Integer;
  OneSecPipPeriod:Boolean;
  H1,H2:TGPFHelper;
  Buf:array [0..OutBufSize-1] of TPipFileRec;

  function Period:TDateTime;
  begin
    Result:=F1.ADTrack.Period;
  end;

  procedure WriteDataToBuf;
  var
    j:Integer;
  begin
    j:=nRec and OutBufMask;
    Buf[j].Time:=PFT;
    H1.GetAvgData(Buf[j].F1,Buf[j].P1);
    H2.GetAvgData(Buf[j].F2,Buf[j].P2);
    if (Buf[j].F1<>0) or (Buf[j].F2<>0) then Inc(nRec);
    if (nRec>0) and (nRec and OutBufMask=0)
    then BlockWrite(PipFile,Buf,OutBufSize);
  end;

begin
  Result:='';
  StartDT:=Trunc(StartDT/dtOneSecond)*dtOneSecond;
//  DT:=LastRecTime; if (StartDT+Len>DT) then Len:=DT-StartDT;
  Len:=Trunc(Len/dtOneSecond)*dtOneSecond;
  GetActiveGraphs(F1,F2);
  ID1:=F1.ADTrack.TrackID;
  ID2:=F2.ADTrack.TrackID;
  applySubstitutions(PathTemplate,ID1,StartDT,Path);
  //
  if Period<dtOneSecond then begin
    OneSecPipPeriod:=True;
    GetPipFileTime(StartDT,PFT);
    FillChar(PFTPeriod,SizeOf(PFTPeriod),0);
    PFTPeriod.Sec:=1;
  end
  else OneSecPipPeriod:=False;
  //
  try
    try
      i:=Length(Path);
      while (i>0) and (Path[i]<>'\') do Dec(i);
      if i>1 then ForceDirectories(Copy(Path,1,i-1));
      AssignFile(PipFile,Path);
      Rewrite(PipFile,SizeOf(TPipFileRec));

      RecCount:=Round(Len/Period);
      NextDT:=StartDT+dtOneSecond*0.999;
      DT:=NextDT;
      H1.Zero; H2.Zero;
      nRec:=0;

      for i:=0 to RecCount-1 do begin
        DT:=StartDT+i*Period;
        if i and InBufMask=0 then begin
          if i+InBufSize>RecCount
          then BlockSize:=RecCount-i
          else BlockSize:=InBufSize;
          AM2.readRecords(ID1,DT,BlockSize,H1.Data);
          AM2.readRecords(ID2,DT,BlockSize,H2.Data);
        end;
        H1.Process(i and InBufMask);
        H2.Process(i and InBufMask);
        if OneSecPipPeriod then begin
          if DT>NextDT then begin
            WriteDataToBuf;
            NextPipTime(PFT,PFTPeriod);
            NextDT:=StartDT+dtOneSecond*(nRec+0.999);
          end;
        end
        else begin
          GetPipFileTime(DT,PFT);
          WriteDataToBuf;
        end;
      end;
      if DT<NextDT then WriteDataToBuf;
      if nRec and OutBufMask>0 then BlockWrite(PipFile,Buf,nRec and OutBufMask);
    finally
      CloseFile(PipFile);
    end;
    Result:=Path;
  except
    Application.MessageBox('Ошибка',PChar('Сбой при записи PIP-файла '+Path),MB_OK);
  end;
end;

procedure TFrameGroup.miViewLastNMinutesPipClick(Sender: TObject);
var
  Interval:TDateTime;
begin
  Interval:=TComponent(Sender).Tag*dtOneMinute;
  RunPipViewer(GeneratePipFile(LastRecTime-Interval, Interval, TmpPipFilePath));
end;

procedure TFrameGroup.RunPipViewer(const Params: String);
var
  i:Integer;
  Path:String;
begin
  Path:=PipViewerPath[ActiveGraph.ADTrack.TrackID];
  i:=Length(Path);
  while (i>0) and (Path[i]<>'\') do Dec(i);
  ShellExecute(Handle,'open',PChar(Path),PChar(Params),
    PChar(Copy(Path,1,i-1)),SW_SHOWNORMAL);
end;

procedure TFrameGroup.miViewLastNthDayPipClick(Sender: TObject);
begin
  RunPipViewer(GeneratePipFile(Trunc(LastRecTime)-TComponent(Sender).Tag,
    dtOneDay,TmpPipFilePath
  ));
end;

procedure TFrameGroup.miViewPipAnyDayClick(Sender: TObject);
var
  Date:TDateTime;
begin
  if QueryDate(Date)
  then RunPipViewer(GeneratePipFile(Trunc(Date),dtOneDay,TmpPipFilePath));
end;

procedure TFrameGroup.miRunPipViewerClick(Sender: TObject);
begin
  RunPipViewer('');
end;


constructor TFrameGroup.CreateFromIniSection(AOwner: TComponent;
  Ini,Cfg: TIniFile; const Section: String);
var
  hSysMenu:Integer;
begin
  inherited Create(AOwner);
  Name:='';
  Graphs:=TList.Create;
  Canvas:=TControlCanvas.Create;
  Canvas.Control:=Self;
  PnlTools.DoubleBuffered:=True;
  LoadFromIniSection(Ini,Cfg,Section);
  hSysMenu:=GetSystemMenu(Handle,False);
  DeleteMenu(hSysMenu,SC_CLOSE,MF_BYCOMMAND);
end;

procedure TFrameGroup.SpdBtnOptionsClick(Sender: TObject);
var
  FPO:TGroupOptions;
  MR:TModalResult;
begin
  FPO:=TGroupOptions.Create(Self);
  FPO.Caption:=Caption;
  FPO.cbAlarmSingle.Checked:=AlarmSingle;
  FPO.cbAlarmNoSound.Checked:=AlarmNoSound;
  FPO.cbAlarmNoData.Checked:=AlarmNoData;
  FPO.cbAlarmSpeaker.Checked:=AlarmSpeaker;
  FPO.cbAlarmMedia.Checked:=AlarmMedia;
  FPO.btnMediaFile.Caption:=MediaFile;
  FPO.edWaveSpeed.Text:=Format('%g',[WaveSpeed]);
  FPO.edDDSLineLen.Text:=Format('%d',[DDSLineLen]);
  FPO.PipeLength:=Abs(Graph[Graphs.Count-1].Kilometer-Graph[0].Kilometer);
  if SpyMode
  then FPO.BtnCalcWaveSpeed.Enabled:=False
  else FPO.CalcWaveSpeed:=CalculateWaveSpeed;
  repeat
    MR:=FPO.ShowModal;
    if MR<>mrCancel then begin
      AlarmNoSound:=FPO.cbAlarmNoSound.Checked;
      AlarmSingle:=FPO.cbAlarmSingle.Checked;
      AlarmNoData:=FPO.cbAlarmNoData.Checked;
      AlarmSpeaker:=FPO.cbAlarmSpeaker.Checked;
      AlarmMedia:=FPO.cbAlarmMedia.Checked;
      MediaFile:=FPO.btnMediaFile.Caption;
      SetDDS_LL(FPO.DDSLineLen);
      WaveSpeed:=FPO.WaveSpeed;
    end;
  until MR<>mrRetry;
  FPO.Free;
end;

procedure TFrameGroup.SetDDS_LL(LL: Integer);
var
  i:Integer;
  Graph:TFrameGraph;
begin
  DDSLineLen:=LL;
  for i:=0 to Graphs.Count-1 do begin
    Graph:=Graphs[i];
    Graph.DDSLineLen:=LL;
    Graph.DDSCheck;
    Graph.View1ChangeViewState;
  end;
end;

procedure TFrameGroup.DDSSignal(SignalOn, ReqLight: Boolean);
var
  Changed,Light:Boolean;
begin
  Changed:=SignalOn xor not SpdBtnROnGOn.Down;
  SpdBtnROnGOn.Down:=not SignalOn;
  SpdBtnROffGOn.Down:=not SignalOn;
  if SignalOn then begin
    Light:=SpdBtnROnGOn.Visible;
    if ReqLight then Light:=True else Light:=not Light;
    SpdBtnROnGOn.Visible:=Light;
    SpdBtnROffGOn.Visible:=not Light;
    if Light and not AlarmNoSound then begin
      if AlarmSpeaker then begin
        Windows.Beep(500,250);
        MessageBeep(MB_ICONASTERISK);
      end;
      if AlarmMedia and (MediaFile<>'') then FormMain.PlayMedia(Self,MediaFile);
    end;
    if Changed then SpdBtnROnGOn.Hint:='Отключить сигнал';
  end
  else begin
    if Changed then SpdBtnROnGOn.Hint:='Сигнализация';
    if AlarmMedia then FormMain.StopMedia(Self);
  end;
  if Changed then SpdBtnROffGOn.Hint:=SpdBtnROnGOn.Hint;
end;

procedure TFrameGroup.SpdBtnSignalClick(Sender: TObject);
var
  SpdBtn:TSpeedButton absolute Sender;
begin
  AlarmConfirm:=True;
  if AlarmActive then DDSSignal(False,False) else SpdBtn.Down:=True;
end;

procedure TFrameGroup.miViewPipAdvancedDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; State: TOwnerDrawState);
begin
  DrawHeaderMenuItem(TMenuItem(Sender),ACanvas,ARect,State);
end;

function TFrameGroup.QueryDate(var Date: TDateTime): Boolean;
begin
  Result:=False;
  DateForm:=TDateForm.Create(Self);
  DateForm.ShowModal;
  if DateForm.ModalResult=mrOk then begin
    Date:=DateForm.DateTimePicker.DateTime;
    Result:=True;
  end;
  DateForm.Free;
end;
{
procedure TFrameGroup.SetArcView(Time: TDateTime);
var
  i:Integer;
begin
  if SpyMode
  then for i:=0 to Graphs.Count-1 do Graph[i].ArcEndTime:=Time
  else ActiveGraph2.ArcEndTime:=Time;
  if SpyMode then begin
    ActSpyModeOff.Execute;
    SpdBtnCalculation.Enabled:=True;
  end;
end;
}
procedure TFrameGroup.SpdBtnSetArcTimeClick(Sender: TObject);
begin
  FormDateTime:=TFormDateTime.Create(Self);
  FormDateTime.DatePicker.Date:=Int(LastRecTime);
  if FormDateTime.ShowModal=mrOk then begin
    QueryArcView(
      Int(FormDateTime.DatePicker.Date)+
      Frac(FormDateTime.TimePicker.Time)+
      TimeCapacity*0.5
    );
  end;
  FormDateTime.Free;
  FormDateTime:=nil;
end;

function TFrameGroup.Get_SpyMode: Boolean;
begin
  Result:=False;
  if ActiveGraph<>nil
  then Result:=ActiveGraph.SpyMode;
end;

function TFrameGroup.CalculateWaveSpeed: Double;
var
  FPG1,FPG2:TFrameGraph;
begin
  GetActiveGraphs(FPG1,FPG2);
  try
    Result:=Abs((FPG1.Kilometer-FPG2.Kilometer)/(FPG1.LabelTime-FPG2.LabelTime))*(dtOneSecond*1000){/Period};
  except
    Result:=0;
  end;
end;

procedure TFrameGroup.CalculateDrainKm;
var
  Km1,Km2,MinKmX,KmX,MaxKmX,L:Double;
  t1,dt:Double;
  t:TDateTime;
  w:Double;
  FPG1,FPG2:TFrameGraph;
  Comment:String;
begin
  GetActiveGraphs(FPG1,FPG2);
  Km1:=FPG1.Kilometer;
  Km2:=FPG2.Kilometer;
  L:=Km2-Km1;
  t1:=FPG1.LabelTime/dtOneSecond;
  dt:=t1-FPG2.LabelTime/dtOneSecond;
  w:=WaveSpeed*0.001;
  MinKmX:=Km1+((dt-TimeDelta)*w+L)*0.5;
  MaxKmX:=Km1+((dt+TimeDelta)*w+L)*0.5;
  if MaxKmX<MinKmX then begin
    KmX:=MaxKmX; MaxKmX:=MinKmX; MinKmX:=KmX;
  end;
  KmX:=(dt*w+L)*0.5;
  t:=(t1-KmX/w)*dtOneSecond;
  if (MaxKmX<Km1) or (Km2<MinKmX) then Comment:='***НЕКОРРЕКТНО***';
  FormMessage:=TFormMessage.Create(Self);
  FormMessage.Caption:='Результаты расчета';
  FormMessage.Memo.Text:=
    Format(
      'Расчетное место : %s'#13#10+
      '  %.1f км от начала участка'#13#10+
      '  %.1f км НПП'#13#10#13#10,
      [Comment,KmX,Km1+KmX]
    )+
    'Расчетное время : '+TimeToStr(t)+
    Format(
      #13#10#13#10'Участок "%s" - "%s"'#13#10+
      '  длина %.1f км'#13#10+
      '  от %.1f до %.1f км НПП'#13#10#13#10+
      'Скорость распространения волны : %.1f м/с',
      [FPG1.Caption,FPG2.Caption,Km2-Km1,Km1,Km2,WaveSpeed]
    );
  FormMessage.ShowModal;
  FormMessage.Free;
  FormMessage:=nil;
end;

procedure TFrameGroup.SpdBtnCalculationClick(Sender: TObject);
begin
  CalculateDrainKm;
end;

function TFrameGroup.Get_FPG(i: Integer): TFrameGraph;
begin
  Result:=Graphs[i];
end;

procedure TFrameGroup.miCopyClick(Sender: TObject);
begin
  Application.ProcessMessages;
  CopyToClipboard(Canvas,ClientRect);
end;

procedure TFrameGroup.SpdBtnAlarmDblClick(Sender: TObject);
begin
  UserAlarm:=True;
end;

procedure TFrameGroup.GetActiveGraphs(var F1, F2: TFrameGraph);
begin
  if ActiveGraph1.Kilometer<ActiveGraph2.Kilometer then begin
    F1:=ActiveGraph1; F2:=ActiveGraph2;
  end
  else begin
    F1:=ActiveGraph2; F2:=ActiveGraph1;
  end;
end;

function TFrameGroup.Get_LastRecTime: TDateTime;
var
  T1,T2:TDateTime;
begin
  T1:=ActiveGraph1.ADTrack.LastRecTime;
  T2:=ActiveGraph2.ADTrack.LastRecTime;
  if T1<T2 then Result:=T2 else Result:=T1;
end;

{ TGPFHelper }

procedure TGPFHelper.GetAvgData(var F: Byte; var P: Single);
const
  Coeff=1024;
  OneDivCoeff=1/Coeff;
var
  S:Single;
  I:Integer absolute S;
begin
  if Cnt>0 then begin
    F:=pfOkData; S:=Sum/Cnt;
    Sum:=0; Cnt:=0; P:=S; Last:=S;
  end
  else begin
    F:=0; P:=Last;
  end;
end;

procedure TGPFHelper.Process(i:Integer);
var
  AD:TAnalogData;
begin
  TMySensor.GetAD(Data,i,AD);
  if ValidAD(AD) then begin
    Inc(Cnt); Sum:=Sum+AD.Value;
  end;
end;

procedure TGPFHelper.Zero;
begin
  Cnt:=0; Data:=''; Last:=0; Sum:=0;
end;

procedure TFrameGroup.Set_TimeCapacity(const Value: TDateTime);
var
  i:Integer;
begin
  for i:=0 to Graphs.Count-1 do Graph[i].TimeCapacity:=Value;
end;

function TFrameGroup.Get_TimeCapacity: TDateTime;
begin
  Result:=ActiveGraph.TimeCapacity;
end;

destructor TFrameGroup.Destroy;
begin
  Graphs.Free;
  Canvas.Free;
  inherited;
end;

procedure TFrameGroup.Set_SpyMode(const Value: Boolean);
var
  i:Integer;
  F:TFrameGraph;
begin
  LockGraphs;
  for i:=0 to Graphs.Count-1 do begin
    F:=Graph[i];
    F.SpyMode:=Value;
  end;
  UnlockGraphs;
  SpdBtnSpyMode.Down:=Value;
  SpdBtnCalculation.Enabled:=not Value;
end;

function TFrameGroup.Get_ArcEndTime: TDateTime;
begin
  Result:=ActiveGraph.ArcEndTime;
end;

procedure TFrameGroup.Set_ArcEndTime(const Value: TDateTime);
var
  i:Integer;
begin
  if ScrollLock
  then for i:=0 to Graphs.Count-1 do Graph[i].ArcEndTime:=Value
  else ActiveGraph.ArcEndTime:=Value;
end;

function TFrameGroup.Get_ScrollLock: Boolean;
begin
  Result:=SpdBtnScrollLock.Down;
end;

function TFrameGroup.Get_SpyEndTime: TDateTime;
var
  i:Integer;
  Tmp:TDateTime;
begin
  Result:=0;
  for i:=0 to Graphs.Count-1 do begin
    Tmp:=Graph[i].SpyEndTime;
    if Result<Tmp then Result:=Tmp;
  end;
end;

procedure TFrameGroup.FrameEnter(Sender: TObject);
begin
  TFormPipe(Parent).NotifyActivity(Self);
  PnlTools.Color:=clYellow;
end;

procedure TFrameGroup.FrameExit(Sender: TObject);
begin
  PnlTools.Color:=clBlack;
  ActiveGraph.OnExit(ActiveGraph);
end;

procedure TFrameGroup.FrameClick(Sender: TObject);
begin
  ActiveGraph.SetFocus;
end;

procedure TFrameGroup.Set_Negative(const Value: Boolean);
var
  i:Integer;
begin
  for i:=0 to Graphs.Count-1 do Graph[i].Negative:=Value;
end;

procedure TFrameGroup.NotifyActivity(Sender: TObject);
var
  F2,F1:TFrameGraph;
  FG:TFrameGraph absolute Sender;
begin
  F2:=ActiveGraph2;
  F1:=ActiveGraph1;
  if FG<>F2 then begin
    if FG<>F1 then begin
      F1.LabelActive:=0;
    end;
    ActiveGraph1:=F2; F2.LabelActive:=1;
    ActiveGraph2:=FG; FG.LabelActive:=2;
    if not SpyMode then begin
      F1.View1ChangeViewState;
      F2.View1ChangeViewState;
      FG.View1ChangeViewState;
    end;
  end;
end;

procedure TFrameGroup.QueryArcView(Time: TDateTime);
begin
  TFormPipe(Parent).QueryArcView(Time);
end;

procedure TFrameGroup.MyPaintTo(dc: HDC; X, Y: Integer);
var
  i:Integer;
  G:TFrameGraph;
begin
  for i:=0 to Graphs.Count-1 do begin
    G:=Graph[i];
    G.MyPaintTo(dc,X,Y+G.Top);
  end;
end;

function TFrameGroup.Get_ArcPipFilePath: String;
begin
  Result:=FormMain.GetArcPipFilePath;
end;

function TFrameGroup.Get_TmpPipFilePath: String;
begin
  Result:=FormMain.GetTmpPipFilePath;
end;

function TFrameGroup.Get_PipViewerPath(TrackID: Integer): String;
begin
  Result:=FormMain.GetPipViewerPath(TrackID);
end;

procedure TFrameGroup.miGeneratePipClick(Sender: TObject);
var
  Path:String;
  Date:TDateTime;
begin
  case TComponent(Sender).Tag of
    0: if not QueryDate(Date) then exit;
    1: Date:=Trunc(LastRecTime)-1;
  end;
  Path:=GeneratePipFile(Trunc(Date),dtOneDay,ArcPipFilePath);
  Application.MessageBox(PChar(Path),'Создан PIP-файл',MB_ICONINFORMATION or MB_OK);
end;

procedure TFrameGroup.AnyArcViewClick(Sender: TObject);
var
  DT:TDateTime;
begin
  Application.ProcessMessages;
  if SpyMode
  then DT:=SpyEndTime
  else DT:=ArcEndTime+TimeCapacity*0.01*TComponent(Sender).Tag;
  QueryArcView(DT);
end;


procedure TFrameGroup.SpdBtnSpyModeClick(Sender: TObject);
begin
  TFormPipe(Parent).miSpyMode.Click;
end;

procedure TFrameGroup.miAnyCapacityClick(Sender: TObject);
begin
  TFormPipe(Parent).miAnyCapacityClick(Sender);
end;

procedure TFrameGroup.miDecCapacityClick(Sender: TObject);
begin
  TFormPipe(Parent).miDecCapacityClick(Sender);
end;

procedure TFrameGroup.miIncCapacityClick(Sender: TObject);
begin
  TFormPipe(Parent).miIncCapacityClick(Sender);
end;

end.

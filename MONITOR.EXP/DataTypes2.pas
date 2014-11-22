unit DataTypes2;

interface

uses Classes,SysUtils,ArchManThd,SensorTypes;

type
  TAnalogDataTrack=class;

  PAnalogData=^TAnalogData;

  TADDynamicArray=packed array of TAnalogData;

  TDataUpdateEvent=procedure(Sender:TAnalogDataTrack; FromRec:Int64;
    const Data:TADDynamicArray) of object;

  TAnalogDataTrack=class(TObject)
  private
    function Get_LastRecTime: TDateTime;
  protected
    FTrackID:Integer;
    FPeriod:TDateTime;
    FRecsPerDay:Integer;
    FLastRec:Int64;
    FStrTrackID:String;
  public
    procedure requestData(FromRec: Int64; Count: Integer;
      Handler:TDataUpdateEvent);
    constructor Create(StrTrackID:String; RecsPerDay:Integer);
    function OnTimer:Boolean;
  public
    OnNewData:TNotifyEvent;
    property Period:TDateTime read FPeriod;
    property RecsPerDay:Integer read FRecsPerDay;
    property LastRec:Int64 read FLastRec;
    property StrTrackID:String read FStrTrackID;
    property TrackID:Integer read FTrackID;
    property LastRecTime:TDateTime read Get_LastRecTime;
  end;

  TListChangeAction=object Action:(lcaResize,lcaShift,lcaUpdate); end;
  TLCA_Resize=object(TListChangeAction)
    NewSize:Integer;
    constructor Init(ANewSize:Integer);
  end;
  TLCA_Shift=object(TListChangeAction)
    Shift:Int64;
    constructor Init(AShift:Int64);
  end;
  TLCA_Update=object(TListChangeAction)
    FromNdx,Count:Integer;
    constructor Init(AFromNdx,ACount:Integer);
  end;

  TChangeListEvent=procedure(Sender:TObject; var LCA:TListChangeAction) of object;

  TAnalogDataList=class(TObject)
  private
    function Get_Capacity: Integer;
    function Get_LastI: PAnalogData;
    function Get_EndTime: TDateTime;
    function Get_BegTime: TDateTime;
    procedure Set_StartRec(const Value: Int64);
    procedure Set_EndTime(const Value: TDateTime);
    procedure Set_BegTime(const Value: TDateTime);
    procedure Set_Capacity(const Value: Integer);virtual;
  protected
    FStartRec:Int64;
    FItems:TADDynamicArray;
    Notifiers:TList;
    RefreshUnlocked:Boolean;
    AnchorBeg:Boolean;
    function Get_Period: TDateTime; virtual; abstract;
    function Get_RecsPerDay: Integer; virtual; abstract;
    procedure notify(var LCA:TListChangeAction);
    procedure notifyRefresh(FromNdx,Count:Integer);
    procedure notifyResize(NewSize:Integer);
    procedure notifyShift(Shift:Int64);
    procedure refreshItems(FromNdx,Count:Integer); virtual; abstract;
    procedure shiftBk(Count: Integer);
    procedure shiftFw(Count: Integer);
  public
    constructor Create;
    destructor Destroy;override;
    procedure addUpdateNotifier(Handler:TChangeListEvent);
    procedure removeUpdateNotifier(Handler:TChangeListEvent);
    procedure shiftBackward(Count: Int64; Refresh,Notify:Boolean);
    procedure shiftForward(Count: Int64; Refresh,Notify:Boolean);
    procedure shift(Count:Int64; Refresh,Notify:Boolean);
    procedure Refresh;
  public
    property Capacity:Integer read Get_Capacity write Set_Capacity;
    property I:TADDynamicArray read FItems;
    property LastI:PAnalogData read Get_LastI;
    property StartRec:Int64 read FStartRec write Set_StartRec;
    property Period:TDateTime read Get_Period;
    property RecsPerDay:Integer read Get_RecsPerDay;
    property BegTime:TDateTime read Get_BegTime write Set_BegTime;
    property EndTime:TDateTime read Get_EndTime write Set_EndTime;
  end;

  TADL_SrcData=class(TAnalogDataList)
  protected
    Track:TAnalogDataTrack;
    procedure OnDataUpdate(Sender:TAnalogDataTrack; FromRec:Int64;
      const Data:TADDynamicArray);
    procedure OnNewData(Sender:TObject);
    procedure refreshItems(FromNdx,Count:Integer); override;
    function Get_Period: TDateTime; override;
    function Get_RecsPerDay: Integer; override;
  public
    constructor Create(ADTrack:TAnalogDataTrack; Spy:Boolean);
  end;

  TADL_Filter=class(TAnalogDataList)
  protected
    FSrcData:TAnalogDataList;
    procedure Set_SrcData(const Value: TAnalogDataList);virtual;
    procedure OnChangeSrcData(Sender:TObject; var LCA:TListChangeAction);virtual;
    function Get_Period: TDateTime; override;
    function Get_RecsPerDay: Integer; override;
  public
    constructor Create(SrcData:TAnalogDataList);
  public
    property SrcData:TAnalogDataList read FSrcData write Set_SrcData;
  end;

  TADLF_Screen=class(TADL_Filter)
    constructor Create(SrcData:TAnalogDataList);
  protected
    procedure Set_SrcData(const Value: TAnalogDataList);override;
    procedure Set_Capacity(const Value: Integer);override;
    procedure Set_TimeCapacity(const Value: TDateTime);
    function Get_ScrTimeCapacity: TDateTime;
    procedure CalcScaleFactor;
  protected
    FTimeCapacity:TDateTime;
    fSrcToScr:Double;
    iSrcToScr:Integer;
    FactorIsDivisor:Boolean;
    NeedFullRefresh:Boolean;
    DimChanging:Boolean;
    procedure OnChangeSrcData(Sender:TObject; var LCA:TListChangeAction);override;
    procedure refreshItems(FromNdx,Count:Integer); override;
    function Get_Period: TDateTime; override;
    function Get_RecsPerDay: Integer; override;
  public
    property TimeCapacity:TDateTime read FTimeCapacity write Set_TimeCapacity;
    property ScrTimeCapacity:TDateTime read Get_ScrTimeCapacity;
  end;

  TADLF_Half=class(TADL_Filter)
  protected
    procedure OnChangeSrcData(Sender:TObject; var LCA:TListChangeAction);override;
    procedure refreshItems(FromNdx,Count:Integer); override;
    function Get_Period: TDateTime; override;
    function Get_RecsPerDay: Integer; override;
  end;

  TADLF_ExpAvg=class(TADL_Filter)
    constructor Create(SrcData:TAnalogDataList; Alpha:Double);
  protected
    FAlpha:Double;
    procedure Set_Alpha(const Value: Double);
    procedure refreshItems(FromNdx,Count:Integer); override;
    function Get_Period: TDateTime; override;
    function Get_RecsPerDay: Integer; override;
  public
    property Alpha:Double read FAlpha write Set_Alpha;
  end;

  TADLF_Substract=class(TADL_Filter)
    constructor Create(SrcData,SrcData2:TAnalogDataList);
  protected
    SrcData2:TAnalogDataList;
    procedure refreshItems(FromNdx,Count:Integer); override;
  end;

  TADLF_Krivizna=class(TADL_Filter)
    constructor Create(SrcData:TAnalogDataList; Alpha1,Alpha2:Double);
  protected
    Alpha1,Alpha2:Double;
    procedure refreshItems(FromNdx,Count:Integer); override;
  end;

  TADLF_Fourier=class(TADL_Filter)
    constructor Create(SrcData:TAnalogDataList; N,W:Integer);
  protected
    N,W:Integer;
    Coeffs:array of Single;
    procedure refreshItems(FromNdx,Count:Integer); override;
  end;

  TADLF_Differentiator=class(TADL_Filter)
  protected
    procedure refreshItems(FromNdx,Count:Integer); override;
  end;

  TADLF_Differentiator2=class(TADL_Filter)
  protected
    procedure refreshItems(FromNdx,Count:Integer); override;
  end;

  TADLF_Integrator=class(TADL_Filter)
  protected
    procedure refreshItems(FromNdx,Count:Integer); override;
  end;

procedure applySubstitutions(const Src: WideString; TrackID: Integer; Time: TDateTime;
  var Result: WideString);

function Initialize(ServerName:String):Boolean;
procedure Finalize;

function AM2:TArchManThread;

const
  dtY2K=36526.0;

implementation

const
  LnPrecision=-2.3;
var
  AM:TArchManThread;
  ProgramStartTime:TDateTime;

function MyCeil(const X:Extended):Int64;
begin
  Result:=Trunc(X); if Frac(X)>0 then Inc(Result);
end;

procedure Finalize;
begin
  AM.Free;
end;

function AM2:TArchManThread;
begin
  Result:=AM;
end;

procedure applySubstitutions(const Src: WideString; TrackID: Integer; Time: TDateTime;
  var Result: WideString);
begin
  AM.applySubstitutions(Src,TrackID,Time,Result);
end;

function CalcAvg(const A:TADDynamicArray; i1,i2:Integer; var Avg:Double):Boolean;
var
  i,Cnt:Integer;
  AD:^TAnalogData;
  Sum:Double;
begin
  Sum:=0; Cnt:=0;
  for i:=i1 to i2 do begin
    AD:=@(A[i]);
    if ValidAD(AD^) then begin
      Sum:=Sum+AD.Value;
      Inc(Cnt);
    end;
  end;
  Result:=Cnt>0;
  if Result then Avg:=Sum/Cnt else Avg:=0;
end;

function CalcAvgDist(const A:TADDynamicArray; i1,i2:Integer; K,B:Double):Double;
var
  i,Cnt:Integer;
  Sum:Double;
begin
  Sum:=0; Cnt:=0;
  for i:=i1 to i2 do begin
    if not ValidAD(A[i]) then continue;
    Sum:=Sum+Sqr(i*K+B-A[i].Value);
    Inc(Cnt);
  end;
  if Cnt>1 then Result:=Sum/(Cnt-1) else Result:=0;
end;

function CalcAvgD3(const A:TADDynamicArray; i1,i2:Integer; K,B:Double):Double;
var
  i,Cnt:Integer;
  Sum:Double;
begin
  Sum:=0; Cnt:=0;
  for i:=i1 to i2 do begin
    if not ValidAD(A[i]) then continue;
    Sum:=Sum+Sqr(Sqr(Sqr(i*K+B-A[i].Value)));
    Inc(Cnt);
  end;
  if Cnt>1 then Result:=Sum/(Cnt-1) else Result:=0;
end;

function CalcKB(const A:TADDynamicArray; i1, i2: Integer; var K,B:Double):Integer;
var
  i,n,Xi:Integer;
  Yi:Double;
  p,q,r,s:Double;
begin
  Result:=0;
  p:=0; q:=0; r:=0; s:=0;
  n:=0;
  for i:=i1 to i2 do begin
    if not ValidAD(A[i]) then continue;
    Yi:=A[i].Value;
    Xi:=i;
    p:=p+Xi*Xi; q:=q+Xi; r:=r+Xi*Yi; s:=s+Yi;
    Inc(n);
  end;
  if n>=1 then begin
    if n>1
    then try K:=(n*r-q*s)/(n*p-q*q); except K:=0; end
    else K:=0;
    B:=(s-K*q)/n;
    Result:=n;
  end
  else begin
    K:=0; B:=0;
  end;
end;

function CalcAdaptiveKB(const A:TADDynamicArray; ForNdx, MinN, MaxN: Integer; var K,B:Double):Integer;
type
  TKBRec=record
    K,B:Double;
  end;
var
  i,Ndx,Dir,Cnt:Integer;
  FromI,ToI:^Integer;
  Tmp,MinAvgDist:Double;
  KK,BB,KMin,BMin:Double;
begin
  if MaxN>0 then begin
    Dir:=+4; FromI:=@ForNdx; ToI:=@Ndx;
  end
  else begin
    Dir:=-4; FromI:=@Ndx; ToI:=@ForNdx; MaxN:=-MaxN;
  end;
  KMin:=0; BMin:=0; Result:=0; MinAvgDist:=1e+100;
  for i:=MinN div 4 to MaxN div 4 do begin
    Ndx:=ForNdx+i*Dir;
    Cnt:=CalcKB(A,FromI^,ToI^,KK,BB);
    if Cnt>2 then begin
      Tmp:=CalcAvgDist(A,FromI^,ToI^,KK,BB);
      if Tmp<MinAvgDist then begin
        KMin:=KK; BMin:=BB; MinAvgDist:=Tmp;
        Result:=Cnt;
      end;
    end;
  end;
  K:=KMin;
  B:=BMin;
end;

{ TAnalogDataTrack }

constructor TAnalogDataTrack.Create(StrTrackID: String;
  RecsPerDay: Integer);
begin
  FStrTrackID:=StrTrackID;
  AM.StrToTrackID(StrTrackID,FTrackID);
  AM.setTrackInfo(FTrackID,TMySensor.GetRecSize,RecsPerDay);
  FRecsPerDay:=RecsPerDay;
  FPeriod:=1/RecsPerDay;
end;

function TAnalogDataTrack.Get_LastRecTime: TDateTime;
begin
  Result:=LastRec*Period;
end;

function TAnalogDataTrack.OnTimer:Boolean;
var
  NewLastRec:Int64;
  LRT:TDateTime;
begin
  Result:=False;
  AM.getLastRecTime(FTrackID,LRT);
  NewLastRec:=Round(LRT*FRecsPerDay);
  if NewLastRec=0 then NewLastRec:=Round(ProgramStartTime*RecsPerDay);
  if FLastRec<>NewLastRec then begin
    Result:=True;
    FLastRec:=NewLastRec;
    if Assigned(OnNewData) then OnNewData(Self);
  end;
end;

procedure TAnalogDataTrack.requestData(FromRec:Int64; Count: Integer;
  Handler: TDataUpdateEvent);
var
  Data:WideString;
  i:Integer;
  ADDA:TADDynamicArray;
begin
  AM.readRecords(FTrackID,FromRec*FPeriod,Count,Data);
  SetLength(ADDA,Count);
  for i:=0 to Count-1 do TMySensor.GetAD(Data,i,ADDA[i]);
  Handler(Self,FromRec,ADDA);
end;

{ TAnalogDataList }

procedure TAnalogDataList.addUpdateNotifier(Handler: TChangeListEvent);
var
  M:^TChangeListEvent;
begin
  if Assigned(Handler) then begin
    GetMem(M,SizeOf(TChangeListEvent));
    M^:=Handler;
    Notifiers.Add(M);
  end;
end;

constructor TAnalogDataList.Create;
begin
  inherited Create;
  Notifiers:=TList.Create;
end;

destructor TAnalogDataList.Destroy;
var
  i:Integer;
begin
  for i:=0 to Notifiers.Count-1 do FreeMem(Notifiers[i],SizeOf(TMethod));
  Notifiers.Free;
  inherited;
end;

function TAnalogDataList.Get_Capacity: Integer;
begin
  Result:=Length(FItems);
end;

function TAnalogDataList.Get_LastI: PAnalogData;
begin
  Result:=@(FItems[High(FItems)]);
end;

procedure TAnalogDataList.Notify(var LCA:TListChangeAction);
var
  i:Integer;
begin
  for i:=0 to Notifiers.Count-1
  do TChangeListEvent(Notifiers[i]^)(Self,LCA);
end;

procedure TAnalogDataList.Set_Capacity(const Value: Integer);
var
  OldLength:Integer;
begin
  OldLength:=Length(FItems);
  if Value=OldLength then exit;
  if OldLength<Value then begin
    SetLength(FItems,Value);
    notifyResize(Value);
    if AnchorBeg then begin
      FillChar(FItems[OldLength],(Value-OldLength)*SizeOf(TAnalogData),0);
      refreshItems(OldLength,Value-OldLength);
    end
    else shiftBackward(Value-OldLength,True,False);
  end
  else if not AnchorBeg then begin
    shiftForward(OldLength-Value,False,False);
    setLength(FItems,Value);
    notifyResize(Value);
  end;
end;

procedure TAnalogDataList.ShiftBk(Count: Integer);
var
  Size:Integer;
begin
  Size:=Length(FItems);
  if Count>=Size then FillChar(FItems[0],Size*SizeOf(TAnalogData),0)
  else if Count>0 then begin
    Move(FItems[0],FItems[Count],(Size-Count)*SizeOf(TAnalogData));
    FillChar(FItems[0],Count*SizeOf(TAnalogData),0);
  end
end;

procedure TAnalogDataList.ShiftFw(Count: Integer);
var
  Size:Integer;
begin
  Size:=Length(FItems);
  if Count>=Size then FillChar(FItems[0],Size*SizeOf(TAnalogData),0)
  else if Count>0 then begin
    Move(FItems[Count],FItems[0],(Size-Count)*SizeOf(TAnalogData));
    FillChar(FItems[Size-Count],Count*SizeOf(TAnalogData),0);
  end
end;

function TAnalogDataList.Get_EndTime: TDateTime;
begin
  Result:=(StartRec+Length(FItems){+0.5})*Period;
end;

procedure TAnalogDataList.Set_StartRec(const Value: Int64);
begin
  if Value<FStartRec then shiftBackward(FStartRec-Value,True,True)
  else if FStartRec<Value then shiftForward(Value-FStartRec,True,True);
end;

procedure TAnalogDataList.Set_EndTime(const Value: TDateTime);
begin
  StartRec:=Round(Value*RecsPerDay{-0.5})-Length(FItems);
end;

procedure TAnalogDataList.ShiftBackward(Count: Int64; Refresh,Notify:Boolean);
var
  Cnt:Integer;
begin
  if Count<Capacity then ShiftBk(Count);
  Dec(FStartRec,Count);
  if Notify then notifyShift(-Count);
  if Refresh then begin
    if Count>Capacity then Cnt:=Capacity else Cnt:=Count;
    if (Cnt>0) then refreshItems(0,Cnt);
  end;
end;

procedure TAnalogDataList.ShiftForward(Count: Int64; Refresh,Notify:Boolean);
var
  Cnt:Integer;
begin
  if Count<Capacity then ShiftFw(Count);
  Inc(FStartRec,Count);
  if Notify then notifyShift(Count);
  if Refresh then begin
    if Count>Capacity then Cnt:=Capacity else Cnt:=Count;
    if (Cnt>0) then refreshItems(Length(FItems)-Cnt,Cnt);
  end;
end;

procedure TAnalogDataList.NotifyRefresh(FromNdx, Count: Integer);
var
  LCA:TLCA_Update;
begin
  LCA.Init(FromNdx,Count);
  Notify(LCA);
end;

procedure TAnalogDataList.NotifyResize(NewSize: Integer);
var
  LCA:TLCA_Resize;
begin
  LCA.Init(NewSize); Notify(LCA);
end;

procedure TAnalogDataList.NotifyShift(Shift: Int64);
var
  LCA:TLCA_Shift;
begin
  LCA.Init(Shift); Notify(LCA);
end;

procedure TAnalogDataList.shift(Count: Int64; Refresh,Notify:Boolean);
begin
  if Count>0 then shiftForward(Count,Refresh,Notify)
  else if Count<0 then shiftBackward(-Count,Refresh,Notify);
end;

procedure TAnalogDataList.Refresh;
begin
  RefreshUnlocked:=True;
  refreshItems(0,Capacity);
  RefreshUnlocked:=False;
end;

function TAnalogDataList.Get_BegTime: TDateTime;
begin
  Result:=(StartRec{+0.5})*Period;
end;

procedure TAnalogDataList.Set_BegTime(const Value: TDateTime);
begin
  StartRec:=Round(Value*RecsPerDay{-0.5});
end;

procedure TAnalogDataList.removeUpdateNotifier(Handler: TChangeListEvent);
var
  i:Integer;
begin
  i:=Notifiers.Count-1;
  while (0<=i) and (@TChangeListEvent(Notifiers[i]^)<>@Handler)
  do Dec(i);
  if 0<=i then begin
    FreeMem(Notifiers[i],SizeOf(TChangeListEvent));
    Notifiers.Delete(i);
  end;
end;

{ TADL_SrcData }

constructor TADL_SrcData.Create(ADTrack: TAnalogDataTrack; Spy:Boolean);
begin
  inherited Create;
  Track:=ADTrack;
  if Spy then Track.OnNewData:=OnNewData;
end;

procedure TADL_SrcData.OnDataUpdate(Sender: TAnalogDataTrack;
  FromRec: Int64; const Data:TADDynamicArray);
var
  Count,i,j0,k0:Integer;
begin
  Count:=Length(Data);
  if (FromRec+Count<=StartRec) or (StartRec+Length(FItems)<=FromRec)
  then exit;
  if FromRec<StartRec then begin
    j0:=StartRec-FromRec; k0:=0; Dec(Count,j0);
  end
  else {if StartRec<=FromRec then} begin
    j0:=0; k0:=FromRec-StartRec;
  end;
  if Length(FItems)<k0+Count then Count:=Length(FItems)-k0;
  for i:=0 to Count-1 do FItems[k0+i]:=Data[j0+i];
  NotifyRefresh(k0,Count);
end;

procedure TADL_SrcData.OnNewData(Sender: TObject);
begin
  StartRec:=Track.LastRec-Capacity;
end;

procedure TADL_SrcData.refreshItems(FromNdx, Count: Integer);
begin
  Track.requestData(StartRec+FromNdx,Count,OnDataUpdate);
end;

function TADL_SrcData.Get_Period: TDateTime;
begin
  Result:=Track.Period;
end;

function TADL_SrcData.Get_RecsPerDay: Integer;
begin
  Result:=Track.RecsPerDay;
end;

{ TADL_Filter }

constructor TADL_Filter.Create(SrcData: TAnalogDataList);
begin
  inherited Create;
  FSrcData:=SrcData;
  SrcData.addUpdateNotifier(OnChangeSrcData);
end;

function TADL_Filter.Get_Period: TDateTime;
begin
  Result:=SrcData.Period;
end;

function TADL_Filter.Get_RecsPerDay: Integer;
begin
  Result:=SrcData.RecsPerDay;
end;

procedure TADL_Filter.OnChangeSrcData(Sender: TObject;
  var LCA: TListChangeAction);
var
  LCU:TLCA_Update absolute LCA;
  LCS:TLCA_Shift absolute LCA;
  I:Int64;
begin
  case LCA.Action of
    lcaUpdate: begin
       RefreshUnlocked:=True;
       refreshItems(LCU.FromNdx,LCU.Count);
       RefreshUnlocked:=False;
       notifyRefresh(LCU.FromNdx,LCU.Count);
    end;
    lcaResize: Capacity:=SrcData.Capacity;
    lcaShift: begin
      I:=SrcData.StartRec-StartRec;
      shift(I,False,True);
    end;
  end;
end;

procedure TADL_Filter.Set_SrcData(const Value: TAnalogDataList);
begin
  FSrcData := Value;
end;

{ TADLF_ExpAvg }

constructor TADLF_ExpAvg.Create(SrcData: TAnalogDataList; Alpha:Double);
begin
  inherited Create(SrcData);
  FAlpha:=Alpha;
end;

function TADLF_ExpAvg.Get_Period: TDateTime;
begin
  Result:=SrcData.Period;
end;

function TADLF_ExpAvg.Get_RecsPerDay: Integer;
begin
  Result:=SrcData.RecsPerDay;
end;

procedure TADLF_ExpAvg.refreshItems(FromNdx, Count: Integer);
var
  i,Cnt,MinCnt:Integer;
  Val,AL,InvAL:Double;
  A:TADDynamicArray;
  AD:TAnalogData;
begin
  if RefreshUnlocked=False then exit;
  FillChar(FItems[FromNdx],Count*SizeOf(TAnalogData),0);
  A:=SrcData.I; InvAL:=1-Alpha; AL:=Alpha;
  Val:=0;
  Cnt:=0; MinCnt:=Round(LnPrecision/Ln(Alpha));
  for i:=0 to Capacity-1 do begin
    AD:=A[i];
    if ValidAD(AD) then begin
      if Cnt=0 then Val:=AD.Value
      else Val:=Val*AL+AD.Value*InvAL;
      Inc(Cnt);
    end;
    if (i<=MinCnt) or (Cnt=0) then FItems[i].Flags:=0
    else FItems[i].Value:=Val;
  end;
end;

procedure TADLF_ExpAvg.Set_Alpha(const Value: Double);
begin
  if FAlpha<>Value then begin
    FAlpha:=Value;
    Refresh;
  end;
end;

{ TLCA_Resize }

constructor TLCA_Resize.Init(ANewSize: Integer);
begin
  Action:=lcaResize;
  NewSize:=ANewSize;
end;

{ TLCA_Shift }

constructor TLCA_Shift.Init(AShift: Int64);
begin
  Action:=lcaShift;
  Shift:=AShift;
end;

{ TLCA_Update }

constructor TLCA_Update.Init(AFromNdx, ACount: Integer);
begin
  Action:=lcaUpdate;
  FromNdx:=AFromNdx;
  Count:=ACount;
end;

function Initialize(ServerName:String):Boolean;
begin
  ProgramStartTime:=Trunc(Now)+1/86400;
  Result:=False;
  try
    AM:=TArchManThread.Create;//(ServerName);
    AM.Resume;
    AM.NOP;
    Result:=(AM.HasError=FALSE);
  except
    Halt(1);
  end;
end;

{ TADLF_Screen }

procedure TADLF_Screen.CalcScaleFactor;
var
  SrcCap:Integer;
  x:Integer;
begin
  if (Capacity=0) or (FTimeCapacity=0)
  then begin
    fSrcToScr:=1; iSrcToScr:=1; FactorIsDivisor:=False;
    x:=0;
  end
  else begin
    SrcCap:=Round(FTimeCapacity*SrcData.RecsPerDay);
    if Capacity<=SrcCap shr 1 then begin
      iSrcToScr:=Round(SrcCap/Capacity);
      FactorIsDivisor:=True;
      fSrcToScr:=1/iSrcToScr;
      x:=iSrcToScr-1;
    end
    else begin
      fSrcToScr:=Capacity/SrcCap;
      iSrcToScr:=Trunc(fSrcToScr);
      FactorIsDivisor:=False;
      x:=0;
    end;
  end;
  SrcData.Capacity:=Round(Capacity/fSrcToScr)+x;
  SrcData.notifyShift(0);
end;

constructor TADLF_Screen.Create(SrcData: TAnalogDataList);
begin
  inherited;
  CalcScaleFactor;
end;

function TADLF_Screen.Get_Period: TDateTime;
begin
  Result:=SrcData.Period/fSrcToScr;
end;

function TADLF_Screen.Get_RecsPerDay: Integer;
begin
  Result:=Round(SrcData.RecsPerDay*fSrcToScr);
end;

function TADLF_Screen.Get_ScrTimeCapacity: TDateTime;
begin
  Result:=Capacity*Period;
end;

procedure TADLF_Screen.OnChangeSrcData(Sender: TObject;
  var LCA: TListChangeAction);
var
  LCU:TLCA_Update absolute LCA;
//  LCR:TLCA_Resize absolute LCA;
  LCS:TLCA_Shift absolute LCA;
  SR,FN:Int64;
  Ndx,Cnt:Integer;
begin
  case LCA.Action of
    lcaUpdate: begin
      if DimChanging then begin NeedFullRefresh:=True; exit; end;
      if NeedFullRefresh then begin
        Refresh; NeedFullRefresh:=False;
      end
      else begin
        if FactorIsDivisor then begin
          SR:=(SrcData.StartRec+iSrcToScr-1) div iSrcToScr;
          FN:=SrcData.StartRec+LCU.FromNdx;
          Ndx:=FN div iSrcToScr-SR;
          Cnt:=(FN+LCU.Count+iSrcToScr-1) div iSrcToScr-SR-Ndx+1;
        end
        else begin
          Ndx:=Trunc(LCU.FromNdx*fSrcToScr);
          Cnt:=Trunc(LCU.Count*fSrcToScr)+2;
        end;
        if Ndx<0 then begin Inc(Cnt,Ndx); Ndx:=0; end;
        if Ndx+Cnt>Capacity then Cnt:=Capacity-Ndx;
        if Cnt>0 then begin
          RefreshUnlocked:=True;
          refreshItems(Ndx,Cnt);
          RefreshUnlocked:=False;
        end;
      end;
    end;
    lcaShift: begin
      if FactorIsDivisor
      then SR:=(SrcData.StartRec+iSrcToScr-1) div iSrcToScr
      else SR:=Trunc(SrcData.StartRec*fSrcToScr);
      Shift(SR-StartRec,False,True);
    end;
  end;
end;

procedure TADLF_Screen.refreshItems(FromNdx, Count: Integer);
var
  Src,Dst:TADDynamicArray;
  Tmp:TAnalogData;
  si,di:Integer;
  xsi,xst:Integer;
  j,Cnt:Integer;
begin
  if DimChanging or not RefreshUnlocked then exit;
  Src:=SrcData.I;
  Dst:=I;
  FillChar(Dst[FromNdx],Count*SizeOf(TAnalogData),0);
  if FactorIsDivisor then begin
    si:=(SrcData.StartRec+iSrcToScr-1)div iSrcToScr*iSrcToScr-SrcData.StartRec;
    si:=si+FromNdx*iSrcToScr;
    for di:=FromNdx to FromNdx+Count-1 do begin
      Cnt:=0; Tmp.Value:=0;
      for j:=0 to iSrcToScr-1 do begin
        if ValidAD(Src[si]) then begin
          if Cnt=0 then Tmp:=Src[si]
          else Tmp.Value:=Tmp.Value+Src[si].Value;
          Inc(Cnt);
        end
        else if Cnt=0 then Tmp:=Src[si];
        Inc(si);
      end;
      if (Cnt>0) and ValidAD(Tmp) then Tmp.Value:=Tmp.Value/Cnt;
      Dst[di]:=Tmp;
    end;
  end
  else begin
    xsi:=Trunc(FromNdx/fSrcToScr*65536);
    xst:=Trunc(65536/fSrcToScr);
    for di:=FromNdx to FromNdx+Count-1 do begin
      Dst[di]:=Src[xsi shr 16];
      Inc(xsi,xst);
    end;
  end;
end;

procedure TADLF_Screen.Set_Capacity(const Value: Integer);
begin
  DimChanging:=True;
  inherited;
  CalcScaleFactor;
  DimChanging:=False;
  Refresh;
end;

procedure TADLF_Screen.Set_TimeCapacity(const Value: TDateTime);
begin
  DimChanging:=True;
  FTimeCapacity:=Value;
  CalcScaleFactor;
  DimChanging:=False;
  Refresh;
end;

procedure TADLF_Screen.Set_SrcData(const Value: TAnalogDataList);
var
  LCS:TLCA_Shift;
  LCU:TLCA_Update;
begin
  if FSrcData<>Value then begin
    if SrcData<>nil then SrcData.removeUpdateNotifier(OnChangeSrcData);
    inherited;
    SrcData.addUpdateNotifier(OnChangeSrcData);
    Capacity:=Capacity; // this update SrcData.Capacity
    LCS.Init(0);
    OnChangeSrcData(SrcData,LCS);
    LCU.Init(0,SrcData.Capacity);
    OnChangeSrcData(SrcData,LCU);
  end;
end;

{ TADLF_Half }

function TADLF_Half.Get_Period: TDateTime;
begin
  Result:=SrcData.Period*2;
end;

function TADLF_Half.Get_RecsPerDay: Integer;
begin
  Result:=Trunc(SrcData.RecsPerDay*0.5);
end;

procedure TADLF_Half.OnChangeSrcData(Sender: TObject;
  var LCA: TListChangeAction);
var
  LCU:TLCA_Update absolute LCA;
  LCS:TLCA_Shift absolute LCA;
  I:Int64;
  Ndx,Cnt:Integer;
begin
  case LCA.Action of
    lcaUpdate: begin
      I:=SrcData.StartRec+LCU.FromNdx;
      Ndx:=I div 2-(SrcData.StartRec+1) div 2-1;
      Cnt:=(I+LCU.Count+1) div 2-I div 2+2;
      if Ndx<0 then begin Inc(Cnt,Ndx); Ndx:=0; end;
      if Ndx+Cnt>Capacity then Cnt:=Capacity-Ndx;
      if Cnt>0 then begin
        RefreshUnlocked:=True;
        refreshItems(Ndx,Cnt);
        RefreshUnlocked:=False;
        notifyRefresh(Ndx,Cnt);
      end;
    end;
    lcaResize: Capacity:=(SrcData.Capacity-1) div 2;
    lcaShift: begin
      I:=(SrcData.StartRec+1) div 2-StartRec;
      if I<>0
      then shift(I,False,True);
    end;
  end;
end;

procedure TADLF_Half.refreshItems(FromNdx, Count: Integer);
var
  di,si:Integer;
  Src,Dst:TADDynamicArray;
  Tmp:TAnalogData;
begin
  if not RefreshUnlocked or (Count=0) then exit;
  Dst:=I;
  FillChar(Dst[FromNdx],Count*SizeOf(TAnalogData),0);
  di:=FromNdx-16;
  if di<0 then di:=0;
  Src:=SrcData.I;
  si:=(SrcData.StartRec+1) and (not 1)-SrcData.StartRec;
  si:=si+di shl 1;
  Tmp.Flags:=0;
  for di:=di to FromNdx+Count-1 do begin
    // Среднее
    if ValidAD(Src[si]) then begin
      Tmp:=Src[si];
      if ValidAD(Src[si+1])
      then Tmp.Value:=(Tmp.Value+Src[si+1].Value)*0.5;
    end
    else Tmp:=Src[si+1];
    Inc(si,2);
    if di>=FromNdx then Dst[di]:=Tmp;
  end;
end;

{ TADLF_Substract }

constructor TADLF_Substract.Create(SrcData, SrcData2: TAnalogDataList);
begin
  inherited Create(SrcData);
  Self.SrcData2:=SrcData2;
end;

procedure TADLF_Substract.refreshItems(FromNdx, Count: Integer);
var
  i:Integer;
  Tmp:TAnalogData;
  Src1,Src2,Dst:TADDynamicArray;
begin
  if RefreshUnlocked=False then exit;
//  FillChar(FItems[FromNdx],Count*SizeOf(TAnalogData),0);
  FillChar(FItems[0],Capacity*SizeOf(TAnalogData),0);
  Src1:=SrcData.I;
  Src2:=SrcData2.I;
  Dst:=FItems;
//  for i:=FromNdx to FromNdx+Count-1 do begin
  for i:=0 to Capacity-1 do begin
    if ValidAD(Src2[i]) and ValidAD(Src1[i]) then begin
      Tmp.Value:=(Src2[i].Value-Src1[i].Value)*4;
      if Tmp.Value=0 then Tmp.Value:=SignedZero;
    end
    else Tmp.Flags:=0;
    Dst[i]:=Tmp;
  end;
end;

{ TADLF_Krivizna }

constructor TADLF_Krivizna.Create(SrcData: TAnalogDataList; Alpha1,Alpha2: Double);
begin
  inherited Create(SrcData);
  Self.Alpha1:=Alpha1;
  Self.Alpha2:=Alpha2;
end;

procedure TADLF_Krivizna.refreshItems(FromNdx, Count: Integer);
var
  i,Cnt,MinCnt:Integer;
  Avg1,Avg2:Double;
  Val:Single;
  A:TADDynamicArray;
  AD:TAnalogData;
begin
  if RefreshUnlocked=False then exit;
  FillChar(FItems[FromNdx],Count*SizeOf(TAnalogData),0);
  A:=SrcData.I;
  Avg1:=0; Avg2:=0; Val:=0; Cnt:=0;
  MinCnt:=Round(LnPrecision/Ln(Alpha1));
  for i:=0 to Capacity-1 do begin
    AD:=A[i];
    if ValidAD(AD) then begin
      if Cnt=0 then begin
        Avg1:=AD.Value; Avg2:=AD.Value;
      end
      else begin
        Avg1:=Avg1*Alpha1+AD.Value*(1-Alpha1);
        Avg2:=Avg2*Alpha2+AD.Value*(1-Alpha2);
      end;
      Val:=Avg2-Avg1; if Val=0 then Val:=SignedZero;
      Inc(Cnt);
    end;
    if (i<=MinCnt) or (Cnt=0) then FItems[i].Flags:=0
    else FItems[i].Value:=Val;
  end;
end;

{ TADLF_Fourier }

constructor TADLF_Fourier.Create(SrcData: TAnalogDataList; N, W: Integer);
var
  i:Integer;
  X,Sum,Tmp:Double;
begin
  inherited Create(SrcData);
  Self.N:=N; Self.W:=W;
  SetLength(Coeffs,N);
  X:=-2*Pi*(W-1)/N;
  Sum:=0;
  for i:=0 to N-1 do begin
    Tmp:=Exp(X*i); Coeffs[i]:=Tmp;
    Sum:=Sum+Tmp;
  end;
  Tmp:=10/Sum;
  for i:=0 to N-1 do Coeffs[i]:=Coeffs[i]*Tmp;
end;

procedure TADLF_Fourier.refreshItems(FromNdx, Count: Integer);
var
  di,si:Integer;
  Src,Dst:TADDynamicArray;
  Sum:Double;
  Poor:Boolean;
begin
  if not RefreshUnlocked or (Count=0) then exit;
  FillChar(FItems[0],Capacity*SizeOf(TAnalogData),0);
  Dst:=I;
  Src:=SrcData.I;
  for di:=N-1 to Capacity-1 do begin
    Sum:=0; Poor:=False;
    for si:=0 to N-1 do begin
      if ValidAD(Src[di-si])
      then Sum:=Sum+Src[di-si].Value*Coeffs[si]
      else begin Poor:=True; break; end;
    end;
    if Poor then Dst[di].Flags:=0
    else Dst[di].Value:=Sum;
  end;
end;

{ TADLF_Differentiator }

procedure TADLF_Differentiator.refreshItems(FromNdx, Count: Integer);
var
  i:Integer;
  Tmp:TAnalogData;
  V0,V1:Single;
  Src,Dst:TADDynamicArray;
  First:Boolean;
begin
  if RefreshUnlocked=False then exit;
  FillChar(FItems[0],Capacity*SizeOf(TAnalogData),0);
  Src:=SrcData.I;
  Dst:=FItems;
  First:=True;
  V0:=0; V1:=0;
  for i:=0 to Capacity-1 do begin
    if ValidAD(Src[i]) then begin
      V0:=Src[i].Value;
      if First then begin V1:=V0; First:=False; end;
      Tmp.Value:=V0-V1;
      if Tmp.Value=0 then Tmp.Value:=SignedZero;
    end
    else Tmp.Flags:=0;
    V1:=V0;
    Dst[i]:=Tmp;
  end;
end;

{ TADLF_Integrator }

procedure TADLF_Integrator.refreshItems(FromNdx, Count: Integer);
var
  i:Integer;
  Sum:Double;
  Tmp:TAnalogData;
  Src,Dst:TADDynamicArray;
begin
  if RefreshUnlocked=False then exit;
  FillChar(FItems[0],Capacity*SizeOf(TAnalogData),0);
  Src:=SrcData.I;
  Dst:=FItems;
  Sum:=0;
  Tmp.Flags:=0;
  for i:=0 to Capacity-1 do begin
    if ValidAD(Src[i]) then begin
      Sum:=Sum+Src[i].Value;
      Tmp.Value:=Sum;
      if Tmp.Flags=0 then Tmp.Value:=SignedZero;
    end;
    Dst[i]:=Tmp;
  end;
end;

{ TADLF_Differentiator2 }

procedure TADLF_Differentiator2.refreshItems(FromNdx, Count: Integer);
var
  i:Integer;
  Tmp:TAnalogData;
  V0,V1,V2:Single;
  Src,Dst:TADDynamicArray;
  First:Boolean;
begin
  if RefreshUnlocked=False then exit;
  FillChar(FItems[0],Capacity*SizeOf(TAnalogData),0);
  Src:=SrcData.I;
  Dst:=FItems;
  First:=True;
  V0:=0; V1:=0; V2:=0;
  for i:=0 to Capacity-1 do begin
    if ValidAD(Src[i]) then begin
      V0:=Src[i].Value;
      if First then begin V1:=V0; V2:=V0; First:=False; end;
      Tmp.Value:=V0-2*V1+V2;
      if Tmp.Value=0 then Tmp.Value:=SignedZero;
    end
    else Tmp.Flags:=0;
    V2:=V1; V1:=V0;
    Dst[i]:=Tmp;
  end;
end;

end.

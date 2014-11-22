{$DEFINE DebugWriteTracks}
unit UScanner;

interface

uses
  Classes, Contnrs, Forms,
  Misc,SensorTypes,DataTypes,DataTypes2,UWaveFormComputer,
  UFrameGraph,UFormScanner;

type
  TExpFilter = object
    FVal:Double;
    CntPrecharge:Integer;
  public
    function GetNextVal(V,Alpha:Double):Double;
    function GetCurVal:Double;
  end;

  TScanner = class;

  TMeasurePoint = class(TADL_SrcData)
    FG:TFrameGraph;
    //*** Source data preprocessor
    FLastKnownRec:Int64;
    FLastKnownValue:Single;
    FSurgeFilter0,FSurgeFilter1:TExpFilter;
    // Noise & surges calculator
    FLastCalcRec:Int64;
    FNoiseFilter:TExpFilter;
    FNoise:TArrayOfSingle;
    FSurge:TArrayOfSingle;
    //*** Outer impulses
    FLastImpulseRec:array[0..1] of Int64;
    FImpulse:array[0..1] of TArrayOfSingle;
    //
    procedure OnChange(Sender:TObject; var LCA:TListChangeAction);
    procedure PreprocessSourceData(FromNdx,Count:Integer);
    procedure CalcNoiseAndSurges(i1,i2:Integer);
  private
    function Get_Meter: Double;
    function Get_MostLastRec: Int64;
{$IFDEF DebugWriteTracks}
  private
    ImpTrack:array[0..1] of Integer;
    LastWritedRec:array[0..1] of Int64;
    function DebugWrite:Boolean;
{$ENDIF}
  public
    constructor Create(AGraph:TFrameGraph);
    function CalculationComplete:Boolean;
  public
    property Graph:TFrameGraph read FG;
    property LastKnownRec:Int64 read FLastKnownRec;
    property Meter:Double read Get_Meter;
    property MostLastRec:Int64 read Get_MostLastRec;
  end;

  TMEF_Array = array[1..7] of Double;
  TMultilevelExpFilter = object
    SrcVal:array[0..7] of Single;
    Values:array[0..7] of TMEF_Array;
    procedure AddValue(i:Integer; V:Single);
    procedure GetValues(i:Integer; var V:TArrayOfSingle);
  end;

  TPipePart = class(TObject)
    MP:array[0..1] of TMeasurePoint;
    NoWaitImpulse:array[0..1] of Boolean;
    Scanner:TScanner;
  private
    function Get_Period: TDateTime;
  public
    constructor Create(S:TScanner; MP0,MP1:TMeasurePoint);
    function Process:Boolean;virtual;
    property Period:TDateTime read Get_Period;
  end;

  TSpottiness = class(TPipePart)
    TransFactor:array[0..1] of Double;
    LastCalcRec:array[0..1] of Int64;
    MEF:array[0..1] of TMultilevelExpFilter;
    SignFilters:array[0..1] of array of TExpFilter;
    dt:Double;
  public
    constructor Create(S:TScanner; MP0,MP1:TMeasurePoint);
    function Process:Boolean;override;
  end;

  TDTAlphaFinder = object
    NearImp,FarImp,FarNoise:TArrayOfSingle;
    P2C:TWaveP2Calculator;
    iDTmin:Integer;
    PCalc,PReal:array[0..255] of Single;
    function OptFunc:Double;
    procedure GetAdvInfo(var Inacc,NearDelta,FarDelta:Double);
    procedure PrepareP;
  end;

  TLinearPart = class(TPipePart)
    DTmin,DTmax,DT:Double;
    WaveAlpha:array[0..1] of Double;
    LastCalcRec:array[0..1] of Int64;
    P2C:array[0..1] of TWaveP2Calculator;
    t:array[0..1] of Double;
  private
    DTAF:TDTAlphaFinder;
    procedure Calc_DT_And_Alpha(i,j,BlockLen:Integer; var DT,Alpha:Double);
  public
    constructor Create(S:TScanner; MP0,MP1:TMeasurePoint);
    function Process:Boolean;override;
  end;

  TScanner = class(TObject)
    MPs,Parts:TObjectList;
    FCurStartRec:Int64;
    FScanToRec:Int64;
    Capacity:Integer;
    State:(ssNotReady, ssProcess, ssStopAndFree, ssDone);
  private
    function Get_RecsPerDay: Integer;
    procedure SetForm(const Value: TFormScanner);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormStart(Sender:TObject);
    function FindGraphByStrID(StrID:String):TFrameGraph;
  public
    Info:String;
    FS:TFormScanner;
    constructor Create;
    procedure addGraph(G:TFrameGraph);
    procedure Process;
    destructor Destroy;override;
    procedure SetScanRange(FromTime,ToTime:TDateTime);
    procedure ScanLog(S:String);
    procedure FormShowAdvInfo(Sender:TObject; SS:TStrings);
  private
    InProcess:Boolean;
    procedure Set_CurStartRec(const Value: Int64);
    function Get_StopRec: Int64;
    property CurStartRec:Int64 read FCurStartRec write Set_CurStartRec;
    property RecsPerDay:Integer read Get_RecsPerDay;
  public
    property StopRec:Int64 read Get_StopRec;
    property Form:TFormScanner read FS write SetForm;
  end;

var
  WaveSpeedMin,WaveSpeedMax:Double;
  WaveAlphaMin,WaveAlphaMax:Double;
  Scanners:TList;

procedure ProcessScanners;

implementation

uses
  Windows, SysUtils,
  Minimize;

var
  LogText:String;

procedure Log(const S:String; Flush:Boolean=False);
const
  LogFName='scanner.log';
  FirstTime:Boolean=True;
begin
  if FirstTime then begin
    DeleteFile(LogFName); FirstTime:=False;
  end;
  LogText:=LogText+S;
  if (Flush and (LogText<>'')) or (Length(LogText)>=4096) then begin
    WriteToLog(LogFName,LogText);
    LogText:='';
  end;
end;

procedure ProcessScanners;
const
  InProcess:Boolean=False;
var
  i:Integer;
begin
  if InProcess then exit;
  InProcess:=True;
  i:=Scanners.Count-1;
  while i>=0 do begin
    TScanner(Scanners[i]).Process;
    Dec(i);
  end;
  InProcess:=False;
end;

procedure GetJ1J2(const StartRec,FirstRec:Int64;
  const LastRecsOfSources:array of Int64; MinJ,MaxJ:Integer; var J0,J1,J2:Integer);
var
  LastRec:Int64;
begin
  if FirstRec <= StartRec+MinJ
  then begin J0:=0; J1:=MinJ; end
  else begin J1:=FirstRec - StartRec; J0:=J1; end;
  LastRec:=MinInt64(LastRecsOfSources);
  if LastRec < StartRec
  then J2:=0
  else begin
    J2:=LastRec-StartRec;
    if J2>MaxJ then J2:=MaxJ;
  end;
end;

constructor TMeasurePoint.Create(AGraph: TFrameGraph);
begin
  inherited Create(AGraph.ADTrack,False);
  FG:=AGraph;
  addUpdateNotifier(OnChange);
end;

procedure TMeasurePoint.PreprocessSourceData(FromNdx,Count:Integer);
var
  i,i1,i2,j:Integer;
  K,B:Double;
  lkr:Int64;
  lkv:Single;
begin
  lkr:=LastKnownRec;
  lkv:=FLastKnownValue;
  if LastKnownRec<StartRec then i1:=0 else i1:=LastKnownRec-StartRec+1;
  // Extrapolate missed measurements
  i2:=FromNdx+Count;
  i:=i1;
  while i<i2 do begin
    if ValidAD(FItems[i]) then begin
      lkr:=StartRec+i; lkv:=FItems[i].Value;
      Inc(i);
    end
    else begin
      repeat
        FItems[i].Flags:=0;
        Inc(i);
      until (i>=i2) or ValidAD(FItems[i]);
      if i<i2 then begin
        B:=1/(StartRec+i-lkr);
        K:=(FItems[i].Value - lkv)*B;
        B:=(lkv*(i+StartRec) - FItems[i].Value*lkr)*B;
        if lkr<StartRec then lkr:=StartRec else Inc(lkr);
        for j:=lkr-StartRec to i-1 do FItems[j].Value:=K*(StartRec+j)+B;
      end;
    end;
  end;
  if lkr<StartRec then begin
    for i:=i1 to i2-1 do FItems[i].Value:=lkv;
    lkr:=StartRec+(i2-1);
  end;
  FLastKnownValue:=lkv;
  FLastKnownRec:=lkr;
end;

procedure TMeasurePoint.CalcNoiseAndSurges;
const
  NoiseAlpha = 0.95;
  Surge0Alpha = 0.85;
  Surge1Alpha = 0.95;
  nleft = 2;
  nright = 1;
var
  i,j:Integer;
  Dvsr,nf:Double;
  K,B,Tmp:Double;
  sf0,sf1:Double;
begin
  sf1:=FSurgeFilter1.GetCurVal;
  Dec(i1,nright);
  if i1<nleft then begin
    nf:=FNoiseFilter.GetCurVal;
    sf0:=FSurgeFilter0.GetCurVal;
    for i:=0 to nleft-1 do begin
      FNoise[i]:=nf;
      FSurge[i]:=sf0+sf1;
    end;
    i1:=nleft;
  end;
  if i2+nright>=Length(FItems) then i2:=Length(FItems)-nright-1;
  Dvsr:=1/(nleft+1+nright);
  for i:=i1 to i2 do begin
    // Calculate noise level
    CalcKB(@(FItems[i].Value),i-nleft,i+nright,@K,@B);
    Tmp:=0;
    for j:=i-nleft to i+nright do Tmp:=Tmp+Abs(K*j+B - FItems[j].Value);
    nf:=FNoiseFilter.GetNextVal(Tmp*Dvsr,NoiseAlpha);
    if nf<0.001 then nf:=0.001;
    FNoise[i]:=nf;
    // Calculate surge
//    Tmp:=K*i+B; // use "noiseless" value
    Tmp:=FItems[i].Value;
    sf0:=FSurgeFilter0.GetNextVal(Tmp,Surge0Alpha);
    Tmp:=Tmp-sf0;
//    sf1:=FSurgeFilter1.GetNextVal(Tmp,Surge1Alpha);
    FSurge[i]:=Tmp-sf1;
  end;
  FLastCalcRec:=StartRec+i2;
end;

procedure TMeasurePoint.OnChange(Sender: TObject;
  var LCA: TListChangeAction);
var
  LCU:TLCA_Update absolute LCA;
  LCS:TLCA_Shift absolute LCA;
  LCR:TLCA_Resize absolute LCA;
  Sh:Integer;
begin
  case LCA.Action of
    lcaUpdate: if StartRec>0 then begin
      PreprocessSourceData(LCU.FromNdx,LCU.Count);
      CalcNoiseAndSurges(LCU.FromNdx,LCU.FromNdx+LCU.Count-1);
    end;
    lcaShift: begin
      Assert(LCS.Shift>=0, 'LCS.Shift<0');
      if LCS.Shift>MaxInt then Sh:=Capacity else Sh:=LCS.Shift;
      ShiftArrFw(FSurge,Sh);
      ShiftArrFw(FNoise,Sh);
      ShiftArrFw(FImpulse[0],Sh);
      ShiftArrFw(FImpulse[1],Sh);
    end;
    lcaResize: begin
      SetLength(FSurge,LCR.NewSize);
      SetLength(FNoise,LCR.NewSize);
      SetLength(FImpulse[0],LCR.NewSize);
      SetLength(FImpulse[1],LCR.NewSize);
    end;
  end;
end;

{ TSpottiness }

function TSpottiness.Process:Boolean;
var
  SrcImps,DstImps:TArrayOfSingle;
  StartRec,BigJ:Int64;
  i,k:Integer;
  j,j0,j1,j2,dj:Integer;
  WA,WB,TF,Tmp:Double;
  SI,DI,SN,DN,Inaccuracy:Double;
  MP0,MP1:TMeasurePoint;
  SA,SB,S,D:TArrayOfSingle;
begin
  Result:=inherited Process;
  dj:=Trunc(dt); WA:=Frac(dt); WB:=1-WA;
  // Recalculate transmission factor
  for i:=0 to 1 do begin
    MP0:=MP[i]; MP1:=MP[i xor 1]; StartRec:=MP0.StartRec;
    SrcImps:=MP0.FSurge; DstImps:=MP1.FSurge;
    GetJ1J2( StartRec,LastCalcRec[i]+1,
      [MP0.FLastCalcRec+dj, MP1.FLastCalcRec],
      dj+1,High(DstImps),J0,J1,J2
    );
    Result:=Result or (J1<=J2);
    for j:=J1 to J2 do begin
      SI:=SrcImps[j-dj-1]*WA+SrcImps[j-dj]*WB;
      DI:=DstImps[j];
      if (SI<0) xor (0<DI) then begin // check signs equality
        SI:=Abs(SI); DI:=Abs(DI);
        SN:=MP0.FNoise[j-dj-1];
        DN:=MP1.FNoise[j];
        if (SI>SN) and (SN>0) and (DI>DN) and (DN>0) and (SI>DI) then begin
          SN:=SI/SN; DN:=DI/DN;
          // Calculate relative inaccuracy
          Inaccuracy:=2*(sn+dn)*dn/((dn-1)*(dn+1)*sn);
          if Inaccuracy<0.5 then begin
            Tmp:=Sqr(Sqr(1-Inaccuracy));
            TF:=DI/SI;
            TransFactor[i]:=TransFactor[i]*(1-Tmp)+TF*Tmp;
          end;
        end;
      end;
    end;
    LastCalcRec[i]:=StartRec+J2;
  end;
  // Transmit the known outer impulses
  GetJ1J2( StartRec, MP[0].FLastImpulseRec[1]+1 {= MP1.FLIR[0]},
    [MP[0].FLastImpulseRec[0], MP[1].FLastImpulseRec[1],
     MP0.FLastCalcRec, MP1.FLastCalcRec],
    dj+1,High(MP0.FImpulse[0]), J0, J1, J2
  );
  Result:=Result or (J1<=J2) or (J0<J1);
  for i:=0 to 1 do begin
    MP0:=MP[i]; MP1:=MP[i xor 1]; StartRec:=MP0.StartRec;
    SrcImps:=MP0.FImpulse[i];
    DstImps:=MP1.FImpulse[i];
    for j:=J0 to J1-1 do DstImps[j]:=0;
    TF:=TransFactor[i];
    for j:=J1 to J2 do DstImps[j]:=(SrcImps[j-dj-1]*WA+SrcImps[j-dj]*WB)*TF;
    if J2<J1 then J2:=J1-1;
    MP1.FLastImpulseRec[i]:=StartRec+J2;
  end;
  // Detect unknown outer impulses
  MP0:=MP[0]; MP1:=MP[1];
  for j:=J1 to J2 do begin
    BigJ:=StartRec+j;
    MEF[0].AddValue(BigJ and $FF,MP0.FItems[j].Value-MP0.FImpulse[0,j]-MP0.FImpulse[1,j]);
    MEF[1].AddValue(BigJ and $FF,MP1.FItems[j].Value-MP1.FImpulse[0,j]-MP1.FImpulse[1,j]);
    for i:=0 to 1 do begin
      MEF[i].GetValues((BigJ-dj-1) and $FF,SA);
      MEF[i].GetValues((BigJ-dj) and $FF,SB);
      k:=BigJ and $FF; MEF[i].GetValues(k,S); MEF[i xor 1].GetValues(k,D);
      if Length(SignFilters[i])<>Length(D) then begin
        SetLength(SignFilters[i],Length(D));
        FillChar(SignFilters[i][0],SizeOf(TExpFilter)*Length(D),0);
      end;
      for k:=0 to High(D) do begin
        DI:=D[k]; SI:=S[k];
        WA:=abs(DI); Tmp:=WA+MP0.FNoise[j]*2;
        if Tmp>0 then begin WA:=WA/Tmp; if WA>1 then WA:=1; end else WA:=1;
        WB:=abs(DI); Tmp:=WB+MP1.FNoise[j]*2;
        if Tmp>0 then begin WB:=WB/Tmp; if WB>1 then WB:=1; end else WB:=1;
        if ((SI>0) xor (DI>0)) then Tmp:=1 else Tmp:=0;
        Tmp:=SignFilters[i][k].GetNextVal(Tmp,WA*WB);
{        else begin
          SI:=SA[k]*WA+SB[k]*WB;
          if ((DI>0) xor (SI<0)) and (abs(SI)>abs(DI))
          then Tmp:=DI
          else Tmp:=0;
        end;}
        MP[i xor 1].FImpulse[i,j]:=MP[i xor 1].FImpulse[i,j]+Tmp*DI;
      end;
    end;
  end;
  // need to detect inner impulses!!!
end;

constructor TSpottiness.Create(S:TScanner; MP0, MP1: TMeasurePoint);
const
  DefaultTF=1/3;
begin
  inherited;
  TransFactor[0]:=DefaultTF;
  TransFactor[1]:=DefaultTF;
  dt:=abs(MP0.Meter-MP1.Meter)/((WaveSpeedMax+WaveSpeedMin)*0.5);
end;

procedure TMultilevelExpFilter.AddValue(i:Integer; V:Single);
const
  MinJ = Low(TMEF_Array);
  MaxJ = High(TMEF_Array);
  Dvsr=1/(1 shl MaxJ);
var
  j:Integer;
  AN,AO:^TMEF_Array;
  Tmp:Double;
begin
  AN:=@(Values[(i-0) and High(Values)]);
  AO:=@(Values[(i-1) and High(Values)]);
  SrcVal[i and High(Values)]:=V;
  Tmp:=V;
  for j:=MinJ to MaxJ do begin
    AN[j]:=(AO[j]*(1 shl j - 1)+Tmp)*(1 shl (MaxJ-j))*Dvsr;
    Tmp:=AN[j];
  end;
end;

procedure TMultilevelExpFilter.GetValues(i: Integer;
  var V: TArrayOfSingle);
var
  j:Integer;
  A:^TMEF_Array;
  pA:Single;
begin
  SetLength(V,High(TMEF_Array)-Low(TMEF_Array)+1);
  i:=i and High(Values);
  A:=@(Values[i]); pA:=SrcVal[i];
  for j:=Low(TMEF_Array) to High(TMEF_Array) do begin
    V[j-Low(TMEF_Array)]:=pA-A[j];
    pA:=A[j];
  end;
end;

{ TPipePart }

constructor TPipePart.Create(S:TScanner; MP0, MP1: TMeasurePoint);
begin
  inherited Create;
  MP[0]:=MP0; MP[1]:=MP1;
  Scanner:=S;
end;

function TPipePart.Get_Period: TDateTime;
begin
  Result:=MP[0].Track.Period;
end;

function TPipePart.Process:Boolean;
var
  i:Integer;
begin
  for i:=0 to 1
  do if NoWaitImpulse[i] then MP[i].FLastImpulseRec[i]:=MP[i].FLastKnownRec;
  Result:=False;
end;

{ TLinearPart }

procedure TLinearPart.Calc_DT_And_Alpha(i, j, BlockLen: Integer; var DT,
  Alpha: Double);
var
  k,iDTmin,iDTmax,FarLen:Integer;
  MP1:TMeasurePoint;
  DA:Double;
begin
  iDTmin:=Trunc(DTmin);
  iDTmax:=Trunc(DTmax)+1;
  FarLen:=iDTmax-iDTmin+BlockLen;
  SetLength(DTAF.NearImp,BlockLen);
  SetLength(DTAF.FarImp,FarLen);
  SetLength(DTAF.FarNoise,FarLen);
  ExtractImpulse(@(MP[i].FItems[j].Value),@(DTAF.NearImp[0]),BlockLen);
  MP1:=MP[i xor 1];
  for k:=0 to FarLen-1 do begin
    DTAF.FarImp[k]:=MP1.FItems[j+iDTmin+k].Value;
    DTAF.FarNoise[k]:=MP1.FNoise[j+iDTmin+k];
  end;
  DTAF.P2C.tf1:=0; DTAF.P2C.Alpha2:=0; DTAF.iDTmin:=iDTmin;
  DA:=(WaveAlphaMax-WaveAlphaMin)*0.05;
  MinimizeFunc(DTAF.OptFunc,
    [ @DTAF.P2C.tf2, @DTAF.P2C.Alpha1 ],
    [ DTmin, WaveAlphaMin-DA ],
    [ DTmax, WaveAlphaMax+DA ],
    0.0005,512
  );
  DT:=DTAF.P2C.tf2; Alpha:=DTAF.P2C.Alpha1;
end;

constructor TLinearPart.Create(S:TScanner; MP0, MP1: TMeasurePoint);
var
  Len:Double;
begin
  inherited;
  Len:=abs(MP0.Meter-MP1.Meter);
  DTmin:=Len/WaveSpeedMax;
  DTmax:=Len/WaveSpeedMin;
  DT:=(DTmin+DTmax)*0.5;
  WaveAlpha[0]:=(WaveAlphaMin+WaveAlphaMax)*0.5;
  WaveAlpha[1]:=WaveAlpha[0];
end;

function TLinearPart.Process:Boolean;
const
  MinCB = 16; // CB = corr. block half
  MaxCB = 32;
var
  StartRec:Int64;
  MP0,MP1:TMeasurePoint;
  SrcImps:TArrayOfSingle;
  DstImps:TArrayOfSingle;
  i,j,CB,CBm,J0,J1,J2,idt:Integer;
  FactorOfFading,WA,WB:Double;
  PrevSignifSurge,NNoise,FNoise:Single;
  tDT,tAlpha,Inaccuracy,Tmp,NearDelta,FarDelta:Double;
  LMean,RMean,Max:Double;
  pwc:^TWaveP2Calculator;
  pt:^Double;
  S:String;
begin
  Result:=inherited Process;
  // calculate dt & alpha
  FactorOfFading:=exp(-WaveAlphaMax*DTmax);
  idt:=Trunc(DTmin);
  StartRec:=MP[0].StartRec;
  for i:=0 to 1 do begin
    MP0:=MP[i]; MP1:=MP[i xor 1];
    GetJ1J2(StartRec,LastCalcRec[i]+1,
      [MP0.FLastKnownRec-MaxCB, MP1.FLastKnownRec-Trunc(DTmax)-1-MaxCB],
      MaxCB,High(MP0.FSurge),J0,J1,J2
    );
    Result:=Result or (J1<=J2);
    PrevSignifSurge:=0;
    j:=J1;
    while j<=J2 do begin
      NNoise:=MP0.FNoise[j-MaxCB];
      FNoise:=MP1.FNoise[j+idt-MaxCB];
      DifferenceFromLine(@MP0.FSurge[j-MinCB],MinCB*2,@LMean,@RMean,@Max);
      if (LMean<NNoise*2) and (RMean>NNoise*4)
        and (RMean*FactorOfFading > 0.5*FNoise)
      then begin
        if Max<PrevSignifSurge then begin
          Dec(j);
          PrevSignifSurge:=0;
          CBm:=MinCB;
          for CB:=MinCB+1 to MaxCB do begin
            DifferenceFromLine(@MP0.FSurge[j-CB],CB*2,nil,nil,@Tmp);
            if Tmp>Max then begin
              Max:=Tmp; CBm:=CB;
            end;
          end;
          if True{CBm<>MaxCB} then begin
            Calc_DT_And_Alpha(i,j-CBm,CBm*2,tDT,tAlpha);
            DTAF.GetAdvInfo(Inaccuracy,NearDelta,FarDelta);
            if (Inaccuracy<=0.1) and
              (WaveAlphaMin<=tAlpha) and (tAlpha<=WaveAlphaMax)
            then begin
              S:=LogMsg((StartRec+j)*MP0.Period, Format(
                '%s-%s'#9+
                '%5.1f'#9'%6.1f'#9+
                '%7.5f'#9'%4.2f'#9'%4.2f'#9'%4.2f',
                [MP0.Track.StrTrackID, MP1.Track.StrTrackID,
                 tDT, abs(MP0.Meter-MP1.Meter)/tDT, tAlpha,
                 Inaccuracy, NearDelta, FarDelta ]
              ));
              Scanner.ScanLog(S);
              Tmp:=Sqr(Sqr(Sqr(1-Inaccuracy)));
              DT:=DT*(1-Tmp)+tDT*Tmp; idt:=Round(DT);
              WaveAlpha[i]:=WaveAlpha[i]*(1-Tmp)+tAlpha*Tmp;
              j:=j+CBm+MinCB;
            end;
          end;
          Inc(j);
        end
        else PrevSignifSurge:=Max;
      end;
      Inc(j);
    end;
    LastCalcRec[i]:=StartRec+J2;
  end;
  // Transmit the known outer impulses
  idt:=Trunc(DT); WA:=Frac(DT); WB:=1-WA;
  for i:=0 to 1 do begin
    MP0:=MP[i]; MP1:=MP[i xor 1];
    SrcImps:=MP0.FImpulse[i];
    DstImps:=MP1.FImpulse[i];
    GetJ1J2(StartRec,MP1.FLastImpulseRec[i]+1,
      [MP0.FLastImpulseRec[i]+idt],
      idt+1,High(DstImps),J0,J1,J2
    );
    Result:=Result or (J1<=J2) or (J0<J1);
    for j:=J0 to J1-1 do DstImps[j]:=0;
    pt:=@t[i];
    pwc:=@P2C[i]; pwc.Alpha1:=WaveAlpha[i]; pwc.tf2:=DT;
    for j:=J1 to J2 do begin
      DstImps[j]:=pwc.CalcP2(pt^,SrcImps[j-idt-1]*WA+SrcImps[j-idt]*WB);
      if Abs(pwc.Int2)<0.01 then pt^:=0
      else pt^:=pt^+1.0;
    end;
    if J2<J1 then J2:=J1-1;
    MP1.FLastImpulseRec[i]:=StartRec+J2;
  end;
end;

function TMeasurePoint.Get_Meter: Double;
begin
  Result:=FG.Kilometer*1000;
end;

{ TDTAlphaFinder }

procedure TDTAlphaFinder.GetAdvInfo(var Inacc,NearDelta,FarDelta:Double);
var
  SqrNoise,Noise:Double;
  NearMin,NearMax,FarMin,FarMax,V:Single;
  K,B:Double;
  MinNL,MaxNL:Single;
  Dist,InvDist,NoiseFactor,RangeFactor,InvFactor:Double;
  i,idt,n:Integer;
begin
  Dist:=OptFunc;
  idt:=Trunc(P2C.tf2)-iDTmin;
  N:=Length(NearImp);
  CalcKB(@PCalc[0],0,n-1,@K,@B);
  NearMin:=NearImp[0]; NearMax:=NearMin;
  FarMin:=PCalc[0]; FarMax:=FarMin;
  SqrNoise:=0; Noise:=0;
  MinNL:=MaxInt; MaxNL:=-MaxInt;
  for i:=0 to n-1 do begin
    V:=PCalc[i]; if V<FarMin then FarMin:=V else if FarMax<V then FarMax:=V;
    V:=NearImp[i]; if V<NearMin then NearMin:=V else if NearMax<V then NearMax:=V;
    V:=K*i+B-V; if V<MinNL then MinNL:=V; if MaxNL<V then MaxNL:=V;
    Noise:=Noise+FarNoise[idt+i];
    SqrNoise:=SqrNoise+Sqr(FarNoise[idt+i]);
    PCalc[i]:=-V;
  end;
  InvDist:=LinearCompensatedDistance(@PCalc[0],@PReal[0],n);
{
  SqrNoise:=Sqrt(SqrNoise);
  if Dist>0 then begin
    RangeFactor:=1-0.5*SqrNoise/Dist; if RangeFactor<0 then RangeFactor:=0;
  end
  else RangeFactor:=1;
{
  if MinNL<MaxNL
  then NoiseFactor:=2*Noise/(n*(MaxNL-MinNL))
  else NoiseFactor:=1;
//}
  if Dist+InvDist>1e-66
  then InvFactor:=1-(InvDist-Dist)/(Dist+InvDist)
  else InvFactor:=1;
  Inacc:={RangeFactor{+NoiseFactor}+InvFactor;
  NearDelta:=NearMax-NearMin;
  FarDelta:=FarMax-FarMin;
end;

function TDTAlphaFinder.OptFunc: Double;
begin
  PrepareP;
  Result:=LinearCompensatedDistance(@PCalc[0],@PReal[0],Length(NearImp));
end;

procedure TDTAlphaFinder.PrepareP;
var
  WA,WB:Double;
  i,idt:Integer;
begin
  WB:=Frac(P2C.tf2); WA:=1-WB;
  idt:=Trunc(P2C.tf2)-iDTmin;
  for i:=0 to High(NearImp) do PReal[i]:=FarImp[idt+i]*WA+FarImp[idt+i+1]*WB;
//  ExtractImpulse(@P2[0],@P2[0],Length(NearImp));
  for i:=0 to High(NearImp) do PCalc[i]:=P2C.CalcP2(i,NearImp[i]);
end;

{$IFDEF DebugWriteTracks}
function TMeasurePoint.DebugWrite;
const
  TrkLetter:array[0..1] of WideChar = ('T','B');
var
  wsTmp:WideString;
  AD:TAnalogData;
  i,j,J0,J1,J2,Count:Integer;
begin
  Result:=False;
  for i:=0 to 1 do begin
    GetJ1J2(StartRec,LastWritedRec[i]+1,[FLastImpulseRec[i]],0,High(FImpulse[i]),J0,J1,J2);
    Count:=J2-J1+1;
    if Count<=0 then continue;
    Result:=True;
    if ImpTrack[i]=0 then begin
      AM2.applySubstitutions(TrkLetter[i]+'%SectID%%SensID%',Track.TrackID,0,wsTmp);
      AM2.StrToTrackID(wsTmp,ImpTrack[i]);
      AM2.setTrackInfo(ImpTrack[i],TMySensor.GetRecSize,Track.RecsPerDay);
    end;
    SetLength(wsTmp,(Count*TMySensor.GetRecSize+1) shr 1);
    for j:=J1 to J2 do begin
      AD.Value:=FImpulse[i,j];
      if AD.Flags=0 then AD.Flags:=AD.Flags or $80000000;
      TMySensor.SetAD(wsTmp,j-J1,AD);
    end;
    AM2.writeRecords(ImpTrack[i],(StartRec+J1)*Period,Count,wsTmp);
    LastWritedRec[i]:=StartRec+J2;
  end;
end;
{$ENDIF}

{ TScanner }

procedure TScanner.addGraph(G: TFrameGraph);
var
  PrevMP,MP:TMeasurePoint;
  P:TPipePart;
  i:Integer;
begin
  assert(Parts=nil);
  if G<>nil then begin
    MP:=TMeasurePoint.Create(G);
    if MPs=nil then MPs:=TObjectList.Create;
    MPs.Add(MP);
    MP.Capacity:=Capacity;
  end
  else begin
    assert(MPs.Count>=2);
    Parts:=TObjectList.Create;
    PrevMP:=TMeasurePoint(MPs[0]);
    P:=nil;
    for i:=1 to MPs.Count-1 do begin
      MP:=TMeasurePoint(MPs[i]);
      if Abs(MP.Meter-PrevMP.Meter)<=2000
      then P:=TSpottiness.Create(Self,PrevMP,MP)
      else P:=TLinearPart.Create(Self,PrevMP,MP);
      if i=1 then P.NoWaitImpulse[0]:=True;
      Parts.Add(P);
      PrevMP:=MP;
    end;
    P.NoWaitImpulse[1]:=True;
  end;
end;

constructor TScanner.Create;
begin
  inherited;
  Capacity:=4096;
  Scanners.Add(Self);
end;

destructor TScanner.Destroy;
begin
  Scanners.Extract(Self);
  Parts.Free;
  MPs.Free;
  inherited;
end;

function TScanner.FindGraphByStrID(StrID: String): TFrameGraph;
var
  i:Integer;
begin
  i:=MPs.Count-1;
  while (i>=0) and (TMeasurePoint(MPs[i]).FG.ADTrack.StrTrackID<>StrID)
  do Dec(i);
  if i<0 then Result:=nil
  else Result:=TMeasurePoint(MPs[i]).FG;
end;

procedure TScanner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
  FS:=nil;
  if State=ssProcess
  then State:=ssStopAndFree
  else Free;
end;

procedure TScanner.FormStart(Sender: TObject);
begin
  State:=ssProcess;
  SetScanRange(FS.StartTime,FS.StopTime);
end;

function TScanner.Get_RecsPerDay: Integer;
begin
  assert(MPs.Count>0);
  Result:=TMeasurePoint(MPs[0]).Track.RecsPerDay;
end;

function TScanner.Get_StopRec: Int64;
var
  Tmp:Int64;
  i:Integer;
begin
  Result:=0;
  if FScanToRec<>0 then Result:=FScanToRec
  else
    for i:=0 to MPs.Count-1 do begin
      Tmp:=TMeasurePoint(MPs[i]).MostLastRec;
      if Result < Tmp then Result:=Tmp;
    end;
end;

procedure TScanner.Process;
var
  i,Cnt:Integer;
  SomethingToDo:Boolean;
  Tmp:Int64;
begin
  if InProcess or (CurStartRec<=0) or (State<>ssProcess) then exit;
  InProcess:=True;
  ScanLog('Time'#9'BEG-END'#9'DT'#9'WS'#9'Alpha'#9'Inaccuracy'#9'NearDelta'#9'FarDelta'#13#10);
  repeat
    Cnt:=512;
    repeat
      SomethingToDo:=False;
      for i:=0 to Parts.Count-1 do begin
        SomethingToDo:=TPipePart(Parts[i]).Process or SomethingToDo;
        Application.ProcessMessages;
      end;
      Dec(Cnt);
    until not SomethingToDo or Application.Terminated;// or (Cnt<=0);
{$IFDEF DebugWriteTracks}
    for i:=0 to MPs.Count-1
    do TMeasurePoint(MPs[i]).DebugWrite;
{$ENDIF}
{
    for i:=0 to MPs.Count-1
    do Ready:=Ready or TMeasurePoint(MPs[i]).CalculationComplete;
    if Ready then begin
//}
      Tmp:=StopRec;
      if CurStartRec+Capacity < Tmp then begin
        if CurStartRec+Capacity*3 div 2 > Tmp
        then CurStartRec:=Tmp-Capacity
        else CurStartRec:=CurStartRec+Capacity div 2;
      end
      else State:=ssDone;
//    end;
    if Assigned(FS)
    then FS.stStatus.Caption:=DateTimeToStr(CurStartRec/RecsPerDay);
  until (State<>ssProcess) or Application.Terminated;
  InProcess:=False;
  Log('',True);
  if State=ssStopAndFree then Free
  else if State=ssDone then begin
    if Assigned(FS) then begin
      FS.stStatus.Caption:='Готово!';
//      FS.sgLog.Enabled:=True;
    end;
  end;
end;

function TMeasurePoint.Get_MostLastRec: Int64;
begin
  Result:=Track.LastRec;
end;

procedure TScanner.ScanLog(S: String);
begin
  Log(S);
  if Assigned(FS) then FS.Log(S);
end;

procedure TScanner.SetForm(const Value: TFormScanner);
begin
  if FS<>Value then begin
    if FS<>nil then FS.OnCloseQuery:=nil;
    FS:=Value;
    FS.OnClose:=FormClose;
    FS.OnStart:=FormStart;
    FS.OnGetRow:=FormShowAdvInfo;
  end;
end;

procedure TScanner.SetScanRange(FromTime, ToTime: TDateTime);
var
  RPD:Integer;
begin
  RPD:=RecsPerDay;
  CurStartRec:=Trunc(FromTime*RPD);
  FScanToRec:=Trunc(ToTime*RPD);
end;

procedure TScanner.Set_CurStartRec(const Value: Int64);
var
  i:Integer;
begin
  if FCurStartRec<>Value then begin
    FCurStartRec:=Value;
    for i:=0 to MPs.Count-1
    do TMeasurePoint(MPs[i]).StartRec:=Value;
  end;
end;

function TMeasurePoint.CalculationComplete: Boolean;
begin
  Result:=
    (FLastCalcRec<=FLastImpulseRec[0]) and
    (FLastCalcRec<=FLastImpulseRec[1]);
end;

procedure Finalize;
var
  i:Integer;
begin
  for i:=Scanners.Count-1 downto 0 do TScanner(Scanners[i]).Free;
  Scanners.Free;
  Log('',True);
end;

procedure TScanner.FormShowAdvInfo(Sender:TObject; SS:TStrings);
var
  T:TDateTime;
  dt:Double;
  FGB,FGE:TFrameGraph;
  sBegEnd:String;
begin
  T:=StrToDateTime(SS[0]);
  sBegEnd:=SS[1];
  dt:=StrToFloat(SS[2])*dtOneSecond;
  FGB:=FindGraphByStrID(Copy(sBegEnd,1,3));
  FGE:=FindGraphByStrID(Copy(sBegEnd,5,3));
  FGB.QueryArcView(T+FGB.TimeCapacity*0.75);
  FGE.View1.lockRender; FGE.LabelTime:=T+dt; FGE.SetFocus; FGE.View1.unlockRender;
  FGB.View1.lockRender; FGB.LabelTime:=T;    FGB.SetFocus; FGB.View1.unlockRender;
end;

{ TExpFilter }

function TExpFilter.GetCurVal: Double;
begin
  Result:=FVal;
end;

function TExpFilter.GetNextVal(V, Alpha: Double): Double;
begin
  FVal:=FVal*Alpha+V*(1-Alpha);
  if CntPrecharge<256 then begin
    if CntPrecharge=0 then FVal:=V;
    Inc(CntPrecharge);
    Result:=V;
  end
  else Result:=FVal;
end;

initialization
  Scanners:=TList.Create;
  WaveSpeedMin:=1000;
  WaveSpeedMax:=1200;
  WaveAlphaMin:=0.005;
  WaveAlphaMax:=0.025;
finalization
  Finalize;
end.

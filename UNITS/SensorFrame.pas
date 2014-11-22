unit SensorFrame;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, IniFiles, Misc, ExtCtrls, SyncObjs, ConversionForm, SensorTypes;

type
  TFrameSensor = class(TFrame)
    Panel1: TPanel;
    cbOn: TCheckBox;
    stCount: TStaticText;
    Label4: TLabel;
    stResult: TStaticText;
    stX: TStaticText;
    edQueryCmd: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edPeriod: TEdit;
    Label3: TLabel;
    BtnConversion: TButton;
    procedure cbOnClick(Sender: TObject);
    procedure BtnConversionClick(Sender: TObject);
  private
    { Private declarations }
    Section:String;
    procedure CalcCoeffs;
  public
    { Public declarations }
    CS:TCriticalSection;
    AdrList:TList;
    BusNumber:Integer;
    NetNumber:Integer;
    Period:Integer;
    // ADC & conversion parameters
    VoltageMode:Boolean;
    ADCRange:Integer;
    PhysScale,VoltsScale:Double;
    Ia,Ib,R:Double;
    Ua,Ub:Double;
    Xm,Xa,Xb:Double;
    CoeffK,CoeffB:Double;
    // Error flags
    IsErrADCComm:Boolean;
    IsErrADCRange:Boolean;
    IsErrAnalog:Boolean;
    X:Single;
    ShowSumX:Double;
    ShowQueryCnt,ShowResponseCnt,ShowMeasureCnt:Integer;
    isSensorOn:Boolean;
    QueryCmd:String;
    MeasureCnt:Integer;
    SumX:Double;
    CounterPoll:Integer;
    PrevSampleNum:Cardinal;
    ReadyForOutput:Boolean;
    ValidConfig:Boolean;
    NotFirstSample:Boolean;
    constructor Create(AOwner:TComponent);override;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);
    procedure WriteToIni(Ini:TIniFile);
    function Validate:Boolean;
    procedure TimerProc(const fSampleNum:Double);
//    procedure TimerShow;
    procedure ShowInfo;
    destructor Destroy;override;
  end;

  TAddress=class(TObject)
    Host:String;
    Port:Integer;
    constructor Create(const Host:String; Port:Integer);
  end;

implementation

{$R *.DFM}

//uses Main;

function fmt(X:Double):String;
begin
  Result:=Format('%.5f',[X]);
  if Result[1]<>'-' then Result:=' '+Result;
  if Length(Result)>8 then SetLength(Result,8);
end;

{ TFrameSensor }

destructor TFrameSensor.Destroy;
var
  i:Integer;
begin
  if AdrList<>nil then begin
    for i:=0 to AdrList.Count-1 do TObject(AdrList[i]).Free;
    AdrList.Free;
  end;
  CS.Free;
  inherited;
end;

procedure TFrameSensor.LoadFromIniSection(Ini: TIniFile;
  const Section: String);
var
  i,Cnt:Integer;
begin
  AdrList:=TList.Create;
  Self.Section:=Section;
  isSensorOn:=Ini.ReadInteger(Section,'On',1)<>0;
  NetNumber:=Ini.ReadInteger(Section,'NetNumber',0);
  cbOn.Checked:=isSensorOn;
  cbOn.Caption:='№'+IntToStr(NetNumber)+' вкл.';
  edQueryCmd.Text:=Ini.ReadString(Section,'QueryCmd','#010');
  edPeriod.Text:=Ini.ReadString(Section,'Period','1');
  // ADC & conversion parameters
  VoltageMode:=Ini.ReadInteger(Section,'VoltageMode',0)<>0;
  ADCRange:=Ini.ReadInteger(Section,'ADCRange',9);
  if VoltageMode then begin
    Ua:=Ini.ReadFloat(Section,'Ua',0.0);
    Ub:=Ini.ReadFloat(Section,'Ub',2.5);
  end
  else begin
    Ia:=Ini.ReadFloat(Section,'Ia',0.004);
    Ib:=Ini.ReadFloat(Section,'Ib',0.020);
    R:=Ini.ReadFloat(Section,'R',125);
    Ua:=Ia*R; Ub:=Ib*R;
  end;
  Xm:=Ini.ReadFloat(Section,'Xm',0);
  Xa:=Ini.ReadFloat(Section,'Xa',0);
  Xb:=Ini.ReadFloat(Section,'Xb',60);
  CalcCoeffs;
  //
  Cnt:=Ini.ReadInteger(Section,'DataCopies',0);
  for i:=1 to Cnt do begin
    AdrList.Add(TAddress.Create(
      Ini.ReadString(Section,'Host'+IntToStr(i),''),
      Ini.ReadInteger(Section,'Port'+IntToStr(i),0)
    ));
  end;
end;

procedure TFrameSensor.TimerProc(const fSampleNum:Double);
var
  pX:^TAnalogData;
  SX:Double;
  MC:Integer;
  SampleNum:Cardinal;
begin
  SampleNum:=Trunc(fSampleNum);//Round
  if not NotFirstSample then begin
    NotFirstSample:=True;
    PrevSampleNum:=SampleNum;
  end;
  ReadyForOutput:=PrevSampleNum<>SampleNum;
  PrevSampleNum:=SampleNum;
  if ReadyForOutput then begin
    CS.Acquire;
    SX:=SumX; MC:=MeasureCnt;
    SumX:=0; MeasureCnt:=0;
    if (MC>0) then X:=SX/MC
    else begin
      pX:=@X;
      if isSensorOn then begin
        if IsErrAnalog then SetErrAnalog(pX^)
        else if IsErrADCRange then SetErrADCRange(pX^)
        else if IsErrADCComm then SetErrADCComm(pX^)
        else SetErrUnknown(pX^);
      end
      else SetSensorRepair(pX^);
    end;
    CS.Release;
  end;
end;

procedure TFrameSensor.ShowInfo;
var
  SX:Double;
  QC,MC,RC:Integer;
begin
  CS.Enter;
  QC:=ShowQueryCnt; RC:=ShowResponseCnt; MC:=ShowMeasureCnt; SX:=ShowSumX;
  ShowQueryCnt:=0; ShowResponseCnt:=0; ShowMeasureCnt:=0; ShowSumX:=0;
  CS.Leave;
  stCount.Caption:=IntToStr(RC)+' из '+IntToStr(QC)+' ';
  if MC>0 then begin
    SX:=SX/MC;
    stX.Caption:=fmt(SX*VoltsScale)+' ';
    stResult.Caption:=fmt(SX*CoeffK+CoeffB)+' ';
  end
  else stX.Caption:='-';
end;

function TFrameSensor.Validate: Boolean;
var
  Tmp:Integer;
begin
  Result:=False;
  ValidConfig:=False;
  try
    try
      Tmp:=StrToInt(edPeriod.Text);
      if(Tmp<1)or(100<Tmp)then raise Exception.Create('');
      CS.Acquire;
      Period:=Tmp;
      CS.Release;
    except
      edPeriod.SetFocus;
      raise;
    end;
    CS.Acquire;
    QueryCmd:=edQueryCmd.Text;
    QueryCmd:=QueryCmd+StrCheckSum(QueryCmd[1],SizeOf(QueryCmd));
    CS.Release;
  except
    exit;
  end;
  Result:=True;
  ValidConfig:=True;
end;

procedure TFrameSensor.cbOnClick(Sender: TObject);
begin
  if cbOn.Checked then cbOn.Checked:=Validate;
  CS.Acquire;
  isSensorOn:=cbOn.Checked;
  CS.Release;
end;

procedure TFrameSensor.WriteToIni(Ini: TIniFile);
begin
  Ini.WriteInteger(Section,'On',Integer(cbOn.Checked));
  if ValidConfig then begin
    Ini.WriteString(Section,'Period',edPeriod.Text);
    Ini.WriteString(Section,'QueryCmd',edQueryCmd.Text);
  end;
  // ADC & conversion parameters
  Ini.WriteInteger(Section,'VoltageMode',Integer(VoltageMode));
  Ini.WriteInteger(Section,'ADCRange',ADCRange);
  if VoltageMode then begin
    Ini.WriteFloat(Section,'Ua',Ua);
    Ini.WriteFloat(Section,'Ub',Ub);
  end
  else begin
    Ini.WriteFloat(Section,'Ia',Ia);
    Ini.WriteFloat(Section,'Ib',Ib);
    Ini.WriteFloat(Section,'R',R);
  end;
  Ini.WriteFloat(Section,'Xm',Xm);
  Ini.WriteFloat(Section,'Xa',Xa);
  Ini.WriteFloat(Section,'Xb',Xb);
end;

constructor TFrameSensor.Create(AOwner: TComponent);
begin
  inherited;
  CS:=TCriticalSection.Create;
end;

procedure TFrameSensor.CalcCoeffs;
begin
  while not getADCRangeParams(ADCRange,PhysScale,VoltsScale) do ADCRange:=9;
  CoeffK:=VoltsScale*(Xb-Xa)/(Ub-Ua);
  CoeffB:=VoltsScale*Xa-CoeffK*Ua;
end;

procedure TFrameSensor.BtnConversionClick(Sender: TObject);
var
  CF:TFormConversion;
  MR:Integer;
begin
  CF:=TFormConversion.Create(Self);
  CF.VoltageMode:=VoltageMode;
  CF.ADCRange:=ADCRange;
  CF.Ia:=Ia; CF.Ib:=Ib; CF.R:=R;
  CF.Ua:=Ua; CF.Ub:=Ub;
  CF.Xm:=Xm; CF.Xa:=Xa; CF.Xb:=Xb;
  while True do begin
    MR:=CF.ShowModal;
    case MR of
      mrOK,mrYes: begin
        CS.Enter;
        VoltageMode:=CF.VoltageMode;
        ADCRange:=CF.ADCRange;
        Ia:=CF.Ia; Ib:=CF.Ib; R:=CF.R;
        Ua:=CF.Ua; Ub:=CF.Ub;
        Xm:=CF.Xm; Xa:=CF.Xa; Xb:=CF.Xb;
        CalcCoeffs;
        CS.Leave;
        if MR=mrOK then break;
      end;
      mrCancel: break;
    end;
  end;
  CF.Free;
end;
{
procedure TFrameSensor.TimerShow;
begin
  if CntP=0 then P:=0;
  stStatus.Caption:=Format('%3d | %7.3f ',[CntP,P]);;
  CntP:=0;
end;
}
{ TAddress }

constructor TAddress.Create(const Host: String; Port: Integer);
begin
  inherited Create;
  Self.Host:=Host;
  Self.Port:=Port;
end;

end.

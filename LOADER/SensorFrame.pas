unit SensorFrame;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, IniFiles, Misc;

type
  TFrameSensor = class(TFrame)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    gbSensor: TGroupBox;
    edFactoryNum: TEdit;
    edBusNumber: TEdit;
    edNetNumber: TEdit;
    cbOn: TCheckBox;
    stPressure: TStaticText;
    stTemperature: TStaticText;
    stCount: TStaticText;
    edCoeffK: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    edCoeffB: TEdit;
  private
    { Private declarations }
    Section:String;
    function Get_TARDir: String;
  public
    { Public declarations }
    AdrList:TList;
    BusNumber:Integer;
    NetNumber:Integer;
    SumPressure,P:Double;
    SumTemperature,T:Double;
    CoeffK,CoeffB:Double;
    QueryCnt,MeasureCnt:Integer;
    ValidTP:Boolean;
    tt,pp:array[0..4] of Double;
    xx,yy:array[0..12] of Double;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);
    procedure WriteToIni(Ini:TIniFile);
    function Validate:Boolean;
    function LoadCoeffsFromTAR:Boolean;
    procedure TimerProc;
    destructor Destroy;override;
    property TARDir:String read Get_TARDir;
  end;

  TAddress=class(TObject)
    Host:String;
    Port:Integer;
    constructor Create(const Host:String; Port:Integer);
  end;

implementation

{$R *.DFM}

uses Main;

{ TFrameSensor }

destructor TFrameSensor.Destroy;
var
  i:Integer;
begin
  if AdrList<>nil then begin
    for i:=0 to AdrList.Count-1 do TObject(AdrList[i]).Free;
    AdrList.Free;
  end;
  inherited;
end;

function TFrameSensor.Get_TARDir: String;
begin
  Result:=TFormMain(Owner).TARDir; 
end;

function TFrameSensor.LoadCoeffsFromTAR: Boolean;
var
  i:Integer;
  TAR:TextFile;
  FileName:String;
begin
  // Загрузка коэффициентов из *.TAR - файла
  try
      FileName:=TARDir+edFactoryNum.Text+'.tar';
      AssignFile(TAR,FileName);
      Reset(TAR);
    try
      for i:=1 to 4 do Read(TAR,tt[i]);
      for i:=1 to 4 do Read(TAR,pp[i]);
      for i:=1 to 12 do begin
         Read(TAR,xx[i]);
         Read(TAR,yy[i]);
      end;
    finally
      Close(TAR);
    end;
  except
    Result:=False;
    exit;
  end;
  Result:=True;
end;

procedure TFrameSensor.LoadFromIniSection(Ini: TIniFile;
  const Section: String);
var
  i,Cnt:Integer;
begin
  AdrList:=TList.Create;
  Self.Section:=Section;
  cbOn.Checked:=Ini.ReadInteger(Section,'On',1)<>0;
  edFactoryNum.Text:=Ini.ReadString(Section,'FactoryNum','000000');
  edBusNumber.Text:=Ini.ReadString(Section,'BusNumber','1');
  edNetNumber.Text:=Ini.ReadString(Section,'NetNumber','1');
  edCoeffK.Text:=Ini.ReadString(Section,'CoeffK','1');
  edCoeffB.Text:=Ini.ReadString(Section,'CoeffB','0');
  Cnt:=Ini.ReadInteger(Section,'DataCopies',0);
  for i:=1 to Cnt do begin
    AdrList.Add(TAddress.Create(
      Ini.ReadString(Section,'Host'+IntToStr(i),''),
      Ini.ReadInteger(Section,'Port'+IntToStr(i),0)
    ));
  end;
end;

procedure TFrameSensor.TimerProc;
var
  Coeff:Double;
begin
  stCount.Caption:=IntToStr(MeasureCnt)+' из '+IntToStr(QueryCnt)+' ';
  if MeasureCnt>0 then begin
    Coeff:=1/MeasureCnt;
    P:=SumPressure*Coeff*CoeffK+CoeffB;
    T:=SumTemperature*Coeff;
    stPressure.Caption:=Format('%2.3f ',[P]);
    stTemperature.Caption:=Format('%2.3f ',[T]);
    SumPressure:=0;
    SumTemperature:=0;
    ValidTP:=True;
  end
  else begin
    stPressure.Caption:='';
    stTemperature.Caption:='';
    ValidTP:=False;
  end;
  MeasureCnt:=0;
  QueryCnt:=0;
end;

function TFrameSensor.Validate: Boolean;

  procedure ErrorMsg(const Msg:String);
  begin
    Application.MessageBox(PChar(Msg),'Ошибка',MB_ICONINFORMATION or MB_OK);
    raise Exception.Create('');
  end;

begin
  Result:=False;
  try
    if not LoadCoeffsFromTAR then begin
      edFactoryNum.SetFocus;
      ErrorMsg('Ошибка при загрузке коэффициентов');
    end;
    try
      CoeffK:=StrToFloat(edCoeffK.Text);
    except
      edCoeffK.SetFocus;
      raise;
    end;
    try
      CoeffB:=StrToFloat(edCoeffB.Text);
    except
      edCoeffB.SetFocus;
      raise;
    end;
    try
      BusNumber:=StrToInt(edBusNumber.Text);
      if (BusNumber<0) or (255<BusNumber)
      then ErrorMsg('Значение номера датчика на шине должно быть от 0 до 255');
    except
      edBusNumber.SetFocus;
      raise;
    end;
    try
      NetNumber:=StrToInt(edNetNumber.Text);
      if (NetNumber<0) or (255<NetNumber)
      then ErrorMsg('Локальный код датчика должен быть числом от 0 до 255');
    except
      edNetNumber.SetFocus;
      raise;
    end;
  except
    exit;
  end;
  Result:=True;
end;

procedure TFrameSensor.WriteToIni(Ini: TIniFile);
begin
  Ini.WriteInteger(Section,'On',Integer(cbOn.Checked));
  Ini.WriteString(Section,'FactoryNum',edFactoryNum.Text);
  Ini.WriteString(Section,'BusNumber',edBusNumber.Text);
  Ini.WriteString(Section,'NetNumber',edNetNumber.Text);
  Ini.WriteString(Section,'CoeffK',edCoeffK.Text);
  Ini.WriteString(Section,'CoeffB',edCoeffB.Text);
end;

{ TAddress }

constructor TAddress.Create(const Host: String; Port: Integer);
begin
  inherited Create;
  Self.Host:=Host;
  Self.Port:=Port;
end;

end.

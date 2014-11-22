unit SensorFrame;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, IniFiles, Misc, ExtCtrls, SyncObjs;

type
  TFrameSensor = class(TFrame)
    Panel1: TPanel;
    cbRepair: TCheckBox;
    stStatus: TStaticText;
    Label3: TLabel;
    edNetNumber: TEdit;
    Label7: TLabel;
    edCoeffK: TEdit;
    Label6: TLabel;
    edCoeffB: TEdit;
    procedure cbRepairClick(Sender: TObject);
  private
    { Private declarations }
    Section:String;
  public
    { Public declarations }
    CS:TCriticalSection;
    AdrList:TList;
    NetNumber:Integer;
    DataList:TStringList;
    CoeffK,CoeffB:Single;
    isSensorOn:Boolean;
    Valid_KB:Boolean;
    CntP:Integer;
    P:Single;
    constructor Create(AOwner:TComponent);override;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);
    procedure WriteToIni(Ini:TIniFile);
    function Validate:Boolean;
    procedure TimerProc;
    destructor Destroy;override;
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
  if DataList<>nil then DataList.Free;
  inherited;
end;

procedure TFrameSensor.LoadFromIniSection(Ini: TIniFile;
  const Section: String);
var
  i,Cnt:Integer;
begin
  AdrList:=TList.Create;
  DataList:=TStringList.Create;
  Self.Section:=Section;
  isSensorOn:=Ini.ReadInteger(Section,'On',1)<>0;
  cbRepair.Checked:=not isSensorOn;
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
  Valid_KB:=TRUE;
end;

procedure TFrameSensor.TimerProc;
begin
  if CntP=0 then P:=0;
  stStatus.Caption:=Format('%3d | %7.3f ',[CntP,P]);;
  CntP:=0;
end;

function TFrameSensor.Validate: Boolean;

  procedure ErrorMsg(const Msg:String);
  begin
    Application.MessageBox(PChar(Msg),'Программа опроса контроллера',MB_ICONINFORMATION or MB_OK);
    raise Exception.Create('');
  end;

begin
  Valid_KB:=FALSE;
  Result:=False;
  try
    try
      CoeffK:=StrToFloat(edCoeffK.Text);
    except
      edCoeffK.SetFocus;
      ErrorMsg('Ошибка в коэффициенте K');
    end;
    try
      CoeffB:=StrToFloat(edCoeffB.Text);
    except
      edCoeffB.SetFocus;
      ErrorMsg('Ошибка в коэффициенте B');
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
  Valid_KB:=TRUE;
  Result:=True;
end;

procedure TFrameSensor.cbRepairClick(Sender: TObject);
var
  Thd:TMainThread;
begin
//  if cbOn.Checked then cbOn.Checked:=Validate;
  Thd:=TFormMain(Owner).Thd;
  if Thd<>nil then Thd.CS.Acquire;
  isSensorOn:=not cbRepair.Checked;
  if Thd<>nil then Thd.CS.Release;
end;

procedure TFrameSensor.WriteToIni(Ini: TIniFile);
begin
  if not Valid_KB then exit;
  Ini.WriteInteger(Section,'On',Integer(not cbRepair.Checked));
  Ini.WriteString(Section,'NetNumber',edNetNumber.Text);
  Ini.WriteString(Section,'CoeffK',edCoeffK.Text);
  Ini.WriteString(Section,'CoeffB',edCoeffB.Text);
end;

constructor TFrameSensor.Create(AOwner: TComponent);
begin
  inherited;
  CS:=TCriticalSection.Create;
end;

{ TAddress }

constructor TAddress.Create(const Host: String; Port: Integer);
begin
  inherited Create;
  Self.Host:=Host;
  Self.Port:=Port;
end;

end.

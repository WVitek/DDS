unit UFrameAnalog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons, UTreeItem, IniFiles, UFrameKP;

type
  TItemAnalog = class;

  TFrameAnalog = class(TFrame)
    Panel: TPanel;
    edR: TEdit;
    edP: TEdit;
    Label7: TLabel;
    Label6: TLabel;
    BtnChange: TButton;
    cbOn: TCheckBox;
    stStatus: TStaticText;
    procedure BtnChangeClick(Sender: TObject);
    procedure cbOnClick(Sender: TObject);
  private
    { Private declarations }
    Analog:TItemAnalog;
  public
    { Public declarations }
  end;

  TItemAnalog = class(TTreeItem)
  public
    KP:TItemKP;
    NetNumber:Integer;
    CoeffR,CoeffP:Double;
    isSensorOn:Boolean;
    FA:TFrameAnalog;
    DataList:TStringList;
    CntP:Integer;
    SumP,P:Double;
    constructor Load(KP:TItemKP; Ini,Cfg:TIniFile; const Section:String);
    function Enter:TFrame;override;
    function Leave:Boolean;override;
    function Validate:Boolean;override;
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
    procedure RefreshFrame;
    procedure GetP(const SrcData; var P:Single);
  private
    CoeffK,CoeffB:Double;
    procedure CalcKB;
  end;

implementation

uses UFormMain, Misc, SensorTypes;

{$R *.DFM}

procedure TFrameAnalog.BtnChangeClick(Sender: TObject);
begin
  Analog.ChangeData(BtnChange,Panel);
end;

{ TItemAnalog }

function TItemAnalog.Enter: TFrame;
begin
  FA:=TFrameAnalog.Create(FormMain);
  FA.Analog:=Self;
  FA.Name:='';
  FA.cbOn.Caption:='№'+IntToStr(NetNumber);
  FA.cbOn.Checked:=isSensorOn;
  FA.edR.Text:=Format('%g',[CoeffR]);
  FA.edP.Text:=Format('%g',[CoeffP]);
  RefreshFrame;
  Result:=FA;
end;

function TItemAnalog.Leave: Boolean;
begin
  FA.Free; FA:=nil;
  Result:=True;
end;

constructor TItemAnalog.Load(KP:TItemKP; Ini,Cfg: TIniFile;
  const Section: String);
begin
  inherited;
  Self.KP:=KP;
  Self.Section:=Section;
  Node:=FormMain.TreeView.Items.AddChildObject(KP.Node,Section,Self);
  NetNumber:=Ini.ReadInteger(Section,'NetNumber',0);
  isSensorOn:=Cfg.ReadBool(Section,'On',True);
  CoeffR:=Cfg.ReadFloat(Section,'R',124);
  CoeffP:=Cfg.ReadFloat(Section,'P',60);
  CalcKB;
end;

procedure TItemAnalog.TimerProc;
begin
  if CntP>0 then begin P:=SumP/CntP; end;
  if FA<>nil then RefreshFrame;
  SumP:=0; CntP:=0;
end;

function TItemAnalog.Validate: Boolean;
var
  CR,CP:Double;
begin
  try
    CheckMinMax(CR,1,999,FA.edR);
    CheckMinMax(CP,0.01,128,FA.edP);
    CoeffR:=CR;
    CoeffP:=CP;
    CalcKB;
    Result:=True;
  except
    Result:=False;
  end;
end;

procedure TItemAnalog.SaveCfg(Cfg: TIniFile);
begin
//  Ini.WriteInteger(Section,'NetNumber',NetNumber);
  Cfg.WriteBool(Section,'On',isSensorOn);
  Cfg.WriteFloat(Section,'R',CoeffR);
  Cfg.WriteFloat(Section,'P',CoeffP);
end;

procedure TItemAnalog.RefreshFrame;
begin
  FA.stStatus.Caption:=Format('%3d | %7.3f ',[CntP,P]);;
  FA.cbOn.Checked:=isSensorOn;
end;

procedure TItemAnalog.CalcKB;
var
  Ua,Ub:Double;
begin
  Ua:=0.004*CoeffR;
  Ub:=0.020*CoeffR;
  CoeffK:=CoeffP/(Ub-Ua);
  CoeffB:=-CoeffK*Ua;
end;

procedure TItemAnalog.GetP(const SrcData; var P: Single);
const
  fErrorFlag    =$8000;
  fErrorComm    =$4000;
  fErrorADCRange=$2000;
  fErrorInvData =$1000;
  fErrorInvResp =$0800;   
  Prescale=2.5/32767;
var
  AD:TAnalogData;
  Tmp:Word;
begin
  Tmp:=0;
  move(SrcData,Tmp,2);
  if Tmp and fErrorFlag<>0 then begin // признак сбоя
    if Tmp and (fErrorComm or fErrorInvData or fErrorInvResp)<>0
    then SetErrADCComm(AD)
    else if Tmp and fErrorADCRange<>0
    then SetErrADCRange(AD)
    else SetErrUnknown(AD);
    if not isSensorOn then SetSensorRepair(AD);
  end
  else begin
    AD.Value:=Tmp*Prescale*CoeffK+CoeffB;
    Inc(CntP); SumP:=SumP+AD.Value;
    if AD.Value < -1 then SetErrAnalog(AD);
  end;
  P:=AD.Value;
end;

procedure TFrameAnalog.cbOnClick(Sender: TObject);
begin
  Analog.isSensorOn:=cbOn.Checked;
end;

end.

unit UFrameAnalog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls, Buttons, UTreeItem, IniFiles, UFrameKP;

type
  TItemAnalog = class;

  TFrameAnalog = class(TFrame)
    Panel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Label6: TLabel;
    BtnChange: TButton;
    cbOn: TCheckBox;
    stStatus: TStaticText;
    edR: TEdit;
    edIa: TEdit;
    edIb: TEdit;
    edXa: TEdit;
    edXb: TEdit;
    edXmin: TEdit;
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
    CoeffR,CoeffIa,CoeffIb,CoeffXa,CoeffXb,CoeffXmin:Double;
    isSensorOn:Boolean;
    FA:TFrameAnalog;
    DataList:TStringList;
    CntX,CntE,LCntX,LCntE:Integer;
    FreshDataTimer:Integer;
    SumX,X:Double;
    EMsg:String;
    constructor Load(Nodes:TTreeNodes; ParentNode:TTreeNode; Ini,Cfg:TIniFile; const Section:String);
    function Enter(Owner:TComponent):TFrame;override;
    function Leave:Boolean;override;
    function Validate:Boolean;override;
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
    procedure RefreshFrame;
    procedure GetX(const SrcData; var X:Single);
  private
    CoeffK,CoeffB:Double;
    procedure CalcKB;
  end;

implementation

uses Misc, SensorTypes;

{$R *.DFM}

procedure TFrameAnalog.BtnChangeClick(Sender: TObject);
begin
  Analog.ChangeData(BtnChange,Panel);
end;

{ TItemAnalog }

function TItemAnalog.Enter(Owner:TComponent): TFrame;
begin
  FA:=TFrameAnalog.Create(Owner);
  FA.Analog:=Self;
  FA.Name:='';
  FA.cbOn.Caption:='Канал №'+IntToStr(NetNumber);
  FA.cbOn.Checked:=isSensorOn;
  FA.edR.Text:=Format('%g',[CoeffR]);
  FA.edIa.Text:=Format('%g',[CoeffIa]);
  FA.edXa.Text:=Format('%g',[CoeffXa]);
  FA.edIb.Text:=Format('%g',[CoeffIb]);
  FA.edXb.Text:=Format('%g',[CoeffXb]);
  FA.edXmin.Text:=Format('%g',[CoeffXmin]);
  RefreshFrame;
  Result:=FA;
end;

function TItemAnalog.Leave: Boolean;
begin
  FA.Free; FA:=nil;
  Result:=True;
end;

constructor TItemAnalog.Load(Nodes:TTreeNodes; ParentNode:TTreeNode;
  Ini,Cfg: TIniFile; const Section: String);
begin
  inherited;
  Self.Section:=Section;
  KP:=TObject(ParentNode.Data) as TItemKP;
  Node:=Nodes.AddChildObject(ParentNode,Section,Self);
  NetNumber:=Ini.ReadInteger(Section,'NetNumber',0);
  isSensorOn:=Cfg.ReadBool(Section,'On',True);
  CoeffR:=Cfg.ReadFloat(Section,'R',124);
  CoeffIa:=Cfg.ReadFloat(Section,'Ia',0.004);
  CoeffXa:=Cfg.ReadFloat(Section,'Xa',0);
  CoeffIb:=Cfg.ReadFloat(Section,'Ib',0.020);
  CoeffXb:=Cfg.ReadFloat(Section,'Xb',Cfg.ReadFloat(Section,'P',60));
  CoeffXmin:=Cfg.ReadFloat(Section,'Xmin',-1);
  CalcKB;
end;

procedure TItemAnalog.TimerProc;
begin
  if CntX>0 then
  begin
    LCntE:=0;
    X:=SumX/CntX; LCntX:=CntX;
  end
  else begin
    LCntX:=0;
    if CntE>0
    then LCntE:=CntE;
  end;
  if FA<>nil then RefreshFrame;
  if FreshDataTimer>0
  then Dec(FreshDataTimer);
  SumX:=0; CntX:=0; CntE:=0;
end;

function TItemAnalog.Validate: Boolean;
var
  CR,CIa,CXa,CIb,CXb,CXmin:Double;
begin
  try
    CheckMinMax(CR,       1,  999, FA.edR   );
    CheckMinMax(CIa,   0.00,    1, FA.edIa  );
    CheckMinMax(CXa,  -1E38, 1E38, FA.edXa  );
    CheckMinMax(CIb,   0.00,    1, FA.edIb  );
    CheckMinMax(CXb,  -1E38, 1E38, FA.edXb  );
    CheckMinMax(CXmin,-1E38, 1E38, FA.edXmin);
    CoeffR   :=CR;
    CoeffIa  :=CIa;
    CoeffXa  :=CXa;
    CoeffIb  :=CIb;
    CoeffXb  :=CXb;
    CoeffXmin:=CXmin;
    CalcKB;
    Result:=True;
  except
    Result:=False;
  end;
end;

procedure TItemAnalog.SaveCfg(Cfg: TIniFile);
begin
//  Ini.WriteInteger(Section,'NetNumber',NetNumber);
  Cfg.WriteBool( Section, 'On', isSensorOn);
  Cfg.WriteFloat(Section, 'R' , CoeffR );
  Cfg.WriteFloat(Section, 'Ia', CoeffIa);
  Cfg.WriteFloat(Section, 'Xa', CoeffXa);
  Cfg.WriteFloat(Section, 'Ib', CoeffIb);
  Cfg.WriteFloat(Section, 'Xb', CoeffXb);
  Cfg.WriteFloat(Section,'Xmin',CoeffXmin);
end;

procedure TItemAnalog.RefreshFrame;
begin
  if LCntX>0 then
  begin
    FA.stStatus.Caption:=Format('%3d | %7.3f ',[LCntX,X]);
    if FreshDataTimer>0
    then FA.stStatus.Font.Color:=clLime
    else FA.stStatus.Font.Color:=clGreen;
  end
  else if (LCntE>0) and (EMsg<>'') then
  begin
    FA.stStatus.Caption:=Format('%3d:'+EMsg,[LCntE]);
    if FreshDataTimer>0
    then FA.stStatus.Font.Color:=clRed
    else FA.stStatus.Font.Color:=clMaroon;
  end;
  FA.cbOn.Checked:=isSensorOn;
end;

procedure TItemAnalog.CalcKB;
var
  Ua,Ub:Double;
begin
  Ua:=CoeffIa*CoeffR;
  Ub:=CoeffIb*CoeffR;
  try
    CoeffK := (CoeffXb - CoeffXa) / (Ub - Ua);
    CoeffB := -CoeffK * Ua + CoeffXa;
  except
    CoeffK := 0;
    CoeffB := 0;
  end;
end;

procedure TItemAnalog.GetX(const SrcData; var X: Single);
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
  FreshDataTimer:=1;
  Tmp:=0;
  move(SrcData,Tmp,2);
  if Tmp and fErrorFlag<>0 then begin // признак сбоя
    Inc(CntE);
    if EMsg='' then EMsg:=' __ __ __ ';
    if Tmp and (fErrorComm or fErrorInvData or fErrorInvResp)<>0 then
    begin
      SetErrADCComm(AD);
      EMsg[1]:='C'; EMsg[2]:='o'; EMsg[3]:='m';
    end
    else if Tmp and fErrorADCRange<>0
    then begin
      SetErrADCRange(AD);
      EMsg[5]:='R'; EMsg[6]:='n'; EMsg[7]:='g';
    end
    else begin
      SetErrUnknown(AD);
      EMsg[9]:='E'; EMsg[10]:='r'; EMsg[11]:='r';
    end;
    if not isSensorOn then SetSensorRepair(AD);
  end
  else begin
    EMsg:='';
    AD.Value:=Tmp*Prescale*CoeffK+CoeffB;
    Inc(CntX); SumX:=SumX+AD.Value;
    if AD.Value < CoeffXmin then SetErrAnalog(AD);
  end;
  X:=AD.Value;
end;

procedure TFrameAnalog.cbOnClick(Sender: TObject);
begin
  Analog.isSensorOn:=cbOn.Checked;
end;

end.

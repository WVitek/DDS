unit UFrameKP;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons, UTreeItem, IniFiles, UFrameMain;

type
  TItemKP = class;

  TFrameKP = class(TFrame)
    GroupBox1: TGroupBox;
    Panel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    GroupBox2: TGroupBox;
    edName: TEdit;
    edAddress: TEdit;
    edPhoneNum: TEdit;
    edInterval: TEdit;
    cbDialRequest: TCheckBox;
    BtnKvit: TButton;
    BtnChange: TButton;
    Memo: TMemo;
    Label5: TLabel;
    stLastConnect: TStaticText;
    procedure BtnChangeClick(Sender: TObject);
    procedure cbDialRequestClick(Sender: TObject);
    procedure BtnKvitClick(Sender: TObject);
  private
    { Private declarations }
    KP:TItemKP;
  public
    { Public declarations }
  end;

  TItemKP = class(TTreeItem)
  private
    function GetAutoDialRequest: Boolean;
    procedure SetManualDialRequest(const Value: Boolean);
    procedure SetLastDataTime(const Value: TDateTime);
    function GetManualDialRequest: Boolean;
    function GetPeriod: TDateTime;
    function DataLagBigger(Secs:Cardinal):Boolean;
    function GetNeedConnection: Boolean;
  protected
    Main:TItemMain;
    FKP:TFrameKP;
    // Persistent variables
    FName:String;
    FAddress:Byte;
    FDialInterval:Integer;
    FPhone:String;
    FLastDataTime:TDateTime;
    Port:Integer;
    Analogs:TList;
    //
    FManualDialRequest:Boolean;
    FEvents:String;
    DialPause:Integer;
    AlarmTimer:Integer;
    procedure RefreshFrame;
  public
    function Enter:TFrame;override;
    function Leave:Boolean;override;
    function Validate:Boolean;override;
    constructor Load(Main:TItemMain; Ini,Cfg:TIniFile; const Section:String);
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
    destructor Destroy;override;
    procedure PauseDial;
    procedure AddEvent(Time:TDateTime; Event:String);
    procedure handleADCService(const DataI:String);
  public
    Alarm:Boolean;
    property ManualDialRequest:Boolean read GetManualDialRequest write SetManualDialRequest;
    property AutoDialRequest:Boolean read GetAutoDialRequest;
    property LastDataTime:TDateTime read FLastDataTime write SetLastDataTime;
    property Phone:String read FPhone;
    property Name:String read FName;
    property Address:Byte read FAddress;
    property Period:TDateTime read GetPeriod;
    property NeedConnection:Boolean read GetNeedConnection;
  end;

const
  ADCSampleSize=2;

implementation

uses UFormMain, UFrameAnalog, Misc, DataTypes, UServices, UTime;

{$R *.DFM}

procedure TFrameKP.BtnChangeClick(Sender: TObject);
begin
  KP.ChangeData(BtnChange,Panel);
end;

{ TItemKP }

function TItemKP.Enter: TFrame;
begin
  FKP:=TFrameKP.Create(FormMain);
  FKP.KP:=Self;
  FKP.Name:='';
  FKP.edName.Text:=Name;
  FKP.edAddress.Text:=IntToStr(Address);
  FKP.edPhoneNum.Text:=Phone;
  FKP.edInterval.Text:=IntToStr(FDialInterval);
  FKP.cbDialRequest.Checked:=FManualDialRequest;
  RefreshFrame;
  FKP.Memo.Text:=FEvents;
  Result:=FKP;
end;

function TItemKP.Leave: Boolean;
begin
  FKP.Free; FKP:=nil;
  Result:=True;
end;

constructor TItemKP.Load(Main:TItemMain; Ini,Cfg: TIniFile; const Section: String);
var
  i,Cnt:Integer;
  S:String;
begin
  inherited;
  Self.Main:=Main;
  Self.Section:=Section;
  Node:=FormMain.TreeView.Items.AddChildObject(Main.Node,Section,Self);
  FName:=Ini.ReadString(Section,'Name',Section);
  FAddress:=Ini.ReadInteger(Section,'Address',0);
  FPhone:=Ini.ReadString(Section,'Phone','');
  Port:=Ini.ReadInteger(Section,'Port',22000+Address);
  FDialInterval:=Cfg.ReadInteger(Section,'DialInterval',240);
  LastDataTime:=Cfg.ReadDateTime(Section,'LastDataTime',0);
  Cnt:=Ini.ReadInteger(Section,'ADCCount',0);
  Analogs:=TList.Create;
  for i:=1 to Cnt do begin
    S:=Ini.ReadString(Section,Format('ADC%.2d',[i]),'');
    if S<>''
    then Analogs.Add(TItemAnalog.Load(Self,Ini,Cfg,S));
  end;
end;

procedure TItemKP.TimerProc;
var
  i:Integer;
begin
  if DialPause>0 then Dec(DialPause);
  for i:=0 to Analogs.Count-1 do TItemAnalog(Analogs[i]).TimerProc;
  if Alarm then begin
    if AlarmTimer=0 then begin
      FormMain.Visible:=True;
      SetForegroundWindow(FormMain.Handle);
      FormMain.TreeView.Selected:=Node;
      if FKP<>nil then FKP.BtnKvit.SetFocus;
      MessageBeep(MB_OK);
      AlarmTimer:=5;
    end
    else Dec(AlarmTimer);
  end;
end;

function TItemKP.Validate: Boolean;
var
  Name_,Phone_:String;
  Addr,Interv:Double;
begin
  try
    Name_:=FKP.edName.Text;
    CheckMinMax(Addr,0,255,FKP.edAddress);
    Phone_:=FKP.edPhoneNum.Text;
    CheckMinMax(Interv,0,240,FKP.edInterval);
    FName:=Name_;
    FAddress:=Trunc(Addr);
    FPhone:=Phone_;
    FDialInterval:=Trunc(Interv);
    Result:=True;
  except
    Result:=False;
  end;
end;

procedure TItemKP.SaveCfg(Cfg: TIniFile);
var
  i:Integer;
begin
//  Ini.WriteString(Section,'Name',Name);
//  Ini.WriteInteger(Section,'Address',FAddress);
//  Ini.WriteString(Section,'Phone',FPhone);
  Cfg.WriteInteger(Section,'DialInterval',FDialInterval);
  Cfg.WriteDateTime(Section,'LastDataTime',LastDataTime);
  for i:=0 to Analogs.Count-1
  do TItemAnalog(Analogs[i]).SaveCfg(Cfg);
end;

destructor TItemKP.Destroy;
var
  i:Integer;
begin
  for i:=0 to Analogs.Count-1 do TItemAnalog(Analogs[i]).Free;
  Analogs.Free;
  inherited;
end;

function TItemKP.GetAutoDialRequest: Boolean;
begin
  Result:=(FDialInterval>0) and (DialPause=0) and DataLagBigger(FDialInterval*60);
end;

procedure TItemKP.SetManualDialRequest(const Value: Boolean);
begin
  if FManualDialRequest=Value then exit;
  FManualDialRequest := Value;
  DialPause:=0;
  if FKP<>nil then FKP.cbDialRequest.Checked:=Value;
end;

procedure TFrameKP.cbDialRequestClick(Sender: TObject);
begin
  KP.ManualDialRequest:=cbDialRequest.Checked;
end;

procedure TItemKP.SetLastDataTime(const Value: TDateTime);
begin
  FLastDataTime := Value;
  if FKP<>nil then RefreshFrame;
end;

procedure TItemKP.RefreshFrame;
begin
  FKP.stLastConnect.Caption:=DateTimeToStr(LastDataTime);
end;

procedure TItemKP.AddEvent(Time:TDateTime; Event: String);
begin
  Event:=LogMsg(Time,Event);
  if FKP<>nil then begin
    FKP.Memo.SelStart:=0;
    FKP.Memo.SelText:=Event;
  end;
  FEvents:=Event+FEvents;
  WriteToLog(Event);
end;

procedure TFrameKP.BtnKvitClick(Sender: TObject);
begin
  KP.Alarm:=False;
  KP.AddEvent(GetMyTime,'***** ÊÂÈÒÈÐÎÂÀÍÎ');
end;

procedure TItemKP.PauseDial;
begin
  DialPause:=Main.RedialInterval;
end;

function TItemKP.GetManualDialRequest: Boolean;
begin
  Result:=FManualDialRequest and (DialPause=0);
end;

procedure TItemKP.handleADCService(const DataI: String);
var
  ID:^TADCServiceInData;
  IA:TItemAnalog;
  Cnt,k:Integer;
  Time,MaxTime:TDateTime;
  ST:TSystemTime;
  CharBuf:array[0..15] of Char;
  Buf:TSclRec absolute CharBuf;
begin
  ID:=@(DataI[1]);
  if ID.SensNum>=Analogs.Count then exit;
  IA:=TItemAnalog(Analogs[ID.SensNum]);
  Buf.Number:=IA.NetNumber;
  Cnt:=(Length(DataI)-SizeOf(ID.SensNum)-SizeOf(ID.Time)) div ADCSampleSize;
  MaxTime:=GetMyTime;
  // Update LastDataTime
  Time:=ID.Time*dtLLTickPeriod+(Cnt-1)*Period;
  if Time>MaxTime then Time:=MaxTime;
  if LastDataTime<Time then LastDataTime:=Time;
  // Send data cycle
  FormMain.NMUDP.RemotePort:=Port;
  for k:=0 to Cnt-1 do begin
    Time:=ID.Time*dtLLTickPeriod+k*Period;
    if Time>MaxTime then break;
    DateTimeToSystemTime(Time,ST);
    with Buf.Time do begin
      Year:=ST.wYear-1900;
      Month:=ST.wMonth;
      Day:=ST.wDay;
      Hour:=ST.wHour;
      Min:=ST.wMinute;
      Sec:=ST.wSecond;
      Sec100:=Trunc(ST.wMilliseconds*0.1);
    end;
    IA.GetP(ID.Data[k],Buf.P);
    // Îòñûëêà
    FormMain.NMUDP.SendBuffer(CharBuf,SizeOf(CharBuf));
  end;
end;

function TItemKP.GetPeriod: TDateTime;
begin
  Result:=Main.Period;
end;

function TItemKP.DataLagBigger(Secs: Cardinal): Boolean;
const
  SecToTimeCoeff = 1/(24*60*60);
begin
  Result := LastDataTime+Secs*SecToTimeCoeff < GetMyTime;
end;

function TItemKP.GetNeedConnection: Boolean;
begin
  Result := DataLagBigger(10);
end;

end.

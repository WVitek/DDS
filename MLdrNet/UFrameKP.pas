unit UFrameKP;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls, Buttons, IniFiles, Contnrs, UTreeItem;

type
  TItemKP = class;

  TFrameKP = class(TFrame)
    gbKP: TGroupBox;
    Panel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    gbEvents: TGroupBox;
    edName: TEdit;
    edAddress: TEdit;
    BtnChange: TButton;
    Memo: TMemo;
    Label5: TLabel;
    stLastConnect: TStaticText;
    BtnKvit: TButton;
    memoComm: TMemo;
    lblCommMsg: TLabel;
    Label4: TLabel;
    edDataLag: TEdit;
    OpenDialog: TOpenDialog;
    procedure BtnChangeClick(Sender: TObject);
    procedure BtnKvitClick(Sender: TObject);
  private
    { Private declarations }
    KP:TItemKP;
  public
    { Public declarations }
  end;

  TItemKP = class(TTreeItem)
  private
    procedure SetLastDataTime(const Value: TDateTime);
  protected
    FKP:TFrameKP;
    // Persistent variables
    FName:String;
    FAddress:Byte;
    FPeriod:TDateTime;
    FDataLag:Integer;
    FLastDataTime,FLastEvntTime:TDateTime;
    Port:Integer;
    Analogs:TList;
    Services:TObjectList;
    SvcReprog:Pointer;
    //
    FEvents:String;
    FCommMsgs:TStringList;
    AlarmTimer:Integer;
    procedure RefreshFrame;
  public
    function Enter(Owner:TComponent):TFrame;override;
    function Leave:Boolean;override;
    function Validate:Boolean;override;
    constructor Load(Nodes:TTreeNodes; ParentNode:TTreeNode; Ini,Cfg:TIniFile; const Section:String);
    destructor Destroy;override;
    procedure SaveCfg(Cfg:TIniFile);override;
    procedure TimerProc;override;
    procedure AddEvent(Time:TDateTime; Event:String);
    procedure CommMsg(Msg:String; DataSize:Integer);
    function handleADCService(const Data:String):Integer;
    procedure SwitchProgramming;
    procedure SendSoftReset;
  public
    Alarm:Boolean;
    property LastDataTime:TDateTime read FLastDataTime write SetLastDataTime;
    property LastEvntTime:TDateTime read FLastEvntTime write FLastEvntTime;
    property Name:String read FName;
    property Address:Byte read FAddress;
    property Period:TDateTime read FPeriod;
    property DataLag:Integer read FDataLag;
  end;

const
  ADCSampleSize=2;

implementation

uses
  UFormMain, UFrameAnalog, Misc, DataTypes, UNetW,
  UServices, UTime, UPRT_Liner;

{$R *.DFM}

procedure TFrameKP.BtnChangeClick(Sender: TObject);
begin
  KP.ChangeData(BtnChange,Panel);
end;

{ TItemKP }

function TItemKP.Enter(Owner:TComponent): TFrame;
begin
  FKP:=TFrameKP.Create(Owner);
  FKP.KP:=Self;
  FKP.Name:='';
  FKP.edName.Text:=Name;
  FKP.edAddress.Text:=IntToStr(Address);
  FKP.edDataLag.Text:=IntToStr(DataLag);
  RefreshFrame;
  FKP.Memo.Text:=FEvents;
  FKP.memoComm.Text:=FCommMsgs.Text;
  Result:=FKP;
end;

function TItemKP.Leave: Boolean;
begin
  FKP.Free; FKP:=nil;
  Result:=True;
end;

constructor TItemKP.Load(Nodes:TTreeNodes; ParentNode:TTreeNode; Ini,Cfg: TIniFile; const Section: String);
var
  i,Cnt:Integer;
  S:String;
begin
  Self.Section:=Section;
  Node:=Nodes.AddChildObject(ParentNode,Section,Self);
  FName:=Ini.ReadString(Section,'Name',Section);
  FAddress:=Ini.ReadInteger(Section,'Address',0);
  FPeriod:=1/Ini.ReadInteger(Section,'RecsPerDay',nSecsPerDay);
  Port:=Ini.ReadInteger(Section,'Port',22000+Address);
  FLastDataTime:=Cfg.ReadDateTime(Section,'LastDataTime',0);
  FLastEvntTime:=Cfg.ReadDateTime(Section,'LastEvntTime',0);
  FDataLag:=Cfg.ReadInteger(Section,'DataLag',30);
  FCommMsgs:=TStringList.Create;
  Cnt:=Ini.ReadInteger(Section,'ADCCount',0);
  Analogs:=TList.Create;
  for i:=1 to Cnt do begin
    S:=Ini.ReadString(Section,Format('ADC%.2d',[i]),'');
    if S<>''
    then Analogs.Add(TItemAnalog.Load(Nodes,Node,Ini,Cfg,S));
  end;
  Services:=TObjectList.Create;
  Services.Add(TServicePing.Create(Self));
  Services.Add(TServiceTimeServer.Create(Self));
  Services.Add(TServiceAlarm.Create(Self,Ini));
  Services.Add(TServiceADC.Create(Self));
  SvcReprog:=TServiceReprog.Create(Self);
  Services.Add(SvcReprog);
  // register services
  for i:=0 to Services.Count-1
  do NetW_addService(FAddress,TService(Services[i]));
end;

procedure TItemKP.TimerProc;
begin
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
  Name_:String;
  Interv:Double;
begin
  try
    Name_:=FKP.edName.Text;
//    CheckMinMax(Addr,0,255,FKP.edAddress);
    CheckMinMax(Interv,1,60,FKP.edDataLag);
    FName:=Name_;
//    FAddress:=Trunc(Addr);
    FDataLag:=Trunc(Interv);
    Result:=True;
  except
    Result:=False;
  end;
end;

procedure TItemKP.SaveCfg(Cfg: TIniFile);
var
  dtET:TDateTime;
begin
  if LastDataTime>LastEvntTime
  then dtET:=LastEvntTime+dtOneSecond*0.999
  else dtET:=LastEvntTime;
  Cfg.WriteDateTime(Section,'LastDataTime',LastDataTime);
  Cfg.WriteDateTime(Section,'LastEvntTime',dtET);
  Cfg.WriteInteger(Section,'DataLag',FDataLag);
end;

destructor TItemKP.Destroy;
var
  i:Integer;
begin
  for i:=0 to Services.Count-1
  do NetW_remService(FAddress,TService(Services[i])); // net svc
  Services.Free;
//  for i:=0 to Analogs.Count-1 do TItemAnalog(Analogs[i]).Free;
  Analogs.Free;
  FCommMsgs.Free;
  inherited;
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
var
  Msg:String;
  CharBuf:array[0..255] of Char;
  n:Integer;
begin
  Msg:=LogMsg(Time,Event);
  if FKP<>nil then begin
    FKP.Memo.SelStart:=0;
    FKP.Memo.SelText:=Msg;
  end;
  FEvents:=Msg+FEvents;
  WriteToLog(Msg);
  // Отсылка
  FormMain.NMUDP.RemoteHost:='127.0.0.1';
  FormMain.NMUDP.RemotePort:=Port;
  Msg:=#255+LogMsg(Time, Misc.GetUserName+#9+Name+#9+Event+#9);
  n:=Length(Msg);
  if n>256 then n:=256;
  Move(Msg[1],CharBuf[0],n);
  // "time \t user \t addr \t id \t info \r\n"
  FormMain.NMUDP.SendBuffer(CharBuf,n);
end;

procedure TFrameKP.BtnKvitClick(Sender: TObject);
begin
  KP.Alarm:=False;
  KP.AddEvent(GetMyTime,'***** КВИТИРОВАНО');
end;

{$DEFINE UseTSclRecN}
function TItemKP.handleADCService(const Data: String):Integer;
var
  ID:^TADCServiceInData;
  QntSamples,n,i,j:Integer;
  MaxQntSamples:Integer;
  BegDataTime,EndDataTime,CurTime:TDateTime;
  // sending
  IA:TItemAnalog;
  ST:TSystemTime;
{$IFDEF UseTSclRecN}
  CharBuf:array[0..SizeOf(TSclRecN)-1] of Char;
  Buf:TSclRecN absolute CharBuf;
  SizeToSend:Integer;
{$ELSE}
  CharBuf:array[0..SizeOf(TSclRec)-1] of Char;
  Buf:TSclRec absolute CharBuf;
{$ENDIF}
begin
  if Data<>'' then
  begin
    ID:=@(Data[1]);
    if ID.SensQnt>0
    then begin
        // 5 = ToAddr + FromAdd + SvcID + 2 bytes of CRC
        MaxQntSamples:=(LINER_TXBSIZE-5-SizeOf(TIME_STAMP)) div (ID.SensQnt*ADCSampleSize);
        QntSamples:=(Length(Data)-1-SizeOf(TIME_STAMP)) div (ID.SensQnt*ADCSampleSize);
{$IFDEF UseTSclRecN}
        if QntSamples>High(Buf.P)+1
        then QntSamples:=High(Buf.P)+1;
{$ENDIF}
    end
    else QntSamples:=0;
    BegDataTime:=ToDateTime(ID.Time);
    EndDataTime:=BegDataTime+QntSamples*Period;
    // Result = we need to receive
    CurTime := GetMyTime;
    if (LastDataTime<>0) and (LastDataTime+Period*1.5 < BegDataTime)
    then AddEvent(CurTime,Format('Данные с %s по %s утеряны(?)',[DateTimeToStr(LastDataTime+Period),DateTimeToStr(BegDataTime)]));
    if (QntSamples = 0) or (CurTime <= EndDataTime)
    then Result:=DataLag
    else begin
      Result := Round((CurTime - EndDataTime) * nSecsPerDay);
      if Result < DataLag
      then Result:=DataLag-Result
      else if QntSamples<MaxQntSamples
      then Result:=((MaxQntSamples - QntSamples)*DataLag + MaxQntSamples-1) div MaxQntSamples
      else Result:=0;
    end;
    CommMsg(
      Format('Data: %s.%.3d %d*%d',[
        DateTimeToStr(BegDataTime),
        ID.Time mod 1000, ID.SensQnt, QntSamples ]
      ), Length(Data)
    );
    LastDataTime:=EndDataTime;
    // Send data cycle
    n:=Analogs.Count;
    if n>ID.SensQnt then n:=ID.SensQnt;
    FormMain.NMUDP.RemoteHost:='127.0.0.1';
    FormMain.NMUDP.RemotePort:=Port;
{$IFDEF UseTSclRecN}
    DateTimeToSystemTime(BegDataTime,ST);
    with Buf.Time do begin
      Year:=ST.wYear-1900;
      Month:=ST.wMonth;
      Day:=ST.wDay;
      Hour:=ST.wHour;
      Min:=ST.wMinute;
      Sec:=ST.wSecond;
      Sec100:=Trunc(ST.wMilliseconds*0.1);
    end;
    SizeToSend:=SizeOf(TSclRec)+(QntSamples-1)*SizeOf(Single);
    for i:=0 to n-1 do
    begin
      IA:=TItemAnalog(Analogs[i]);
      Buf.Number:=IA.NetNumber;
      for j:=0 to QntSamples-1 do
        IA.GetX(ID.Data[i*QntSamples+j],Buf.P[j]);
      // Отсылка
      FormMain.NMUDP.SendBuffer(CharBuf,SizeToSend);
    end;
{$ELSE}
    for j:=0 to QntSamples-1 do
    begin
      DateTimeToSystemTime(BegDataTime+j*Period,ST);
      with Buf.Time do begin
        Year:=ST.wYear-1900;
        Month:=ST.wMonth;
        Day:=ST.wDay;
        Hour:=ST.wHour;
        Min:=ST.wMinute;
        Sec:=ST.wSecond;
        Sec100:=Trunc(ST.wMilliseconds*0.1);
      end;
      for i:=0 to n-1 do
      begin
        IA:=TItemAnalog(Analogs[i]);
        Buf.Number:=IA.NetNumber;
        IA.GetX(ID.Data[i*QntSamples+j],Buf.P);
        // Отсылка
        FormMain.NMUDP.SendBuffer(CharBuf,SizeOf(CharBuf));
      end;
    end;
{$ENDIF}
  end
  else
  begin
    CommMsg('Data: [empty answer = not ready]',Length(Data));
    Result:=DataLag;
  end;
end;

procedure TItemKP.CommMsg(Msg: String; DataSize:Integer);
var
  fmt: String;
begin
  if DataSize<>0 then
  begin
    if DataSize>0
    then fmt := '%s %d:> %s'
    else fmt := '%s %d:< %s';
    DataSize := Abs(DataSize);
  end
  else
    fmt := '%s %2:s';
  Msg:=Format(fmt,[TimeToStr(GetMyTime),DataSize+3, Msg]);
  FCommMsgs.Insert(0,Msg);
  if FCommMsgs.Count=128 then FCommMsgs.Delete(127);
  if FKP<>nil then FKP.memoComm.Text:=FCommMsgs.Text;
end;

procedure TItemKP.SwitchProgramming;
var
  SR:TServiceReprog;
begin
  SR:=SvcReprog;
  if SR.State = sNone
  then begin
    if (FKP<>nil) and FKP.OpenDialog.Execute
    then SR.startProgramming(FKP.OpenDialog.FileName);
  end
  else SR.stopProgramming;
end;

procedure TItemKP.SendSoftReset;
begin
  TServiceReprog(SvcReprog).SendSoftReset;
end;

end.

unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Sequences, Works, StdCtrls, ArchManThd, IniFiles;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    stTime: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    S1,S2:TSequence;
    Thd1,Thd2:TFinder;
    AM:TArchManThread;
    Stop,InProcess:Boolean;
    Time,StopTime:TDateTime;
    Calc1Time,Calc2Time:TDateTime;
    Ini:TIniFile;
    MaxDT,BlockLen:Integer;
    WriteTracks:Boolean;
    ShowMinDT,ShowMaxDT:Integer;
    ShowWToAvgRatio:Double;
  end;

const
  Section='Config';
  dtOneSecond=1/(24*60*60);

var
  Form1: TForm1;

implementation

uses
  Misc, DataTypes, SensorTypes;

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
var
  Alpha1,Alpha2,Damping,Smoothing:Double;
begin
  InitFormattingVariables;
  Ini:=TIniFile.Create(GetModuleFullName+'.ini');
  MaxDT:=Ini.ReadInteger(Section,'MaxDT',100);
  BlockLen:=Ini.ReadInteger(Section,'BlockLen',15);
  Alpha1:=Ini.ReadFloat(Section,'Alpha1',0.7);
  Alpha2:=Ini.ReadFloat(Section,'Alpha2',0.98);
  Damping:=Ini.ReadFloat(Section,'Damping',0.15);
  Smoothing:=Ini.ReadFloat(Section,'Smoothing',0.95);
//  S1:=TDiffSequence.Create(MaxDT+BlockLen,Alpha1,Alpha2);
//  S2:=TDiffSequence.Create(MaxDT+BlockLen,Alpha1,Alpha2);
  S1:=TDispSequence.Create(MaxDT+BlockLen,15);
  S2:=TDispSequence.Create(MaxDT+BlockLen,15);
  AM:=TArchManThread.Create;
  // 1
  Thd1:=TFinder.Create;
  Thd1.S1:=S1;
  Thd1.S2:=S2;
  Thd1.BlockLen:=BlockLen;
  Thd1.Damping:=Damping; Thd1.Smoothing:=Smoothing;
  // 2
  Thd2:=TFinder.Create;
  Thd2.S1:=S2;
  Thd2.S2:=S1;
  Thd2.BlockLen:=BlockLen;
  Thd2.Damping:=Damping; Thd2.Smoothing:=Smoothing;
  //
  Time:=Ini.ReadDateTime(Section,'StartTime',0);
  StopTime:=Ini.ReadDateTime(Section,'StopTime',0);
  Calc1Time:=Ini.ReadDateTime(Section,'Calc1Time',0)+(MaxDT+BlockLen)*dtOneSecond;
  Calc2Time:=Ini.ReadDateTime(Section,'Calc2Time',0)+(MaxDT+BlockLen)*dtOneSecond;
  WriteTracks:=Ini.ReadBool(Section,'WriteTracks',False);
  ShowMinDT:=Ini.ReadInteger(Section,'ShowMinDT',0);
  ShowMaxDT:=Ini.ReadInteger(Section,'ShowMaxDT',MaxDT);
  ShowWToAvgRatio:=Ini.ReadFloat(Section,'ShowWToAvgRatio',0.5);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Thd2.Free;
  Thd1.Free;
  AM.Free;
  S2.Free;
  S1.Free;
end;

procedure TForm1.Button1Click(Sender: TObject);
type
  TWorkState=record
    Old_iMax:Integer;
    OldMaxWeight:Double;
  end;

var
  i,SecCnt:Integer;
  InID1,InID2:Integer;
  OutID1,OutID2:Integer;
  InData1,InData2:WideString;
  OutData1,OutData2:WideString;
  AD:TAnalogData;
  Value1,Value2:Single;
  WS1,WS2:TWorkState;
  StartTime:TDateTime;

  procedure ShowWorkState(Memo:TMemo; var WS:TWorkState; Thd:TFinder);
  var
    StartT:TDateTime;
  begin
    if (ShowMinDT<=Thd.iFound) and (Thd.iFound<=ShowMaxDT)
      and (Thd.wFound<Thd.wAvg*ShowWToAvgRatio)
{      and
      (
        (Abs(WS.Old_iMax-Thd.iFound)>1) or
        (Thd.wFound<WS.OldMaxWeight)
      )//}
    then begin
      WS.Old_iMax:=Thd.iFound;
      WS.OldMaxWeight:=Thd.wFound;
      StartT:=Frac(Time)-Thd.S1.ItemsLength*dtOneSecond;
      Memo.SelText:=
        'T='+TimeToStr(StartT)+
        '; T2='+TimeToStr(StartT+Thd.iFound*dtOneSecond)+
        '; DT='+IntToStr(Thd.iFound)+
        '; w/wA='+Format('%g',[Thd.wFound/Thd.wAvg])+#13#10;
    end;
  end;

begin
  if (Time>=StopTime) or InProcess then begin
    Stop:=True;
    exit;
  end;
  Button1.Caption:='Stop';
  Stop:=False; InProcess:=True;
  AM.Resume;
  AM.StrToTrackID(Ini.ReadString(Section, 'InTrk1','ZZZ'), InID1);
  AM.setTrackInfo( InID1,3,24*60*60);
  AM.StrToTrackID(Ini.ReadString(Section, 'InTrk2','ZZZ'), InID2);
  AM.setTrackInfo( InID2,3,24*60*60);
  AM.StrToTrackID(Ini.ReadString(Section,'OutTrk1','ZZZ'),OutID1);
  AM.setTrackInfo(OutID1,3,24*60*60);
  AM.StrToTrackID(Ini.ReadString(Section,'OutTrk2','ZZZ'),OutID2);
  AM.setTrackInfo(OutID2,3,24*60*60);
  Value1:=0;
  Value2:=0;
  StartTime:=Time;
  SecCnt:=Round((StopTime-StartTime)/dtOneSecond);
  AM.readRecords(InID1,StartTime,SecCnt,InData1);
  SetLength(OutData1,Length(InData1));
  AM.readRecords(InID2,StartTime,SecCnt,InData2);
  SetLength(OutData2,Length(InData2));
  AM.Suspend;
  i:=0;
  FillChar(WS1,SizeOf(WS1),0);
  FillChar(WS2,SizeOf(WS2),0);
  while (i<SecCnt) and not Stop do begin
    // 1
    TMySensor.GetAD(InData1,i,AD);
    if ValidAD(AD) then Value1:=AD.Value;
    S1.Add(Value1);
    AD.Value:=S1.LastValue; if AD.Flags=0 then AD.Value:=SignedZero;
    TMySensor.SetAD(OutData1,i,AD);
    // 2
    TMySensor.GetAD(InData2,i,AD);
    if ValidAD(AD) then Value2:=AD.Value;
    S2.Add(Value2);
    AD.Value:=S2.LastValue; if AD.Flags=0 then AD.Value:=SignedZero;
    TMySensor.SetAD(OutData2,i,AD);
    if (Time<=Calc1Time) and (Calc1Time<=Time+dtOneSecond)
    then Thd1.CalcParams(Ini.ReadInteger(Section,'Calc1DT',MaxDT));
    if (Time<=Calc2Time) and (Calc2Time<=Time+dtOneSecond)
    then Thd2.CalcParams(Ini.ReadInteger(Section,'Calc2DT',MaxDT));
    // find
    if Thd1.Work2(MaxDT) then ShowWorkState(Memo1,WS1,Thd1);
    if Thd2.Work2(MaxDT) then ShowWorkState(Memo2,WS2,Thd2);
    // next
    Inc(i);
    if (i and $7F=$7F) or (i=SecCnt) then begin
      Application.ProcessMessages;
      if (i and $FF=$FF) or (i=SecCnt)
      then stTime.Caption:=TimeToStr(Frac(Time));
    end;
    Time:=Time+dtOneSecond;
  end;
  if WriteTracks then begin
    i:=Round((Time-StartTime)/dtOneSecond);
    AM.Resume;
    AM.writeRecords(OutID1,StartTime,i,OutData1);
    AM.writeRecords(OutID2,StartTime,i,OutData2);
    AM.Suspend;
  end;
  InProcess:=False;
  if Time>=StopTime then Button1.Visible:=False
  else Button1.Caption:='Start';
end;

end.

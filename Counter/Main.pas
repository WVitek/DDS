unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ArchManThd, SensorTypes;

type
  TFormMain = class(TForm)
    dtpBegin: TDateTimePicker;
    dtpEnd: TDateTimePicker;
    memoList: TMemo;
    Button: TButton;
    stStatus: TStaticText;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Work;
  end;

var
  FormMain: TFormMain;

const
  RecsPerDay = 86400;
  
implementation

{$R *.DFM}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  InitFormattingVariables;
  try
    MemoList.Lines.LoadFromFile('SensList.txt');
  except
  end;
(*
  for i:=0 to Sensors.Count-1 do begin
    AMThd.StrToTrackID(Ini.ReadString(Section,'Sensor'+IntToStr(i+1),'ZZZ'),ID);
    Sensors[i]:=Pointer(ID);
    AMThd.setTrackInfo(ID,TMySensor.GetRecSize,RecsPerDay);
  end;
  Ini.Free;
*)
end;

procedure TFormMain.Work;
const
  RepNoDName='Простои ''Нет данных''.txt';
  RepErrName='Простои ''Сбой''.txt';
type
  TSensData = record
    ID:Integer;
    CntNoData:Integer;
    CntError:Integer;
  end;
var
  BeginDate,EndDate,Date:TDateTime;
  Sens:array of TSensData;
  AM:TArchManThread;
  i,j:Integer;
  W:WideString;
  AD:TAnalogData;
  RepNoD,RepErr:TextFile;
  S:String;
begin
  SetLength(Sens,memoList.Lines.Count);
  FillChar(Sens[0],Length(Sens)*SizeOf(TSensData),0);
  AM:=TArchManThread.Create;
  AM.Resume;
  AssignFile(RepNoD,RepNoDName);
  AssignFile(RepErr,RepErrName);
  if FileExists(RepNoDName) then begin
    Append(RepNoD);
    Append(RepErr);
  end
  else begin
    Rewrite(RepNoD);
    Rewrite(RepErr);
    for i:=0 to memoList.Lines.Count-1 do begin
      S:=#9+memoList.Lines[i];
      Write(RepNoD,S);
      Write(RepErr,S);
    end;
    WriteLn(RepNoD);
    WriteLn(RepErr);
  end;
  for j:=0 to Length(Sens)-1 do begin
    AM.StrToTrackID(Copy(memoList.Lines[j],1,3),Sens[j].ID);
    AM.setTrackInfo(Sens[j].ID,TMySensor.GetRecSize,RecsPerDay);
  end;
  BeginDate:=dtpBegin.Date;
  EndDate:=dtpEnd.Date;
  Date:=BeginDate;
  i:=Length(Sens);
  repeat
    Dec(i);
    AM.readRecords(Sens[i].ID,Date,RecsPerDay,W);
    for j:=0 to RecsPerDay-1 do begin
      TMySensor.GetAD(W,j,AD);
      if AD.Flags=0 then Inc(Sens[i].CntNoData)
      else if AD.Flags and smExpMask=smSNaN then Inc(Sens[i].CntError);
    end;
    if i=0 then begin
      S:=FormatDateTime('dd/mm/yyyy',Date);
      stStatus.Caption:=S;
      i:=Length(Sens);
      Write(RepNoD,S);
      Write(RepErr,S);
      for j:=0 to Length(Sens)-1 do begin
        Write(RepNoD,#9+IntToStr(Sens[j].CntNoData));
        Write(RepErr,#9+IntToStr(Sens[j].CntError));
        Sens[j].CntNoData:=0;
        Sens[j].CntError:=0;
      end;
      WriteLn(RepNoD);
      WriteLn(RepErr);
      Date:=Date+1;
    end;
    Application.ProcessMessages;
  until (Date>EndDate) or (Button.Tag=0);
  CloseFile(RepNoD);
  CloseFile(RepErr);
  AM.Free;
  if Button.Tag<>0 then ButtonClick(Self);
end;

procedure TFormMain.ButtonClick(Sender: TObject);
begin
  if Button.Tag=0 then begin
    Button.Tag:=1;
    Button.Caption:='Стоп';
    memoList.Enabled:=False;
    Work;
  end
  else begin
    Button.Tag:=0;
    Button.Caption:='Старт';
    memoList.Enabled:=True;
  end;
end;

end.

unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  NMUDP, ExtCtrls, IniFiles, StdCtrls, Misc, DataTypes;

type
  TForm1 = class(TForm)
    NMUDP1: TNMUDP;
      Timer: TTimer;
    StTxtP1: TStaticText;
    StTxtP2: TStaticText;
    CheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
    procedure AppOnIdle(Sender: TObject; var Done: Boolean);
  public
    { Public declarations }
    PipFile:File of TPipFileRec;
    PipTime:TPipTime;
    TimerTicked:Boolean;
    procedure SendNextRec;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

var
  PFSecond:TPipTime;

procedure TForm1.FormCreate(Sender: TObject);
const
  Cfg='Config';
var
  Ini:TIniFile;
  FName:String;
  Time:TSystemTime;
begin
  Ini:=TIniFile.Create(GetModuleFullName+'.ini');
  try
    try
      NMUDP1.RemoteHost:=Ini.ReadString(Cfg,'RemoteHost','');
      NMUDP1.RemotePort:=Ini.ReadInteger(Cfg,'RemotePort',0);
      FName:=Ini.ReadString(Cfg,'PipFileName','filenotfound');
      AssignFile(PipFile,FName);
      Reset(PipFile);
    finally
      Ini.Free;
    end;
  except
    Close;
  end;
  GetLocalTime(Time);
  PipTime.Year:=Time.wYear-1900;
  PipTime.Month:=Time.wMonth;
  PipTime.Day:=Time.wDay;
  PipTime.Hour:=Time.wHour;
  PipTime.Min:=Time.wMinute;
  PipTime.Sec:=Time.wSecond;
  FillChar(PFSecond,SizeOf(PFSecond),0);
  PFSecond.Sec:=1;
  Application.OnIdle:=AppOnIdle;
end;

procedure TForm1.SendNextRec;
type
  TCharArray=packed array[0..15] of Char;
var
  R:TPipFileRec;
  Buf:TCharArray;
  SR:TSclRec absolute Buf;
  S:String;
begin
  FillChar(Buf,SizeOf(Buf),0);
  SR.Time:=PipTime;
  NextPipTime(PipTime,PFSecond);
  try
    if EOF(PipFile) then Seek(PipFile,0);
    Read(PipFile,R);
    // Pressure 1
    if (R.F1 and $02<>0)and(R.F1 and $04=0) then begin
      SR.Number:=1;
      SR.p:=R.p1;
      NMUDP1.SendBuffer(Buf,SizeOf(Buf));
      Str(R.p1:6:3,S);
    end
    else S:='бсющ';
    StTxtP1.Caption:=S;
    // Pressure 2
    if (R.F2 and $02<>0)and(R.F2 and $04=0) then begin
      SR.Number:=2;
      SR.p:=R.p2;
      NMUDP1.SendBuffer(Buf,SizeOf(Buf));
      Str(R.p2:6:3,S);
    end
    else S:='бсющ';
    StTxtP2.Caption:=S;
  except
    Halt(1);
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  CloseFile(PipFile);
end;

procedure TForm1.TimerTimer(Sender: TObject);
begin
  if not CheckBox.Checked then SendNextRec;
  TimerTicked:=True;
end;

procedure TForm1.AppOnIdle(Sender: TObject; var Done: Boolean);
var
  i:Integer;
begin
  if CheckBox.Checked and TimerTicked
  then for i:=1 to 60 do SendNextRec;
  TimerTicked:=False;
end;

end.

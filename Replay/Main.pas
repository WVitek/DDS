unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ExtCtrls, IniFiles, Misc, SensorTypes, Menus,
  DdhAppX, ImgList, StdCtrls, ArchManThd;

type
  TFormReplay = class(TForm)
    AppExt: TDdhAppExt;
    TrayPopupMenu: TPopupMenu;
    pmiClose: TMenuItem;
    pmiAbout: TMenuItem;
    Timer: TTimer;
    pmiStart: TMenuItem;
    pmiStop: TMenuItem;
    N3: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pmiAboutClick(Sender: TObject);
    procedure pmiCloseClick(Sender: TObject);
    procedure AppExtTrayDefault(Sender: TObject);
    procedure AppExtLBtnDown(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure pmiStartClick(Sender: TObject);
    procedure pmiStopClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    AMThd:TArchManThread;
    Sensors:TList;
    StartDate:TDateTime;
    LastSec:Integer;
  end;

var
  FormReplay: TFormReplay;

implementation

const
  RecsPerDay=SecsPerDay;
  dtOneSecond=1/SecsPerDay;

{$R *.DFM}

procedure TFormReplay.FormCreate(Sender: TObject);
const
  Section='config';
var
  Ini:TIniFile;
  FName:String;
  i,ID:Integer;
begin
  InitFormattingVariables;
  AMThd:=TArchManThread.Create;//('127.0.0.1');
  AMThd.Resume;
  FName:=GetModuleFullName+'.ini';
  if not FileExists(FName)
  then raise Exception.Create('Программа повтора данных: Не найден файл конфигурации "'+FName+'"');
  Ini:=TIniFile.Create(FName);
  StartDate:=Ini.ReadDate(Section,'StartDate',Int(Now)-1);
  Sensors:=TList.Create;
  Sensors.Count:=Ini.ReadInteger(Section,'SensorCount',0);
  for i:=0 to Sensors.Count-1 do begin
    AMThd.StrToTrackID(Ini.ReadString(Section,'Sensor'+IntToStr(i+1),'ZZZ'),ID);
    Sensors[i]:=Pointer(ID);
    AMThd.setTrackInfo(ID,TMySensor.GetRecSize,RecsPerDay);
  end;
  Ini.Free;
end;

procedure TFormReplay.FormDestroy(Sender: TObject);
begin
  Sensors.Free;
  AMThd.Free;
end;

procedure TFormReplay.pmiAboutClick(Sender: TObject);
begin
  Application.MessageBox(
    'СКУ (для презентаций)'#13#13+
    'Программа повтора данных'#13+
    '(имитация поступления новых данных повторением старых)'#13#13+
    '(c) 2000-2002 ООО "Компания Телекомнур"'#13+
    'e-mail: test@mail.rb.ru',
    'О программе',
    MB_ICONINFORMATION or MB_OK);
end;

procedure TFormReplay.pmiCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormReplay.AppExtTrayDefault(Sender: TObject);
var
  P:TPoint;
begin
  GetCursorPos(P);
  PopupMenu.Popup(P.x,P.y);
end;

procedure TFormReplay.AppExtLBtnDown(Sender: TObject);
var
  P:TPoint;
begin
  GetCursorPos(P);
  TrayPopupMenu.Popup(P.x,P.y);
end;

procedure TFormReplay.TimerTimer(Sender: TObject);
var
  DayTime,SrcTime,DstTime:TDateTime;
  NewSec:Integer;
  i,ID:Integer;
  Data:WideString;
begin
  NewSec:=Trunc(Time*SecsPerDay);
  if LastSec<>NewSec then begin
    DayTime:=NewSec*dtOneSecond;
    SrcTime:=StartDate+DayTime;
    DstTime:=Date+DayTime;
    for i:=0 to Sensors.Count-1 do begin
      ID:=Integer(Sensors[i]);
      AMThd.readRecords(ID,SrcTime,1,Data);
      AMThd.writeRecords(ID,DstTime,1,Data);
    end;
    LastSec:=NewSec;
  end;
end;

procedure TFormReplay.pmiStartClick(Sender: TObject);
begin
  Timer.Enabled:=True;
  pmiStart.Visible:=False;
  pmiStop.Visible:=True;
end;

procedure TFormReplay.pmiStopClick(Sender: TObject);
begin
  Timer.Enabled:=False;
  pmiStart.Visible:=True;
  pmiStop.Visible:=False;
end;

end.

unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ExtCtrls, IniFiles, Misc, NMUDP, SensorTypes, Menus,
  DdhAppX, ImgList, StdCtrls, ArchManThd;

type
  TFormDataCol = class(TForm)
    AppExt: TDdhAppExt;
    TrayPopupMenu: TPopupMenu;
    pmiClose: TMenuItem;
    pmiAbout: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NMUDPDataReceived(Sender: TComponent; NumberBytes: Integer;
      FromIP: String; Port: Integer);
    procedure pmiAboutClick(Sender: TObject);
    procedure pmiCloseClick(Sender: TObject);
    procedure AppExtLBtnDown(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    UDPs:TList;
    AMThd:TArchManThread;
    LogFileName:String;
  end;

  TMyUDP=class(TNMUDP)
    Sensors:TByteStringList;
    constructor CreateFromIniSection(Owner:TFormDataCol; Ini:TIniFile;
      const Section:String);
    destructor Destroy;override;
  end;

var
  FormDataCol: TFormDataCol;
  TMySensor:CSensor;

implementation

{$R *.DFM}

procedure TFormDataCol.FormCreate(Sender: TObject);
const
  Section = 'config';
var
  Ini:TIniFile;
  FName:String;
  SV:TStringList;
  i:Integer;
  UDP:TMyUDP;
  Num,ErrPos:Integer;
  S:String;
begin
  InitFormattingVariables;
  FName:=GetModuleFullName+'.ini';
  if not FileExists(FName)
  then raise Exception.Create('Программа сбора данных: Не найден файл конфигурации "'+FName+'"');
  LogFileName:=ChangeFileExt(FName,'.log');
  WriteToLog(LogFileName,LogMsg(Now,'ЗАПУСК DataCol'));
  AMThd:=TArchManThread.Create;//('127.0.0.1');
  AMThd.Resume;
  Ini:=TIniFile.Create(FName);
  SV:=TStringList.Create;
  UDPs:=TList.Create;
  S:=Ini.ReadString(Section,'JumpLimit','0.0'); //0.3
  try
    SensorTypes.JumpLimit:=StrToFloat(S);
  except
    SensorTypes.JumpLimit:=0.3;
  end;
  if Ini.ReadInteger(Section,'NewSensorType',0)<>0
  then TMySensor:=TSensorFloat32
  else TMySensor:=TSensorFixed24;
  Ini.ReadSections(SV);
  for i:=0 to SV.Count-1 do begin
    Val(SV[i],Num,ErrPos);
    if (ErrPos=0) and (0<Num) and (Num<65536) then begin
      UDP:=TMyUDP.CreateFromIniSection(Self,Ini,SV[i]);
      if UDP<>nil then begin
        UDP.OnDataReceived:=NMUDPDataReceived;
        UDPs.Add(UDP);
      end;
    end;
  end;
  SV.Free;
  Ini.Free;
end;

procedure TFormDataCol.FormDestroy(Sender: TObject);
var
  i:Integer;
begin
  if UDPs<>nil then begin
    for i:=0 to UDPs.Count-1 do TObject(UDPs[i]).Free;
    UDPs.Free;
  end;
  AMThd.Free;
  WriteToLog(LogFileName,LogMsg(Now,'ОСТАНОВ DataCol'));
end;

procedure TFormDataCol.NMUDPDataReceived(Sender: TComponent;
  NumberBytes: Integer; FromIP: String; Port: Integer);
var
  InBuf:String;
  OutBuf:WideString;
  i,Cnt:Integer;
  S:TSensor;
  DT:TDateTime;
  UDP:TMyUDP absolute Sender;
begin
  //if NumberBytes<16 then exit;
  SetLength(InBuf,NumberBytes);
  UDP.ReadBuffer(InBuf[1],NumberBytes);
  if UDP.Sensors.Find(InBuf[1],i) then begin
    S:=UDP.Sensors.Objects[i] as TSensor;
    if S.Num=255
    then begin
      Cnt:=0;
      i:=NumberBytes shr 1;
    end
    else begin
      Cnt:=(NumberBytes - SizeOf(TLdrData)) div SizeOf(Single) + 1;
      i:=(S.GetRecSize*Cnt+1) shr 1;
    end;
    SetLength(OutBuf,i);
    try
      if S.Num=255 then begin
        i:=NumberBytes-1;
        Move(InBuf[2],OutBuf[1],i);
        DT:=0;
      end
      else begin
        i:=Cnt;
        if Cnt=1
        then DT:=S.FormatData(InBuf[1],OutBuf[1])
        else DT:=S.FormatDataN(InBuf[1],OutBuf[1],Cnt);
      end;
      AMThd.writeRecords(S.TrackID,DT,i,OutBuf);
    except
      on E:Exception do begin
        WriteToLog(LogFileName,
          '#'+IntToStr(Ord(InBuf[1]))+' : raised '+E.ClassName+' "'+E.Message+'"');
        Close;
      end;
    end;
  end;
end;

{ TMyUDP }

constructor TMyUDP.CreateFromIniSection(Owner:TFormDataCol; Ini: TIniFile;
  const Section: String);
var
  SV:TStringList;
  i,j:Integer;
  S:TSensor;
  Num,ID:Integer;
  Tmp:String;
begin
  Create(Owner);
  LocalPort:=StrToInt(Section);
  SV:=TStringList.Create;
  Ini.ReadSectionValues(Section,SV);
  Sensors:=TByteStringList.Create;
  Sensors.Sorted:=True;
  for i:=0 to SV.Count-1 do begin
    Num:=StrToInt(SV.Names[i]);
    Tmp:=SV.Values[SV.Names[i]];
    j:=Pos(',',Tmp); if j=0 then j:=Length(Tmp)+1;
    Owner.AMThd.StrToTrackID(Copy(Tmp,1,j-1),ID);
    Tmp:=Copy(Tmp,j+1,Length(Tmp)-j);
    if Tmp='' then Tmp:='86400';
    j:=StrToInt(Tmp);
    S:=TMySensor.Create(Num,ID,j);
    Owner.AMThd.setTrackInfo(S.TrackID,S.GetRecSize,S.GetRecsPerDay);
    Sensors.AddObject(Char(Num),S);
  end;
  SV.Free;
  // Events 'sensor'
  Owner.AMThd.StrToTrackID('EVT',ID);
  S:=TMySensor.Create(255,ID,0);
  Owner.AMThd.setTrackInfo(ID,0,0);
  Sensors.AddObject(#255,S);
end;

destructor TMyUDP.Destroy;
var
  i:Integer;
begin
  if Sensors<>nil then begin
    for i:=0 to Sensors.Count-1 do Sensors.Objects[i].Free;
    Sensors.Free;
  end;
  inherited;
end;

procedure TFormDataCol.pmiAboutClick(Sender: TObject);
begin
  Application.MessageBox(
    'СКУ'#13#13+
    'Программа сбора данных'#13+            
    '(прием из сети и помещение в архив)'#13#13+
    '(c) 2000-2002 ООО "Компания Телекомнур"'#13+
    'e-mail: test@mail.rb.ru',
    'О программе',
    MB_ICONINFORMATION or MB_OK);
end;

procedure TFormDataCol.pmiCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormDataCol.AppExtLBtnDown(Sender: TObject);
var
  P:TPoint;
begin
  GetCursorPos(P);
  TrayPopupMenu.Popup(P.x,P.y);
end;

end.

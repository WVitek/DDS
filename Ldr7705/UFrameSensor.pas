unit UFrameSensor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, UFormConv, IniFiles, SensorTypes;

type
  TQuality = (qOK,qOutOfRange,qCommErr,qAnalogErr);
  TSampleData = record
    SumX,SumY:Double;
    CntX,CntY:Integer;
    LastQuality:TQuality;
  end;
  TFrameSensor = class(TFrame)
    GroupBox: TGroupBox;
    stStatus: TStaticText;
    cbOn: TCheckBox;
    BtnConv: TButton;
    procedure BtnConvClick(Sender: TObject);
    procedure cbOnClick(Sender: TObject);
  private
    { Private declarations }
    procedure CalcCoeffs;
  public
    { Public declarations }
    Section:String;
    X0,X1,Y0,Y1,Ymin:Double;
    CoeffK,CoeffB:Double;
    Host:String;
    Port,NetNumber:Integer;
    isSensorOn:Boolean;
    CurData,LatchedData:TSampleData;
    LastData:TAnalogData;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);
    procedure WriteToIni(Ini:TIniFile);
    procedure TimerProc;
    procedure addSample(X:Double; Quality:TQuality);
    procedure LatchData;
    function GetLatchedY:TAnalogData;
  end;

implementation

{$R *.DFM}

procedure TFrameSensor.BtnConvClick(Sender: TObject);
var
  CF:TFormConv;
  MR:Integer;
begin
  CF:=TFormConv.Create(Self);
  CF.X0:=X0; CF.Y0:=Y0;
  CF.X1:=X1; CF.Y1:=Y1;
  CF.Ymin:=Ymin;
  while True do begin
    MR:=CF.ShowModal;
    case MR of
      mrOK,mrYes: begin
        X0:=CF.X0; Y0:=CF.Y0;
        X1:=CF.X1; Y1:=CF.Y1;
        Ymin:=CF.Ymin;
        CalcCoeffs;
        if MR=mrOK then break;
      end;
      mrCancel: break;
    end;
  end;
  CF.Free;
end;

procedure TFrameSensor.CalcCoeffs;
begin
  CoeffK:=(Y1-Y0)/(X1-X0);
  CoeffB:=Y0-CoeffK*X0;
end;

procedure TFrameSensor.LoadFromIniSection(Ini: TIniFile;
  const Section: String);
begin
  Self.Section:=Section;
  isSensorOn:=Ini.ReadBool(Section,'On',True);
  NetNumber:=Ini.ReadInteger(Section,'NetNumber',0);
  cbOn.Checked:=isSensorOn;
  GroupBox.Caption:=' ¹'+IntToStr(NetNumber)+' ';
  X0:=Ini.ReadFloat(Section,'X0',0.0);
  Y0:=Ini.ReadFloat(Section,'Y0',0);
  X1:=Ini.ReadFloat(Section,'X1',1.0);
  Y1:=Ini.ReadFloat(Section,'Y1',65535);
  Ymin:=Ini.ReadFloat(Section,'Ymin',0);
  CalcCoeffs;
  Host:=Ini.ReadString(Section,'Host','');
  Port:=Ini.ReadInteger(Section,'Port',0);
end;

procedure TFrameSensor.WriteToIni(Ini: TIniFile);
begin
  Ini.WriteBool(Section,'On',isSensorOn);
  Ini.WriteFloat(Section,'X0',X0);
  Ini.WriteFloat(Section,'Y0',Y0);
  Ini.WriteFloat(Section,'X1',X1);
  Ini.WriteFloat(Section,'Y1',Y1);
  Ini.WriteFloat(Section,'Ymin',Ymin);
end;

procedure TFrameSensor.addSample(X: Double; Quality: TQuality);
var
  Y:Double;
begin
  if Quality<>qCommErr then begin
    CurData.SumX:=CurData.SumX+X;
    Inc(CurData.CntX);
  end;
  if Quality=qOK then begin
    Y:=CoeffK*X+CoeffB;
    if Y<Ymin then Quality:=qAnalogErr
    else begin
      CurData.SumY:=CurData.SumY+Y;
      Inc(CurData.CntY);
    end;
  end;
  CurData.LastQuality:=Quality;
end;

procedure TFrameSensor.LatchData;
begin
  LatchedData:=CurData;
  FillChar(CurData,SizeOf(CurData),0);
end;

function TFrameSensor.GetLatchedY: TAnalogData;
begin
  if (LatchedData.CntY>0) then begin
    Result.Value:=LatchedData.SumY/LatchedData.CntY;
  end
  else begin
    if isSensorOn then begin
      case LatchedData.LastQuality of
        qOK:
          SetErrADCComm(Result);
        qOutOfRange:
          SetErrADCRange(Result);
        qCommErr:
          SetErrADCComm(Result);
        qAnalogErr:
          SetErrAnalog(Result);
      end;
    end
    else SetSensorRepair(Result);
  end;
  LastData:=Result;
end;

procedure TFrameSensor.TimerProc;
var
  S:String;
begin
  if LatchedData.CntX>0 then begin
    S:=Format(' %.4e;%3d, ',[LatchedData.SumX/LatchedData.CntX, LatchedData.CntX]);
    if LatchedData.CntY>0
    then S:=S+Format('%05.1f',[LatchedData.SumY/LatchedData.CntY])
    else S:=S+GetADMsg(LastData);
  end
  else S:=GetADMsg(LastData);
  stStatus.Caption:=S;
end;

procedure TFrameSensor.cbOnClick(Sender: TObject);
begin
  isSensorOn:=cbOn.Checked;
end;

end.

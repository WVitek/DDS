unit ConversionForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls;

type
  TFormConversion = class(TForm)
    rgADCRange: TRadioGroup;
    GroupBoxDst: TGroupBox;
    edXa: TEdit;
    edXb: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    GroupBoxSrc: TGroupBox;
    pcSource: TPageControl;
    tsCurrent: TTabSheet;
    Label3: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    edR: TEdit;
    edIa: TEdit;
    edIb: TEdit;
    tsVoltage: TTabSheet;
    Label4: TLabel;
    Label5: TLabel;
    edUa: TEdit;
    edUb: TEdit;
    BtnOk: TButton;
    BtnCancel: TButton;
    BtnApply: TButton;
    edXm: TEdit;
    Label8: TLabel;
    procedure FormShow(Sender: TObject);
    procedure BtnOkClick(Sender: TObject);
    procedure BtnApplyClick(Sender: TObject);
  private
    function GetVolatageMode: Boolean;
    procedure SetVoltageMode(const Value: Boolean);
    function Validate:Boolean;
    function GetADCRange: Integer;
    procedure SetADCRange(const Value: Integer);
  public
    Ia,Ib,R:Double;
    Ua,Ub:Double;
    Xm,Xa,Xb:Double;
  public
    property ADCRange:Integer read GetADCRange write SetADCRange;
    property VoltageMode:Boolean read GetVolatageMode write SetVoltageMode;
  end;

function getADCRangeParams(Range:Integer; var PhysScale,VoltsScale:Double
):Boolean;

var
  FormConversion: TFormConversion;

implementation

{$R *.DFM}

function getADCRangeParams(Range:Integer; var PhysScale,VoltsScale:Double
):Boolean;
begin
  Result:=True;
  case Range of
  0: begin PhysScale:=15.000; VoltsScale:=0.001; end; // 15 mV
  1: begin PhysScale:=50.000; VoltsScale:=0.001; end; // 50 mV
  2: begin PhysScale:=100.00; VoltsScale:=0.001; end; // 100 mV
  3: begin PhysScale:=150.00; VoltsScale:=0.001; end; // 150 mV
  4: begin PhysScale:=500.00; VoltsScale:=0.001; end; // 500 mV
  5: begin PhysScale:=1.0000; VoltsScale:=1.000; end; // 1 V
  6: begin PhysScale:=2.5000; VoltsScale:=1.000; end; // 2.5 V
  7: begin PhysScale:=5.0000; VoltsScale:=1.000; end; // 5 V
  8: begin PhysScale:=10.000; VoltsScale:=1.000; end; // 10 V
  9: begin PhysScale:=20.000; VoltsScale:=0.125; end; // 20 mA (with R=125 Ohm, U=2.5V)
  else Result:=False;
  end;
end;

procedure TFormConversion.FormShow(Sender: TObject);
begin
  rgADCRange.ItemIndex:=ADCRange;
  edIa.Text:=FloatToStr(Ia);
  edIb.Text:=FloatToStr(Ib);
  edR.Text:=FloatToStr(R);
  edUa.Text:=FloatToStr(Ua);
  edUb.Text:=FloatToStr(Ub);
  edXm.Text:=FloatToStr(Xm);
  edXa.Text:=FloatToStr(Xa);
  edXb.Text:=FloatToStr(Xb);
end;

function TFormConversion.GetVolatageMode: Boolean;
begin
  Result:=pcSource.ActivePageIndex=1;
end;

procedure TFormConversion.SetVoltageMode(const Value: Boolean);
begin
  if Value
  then pcSource.ActivePageIndex:=1
  else pcSource.ActivePageIndex:=0
end;

function TFormConversion.Validate: Boolean;
{
var
  VoltsRange:Double;
  PhysScale,VoltsScale:Double;
}
begin
  Result:=False;
  try
    if VoltageMode then begin
      // "Voltage" page checking
      try Ua:=StrToFloat(edUa.Text);
      except edUa.SetFocus; raise; end;
      try Ub:=StrToFloat(edUb.Text);
      except edUb.SetFocus; raise; end;
    end
    else begin
      // "Current" page checking
      try Ia:=StrToFloat(edIa.Text);
      except edIa.SetFocus; raise; end;
      try Ib:=StrToFloat(edIb.Text);
      except edIb.SetFocus; raise; end;
      try
        R:=StrToFloat(edR.Text);
        if R<=0 then raise Exception.Create(
          'Величина шунтирующего сопротивления должна быть больше 0'
        );
      except edR.SetFocus; raise; end;
    end;
    // "Result value" checking
    try Xm:=StrToFloat(edXm.Text);
    except edXm.SetFocus; raise; end;
    try Xa:=StrToFloat(edXa.Text);
    except edXa.SetFocus; raise; end;
    try Xb:=StrToFloat(edXb.Text);
    except edXb.SetFocus; raise; end;
    if Xa=Xb then raise Exception.Create('Значение Xa должно отличаться от Xb');
  except
    on E:Exception do begin
      Application.MessageBox(PChar(E.Message),'Ошибка',MB_ICONERROR or MB_OK);
      exit;
    end;
  end;
  if not VoltageMode then begin
    Ua:=Ia*R;
    Ub:=Ib*R;
  end;
{
  getADCRangeParams(ADCRange,PhysScale,VoltsScale);
  VoltsRange:=PhysScale*VoltsScale;
  if (Ua<=-VoltsRange) or (+VoltsRange<=Ub)
}
  Result:=True;
end;

procedure TFormConversion.BtnOkClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrOK;
end;

procedure TFormConversion.BtnApplyClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrYes;
end;

function TFormConversion.GetADCRange: Integer;
begin
  Result:=rgADCRange.ItemIndex;
end;

procedure TFormConversion.SetADCRange(const Value: Integer);
begin
  rgADCRange.ItemIndex:=Value;
  if rgADCRange.ItemIndex=-1 then rgADCRange.ItemIndex:=9;
end;

{
(Application.MessageBox(
  'Вы действительно хотите изменить настройки?',
  'Подтверждение',
  MB_ICONQUESTION or MB_YESNO or MB_TOPMOST or MB_DEFBUTTON2
)<>ID_YES);
}
end.


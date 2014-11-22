unit SensorOptions;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Misc, ComCtrls;

type
  TFormSensorOptions = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    BtnOk: TButton;
    BtnCancel: TButton;
    BtnApply: TButton;
    StaticText2: TStaticText;
    edMinGraphHeight: TEdit;
    StaticText3: TStaticText;
    GroupBox3: TGroupBox;
    StaticText1: TStaticText;
    edMaxNoDataTime: TEdit;
    StaticText4: TStaticText;
    edKilometer: TEdit;
    edAlphaArc: TComboBox;
    StaticText5: TStaticText;
    edAlphaSpy: TComboBox;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    cbHigh: TCheckBox;
    rbtnHighManual: TRadioButton;
    rbtnHighAuto: TRadioButton;
    pnlAutoHigh: TPanel;
    StaticText8: TStaticText;
    StaticText6: TStaticText;
    edHighAlpha: TComboBox;
    StaticText7: TStaticText;
    edHighScale: TComboBox;
    edHighMin: TEdit;
    edHighMax: TEdit;
    edHigh: TEdit;
    cbUseAlpha: TCheckBox;
    cbLow: TCheckBox;
    rbtnLowManual: TRadioButton;
    edLow: TEdit;
    rbtnLowAuto: TRadioButton;
    pnlAutoLow: TPanel;
    StaticText9: TStaticText;
    StaticText10: TStaticText;
    edLowAlpha: TComboBox;
    StaticText11: TStaticText;
    edLowScale: TComboBox;
    edLowMin: TEdit;
    edLowMax: TEdit;
    procedure BtnOkClick(Sender: TObject);
    procedure BtnApplyClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    HighValue,HighAlpha,HighScale,HighMin,HighMax:Double;
    LowValue, LowAlpha, LowScale, LowMin, LowMax :Double;
    AlphaSpy,AlphaArc:Double;
    MinGraphHeight:Double;
    MaxNoDataTime:Integer;
    Kilometer:Double;
    function Validate:Boolean;
  end;

var
  FormSensorOptions: TFormSensorOptions;

implementation

//uses UFrameGraph;

{$R *.DFM}

{ TFormFPGOptions }

function TFormSensorOptions.Validate: Boolean;
var
  AC:TWinControl;
begin
  Result:=False;
  AC:=ActiveControl;
  try
    // High
    CheckMinMax(HighValue,0.0001,100,edHigh);
    CheckMinMax(HighAlpha,0,0.9999,edHighAlpha);
    CheckMinMax(HighScale,2,10,edHighScale);
    CheckMinMax(HighMin,0,80,edHighMin);
    CheckMinMax(HighMax,HighMin,80,edHighMax);
    // Low
    CheckMinMax(LowValue,0.0001,100,edLow);
    CheckMinMax(LowAlpha,0,0.9999,edLowAlpha);
    CheckMinMax(LowScale,2,10,edLowScale);
    CheckMinMax(LowMin,0,80,edLowMin);
    CheckMinMax(LowMax,LowMin,80,edLowMax);
    // Other
    CheckMinMax(AlphaSpy,0,0.99,edAlphaSpy);
    CheckMinMax(AlphaArc,0,0.99,edAlphaArc);
    CheckMinMax(MinGraphHeight,0.05,80,edMinGraphHeight);
    try
      MaxNoDataTime:=StrToInt(edMaxNoDataTime.Text);
      if MaxNoDataTime<0
      then ErrorMsg('Значение задержки не может быть отрицательным');
    except
      edMaxNoDataTime.SetFocus;
      raise;
    end;
    CheckMinMax(Kilometer,0,99999,edKilometer);
  except
    exit;
  end;
  ActiveControl:=AC;
  Result:=True;
end;

procedure TFormSensorOptions.BtnOkClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrOk;
end;

procedure TFormSensorOptions.BtnApplyClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrRetry;
end;

end.

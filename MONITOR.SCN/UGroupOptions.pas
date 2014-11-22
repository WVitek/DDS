unit UGroupOptions;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,Misc,Math;

type
  TGroupOptions = class(TForm)
    gbDDS: TGroupBox;
    BtnOk: TButton;
    BtnCancel: TButton;
    BtnApply: TButton;
    stWaveSpeed: TStaticText;
    edWaveSpeed: TEdit;
    BtnCalcWaveSpeed: TButton;
    stLineLen: TStaticText;
    edDDSLineLen: TEdit;
    gbAlarm: TGroupBox;
    cbAlarmSingle: TCheckBox;
    cbAlarmNoSound: TCheckBox;
    cbAlarmNoData: TCheckBox;
    cbAlarmSpeaker: TCheckBox;
    cbAlarmMedia: TCheckBox;
    btnMediaFile: TButton;
    OpenDialog: TOpenDialog;
    lblAlpha1: TLabel;
    edAlpha1: TEdit;
    lblAlpha2: TLabel;
    edAlpha2: TEdit;
    BtnCalcAlpha1: TButton;
    BtnCalcAlpha2: TButton;
    procedure BtnOkClick(Sender: TObject);
    procedure BtnApplyClick(Sender: TObject);
    procedure BtnCalcWaveSpeedClick(Sender: TObject);
    procedure btnMediaFileClick(Sender: TObject);
    procedure BtnCalcAlpha1Click(Sender: TObject);
    procedure BtnCalcAlpha2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    DDSLineLen:Integer;
    CalcWaveSpeed:Double;
    WaveSpeed,WaveAlpha1,WaveAlpha2:Double;
    function Validate:Boolean;
  end;

implementation

uses UFrameGroup,UFormAnaliz;

{$R *.DFM}

{ TFormPipeOptions }

function TGroupOptions.Validate: Boolean;
var
  AC:TWinControl;
begin
  Result:=False;
  AC:=ActiveControl;
  try
    DDSLineLen:=StrToInt(edDDSLineLen.Text);
    if DDSLineLen<2
    then ErrorMsg('Длина ограничивающих линий должна быть не меньше 2 сек.');
  except
    edDDSLineLen.SetFocus;
    exit;
  end;
  try
    CheckMinMax(WaveSpeed,1,99999,edWaveSpeed);
    CheckMinMax(WaveAlpha1,0,0.95,edAlpha1);
    CheckMinMax(WaveAlpha2,0,0.95,edAlpha2);
  except
    exit;
  end;
  ActiveControl:=AC;
  Result:=True;
end;

procedure TGroupOptions.BtnOkClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrOk;
end;

procedure TGroupOptions.BtnApplyClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrRetry;
end;

procedure TGroupOptions.BtnCalcWaveSpeedClick(Sender: TObject);
begin
  edWaveSpeed.Text:=Format('%g',[CalcWaveSpeed]);
end;

procedure TGroupOptions.btnMediaFileClick(Sender: TObject);
begin
  if OpenDialog.Execute then begin
    btnMediaFile.Caption:=OpenDialog.FileName;
    cbAlarmMedia.Checked:=True;
  end;
end;

procedure TGroupOptions.BtnCalcAlpha1Click(Sender: TObject);
begin
  edAlpha1.Text:=Format('%g',[FormAnaliz.CalcAlpha]);
end;

procedure TGroupOptions.BtnCalcAlpha2Click(Sender: TObject);
begin
  edAlpha2.Text:=Format('%g',[FormAnaliz.CalcAlpha]);
end;

end.

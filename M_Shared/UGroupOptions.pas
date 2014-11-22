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
    StaticText2: TStaticText;
    edWaveSpeed: TEdit;
    BtnCalcWaveSpeed: TButton;
    StaticText3: TStaticText;
    edDDSLineLen: TEdit;
    gbAlarm: TGroupBox;
    cbAlarmSingle: TCheckBox;
    cbAlarmNoSound: TCheckBox;
    cbAlarmNoData: TCheckBox;
    cbAlarmSpeaker: TCheckBox;
    cbAlarmMedia: TCheckBox;
    btnMediaFile: TButton;
    OpenDialog: TOpenDialog;
    procedure BtnOkClick(Sender: TObject);
    procedure BtnApplyClick(Sender: TObject);
    procedure BtnCalcWaveSpeedClick(Sender: TObject);
    procedure btnMediaFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    DDSLineLen:Integer;
    CalcWaveSpeed,WaveSpeed:Double;
    PipeLength:Double;
    function Validate:Boolean;
    function ValidateWaveSpeed:Boolean;
  end;

implementation

{$R *.DFM}

{ TGroupOptions }

function TGroupOptions.Validate: Boolean;
var
  AC:TWinControl;
begin
  Result:=False;
  AC:=ActiveControl;
  try
    try
      DDSLineLen:=StrToInt(edDDSLineLen.Text);
      if DDSLineLen<2
      then ErrorMsg('Длина ограничивающих линий должна быть не меньше 2 сек.');
    except
      edDDSLineLen.SetFocus;
      raise;
    end;
    if not ValidateWaveSpeed then exit;
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

function TGroupOptions.ValidateWaveSpeed: Boolean;
begin
  try
    CheckMinMax(WaveSpeed,1,99999,edWaveSpeed);
  except
    Result:=False;
    exit;
  end;
  Result:=True;
end;

procedure TGroupOptions.btnMediaFileClick(Sender: TObject);
begin
  if OpenDialog.Execute then begin
    btnMediaFile.Caption:=OpenDialog.FileName;
    cbAlarmMedia.Checked:=True;
  end;
end;

end.

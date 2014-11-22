unit PipeOptions;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,Misc,Math;

type
  TFormPipeOptions = class(TForm)
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

var
  FormPipeOptions: TFormPipeOptions;

implementation

{$R *.DFM}

{ TFormPipeOptions }

function TFormPipeOptions.Validate: Boolean;
var
  AC:TWinControl;
begin
  Result:=False;
  AC:=ActiveControl;
  try
    try
      DDSLineLen:=StrToInt(edDDSLineLen.Text);
      if DDSLineLen<2
      then ErrorMsg('����� �������������� ����� ������ ���� �� ������ 2 ���.');
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

procedure TFormPipeOptions.BtnOkClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrOk;
end;

procedure TFormPipeOptions.BtnApplyClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrRetry;
end;

procedure TFormPipeOptions.BtnCalcWaveSpeedClick(Sender: TObject);
begin
  edWaveSpeed.Text:=Format('%g',[CalcWaveSpeed]);
end;

function TFormPipeOptions.ValidateWaveSpeed: Boolean;
begin
  try
    CheckMinMax(WaveSpeed,1,99999,edWaveSpeed);
  except
    Result:=False;
    exit;
  end;
  Result:=True;
end;

procedure TFormPipeOptions.btnMediaFileClick(Sender: TObject);
begin
  if OpenDialog.Execute then begin
    btnMediaFile.Caption:=OpenDialog.FileName;
    cbAlarmMedia.Checked:=True;
  end;
end;

end.

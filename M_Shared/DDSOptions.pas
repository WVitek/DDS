unit DDSOptions;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TFormDDSOptions = class(TForm)
    BtnOk: TButton;
    BtnCancel: TButton;
    BtnApply: TButton;
    GroupBox1: TGroupBox;
    cbOtn: TCheckBox;
    edOtn: TEdit;
    edAbs: TEdit;
    cbAbs: TCheckBox;
    procedure BtnOkClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    OtnValue,AbsValue:Double;
    function Validate:Boolean;
  end;

var
  FormDDSOptions: TFormDDSOptions;

implementation

uses
  PressureGraphFrame;

{$R *.DFM}

{ TFormFPGOptions }

function TFormDDSOptions.Validate: Boolean;
begin
  Result:=False;
  try
    edOtn.SetFocus;
    OtnValue:=StrToFloat(edOtn.Text);
    if (OtnValue<0.01) or (100<OtnValue) then exit;
    edAbs.SetFocus;
    AbsValue:=StrToFloat(edAbs.Text);
    if AbsValue<0 then exit;
  except
    exit;
  end;
  Result:=True;
end;

procedure TFormDDSOptions.BtnOkClick(Sender: TObject);
begin
  if Validate then ModalResult:=TButton(Sender).ModalResult;
end;

end.

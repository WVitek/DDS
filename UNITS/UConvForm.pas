unit UConvForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Misc;

type
  TFormConv = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    edX0: TEdit;
    edX1: TEdit;
    edY1: TEdit;
    edY0: TEdit;
    edYmin: TEdit;
    BtnOk: TButton;
    BtnCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure BtnOkClick(Sender: TObject);
  private
    { Private declarations }
    function Validate:Boolean;
  public
    { Public declarations }
    X0,X1,Y0,Y1,Ymin:Double;
  end;

var
  FormConv: TFormConv;

implementation

{$R *.DFM}

procedure TFormConv.FormShow(Sender: TObject);
begin
  edX0.Text:=FloatToStr(X0);
  edX1.Text:=FloatToStr(X1);
  edY0.Text:=FloatToStr(Y0);
  edY1.Text:=FloatToStr(Y1);
  edYmin.Text:=FloatToStr(Ymin);
end;

function TFormConv.Validate: Boolean;
var
  MX = 3.4E+38;
begin
  try
    CheckMinMax(X0,0,1,edX0);
    CheckMinMax(Y0,-MX,+MX,edY0);
    CheckMinMax(X1,0,1,edX1);
    CheckMinMax(Y1,-MX,+MX,edY1);
    if X0=X1 then raise Exception.Create('Значение X0 должно отличаться от X1');
  except
    on E:Exception do begin
      Application.MessageBox(PChar(E.Message),'Ошибка',MB_ICONERROR or MB_OK);
      exit;
    end;
  end;
end;

procedure TFormConv.BtnOkClick(Sender: TObject);
begin
  if Validate then ModalResult:=mrOK;
end;

end.

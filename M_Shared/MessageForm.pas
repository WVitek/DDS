unit MessageForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TFormMessage = class(TForm)
    Memo: TMemo;
    BtnOk: TButton;
    BtnMap: TButton;
    procedure BtnMapClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    strMapViewerMessage: string;
  end;

var
  FormMessage: TFormMessage;

implementation

{$R *.DFM}

procedure TFormMessage.BtnMapClick(Sender: TObject);
var
  //st : String;
  cd : TCopyDataStruct;
begin
  //st := 'BiaChe;'+FloatToStr(73.1);
  cd.cbData := Length(strMapViewerMessage)+1;
  cd.lpData := PChar(strMapViewerMessage);
  SendMessage(FindWindow('TMain', 'main'), WM_COPYDATA, 0, LParam(@cd));
end;

end.

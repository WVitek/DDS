unit DateTimeSelect;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls;

type
  TFormDateTime = class(TForm)
    DatePicker: TDateTimePicker;
    TimePicker: TDateTimePicker;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    BtnDayStart: TButton;
    BtnOk: TButton;
    BtnCancel: TButton;
    procedure BtnDayStartClick(Sender: TObject);
    procedure TimePickerChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormDateTime: TFormDateTime;

implementation

{$R *.DFM}

procedure TFormDateTime.BtnDayStartClick(Sender: TObject);
begin
  TimePicker.Time:=0;
  BtnDayStart.Enabled:=False;
end;

procedure TFormDateTime.TimePickerChange(Sender: TObject);
begin
  BtnDayStart.Enabled:=True;
end;

end.

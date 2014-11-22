unit DaySelect;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, Grids, Calendar, ComCtrls;

type
  TDateForm = class(TForm)
    Label1: TLabel;
    ButtonOk: TButton;
    ButtonCancel: TButton;
    DateTimePicker: TDateTimePicker;
    Label2: TLabel;
    UpDownYear: TUpDown;
    EditYear: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure DateTimePickerChange(Sender: TObject);
    procedure EditYearChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DateForm: TDateForm;

implementation

{$R *.DFM}

procedure TDateForm.FormCreate(Sender: TObject);
var
  ST:TSystemTime;
begin
  GetSystemTime(ST);
  UpDownYear.Position:=ST.wYear;
  UpDownYear.Max:=ST.wYear;
  DateTimePicker.DateTime:=Trunc(Now);
  DateTimePicker.MaxDate:=Trunc(Now);
end;

procedure TDateForm.DateTimePickerChange(Sender: TObject);
var
  ST:TSystemTime;
begin
  DateTimeToSystemTime(DateTimePicker.DateTime,ST);
  UpDownYear.Position:=ST.wYear;
end;

procedure TDateForm.EditYearChange(Sender: TObject);
var
  ST:TSystemTime;
begin
  DateTimeToSystemTime(DateTimePicker.DateTime,ST);
  ST.wYear:=UpDownYear.Position;
  DateTimePicker.DateTime:=SystemTimeToDateTime(ST);
end;

end.

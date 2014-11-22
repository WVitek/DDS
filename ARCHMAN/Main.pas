unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ArchManImplementation, Menus, ExtCtrls, IniFiles, Misc;

type
  TMainForm = class(TForm)
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    AM:TDDSArchiveManager;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
var
  Ini:TIniFile;
  FName:String;
begin
  inherited;
  FName:=GetModuleFullName+'.ini';
  if not FileExists(FName)
  then raise Exception.Create('Менеджер архива: Не найден файл конфигурации "'+FName+'"');
  Ini:=TIniFile.Create(FName);
  try
    AM:=TDDSArchiveManager.Create(Ini);
  except
    Close;
  end;
end;

procedure TMainForm.TimerTimer(Sender: TObject);
begin
  AM.timerProc;
end;

end.

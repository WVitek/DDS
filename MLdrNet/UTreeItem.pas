unit UTreeItem;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ComCtrls,
  Dialogs, Buttons, ExtCtrls, StdCtrls, IniFiles;

type
  TTreeItem = class(TObject)
    Node:TTreeNode;
    Section:String;
    procedure ChangeData(Btn:TButton; Pnl:TPanel);
//    constructor Load(Nodes:TTreeNodes; ParentNode:TTreeNode; Ini,Cfg:TIniFile; const Section:String);virtual;abstract;
    function Enter(Owner:TComponent):TFrame;virtual;abstract;
    function Leave:Boolean;virtual;abstract;
    function Validate:Boolean;virtual;
    procedure SaveCfg(Cfg:TIniFile);virtual;abstract;
    procedure TimerProc;virtual;abstract;
    procedure WriteToLog(const S:String);
  end;

implementation

uses
  Misc;
  
{ TTreeItem }

procedure TTreeItem.ChangeData(Btn: TButton; Pnl: TPanel);
begin
  if Btn.Tag=0 then begin
    Btn.Tag:=1;
    Pnl.Enabled:=True;
    Btn.Caption:='Применить';
    Pnl.SetFocus;
  end
  else if Validate then begin
    Btn.Tag:=0;
    Pnl.Enabled:=False;
    Btn.Caption:='Внесение изменений';
  end;
end;

function TTreeItem.Validate: Boolean;
begin
  Result:=True;
end;

procedure TTreeItem.WriteToLog(const S: String);
var
  Log:TextFile;
  LogFileName:String;
begin
  try
    LogFileName:=ExtractFileDir(GetModuleFullName)+'\'+Section+'.log';
    AssignFile(Log,LogFileName);
    if not FileExists(LogFileName) then Rewrite(Log) else Append(Log);
    try
      Write(Log,S);
      Flush(Log);
    finally
      CloseFile(Log);
    end;
  except
  end;
end;

end.


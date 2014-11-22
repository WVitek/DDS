unit Types;

interface

uses Classes,Forms,ComCtrls,IniFiles;

type
  TClassOptions = class of TOptions;

  TOptions = class(TObject)
  protected
    FIni:TIniFile;
    FSection:String;
  public
    procedure AssignNode(Node:TTreeNode);virtual; abstract;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);virtual;
    procedure WriteToIniSection;virtual;abstract;
    function CreateOptionsFrame(AOwner:TComponent):TFrame;virtual;abstract;
    function AllowNodeEditing:Boolean;virtual;
    procedure AfterNodeEditing(var S:String);virtual;
  public
    property Ini:TIniFile read FIni;
    property Section:String read FSection;
  end;

  TOptionsList = class(TOptions)
  public
    function AllowNodeEditing:Boolean;override;
  end;
{
    procedure AssignNode(Node:TTreeNode);override;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);override;
    procedure WriteToIniSection;override;
    function CreateOptionsFrame(AOwner:TComponent):TFrame;override;
}

implementation

{ TOptions }

procedure TOptions.AfterNodeEditing(var S: String);
begin
  try
    Ini.EraseSection(Section);
  except
  end;
  FSection:=S;
end;

function TOptions.AllowNodeEditing: Boolean;
begin
  Result:=True;
end;

procedure TOptions.LoadFromIniSection(Ini: TIniFile;
  const Section: String);
begin
  FIni:=Ini;
  FSection:=Section;
end;

{ TOptionsList }

function TOptionsList.AllowNodeEditing: Boolean;
begin
  Result:=False;
end;

end.

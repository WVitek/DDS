unit SeqOptions;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, Types, IniFiles;

type
  TSeqOptions = class;
  TFrameSeqOptions = class(TFrame)
    Label1: TLabel;
    edInitialValue: TEdit;
    Label2: TLabel;
    edNewValue: TEdit;
    Label3: TLabel;
    edBufLength: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TSeqOptions = class(TOptions)
  public
    procedure AssignNode(Node:TTreeNode);override;
    procedure LoadFromIniSection(Ini:TIniFile; const Section:String);override;
    procedure WriteToIniSection;override;
    function CreateOptionsFrame(AOwner:TComponent):TFrame;override;
  end;

implementation

{$R *.DFM}

{ TSeqOptions }

procedure TSeqOptions.AssignNode(Node: TTreeNode);
begin
  Node.Text:='';
end;

function TSeqOptions.CreateOptionsFrame(AOwner: TComponent): TFrame;
begin

end;

procedure TSeqOptions.LoadFromIniSection(Ini: TIniFile;
  const Section: String);
begin
  inherited;

end;

procedure TSeqOptions.WriteToIniSection;
begin
  inherited;

end;

end.

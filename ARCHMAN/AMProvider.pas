unit AMProvider;

interface

uses
  ComObj, ActiveX, ArchMan_TLB, StdVcl;

type
  TDDSArchiveManagerProvider = class(TAutoObject, IDDSArchiveManagerProvider)
  protected
    // IDDSArchiveManagerProvider
    function Get_ArchiveManager: IUnknown; safecall;
    { Protected declarations }
  end;

implementation

uses ComServ,Main;

function TDDSArchiveManagerProvider.Get_ArchiveManager: IUnknown;
begin
  Result:=MainForm.AM;
  Result._AddRef;
end;

initialization
  TAutoObjectFactory.Create(ComServer, TDDSArchiveManagerProvider, Class_DDSArchiveManagerProvider,
    ciMultiInstance, tmSingle);
end.

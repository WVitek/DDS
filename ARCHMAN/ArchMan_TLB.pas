unit ArchMan_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// PASTLWTR : $Revision:   1.88  $
// File generated on 12.05.2002 20:06:06 from Type Library described below.

// *************************************************************************//
// NOTE:                                                                      
// Items guarded by $IFDEF_LIVE_SERVER_AT_DESIGN_TIME are used by properties  
// which return objects that may need to be explicitly created via a function 
// call prior to any access via the property. These items have been disabled  
// in order to prevent accidental use from within the object inspector. You   
// may enable them by defining LIVE_SERVER_AT_DESIGN_TIME or by selectively   
// removing them from the $IFDEF blocks. However, such items must still be    
// programmatically created via a method of the appropriate CoClass before    
// they can be used.                                                          
// ************************************************************************ //
// Type Lib: C:\Work\DDS\ARCHMAN\ArchMan.tlb (1)
// IID\LCID: {6A2726A1-9384-11D4-AE85-00C0DFC5A12E}\0
// Helpfile: 
// DepndLst: 
//   (1) v2.0 stdole, (D:\WINNT\System32\stdole2.tlb)
//   (2) v4.0 StdVCL, (D:\WINNT\System32\STDVCL40.DLL)
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
interface

uses Windows, ActiveX, Classes, Graphics, OleServer, OleCtrls, StdVCL;

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  ArchManMajorVersion = 1;
  ArchManMinorVersion = 0;

  LIBID_ArchMan: TGUID = '{6A2726A1-9384-11D4-AE85-00C0DFC5A12E}';

  IID_IDDSArchiveManager: TGUID = '{6A2726A2-9384-11D4-AE85-00C0DFC5A12E}';
  CLASS_DDSArchiveManager: TGUID = '{6A2726A4-9384-11D4-AE85-00C0DFC5A12E}';
  IID_IDDSArchiveManagerProvider: TGUID = '{06DF07F0-9AAF-11D4-AE9F-00C0DFC5A12E}';
  CLASS_DDSArchiveManagerProvider: TGUID = '{06DF07F2-9AAF-11D4-AE9F-00C0DFC5A12E}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  IDDSArchiveManager = interface;
  IDDSArchiveManagerDisp = dispinterface;
  IDDSArchiveManagerProvider = interface;
  IDDSArchiveManagerProviderDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library                       
// (NOTE: Here we map each CoClass to its Default Interface)              
// *********************************************************************//
  DDSArchiveManager = IDDSArchiveManager;
  DDSArchiveManagerProvider = IDDSArchiveManagerProvider;


// *********************************************************************//
// Interface: IDDSArchiveManager
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {6A2726A2-9384-11D4-AE85-00C0DFC5A12E}
// *********************************************************************//
  IDDSArchiveManager = interface(IDispatch)
    ['{6A2726A2-9384-11D4-AE85-00C0DFC5A12E}']
    procedure getLastRecTime(TrackID: Integer; out Time: TDateTime); safecall;
    procedure readRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                          out Data: WideString); safecall;
    procedure writeRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                           const Data: WideString); safecall;
    procedure setTrackInfo(TrackID: Integer; RecSize: Integer; RecsPerDay: Integer); safecall;
    procedure applySubstitutions(const Src: WideString; TrackID: Integer; Time: TDateTime; 
                                 out Result: WideString); safecall;
    procedure StrToTrackID(const Str: WideString; out TrackID: Integer); safecall;
  end;

// *********************************************************************//
// DispIntf:  IDDSArchiveManagerDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {6A2726A2-9384-11D4-AE85-00C0DFC5A12E}
// *********************************************************************//
  IDDSArchiveManagerDisp = dispinterface
    ['{6A2726A2-9384-11D4-AE85-00C0DFC5A12E}']
    procedure getLastRecTime(TrackID: Integer; out Time: TDateTime); dispid 1;
    procedure readRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                          out Data: WideString); dispid 2;
    procedure writeRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                           const Data: WideString); dispid 3;
    procedure setTrackInfo(TrackID: Integer; RecSize: Integer; RecsPerDay: Integer); dispid 5;
    procedure applySubstitutions(const Src: WideString; TrackID: Integer; Time: TDateTime; 
                                 out Result: WideString); dispid 6;
    procedure StrToTrackID(const Str: WideString; out TrackID: Integer); dispid 4;
  end;

// *********************************************************************//
// Interface: IDDSArchiveManagerProvider
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {06DF07F0-9AAF-11D4-AE9F-00C0DFC5A12E}
// *********************************************************************//
  IDDSArchiveManagerProvider = interface(IDispatch)
    ['{06DF07F0-9AAF-11D4-AE9F-00C0DFC5A12E}']
    function  Get_ArchiveManager: IUnknown; safecall;
    property ArchiveManager: IUnknown read Get_ArchiveManager;
  end;

// *********************************************************************//
// DispIntf:  IDDSArchiveManagerProviderDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {06DF07F0-9AAF-11D4-AE9F-00C0DFC5A12E}
// *********************************************************************//
  IDDSArchiveManagerProviderDisp = dispinterface
    ['{06DF07F0-9AAF-11D4-AE9F-00C0DFC5A12E}']
    property ArchiveManager: IUnknown readonly dispid 1;
  end;

// *********************************************************************//
// The Class CoDDSArchiveManager provides a Create and CreateRemote method to          
// create instances of the default interface IDDSArchiveManager exposed by              
// the CoClass DDSArchiveManager. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoDDSArchiveManager = class
    class function Create: IDDSArchiveManager;
    class function CreateRemote(const MachineName: string): IDDSArchiveManager;
  end;


// *********************************************************************//
// OLE Server Proxy class declaration
// Server Object    : TDDSArchiveManager
// Help String      : DDSArchiveManager Object
// Default Interface: IDDSArchiveManager
// Def. Intf. DISP? : No
// Event   Interface: 
// TypeFlags        : (2) CanCreate
// *********************************************************************//
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  TDDSArchiveManagerProperties= class;
{$ENDIF}
  TDDSArchiveManager = class(TOleServer)
  private
    FIntf:        IDDSArchiveManager;
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    FProps:       TDDSArchiveManagerProperties;
    function      GetServerProperties: TDDSArchiveManagerProperties;
{$ENDIF}
    function      GetDefaultInterface: IDDSArchiveManager;
  protected
    procedure InitServerData; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Connect; override;
    procedure ConnectTo(svrIntf: IDDSArchiveManager);
    procedure Disconnect; override;
    procedure getLastRecTime(TrackID: Integer; out Time: TDateTime);
    procedure readRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                          out Data: WideString);
    procedure writeRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                           const Data: WideString);
    procedure setTrackInfo(TrackID: Integer; RecSize: Integer; RecsPerDay: Integer);
    procedure applySubstitutions(const Src: WideString; TrackID: Integer; Time: TDateTime; 
                                 out Result: WideString);
    procedure StrToTrackID(const Str: WideString; out TrackID: Integer);
    property  DefaultInterface: IDDSArchiveManager read GetDefaultInterface;
  published
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    property Server: TDDSArchiveManagerProperties read GetServerProperties;
{$ENDIF}
  end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
// *********************************************************************//
// OLE Server Properties Proxy Class
// Server Object    : TDDSArchiveManager
// (This object is used by the IDE's Property Inspector to allow editing
//  of the properties of this server)
// *********************************************************************//
 TDDSArchiveManagerProperties = class(TPersistent)
  private
    FServer:    TDDSArchiveManager;
    function    GetDefaultInterface: IDDSArchiveManager;
    constructor Create(AServer: TDDSArchiveManager);
  protected
  public
    property DefaultInterface: IDDSArchiveManager read GetDefaultInterface;
  published
  end;
{$ENDIF}


// *********************************************************************//
// The Class CoDDSArchiveManagerProvider provides a Create and CreateRemote method to          
// create instances of the default interface IDDSArchiveManagerProvider exposed by              
// the CoClass DDSArchiveManagerProvider. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoDDSArchiveManagerProvider = class
    class function Create: IDDSArchiveManagerProvider;
    class function CreateRemote(const MachineName: string): IDDSArchiveManagerProvider;
  end;


// *********************************************************************//
// OLE Server Proxy class declaration
// Server Object    : TDDSArchiveManagerProvider
// Help String      : DDSArchiveManagerProvider Object
// Default Interface: IDDSArchiveManagerProvider
// Def. Intf. DISP? : No
// Event   Interface: 
// TypeFlags        : (2) CanCreate
// *********************************************************************//
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  TDDSArchiveManagerProviderProperties= class;
{$ENDIF}
  TDDSArchiveManagerProvider = class(TOleServer)
  private
    FIntf:        IDDSArchiveManagerProvider;
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    FProps:       TDDSArchiveManagerProviderProperties;
    function      GetServerProperties: TDDSArchiveManagerProviderProperties;
{$ENDIF}
    function      GetDefaultInterface: IDDSArchiveManagerProvider;
  protected
    procedure InitServerData; override;
    function  Get_ArchiveManager: IUnknown;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Connect; override;
    procedure ConnectTo(svrIntf: IDDSArchiveManagerProvider);
    procedure Disconnect; override;
    property  DefaultInterface: IDDSArchiveManagerProvider read GetDefaultInterface;
    property ArchiveManager: IUnknown read Get_ArchiveManager;
  published
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
    property Server: TDDSArchiveManagerProviderProperties read GetServerProperties;
{$ENDIF}
  end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
// *********************************************************************//
// OLE Server Properties Proxy Class
// Server Object    : TDDSArchiveManagerProvider
// (This object is used by the IDE's Property Inspector to allow editing
//  of the properties of this server)
// *********************************************************************//
 TDDSArchiveManagerProviderProperties = class(TPersistent)
  private
    FServer:    TDDSArchiveManagerProvider;
    function    GetDefaultInterface: IDDSArchiveManagerProvider;
    constructor Create(AServer: TDDSArchiveManagerProvider);
  protected
    function  Get_ArchiveManager: IUnknown;
  public
    property DefaultInterface: IDDSArchiveManagerProvider read GetDefaultInterface;
  published
  end;
{$ENDIF}


procedure Register;

implementation

uses ComObj;

class function CoDDSArchiveManager.Create: IDDSArchiveManager;
begin
  Result := CreateComObject(CLASS_DDSArchiveManager) as IDDSArchiveManager;
end;

class function CoDDSArchiveManager.CreateRemote(const MachineName: string): IDDSArchiveManager;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_DDSArchiveManager) as IDDSArchiveManager;
end;

procedure TDDSArchiveManager.InitServerData;
const
  CServerData: TServerData = (
    ClassID:   '{6A2726A4-9384-11D4-AE85-00C0DFC5A12E}';
    IntfIID:   '{6A2726A2-9384-11D4-AE85-00C0DFC5A12E}';
    EventIID:  '';
    LicenseKey: nil;
    Version: 500);
begin
  ServerData := @CServerData;
end;

procedure TDDSArchiveManager.Connect;
var
  punk: IUnknown;
begin
  if FIntf = nil then
  begin
    punk := GetServer;
    Fintf:= punk as IDDSArchiveManager;
  end;
end;

procedure TDDSArchiveManager.ConnectTo(svrIntf: IDDSArchiveManager);
begin
  Disconnect;
  FIntf := svrIntf;
end;

procedure TDDSArchiveManager.DisConnect;
begin
  if Fintf <> nil then
  begin
    FIntf := nil;
  end;
end;

function TDDSArchiveManager.GetDefaultInterface: IDDSArchiveManager;
begin
  if FIntf = nil then
    Connect;
  Assert(FIntf <> nil, 'DefaultInterface is NULL. Component is not connected to Server. You must call ''Connect'' or ''ConnectTo'' before this operation');
  Result := FIntf;
end;

constructor TDDSArchiveManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps := TDDSArchiveManagerProperties.Create(Self);
{$ENDIF}
end;

destructor TDDSArchiveManager.Destroy;
begin
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps.Free;
{$ENDIF}
  inherited Destroy;
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
function TDDSArchiveManager.GetServerProperties: TDDSArchiveManagerProperties;
begin
  Result := FProps;
end;
{$ENDIF}

procedure TDDSArchiveManager.getLastRecTime(TrackID: Integer; out Time: TDateTime);
begin
  DefaultInterface.getLastRecTime(TrackID, Time);
end;

procedure TDDSArchiveManager.readRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                                         out Data: WideString);
begin
  DefaultInterface.readRecords(TrackID, FromTime, Count, Data);
end;

procedure TDDSArchiveManager.writeRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer; 
                                          const Data: WideString);
begin
  DefaultInterface.writeRecords(TrackID, FromTime, Count, Data);
end;

procedure TDDSArchiveManager.setTrackInfo(TrackID: Integer; RecSize: Integer; RecsPerDay: Integer);
begin
  DefaultInterface.setTrackInfo(TrackID, RecSize, RecsPerDay);
end;

procedure TDDSArchiveManager.applySubstitutions(const Src: WideString; TrackID: Integer; 
                                                Time: TDateTime; out Result: WideString);
begin
  DefaultInterface.applySubstitutions(Src, TrackID, Time, Result);
end;

procedure TDDSArchiveManager.StrToTrackID(const Str: WideString; out TrackID: Integer);
begin
  DefaultInterface.StrToTrackID(Str, TrackID);
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
constructor TDDSArchiveManagerProperties.Create(AServer: TDDSArchiveManager);
begin
  inherited Create;
  FServer := AServer;
end;

function TDDSArchiveManagerProperties.GetDefaultInterface: IDDSArchiveManager;
begin
  Result := FServer.DefaultInterface;
end;

{$ENDIF}

class function CoDDSArchiveManagerProvider.Create: IDDSArchiveManagerProvider;
begin
  Result := CreateComObject(CLASS_DDSArchiveManagerProvider) as IDDSArchiveManagerProvider;
end;

class function CoDDSArchiveManagerProvider.CreateRemote(const MachineName: string): IDDSArchiveManagerProvider;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_DDSArchiveManagerProvider) as IDDSArchiveManagerProvider;
end;

procedure TDDSArchiveManagerProvider.InitServerData;
const
  CServerData: TServerData = (
    ClassID:   '{06DF07F2-9AAF-11D4-AE9F-00C0DFC5A12E}';
    IntfIID:   '{06DF07F0-9AAF-11D4-AE9F-00C0DFC5A12E}';
    EventIID:  '';
    LicenseKey: nil;
    Version: 500);
begin
  ServerData := @CServerData;
end;

procedure TDDSArchiveManagerProvider.Connect;
var
  punk: IUnknown;
begin
  if FIntf = nil then
  begin
    punk := GetServer;
    Fintf:= punk as IDDSArchiveManagerProvider;
  end;
end;

procedure TDDSArchiveManagerProvider.ConnectTo(svrIntf: IDDSArchiveManagerProvider);
begin
  Disconnect;
  FIntf := svrIntf;
end;

procedure TDDSArchiveManagerProvider.DisConnect;
begin
  if Fintf <> nil then
  begin
    FIntf := nil;
  end;
end;

function TDDSArchiveManagerProvider.GetDefaultInterface: IDDSArchiveManagerProvider;
begin
  if FIntf = nil then
    Connect;
  Assert(FIntf <> nil, 'DefaultInterface is NULL. Component is not connected to Server. You must call ''Connect'' or ''ConnectTo'' before this operation');
  Result := FIntf;
end;

constructor TDDSArchiveManagerProvider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps := TDDSArchiveManagerProviderProperties.Create(Self);
{$ENDIF}
end;

destructor TDDSArchiveManagerProvider.Destroy;
begin
{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
  FProps.Free;
{$ENDIF}
  inherited Destroy;
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
function TDDSArchiveManagerProvider.GetServerProperties: TDDSArchiveManagerProviderProperties;
begin
  Result := FProps;
end;
{$ENDIF}

function  TDDSArchiveManagerProvider.Get_ArchiveManager: IUnknown;
begin
  Result := DefaultInterface.Get_ArchiveManager;
end;

{$IFDEF LIVE_SERVER_AT_DESIGN_TIME}
constructor TDDSArchiveManagerProviderProperties.Create(AServer: TDDSArchiveManagerProvider);
begin
  inherited Create;
  FServer := AServer;
end;

function TDDSArchiveManagerProviderProperties.GetDefaultInterface: IDDSArchiveManagerProvider;
begin
  Result := FServer.DefaultInterface;
end;

function  TDDSArchiveManagerProviderProperties.Get_ArchiveManager: IUnknown;
begin
  Result := DefaultInterface.Get_ArchiveManager;
end;

{$ENDIF}

procedure Register;
begin
  RegisterComponents('Servers',[TDDSArchiveManager, TDDSArchiveManagerProvider]);
end;

end.

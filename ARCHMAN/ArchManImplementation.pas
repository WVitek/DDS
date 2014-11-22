unit ArchManImplementation;

interface

uses
  ComObj, ActiveX, ArchMan_TLB, StdVcl, Classes,
  FileMan, IniFiles, Windows, SysUtils{, SyncObjs};

type
  TDDSArchiveManager = class(TAutoObject, IDDSArchiveManager)
  private
    FileManager:TFileManager;
    Ini:TIniFile;
  protected
    // IDDSArchiveManager
    procedure getLastRecTime(TrackID: Integer; out Time: TDateTime); safecall;
    procedure readRecords(TrackID: Integer; FromTime: TDateTime;
      Count: Integer; out Data: WideString); safecall;
    procedure writeRecords(TrackID: Integer; FromTime: TDateTime;
      Count: Integer; const Data: WideString); safecall;
    procedure setTrackInfo(ID, RecSize, RecsPerDay: Integer); safecall;
    procedure applySubstitutions(const Src: WideString; TrackID: Integer;
      Time: TDateTime; out Result: WideString); safecall;
    procedure StrToTrackID(const Str: WideString; out TrackID: Integer);
      safecall;
    { Protected declarations }
  public
    constructor Create(aIni:TIniFile);
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
    procedure timerProc;
  end;

implementation

uses ComServ,Main;

procedure TDDSArchiveManager.getLastRecTime(TrackID: Integer;
  out Time: TDateTime);
begin
  FileManager.GetLastRecTime(TrackID,Time);
end;

procedure TDDSArchiveManager.readRecords(TrackID: Integer;
  FromTime: TDateTime; Count: Integer; out Data: WideString);
begin
  FileManager.readRecords(TrackID,FromTime,Count,Data);
end;

procedure TDDSArchiveManager.writeRecords(TrackID: Integer;
  FromTime: TDateTime; Count: Integer; const Data: WideString);
begin
  FileManager.writeRecords(TrackID,FromTime,Count,Data);
end;

procedure TDDSArchiveManager.setTrackInfo(ID, RecSize,
  RecsPerDay: Integer);
begin
  FileManager.setTrackInfo(ID,RecSize,RecsPerDay);
end;

procedure TDDSArchiveManager.applySubstitutions(const Src: WideString;
  TrackID: Integer; Time: TDateTime; out Result: WideString);
begin
  Result:=FileMan.ApplySubstitutions(Src,TrackID,Time);
end;

procedure TDDSArchiveManager.StrToTrackID(const Str: WideString;
  out TrackID: Integer);
begin
  FileManager.StrToTrackID(Str,TrackID);
end;

constructor TDDSArchiveManager.Create(aIni: TIniFile);
begin
  inherited Create;
  Ini:=aIni;
end;

procedure TDDSArchiveManager.AfterConstruction;
begin
  inherited;
  FileManager:=TFileManager.CreateFromIniSection(Ini,'Archive');
end;

procedure TDDSArchiveManager.BeforeDestruction;
begin
  Ini.Free;
  FileManager.Free;
  inherited;
end;

procedure TDDSArchiveManager.timerProc;
begin
  FileManager.timerProc;
end;

initialization
  TAutoObjectFactory.Create(ComServer, TDDSArchiveManager, Class_DDSArchiveManager,
    ciInternal,tmSingle);
end.

unit ArchManThd;

interface

uses Windows,SysUtils,Classes,ActiveX,ArchMan_TLB,SyncObjs,Forms;

type
  TArchManThread=class(TThread)
    procedure getLastRecTime(TrackID: Integer; var Time: TDateTime);
    procedure readRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer;
      var Data: WideString);
    procedure writeRecords(TrackID: Integer; FromTime: TDateTime; Count: Integer;
      const Data: WideString);
    procedure setTrackInfo(TrackID: Integer; RecSize: Integer; RecsPerDay: Integer);
    procedure applySubstitutions(const Src: WideString; TrackID: Integer; Time: TDateTime;
      var Result: WideString);
    procedure StrToTrackID(const Str: WideString; var TrackID: Integer);
    procedure NOP;
    procedure Execute;override;
    constructor Create;//(AServerName:String);
    destructor Destroy;override;
  public
    HasError:Boolean;
  private
    BeginEvent,EndEvent:TSimpleEvent;
    Operation:(opNOP,opGLRT,opRR,opWR,opSTI,opAS,opSTTI,opHE);
    pTrackID:^Integer;
    pTime:^TDateTime;
    Count,RecSize,RecsPerDay:Integer;
    InData:WideString;
    pOutData:^WideString;
//    ServerName:String;
    procedure DoOperation;
  end;

implementation

{ TArchManThread }

procedure TArchManThread.applySubstitutions(const Src: WideString;
  TrackID: Integer; Time: TDateTime; var Result: WideString);
begin
  InData:=Src;
  pTrackID:=@TrackID;
  pTime:=@Time;
  pOutData:=@Result;
  Operation:=opAS;
  DoOperation;
end;

constructor TArchManThread.Create;//(AServerName:String);
begin
  inherited Create(True);
  BeginEvent:=TSimpleEvent.Create;
  EndEvent:=TSimpleEvent.Create;
//  ServerName:=AServerName;
end;

destructor TArchManThread.Destroy;
begin
  EndEvent.Free;
  BeginEvent.Free;
  inherited;
end;

procedure TArchManThread.DoOperation;
var
  i:Integer;
begin
  BeginEvent.SetEvent;
  i:=10;
  while (i>=0) and (EndEvent.WaitFor(200)=wrTimeOut) do Dec(i);
  EndEvent.ResetEvent;
  if (i<0) then Halt(1);
end;

procedure TArchManThread.Execute;
var
  AMP:IDDSArchiveManagerProviderDisp;
  AM:IDDSArchiveManager;
begin
  try
    try
      OleInitialize(nil);
//      AMP:=CoDDSArchiveManagerProvider.CreateRemote(ServerName) as IDDSArchiveManagerProviderDisp;
      AMP:=CoDDSArchiveManagerProvider.Create as IDDSArchiveManagerProviderDisp;
      AM:=AMP.ArchiveManager as IDDSArchiveManager;
      repeat
        if BeginEvent.WaitFor(500)=wrSignaled then begin
          BeginEvent.ResetEvent;
          case Operation of
          opGLRT:
            AM.getLastRecTime(pTrackID^,pTime^);
          opRR:
            AM.readRecords(pTrackID^,pTime^,Count,pOutData^);
          opWR:
            AM.writeRecords(pTrackID^,pTime^,Count,InData);
          opSTI:
            AM.setTrackInfo(pTrackID^,RecSize,RecsPerDay);
          opAS:
            AM.applySubstitutions(InData,pTrackID^,pTime^,pOutData^);
          opSTTI:
            AM.StrToTrackID(InData,pTrackID^);
          end;
          EndEvent.SetEvent;
        end;
      until Terminated;
    except
      on E:Exception do begin
        HasError:=TRUE;
        MessageBox(0,PChar(E.Message),'Error',MB_OK or MB_ICONERROR);
//        Halt(1);
      end;
    end;
  finally
    OleUninitialize;
  end;
end;

procedure TArchManThread.getLastRecTime(TrackID: Integer;
  var Time: TDateTime);
begin
  pTrackID:=@TrackID;
  pTime:=@Time;
  Operation:=opGLRT;
  DoOperation;
end;

procedure TArchManThread.NOP;
begin
  Operation:=opNOP;
  DoOperation;
end;

procedure TArchManThread.readRecords(TrackID: Integer; FromTime: TDateTime;
  Count: Integer; var Data: WideString);
begin
  pTrackID:=@TrackID;
  pTime:=@FromTime;
  Self.Count:=Count;
  pOutData:=@Data;
  Operation:=opRR;
  DoOperation;
end;

procedure TArchManThread.setTrackInfo(TrackID, RecSize,
  RecsPerDay: Integer);
begin
  pTrackID:=@TrackID;
  Self.RecSize:=RecSize;
  Self.RecsPerDay:=RecsPerDay;
  Operation:=opSTI;
  DoOperation;
end;

procedure TArchManThread.StrToTrackID(const Str: WideString;
  var TrackID: Integer);
begin
  InData:=Str;
  pTrackID:=@TrackID;
  Operation:=opSTTI;
  DoOperation;
end;

procedure TArchManThread.writeRecords(TrackID: Integer;
  FromTime: TDateTime; Count: Integer; const Data: WideString);
begin
  pTrackID:=@TrackID;
  pTime:=@FromTime;
  Self.Count:=Count;
  InData:=Data;
  Operation:=opWR;
  DoOperation;
end;

end.

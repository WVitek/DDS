unit FileMan;

interface

uses Classes, IniFiles, Windows, SysUtils, FileCtrl, Misc;

type
  TTrackInfo = class(TObject)
  public
    TrackID:Integer;
    RecSize:Integer;
    RecsPerDay:Integer;
    LastRecTime:TDateTime;
    constructor Create(aID,aSize,aRPD:Integer);
  end;

  TMyFile = class(TFileStream)
    LastAccess:Integer;
  end;

  TFileManager = class(TObject)
  protected
    FileNames:TStringList;
    FilePaths:TStringList;
    Tracks:TByteStringList;
    Files:TByteStringList;
    MaxOpenFiles:Integer;
    AutoCloseTime:Integer;
    ReadOnly:Boolean;
    EventsPath:String;
    function GetMyFile(const FilePath,FileName:String; Mode:Word; Size:Integer):TMyFile;
    procedure AddToFiles(NewMF:TMyFile; const StrID:String);
  public
    constructor CreateFromIniSection(Ini:TIniFile; const Section:String);
    function GetFileStream(TI:TTrackInfo; Date:TDateTime;
      ForReading:Boolean):TFileStream;
    function GetTrackInfo(TrackID:Integer):TTrackInfo;
    function FindTrackInfo(TrackID:Integer):TTrackInfo;
    destructor Destroy;override;
  public
    procedure SetTrackInfo(TrackID, RecSize, RecsPerDay: Integer);
    procedure GetLastRecTime(TrackID:Integer;var Time:TDateTime);
    procedure timerProc;
    procedure writeRecords(TrackID: Integer; FromTime: TDateTime;
      Count: Integer; const Data: WideString);
    procedure readRecords(TrackID: Integer; FromTime: TDateTime;
      Count: Integer; var Data: WideString);
    procedure StrToTrackID(const Str: String; var TrackID: Integer);
  end;

function ApplySubstitutions(const Src:AnsiString; TrackID:Integer; const Date:TDateTime):AnsiString;
function GetStrTrackTimeID(TrackID:Integer;const Time:TDateTime):AnsiString;
function GetStrTrackID(TrackID:Integer):AnsiString;
function GetInvStrTrackID(TrackID:Integer):AnsiString;

implementation

type
  TByteArray=packed array[0..MaxInt-1] of Byte;

const
  Code:PChar='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

var
  SubsList:TStringList;

{ TFileManager }

constructor TFileManager.CreateFromIniSection(Ini:TIniFile; const Section:String);
var
  SV:TStringList;
  VName:String;
  FileName,DefFileName:String;
  i:Integer;
  s:String;
begin
  inherited Create;
  FilePaths:=TStringList.Create;
  FileNames:=TStringList.Create;
  Files:=TByteStringList.Create;
  Files.Sorted:=True;
  Tracks:=TByteStringList.Create;
  Tracks.Sorted:=True;

  AutoCloseTime:=Ini.ReadInteger(Section,'AutoCloseTime',20);
  MaxOpenFiles:=Ini.ReadInteger(Section,'MaxOpenFiles',1);
  ReadOnly:=Ini.ReadInteger(Section,'ReadOnly',0)<>0;
  if MaxOpenFiles<1 then MaxOpenFiles:=1;

  SV:=TStringList.Create;
  Ini.ReadSectionValues(Section,SV);
  for i:=0 to SV.Count-1 do begin
    VName:=SV.Names[i];
    if Pos('FilePath',VName)=1 then begin
      FilePaths.Add(SV.Values[VName]);
      FileName:=SV.Values['FileName'+Copy(VName,9,Length(VName)-9+1)];
      if DefFileName='' then DefFileName:=FileName
      else if FileName='' then FileName:=DefFileName;
      FileNames.Add(FileName);
    end;
  end;
  SV.Free;

  s:=FilePaths[0];
  for i:=1 to Length(s) do begin
    if s[i]='\'
    then EventsPath:=Copy(s,1,i-1)
    else if s[i]='%'
    then break;
  end;
  EventsPath:=EventsPath+'\Events';
end;

destructor TFileManager.Destroy;
var
  i:Integer;
begin
  FilePaths.Free;
  FileNames.Free;
  for i:=0 to Files.Count-1 do TMyFile(Files.Objects[i]).Free;
  Files.Free;
  for i:=0 to Tracks.Count-1 do TTrackInfo(Tracks.Objects[i]).Free;
  Tracks.Free;
  inherited;
end;

function TFileManager.GetMyFile(const FilePath,
  FileName: String; Mode:Word; Size:Integer): TMyFile;
var
  FullName:String;
  Count:Integer;
  Block:packed array[1..1024*128] of byte;
begin
  Result:=nil;
  FullName:=FilePath+'\'+FileName;
  if (Mode<>fmCreate) and not FileExists(FullName) then exit;
  try
    if ForceDirectories(FilePath)
    then begin
      Result:=TMyFile.Create(FullName,Mode);
      if Mode and fmCreate=fmCreate then begin
        FillChar(Block,SizeOf(Block),0);
        try
          while Size>0 do begin
            if SizeOf(Block)<=Size then Count:=SizeOf(Block) else Count:=Size;
            Result.Write(Block,Count);
            Dec(Size,Count);
          end;
        except
          Result.Free;
          DeleteFile(FullName);
          raise;
        end;
        Result.Free;
        Result:=TMyFile.Create(FullName,fmOpenReadWrite or fmShareDenyWrite);
      end
      else if (Size>0) and (Result.Size<>Size) then begin
        Result.Free;
        Result:=nil;
      end;
    end;
  except
    if Result<>nil then Result.Free;
    Result:=nil;
  end;
end;

function TFileManager.GetFileStream(TI: TTrackInfo;
  Date: TDateTime; ForReading:Boolean): TFileStream;
type
  TFileModeArr=array[0..2] of Word;
const
  FileModeRW:TFileModeArr=(fmOpenReadWrite or fmShareDenyNone, fmOpenRead or fmShareDenyNone, fmCreate);
  //FileModeRW:TFileModeArr=(fmOpenReadWrite or fmShareDenyWrite,fmOpenRead or fmShareDenyWrite,fmCreate or fmShareDenyWrite);
  FileModeRO:TFileModeArr=(fmOpenRead or fmShareDenyWrite,fmOpenRead or fmShareDenyWrite,fmOpenRead or fmShareDenyWrite);
var
  FN,FP:String;
  MF:TMyFile;
  i,m,me:Integer;
  StrID:String;
  DayDataSize:Integer;
  FileMode:^TFileModeArr;
begin
  Result:=nil;
  ReplaceTime(Date,0);
  StrID:=GetStrTrackTimeID(TI.TrackID,Date);
  if Files.Find(StrID,i) then begin
    MF:=TMyFile(Files.Objects[i]);
    MF.LastAccess:=0;
    Result:=MF;
    exit;
  end;
  DayDataSize:=TI.RecSize*TI.RecsPerDay;
  if ReadOnly then begin
    FileMode:=@FileModeRO;
    me:=0;
  end
  else begin
    if ForReading then me:=1 else me:=2;
    FileMode:=@FileModeRW;
  end;
  if DayDataSize>0 then
    for m:=0 to me do begin
      for i:=0 to FilePaths.Count-1 do begin
        FP:=ApplySubstitutions(FilePaths[i],TI.TrackID,Date);
        FN:=ApplySubstitutions(FileNames[i],TI.TrackID,Date);
        MF:=GetMyFile(FP,FN,FileMode[m],DayDataSize);
        if MF<>nil then begin
          AddToFiles(MF,StrID);
          Result:=MF;
          exit;
        end;
      end;
    end
  else begin
    FP:=EventsPath;
    FN:=ApplySubstitutions('%NPP_ID%%SectID%%SensID%.bin',TI.TrackID,0);
    for m:=0 to me do begin
      MF:=GetMyFile(FP,FN,FileMode[m],0);
      if MF<>nil then begin
        AddToFiles(MF,StrID);
        Result:=MF;
        exit;
      end;
    end;
  end;
  if not ForReading then raise Exception.Create('TFileManager.GetFileStream:Unable to find or create file');
end;

procedure TFileManager.timerProc;
var
  i:Integer;
  F:TMyFile;
begin
  i:=Files.Count-1;
  while i>=0 do begin
    F:=TMyFile(Files.Objects[i]);
    Inc(F.LastAccess);
    if F.LastAccess>AutoCloseTime then begin
      Files.Delete(i);
      F.Free;
    end;
    Dec(i);
  end;
end;

procedure TFileManager.AddToFiles;
var
  i,iMax:Integer;
  Max:Integer;
begin
  while Files.Count>=MaxOpenFiles do begin
    Max:=TMyFile(Files.Objects[0]).LastAccess;
    iMax:=0;
    for i:=1 to Files.Count-1 do begin
      if TMyFile(Files.Objects[i]).LastAccess > Max then begin
        Max:=TMyFile(Files.Objects[i]).LastAccess;
        iMax:=i;
      end;
    end;
    TMyFile(Files.Objects[iMax]).Free;
    Files.Delete(iMax);
  end;
  Files.AddObject(StrID,NewMF);
end;

procedure TFileManager.setTrackInfo;
var
  StrID:String;
  i:Integer;
  TI:TTrackInfo;
begin
  StrID:=GetStrTrackID(TrackID);
  if Tracks.Find(StrID,i) then begin
    TI:=TTrackInfo(Tracks.Objects[i]);
    if (TI.RecSize<>RecSize) or (TI.RecsPerDay<>RecsPerDay)
    then raise Exception.Create('Несовпадение характеристик трека :)');
  end
  else begin
    TI:=TTrackInfo.Create(TrackID,RecSize,RecsPerDay);
    Tracks.AddObject(StrID,TI);
  end;
end;

procedure TFileManager.GetLastRecTime;
var
  TI:TTrackInfo;
begin
  TI:=GetTrackInfo(TrackID);
  if TI.RecsPerDay=0 then begin
    Time:=GetFileStream(TI,0,False).Size;
  end
  else Time:=TI.LastRecTime;
end;

function TFileManager.GetTrackInfo;
begin
  Result:=FindTrackInfo(TrackID);
  if Result=nil
  then raise Exception.Create('TFileManager.GetTrackInfo:Unknown TrackID');
end;

function TFileManager.FindTrackInfo;
var
  i:Integer;
begin
  if Tracks.Find(GetStrTrackID(TrackID),i)
  then Result:=TTrackInfo(Tracks.Objects[i])
  else Result:=nil;
end;

procedure TFileManager.writeRecords;
var
  TI:TTrackInfo;
  FS:TFileStream;
  DataPos,FilePos,BlockSize:Integer;
  P:^TByteArray;
  LRT:TDateTime;
begin
  if ReadOnly then exit;
  if Count<=0
  then raise Exception.Create('TFileManager.writeRecords:Count<=0');
  try
    TI:=GetTrackInfo(TrackID);
    if TI.RecsPerDay=0 then begin
        FS:=GetFileStream(TI,0,False);
        FS.Seek(0,soFromEnd);
        FS.Write(Data[1],Count);
        exit;
    end;
    P:=Addr(Data[1]);
    FilePos:=Round(Frac(FromTime)*TI.RecsPerDay);
    LRT:=FromTime+Count/TI.RecsPerDay;
    DataPos:=0;
    if Count>TI.RecsPerDay-FilePos
    then BlockSize:=TI.RecsPerDay-FilePos
    else BlockSize:=Count;
    if LRT>TI.LastRecTime then TI.LastRecTime:=LRT;
    repeat
      FS:=GetFileStream(TI,FromTime,False);
      if FS=nil then break;
      FS.Seek(FilePos*TI.RecSize,soFromBeginning);
      FS.Write(P[DataPos*TI.RecSize],BlockSize*TI.RecSize);
      Inc(DataPos,BlockSize);
      Dec(Count,BlockSize);
      if Count>0 then begin
        if Count>TI.RecsPerDay
        then BlockSize:=TI.RecsPerDay
        else BlockSize:=Count;
        FromTime:=Trunc(FromTime)+1;
      end
      else break;
      FilePos:=0;
    until 2*2=5;
  except
  end;
end;

procedure TFileManager.readRecords;
var
  TI:TTrackInfo;
  FS:TFileStream;
  DataPos,FilePos,BlockSize,Size:Integer;
  P:^TByteArray;
begin
  if Count<=0
  then raise Exception.Create('TFileManager.readRecords:Count<=0');
  TI:=GetTrackInfo(TrackID);
  if TI.RecsPerDay=0 then begin
      SetLength(Data,(Count+1) shr 1);
      FS:=GetFileStream(TI,0,False);
      FS.Seek(Trunc(FromTime),soFromBeginning);
      Count:=FS.Read(Data[1],Count);
      SetLength(Data,(Count+1) shr 1);
      if odd(Count) then begin
        P:=Addr(Data[1]);
        P[Count]:=0;
      end;
      exit;
  end;
  FilePos:=Round(Frac(FromTime)*TI.RecsPerDay);
  Size:=Count*TI.RecSize+1;
  SetLength(Data,Size shr 1); FillChar(Data[1],Size,0);
  P:=Addr(Data[1]);
  DataPos:=0;
  if Count>TI.RecsPerDay-FilePos
  then BlockSize:=TI.RecsPerDay-FilePos
  else BlockSize:=Count;
  repeat
    FS:=GetFileStream(TI,FromTime,True);
    if FS<>nil then begin
      FS.Seek(FilePos*TI.RecSize,soFromBeginning);
      FS.Read(P[DataPos*TI.RecSize],BlockSize*TI.RecSize);
    end
    else FillChar(P[DataPos],BlockSize*TI.RecSize,0);
    Inc(DataPos,BlockSize);
    Dec(Count,BlockSize);
    if Count>0 then begin
      if Count>TI.RecsPerDay
      then BlockSize:=TI.RecsPerDay
      else BlockSize:=Count;
      FromTime:=Trunc(FromTime)+1;
    end
    else break;
    FilePos:=0;
  until 2*2=5;
end;


procedure TFileManager.StrToTrackID(const Str: String;
  var TrackID: Integer);

  function MyPos(c:Char):Integer;
  begin
    Result:=Pos(c,Code);
    if Result>0
    then Dec(Result)
    else raise Exception.Create('FileManager.StrToTrackID : Invalid TrackID string'); 
  end;
  
var
  i:Integer;
begin
  TrackID:=0;
  if Length(Str)<4 then i:=Length(Str) else i:=4;
  for i:=1 to i
  do TrackID:=TrackID or (MyPos(Str[i]) shl ((4-i) shl 3));
end;

{ TTrackInfo }

constructor TTrackInfo.Create;
begin
  inherited Create;
  TrackID:=aID;
  if (aSize<0) or (aRPD<0)
  then raise Exception.Create('TTrackInfo.Create : bad track parameters');
  RecSize:=aSize;
  RecsPerDay:=aRPD;
end;

function ApplySubstitutions;
var
  Year,Month,Day:Word;
  B,E,SubsNum:Integer;
  Tag:Boolean;

function getCode(i:Byte):Char;
begin if i<36 then Result:=Code[i] else Result:='_'; end;

function sNPP_ID:String; begin Result:=getCode(TrackID shr 24 and $FF); end;
function sSectID:String; begin Result:=getCode(TrackID shr 16 and $FF); end;
function sSensID:String; begin Result:=getCode(TrackID shr 8 and $FF); end;
function sYear:String; begin Str(Year:4,Result); end;
function sYear2:String; begin Result:=Copy(sYear,3,2); end;
function sMonth:String;
begin
  Str(Month,Result); if Length(Result)=1 then Result:='0'+Result;
end;
function sDay:String;
begin
  Str(Day,Result); if Length(Result)=1 then Result:='0'+Result;
end;
function sMonthHex:String; begin Result:=getCode(Month); end;
function sSpecID:String; begin Result:=getCode(TrackID and $FF); end;

begin
  DecodeDate(Date,Year,Month,Day);
  B:=1;
  Tag:=False;
  Result:='';
  for E:=1 to Length(Src) do begin
    if Src[E]='%' then begin
      if Tag then begin
        SubsNum:=SubsList.IndexOf(Copy(Src,B,E-B));
        case SubsNum of
          0:Result:=Result+sNPP_ID;   // NPP_ID
          1:Result:=Result+sSectID;   // SectID
          2:Result:=Result+sSensID;   // SensID
          3:Result:=Result+sYear;     // Year
          4:Result:=Result+sYear2;    // Year2
          5:Result:=Result+sMonth;    // Month
          6:Result:=Result+sMonthHex; // MonthHex
          7:Result:=Result+sDay;      // Day
          8:Result:=Result+sSpecID;   // SpecID
        end;
        B:=E+1;
        Tag:=False;
      end
      else begin
        Result:=Result+Copy(Src,B,E-B);
        B:=E+1;
        Tag:=True;
      end;
    end;
  end;
  if not Tag then Result:=Result+Copy(Src,B,Length(Src)-B+1);
end;

function GetInvStrTrackID;
type
  TChar4Array=packed array[1..4] of Char;
var
  A:TChar4Array absolute TrackID;
begin
  SetLength(Result,4);
  Result[1]:=A[4];
  Result[2]:=A[3];
  Result[3]:=A[2];
  Result[4]:=A[1];
end;

function GetStrTrackID;
begin
  SetLength(Result,4);
  Integer((@(Result[1]))^):=TrackID;
end;

function GetStrTrackTimeID;
type
  TType=packed record
    I:Integer;
    T:TDateTime;
  end;
begin
  SetLength(Result,12);
  with TType((@(Result[1]))^) do begin
    I:=TrackID;
    T:=Time;
  end;
end;

procedure Initialize;
begin
  SubsList:=TStringList.Create;

  SubsList.Add('NPP_ID');    // NPP      - Код НПП
  SubsList.Add('SectID');    // SectID   - Код участка НПП
  SubsList.Add('SensID');    // SensID   - Код датчика на участке НПП
  SubsList.Add('Year');      // Year     - Год (4 цифры)
  SubsList.Add('Year2');     // Year2    - Год (2 последние цифры)
  SubsList.Add('Month');     // Month    - Месяц (2 цифры)
  SubsList.Add('MonthHex');  // MonthHex - Месяц (1 шестнадцатеричная цифра)
  SubsList.Add('Day');       // Day      - Число месяца (2 цифры)
  SubsList.Add('SpecID');    // SpecID   - Дополнительный спец. код
end;

initialization
  Initialize;
finalization
  SubsList.Free;
end.

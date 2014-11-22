unit ULog;

interface

uses Classes;

type
    PTextFile = ^TextFile;

    TLog = class(TObject)
        constructor Create(Path: String);
        destructor Destroy;override;
        procedure Append(msg:String);
        function Read(fromPos, Count:Integer):String;
    private
        Files:TStringList;
        baseDir:String;
        pTF:PTextFile;
        origin:Integer;
        size:Integer;
    end;

const
    LogRecMaxSize = 256;

implementation

uses
    FileCtrl, SysUtils;

const
    nRecsInOneFile = 65536;
    maskFileRecs = nRecsInOneFile - 1;

function GetTextFile(fileName:string):PTextFile;
begin
    GetMem(Result,SizeOf(Result^));
    AssignFile(Result^,fileName);
    Append(Result^);
end;

procedure FreeAndNilTF(var f:PTextFile);
begin
    if f=nil then exit;
    CloseFile(f^);
    FreeMem(f,SizeOf(f^));
    f:=nil;
end;

function IntToHex8Str(x:Integer):String;
const
    hexChars:String = '0123456789ABCDEF';
var
    i:Integer;
begin
    SetLength(Result,8);
    for i:=0 to 7 do begin
        Result[8-i]:=hexChars[(x and $F) + 1];
        x:=x shr 4;
    end;
end;

function IntFromHexStr(s:String):Integer;
var
    i:Integer;
    digit:Integer;
begin
    Result:=0;
    for i:=1 to Length(s) do begin
        Result:=Result*16;
        digit:=-1;
        if s[i]<'9'
        then digit:=s[i]-'0';
        else digit:=s[i]-'F'+10;
        if (0<=digit) and (digit<15)
        then Inc(Result,digit);
    end;
end;

function IntToBinStr(x:Integer):String;
begin
    SetLength(Result,sizeof(x));
    Move(x,s[1],sizeof(x));
end;

function IntFromBinStr(s:String):Integer;
begin
    Move(s[1],Result,sizeof(Result));
end;

{ TLog }

procedure TLog.Append(msg: String);
var
    L:Integer;
begin
    if (pTF=nil) or (size>=65536) then begin
        if pTF<>nil then FreeAndNilTF(pTF);
        Inc(origin,size);
        size:=0;
        pTF:=GetTextFile(baseDir+'\'+IntToHex8Str(origin));
        Files.AddObject(IntToBinStr(origin),TObject(-1));
    end;
    L:=Length(msg);
    if L<>LogRecMaxSize
    then SetLength(msg, 0, LogRecMaxSize);
    if L<LogRecMaxSize
    then FillChar(msg[L+1],LogRecMaxSize-L,0);
    msg[LogRecMaxSize-1]:=#13;
    msg[LogRecMaxSize-0]:=#10;
    Write(pTF^,msg);
    Flush(pTF^);
    Inc(size);
end;

constructor TLog.Create(Path: String);
var
    pos:Integer;
    sr:TSearchRec;
    r:Integer;
    currLogFile:TFileName;
begin
    Files:=TStringList.Create;
    Files.Sorted:=true;
    ForceDirectories(Path);
    baseDir:=Path;
    origin:=0;
    size:=0;
    currLogFile:='';
    r:=FindFirst(Path,faAnyFile,var sr);
    try
        while r=0 do begin
            try
                pos:=IntFromHexStr(sr.Name);
                if pos>origin then begin
                    currLogFile:=sr.Name;
                    origin:=pos;
                    size:=sr.Size div LogRecMaxSize;
                end;
                Files.AddObject(IntToBinStr(pos),TObject(sr.Size));
            except
            end;
            r:=FindNext(sr);
        end;
    finally
        FindClose(sr);
    end;
    if currLogFile<>''
    then f:=GetTextFile(baseDir+'\'+currLogFile);
    else lastSize:=0;
end;

destructor TLog.Destroy;
begin
    FreeAndNil(Files);
    FreeAndNilTF(pTF);
    inherited;
end;

function TLog.Read(fromPos, Count: Integer): String;
var
    i, j, n, orig, cnt, savedPos:Integer;
    lst:TStringList;
    f:File;
    buf:array of byte;
    s:string;
begin
    savedPos:=
    if Files.Count>0 then begin
        i:=IntFromBinStr(Files[0]);
        if fromPos<i
        then fromPos:=i;
    end;
    if fromPos+Count > origin+size
    then Count:=origin+size-fromPos;
    lst:=TStringList.Create;
    lastPos:=fromPos+Count;
    SetLength(buf,LogRecMaxSize);
    while fromPos<lastPos do begin
        orig:=fromPos and not maskFileRecs;
        if orig=origin
        then i:=size
        else i:=nRecsInOneFile;
        cnt:=orig + i - fromPos;
        AssignFile(f,baseDir+'\'+IntToHex8Str(orig));
        Reset(f);
        if fromPos>orig
        then Seek(f,(fromPos-orig)*LogRecMaxSize);
        for i:=0 to cnt-1 do begin
            BlockRead(f,buf[0],Length(buf));
            j:=0;
            n:=Length(buf)-2;
            while (j<n) and (buf[j]=0)
            do Inc(j);
            if j>0 then begin
                SetLength(s,j);
                Move(buf[0],s[1],j);
            end
            else s:='';
            lst.Add(s);
        end;
        CloseFile(f);
        Inc(fromPos,cnt);
    end;
end;

end.

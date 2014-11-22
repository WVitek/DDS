unit Common;

interface

type
  TArchSyncCommand=(
    ascmdConnect,
    ascmdCheckConnection,
    ascmdDisconnect,
    ascmdGetState
  );
  TLongint=record
    case Integer of
    0: (
      V: Longint);
    1: (
      Lo: Word;
      Hi: Word);
  end;

function IntParam(const S:String):Integer;
function SendASCmd(Cmd:TArchSyncCommand; Param:Word):Cardinal;

var
  WM_MYQUERY,WM_MYANSWER:Cardinal;

implementation

uses
  SysUtils,Windows;

procedure SendAsyncProc(
  hwnd:THandle;     // handle of destination window
  Msg:Cardinal;    // message
  Data:DWord;  // application-defined value
  Res:LRESULT   // result of message processing
);stdcall;
var
  MsgRes:^LRESULT absolute Data;
begin
  MsgRes^:=Res;
end;

function SendASCmd(Cmd:TArchSyncCommand; Param:Word):Cardinal;
var
  wParam:TLongint;
begin
  wParam.Lo:=Param;
  wParam.Hi:=Word(Cmd);
  Result:=255;
  if not SendMessageCallback(HWND_BROADCAST,WM_MYQUERY,wParam.V,0,@SendAsyncProc,Cardinal(@Result))
  then Result:=255;
  if Result=0 then Result:=255;
end;

function IntParam(const S:String):Integer;
begin
  Result:=255;
  try
    Result:=StrToInt(S);
  except
    Halt(255);
  end;
end;

initialization
  WM_MYQUERY:=RegisterWindowMessage('DDS_ARCHSYNC_QUERY_MSG');
  WM_MYANSWER:=RegisterWindowMessage('DDS_ARCHSYNC_ANSWER_MSG');
end.
 
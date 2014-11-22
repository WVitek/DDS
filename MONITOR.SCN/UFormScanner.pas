unit UFormScanner;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, Grids;

type
  TGetStringsEvent = procedure(Sender:TObject; SS:TStrings) of object;

  TFormScanner = class(TForm)
    stStatus: TStaticText;
    gbControls: TGroupBox;
    Label1: TLabel;
    meStartTime: TMaskEdit;
    Label2: TLabel;
    meStopTime: TMaskEdit;
    BtnStart: TButton;
    sgLog: TStringGrid;
    BtnSpy: TButton;
    procedure BtnStartClick(Sender: TObject);
    procedure sgLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    procedure sgLogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgLogColumnMoved(Sender: TObject; FromIndex,
      ToIndex: Integer);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    CurCol,CurRow,CursorRow:Integer;
    StrBuf:String;
    ColOrder:TList;
  public
    { Public declarations }
    OnStart:TNotifyEvent;
    OnGetRow:TGetStringsEvent;
    OnCaptureKey:TKeyPressEvent;
    OnIsShortCut:function(var Msg:TWMKey):Boolean of object;
    StartTime,StopTime:TDateTime;
    procedure Log(Msg:String);
    procedure SortRows;
  end;

var
  FormScanner: TFormScanner;

implementation

uses
  UScanner;

{$R *.DFM}

procedure TFormScanner.BtnStartClick(Sender: TObject);
begin
  try
    StartTime:=StrToDateTime(meStartTime.EditText);
    if Sender = BtnStart then begin
      StopTime:=StrToDateTime(meStopTime.EditText);
      if StopTime<=StartTime
      then raise Exception.Create('Задан неверный временной интервал');
    end
    else StopTime:=0;
  except
    on E:Exception do begin
      Application.MessageBox( PChar(E.Message),'Ошибка',MB_OK or MB_ICONHAND );
      exit;
    end;
  end;
  if Sender=BtnStart then begin
    BtnSpy.Visible:=False;
    BtnStart.Enabled:=False;
  end
  else begin
    BtnStart.Visible:=False;
    BtnSpy.Enabled:=False;
    meStopTime.Visible:=False;
  end;
  gbControls.Enabled:=False;
  if Assigned(OnStart) then OnStart(Self);
end;

procedure TFormScanner.Log(Msg: String);
var
  c:Char;
  i:Integer;
begin
  i:=1;
  while i<=Length(Msg) do begin
    c:=Msg[i];
    case c of
    #9,#13:
      begin
        if sgLog.RowCount<=CurRow then begin
          sgLog.RowCount:=CurRow+1;
          if CurRow=1 then sgLog.FixedRows:=1;
        end;
        if sgLog.ColCount<=CurCol then begin
          sgLog.ColCount:=CurCol+1;
        end;
        sgLog.Cells[CurCol,CurRow]:=StrBuf;
        StrBuf:='';
        if c=#9 then Inc(CurCol)
        else begin Inc(CurRow); CurCol:=0; end
      end;
    #0..#8,#10..#12,#14..#31:;
    else StrBuf:=StrBuf+c;
    end;
    Inc(i);
  end;
  if ColOrder.Count<sgLog.ColCount then begin
    ColOrder.Count:=sgLog.ColCount;
    for i:=0 to ColOrder.Count-1 do ColOrder[i]:=Pointer(i);
  end;
end;

procedure TFormScanner.sgLogClick(Sender: TObject);
var
  Row:TStringList;
  OCO:array of Integer; // Original Columns Order
  i:Integer;
begin
  if Assigned(OnGetRow) and (sgLog.Row<>CursorRow) then begin
    CursorRow:=sgLog.Row;
    SetLength(OCO,ColOrder.Count);
    for i:=0 to High(OCO) do OCO[Integer(ColOrder[i])]:=i;
    Row:=TStringList.Create;
    for i:=0 to High(OCO) do Row.Add(sgLog.Cells[OCO[i],CursorRow]);
    OnGetRow(Self,Row);
    Row.Free;
  end;
end;

procedure TFormScanner.FormCreate(Sender: TObject);
begin
  Left:=GetSystemMetrics(SM_CXFULLSCREEN)+GetSystemMetrics(SM_CXBORDER)-Width;;
  Top:=GetSystemMetrics(SM_CYFULLSCREEN)+GetSystemMetrics(SM_CYCAPTION)-Height;
  ColOrder:=TList.Create;
end;

procedure TFormScanner.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if not BtnStart.Enabled and Assigned(OnCaptureKey)
  then OnCaptureKey(Self,Key);
end;

function TFormScanner.IsShortCut(var Message: TWMKey): Boolean;
begin
  Result:=assigned(OnIsShortCut) and OnIsShortCut(Message) or
    inherited IsShortCut(Message);
end;


procedure TFormScanner.SortRows;
var
  Rows,Row:TStringList;
  i:Integer;
begin
  Rows:=TStringList.Create;
  Rows.Sorted:=True;
  Rows.Duplicates:=dupAccept;
  for i:=1 to sgLog.RowCount-1 do begin
    Row:=TStringList.Create;
    Row.Assign(sgLog.Rows[i]);
    Rows.AddObject(Row.Text,Row)
  end;
  for i:=1 to sgLog.RowCount-1 do begin
    Row:=TStringList(Rows.Objects[i-1]);
    sgLog.Rows[i].Assign(Row);
    Row.Free;
  end;
  Rows.Free;
end;

procedure TFormScanner.sgLogMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col,Row:Integer;
begin
  sgLog.MouseToCell(X,Y,Col,Row);
  if Row=0 then SortRows;
end;

procedure TFormScanner.sgLogColumnMoved(Sender: TObject; FromIndex,
  ToIndex: Integer);
var
  P:Pointer;
begin
  P:=ColOrder[FromIndex]; ColOrder.Delete(FromIndex);
  ColOrder.Insert(ToIndex,P);
end;

procedure TFormScanner.FormDestroy(Sender: TObject);
begin
  ColOrder.Free;
  FormScanner:=nil;
end;

end.

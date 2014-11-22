unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ExtCtrls, IniFiles, Misc, NMUDP, SensorTypes, Menus,
  DdhAppX, ImgList, StdCtrls, ArchManThd, ComCtrls;

type
  TFormEventsView = class(TForm)
    AppExt: TDdhAppExt;
    TrayPopupMenu: TPopupMenu;
    pmiClose: TMenuItem;
    pmiAbout: TMenuItem;
    ListView: TListView;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pmiAboutClick(Sender: TObject);
    procedure pmiCloseClick(Sender: TObject);
    procedure AppExtLBtnDown(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
    function LoadEvents(fromPos:Integer; Size:Integer):TStringList;
    procedure RefreshView;
  public
    { Public declarations }
    AMThd:TArchManThread;
    TrackID:Integer;
  end;

var
  FormEventsView: TFormEventsView;

implementation

{$R *.DFM}

procedure TFormEventsView.FormCreate(Sender: TObject);
var
  i,j:Integer;
  key,val:String;
begin
  InitFormattingVariables;
  AMThd:=TArchManThread.Create;//('127.0.0.1');
  AMThd.Resume;
  TrackID:=0;

  for i:=1 to ParamCount do begin
     val := ParamStr(i);
     j:=Pos('=',val);
     if j=0 then continue;
     key:=Copy(val,1,j-1);
     val:=Copy(val,j+1,Length(val)-j);
     if key='track'
     then AMThd.StrToTrackID(val,TrackID)
     else if key='title' then begin
         Caption:=val;
         Application.Title:=val;
         AppExt.TrayHint:=val;
         AppExt.Title:=val;
     end;
  end;

  if TrackID=0
  then AMThd.StrToTrackID('EVT',TrackID);
  AMThd.setTrackInfo(TrackID,0,0);

  ListView.DoubleBuffered:=true;
  RefreshView;
end;

procedure TFormEventsView.FormDestroy(Sender: TObject);
begin
  AMThd.Free;
end;

procedure TFormEventsView.pmiAboutClick(Sender: TObject);
begin
  Application.MessageBox(
    'СКУ'#13#13+
    'Программа просмотра событий'#13+
    '(c) 2000-2002 ООО "Компания Телекомнур"'#13+
    'e-mail: test@mail.rb.ru',
    'О программе',
    MB_ICONINFORMATION or MB_OK);
end;

procedure TFormEventsView.pmiCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormEventsView.AppExtLBtnDown(Sender: TObject);
var
  P:TPoint;
begin
  GetCursorPos(P);
  TrayPopupMenu.Popup(P.x,P.y);
end;

function TFormEventsView.LoadEvents(fromPos, Size: Integer): TStringList;
var
    W:WideString;
    P:PByteArray;
    i,iBeg:Integer;
    prevCR:Boolean;
    s:String;
begin
    AMThd.readRecords(TrackID,fromPos,Size,W);
    Result:=TStringList.Create;
    Size:=Length(W)*2;
    P:=@W[1];
    PrevCR:=false;
    iBeg:=0;
    for i:=0 to Size-1 do begin
        case P[i] of
        13: PrevCR:=true;
        10: if PrevCR then begin
                SetLength(s,i-iBeg-2);
                Move(P[iBeg],s[1],Length(s));
                iBeg:=i+1;
                Result.AddObject(s,TObject(fromPos+iBeg));
                PrevCR:=false;
            end;
        else PrevCR:=false;
        end;
    end;
end;

const
    nRecsToShow = 1000;

procedure TFormEventsView.RefreshView;
var
    dt:TDateTime;
    items:TListItems;
    sl:TStringList;
    LastRec:Integer;
    i,n:Integer;
    j,k:Integer;
    s:String;
    li:TListItem;
begin
    AMThd.getLastRecTime(TrackID,dt);
    items:=ListView.Items;
    if (items.Count=0)
    then LastRec:=0
    else begin
        LastRec:=Integer(items[0].Data);
        if LastRec>=Trunc(dt)
        then exit;
    end;
    sl:=LoadEvents(LastRec,128*1024);
    items.BeginUpdate;
    try
      if sl.Count<nRecsToShow then begin
        while sl.Count+items.Count > nRecsToShow
        do items.Delete(items.Count-1);
        n:=sl.Count;
      end
      else begin
          items.Clear;
          n:=nRecsToShow;
      end;
      for i:=0 to n-1 do begin
          s:=sl[i];
          li:=items.Insert(0);
          k:=1; j:=1;
          while j<=Length(s) do begin
              if s[j]=#9 then begin
                  if k=1
                  then li.Caption:=Copy(s,k,j-k)
                  else li.SubItems.Add(Copy(s,k,j-k));
                  k:=j+1;
              end;
              Inc(j);
          end;
          if k<j
          then li.SubItems.Add(Copy(s,k,j-k));
          li.Data:=sl.Objects[i];
      end;
    finally
      items.EndUpdate;
      sl.Free;
    end;
end;

procedure TFormEventsView.TimerTimer(Sender: TObject);
begin
    RefreshView;
end;

end.

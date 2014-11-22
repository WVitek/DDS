unit UFormPipe;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Math,
  Dialogs, Buttons, ExtCtrls , UFrameGroup, SensorTypes,
  IniFiles, Misc, ArchManThd, Menus, DataTypes, DataTypes2, ShellAPI, FileCtrl,
  SyncObjs, DblGraphics, PipeOptions, StdCtrls, MessageForm, ActnList;

type
  TFormPipe = class(TForm)
    Bevel: TBevel;
    menuSys: TPopupMenu;
    miCapacity: TMenuItem;
    miCap001: TMenuItem;
    miCap005: TMenuItem;
    miCap015: TMenuItem;
    miCap030: TMenuItem;
    miCap060: TMenuItem;
    miCap120: TMenuItem;
    miCap240: TMenuItem;
    miScrollLock: TMenuItem;
    miSpyMode: TMenuItem;
    miImage: TMenuItem;
    miCopy: TMenuItem;
    miNegative: TMenuItem;
    miMode: TMenuItem;
    miDecCapacity: TMenuItem;
    miIncCapacity: TMenuItem;
    miCapSep1: TMenuItem;
    miCopyForPrinting: TMenuItem;
    miGraphOption: TMenuItem;
    miGroupOptions: TMenuItem;
    BtnFake: TButton;
    miArcView: TMenuItem;
    miArcViewDec010: TMenuItem;
    miArcViewDec001: TMenuItem;
    miArcViewDec100: TMenuItem;
    miArcViewDec005: TMenuItem;
    miArcViewDec050: TMenuItem;
    miArcViewDec500: TMenuItem;
    miArcViewInc005: TMenuItem;
    miArcViewInc010: TMenuItem;
    miArcViewInc050: TMenuItem;
    miArcViewInc100: TMenuItem;
    miArcViewInc500: TMenuItem;
    miArcViewInc001: TMenuItem;
    miCalculate: TMenuItem;
    miSetArcTime: TMenuItem;
    miVertScale: TMenuItem;
    miZoomInV: TMenuItem;
    miZoomOutV: TMenuItem;
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormConstrainedResize(Sender: TObject; var MinWidth,
      MinHeight, MaxWidth, MaxHeight: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure miCopyClick(Sender: TObject);
    procedure miAnyCapacityClick(Sender: TObject);
    procedure miScrollLockClick(Sender: TObject);
    procedure AnyArcViewClick(Sender: TObject);
    procedure miSpyModeClick(Sender: TObject);
    procedure miNegativeClick(Sender: TObject);
    procedure miDecCapacityClick(Sender: TObject);
    procedure miIncCapacityClick(Sender: TObject);
    procedure miGraphOptionClick(Sender: TObject);
    procedure miGroupOptionsClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure miCalculateClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure miSetArcTimeClick(Sender: TObject);
    procedure miZoomOutVClick(Sender: TObject);
    procedure miZoomInVClick(Sender: TObject);
  //***** IMonitorMaster
  public
    procedure QueryArcView(Time:TDateTime);
    procedure NotifyActivity(Sender:TObject);
  //***** IMonitorSlave
  private
    procedure Set_ArcEndTime(const Value:TDateTime);
    function Get_ArcEndTime:TDateTime;
    function Get_SpyEndTime: TDateTime;
    procedure Set_SpyMode(const Value:Boolean);
    function Get_SpyMode:Boolean;
    procedure Set_TimeCapacity(const Value: TDateTime);
    function Get_TimeCapacity: TDateTime;
    procedure Set_Negative(const Value:Boolean);
    function Get_Negative: Boolean;
  public
    property SpyMode:Boolean read Get_SpyMode write Set_SpyMode;
    property ArcEndTime:TDateTime read Get_ArcEndTime write Set_ArcEndTime;
    property SpyEndTime:TDateTime read Get_SpyEndTime;
    property TimeCapacity:TDateTime read Get_TimeCapacity write Set_TimeCapacity;
    property Negative:Boolean read Get_Negative write Set_Negative;
    procedure TimerProc;
  //*****
  private
    { Private declarations }
    function Get_Group(i: Integer): TFrameGroup;
    function Get_ScrollLock: Boolean;
    procedure Set_ScrollLock(const Value: Boolean);
  protected
    FTimeCapacity:TDateTime;
    Groups:TList;
    ActiveGroup:TFrameGroup;
    Section:String;
    procedure ScrollArcView(Step: TDateTime);
    procedure LockGroups;
    procedure UnlockGroups;
    procedure WMSysCommand(var Message:TWMSysCommand);message WM_SYSCOMMAND;
    property Group[i:Integer]:TFrameGroup read Get_Group;
    property ScrollLock:Boolean read Get_ScrollLock write Set_ScrollLock;
  public
    { Public declarations }
    procedure SaveCfg(Cfg:TIniFile);
    constructor CreateFromIniSection(AOwner:TComponent; Cfg:TIniFile;
      const Section:String);
    procedure InsertGroup(G:TFrameGroup);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    procedure CopyToClipboard;
  end;

var
  FormPipe: TFormPipe;

procedure CopyToClipboard(C:TCanvas; R:TRect);

implementation

uses Clipbrd, DaySelect, DateTimeSelect, Main;

{$R *.DFM}

procedure CopyToClipboard(C:TCanvas; R:TRect);
var
  BM:TBitmap;
  Dest:TRect;
begin
  BM:=TBitmap.create;
  Dest.Top:=0; Dest.Left:=0;
  Dest.Right:=R.Right-R.Left;
  Dest.Bottom:=R.Bottom-R.Top;
  BM.Width:=Dest.Right+1;
  BM.Height:=Dest.Bottom+1;
  try
    BM.Canvas.CopyRect(Dest,C,R);
    Clipboard.Assign(BM);
  finally
    BM.Free;
  end;
end;

procedure AppendItemToMenu(Item:TMenuItem; Menu: HMENU);
const
  IBreaks: array[TMenuBreak] of DWORD = (MFT_STRING, MFT_MENUBREAK, MFT_MENUBARBREAK);
  IChecks: array[Boolean] of DWORD = (MFS_UNCHECKED, MFS_CHECKED);
  IDefaults: array[Boolean] of DWORD = (0, MFS_DEFAULT);
  IEnables: array[Boolean] of DWORD = (MFS_DISABLED or MFS_GRAYED, MFS_ENABLED);
  IRadios: array[Boolean] of DWORD = (MFT_STRING, MFT_RADIOCHECK);
  ISeparators: array[Boolean] of DWORD = (MFT_STRING, MFT_SEPARATOR);
  IOwnerDraw: array[Boolean] of DWORD = (MFT_STRING, MFT_OWNERDRAW);
var
  MenuItemInfo: TMenuItemInfo;
  Caption: string;
  IsOwnerDraw: Boolean;
  ParentMenu: TMenu;
begin
  Caption := Item.Caption;
  if Item.Count > 0
  then MenuItemInfo.hSubMenu := Item.Handle
  else if (Item.ShortCut <> scNone) and ((Item.Parent = nil) or
    (Item.Parent.Parent <> nil) or not (Item.Parent.Owner is TMainMenu))
  then Caption := Caption + #9 + ShortCutToText(Item.ShortCut);
  MenuItemInfo.cbSize := SizeOf(TMenuItemInfo)-SizeOf(Integer); // Required for Windows 95
  MenuItemInfo.fMask := MIIM_CHECKMARKS or MIIM_DATA or MIIM_ID or
    MIIM_STATE or MIIM_SUBMENU or MIIM_TYPE;
  ParentMenu := Item.GetParentMenu;
  IsOwnerDraw := Assigned(ParentMenu) and
    (ParentMenu.OwnerDraw or (Item.GetImageList <> nil)) or
    Assigned(Item.Bitmap) and not Item.Bitmap.Empty;
  MenuItemInfo.fType := IRadios[Item.RadioItem] or IBreaks[Item.Break] or
    ISeparators[Item.Caption = cLineCaption] or IOwnerDraw[IsOwnerDraw];
  MenuItemInfo.fState := IChecks[Item.Checked] or IEnables[Item.Enabled]
    or IDefaults[Item.Default];
  MenuItemInfo.wID := Item.Command;
  MenuItemInfo.hbmpChecked := 0;
  MenuItemInfo.hbmpUnchecked := 0;
  MenuItemInfo.dwTypeData := PChar(Caption);
  InsertMenuItem(Menu, 0, True, MenuItemInfo);
end;

procedure TFormPipe.FormResize(Sender: TObject);
var
  i:Integer;
  Y,W,H,MinH:Integer;
  G:TFrameGroup;
  Scale:Double;
begin
  if Groups.Count=0 then exit;
  MinH:=0;
  for i:=0 to Groups.Count-1
  do Inc(MinH,Group[i].Constraints.MinHeight);
  Scale:=ClientHeight/MinH;
  if Scale<1 then begin
    Scale:=1;
    VertScrollBar.Visible:=True;
  end
  else VertScrollBar.Visible:=False;
  Y:=0;
  for i:=0 to Groups.Count-1 do begin
    G:=Group[i];
    Inc(Y,Round(G.Constraints.MinHeight*Scale));
  end;
  Bevel.Height:=Y;
  W:=ClientWidth;
  LockGroups;
  Y:=Bevel.Top;
  for i:=0 to Groups.Count-1 do begin
    G:=Group[i];
    H:=Round(G.Constraints.MinHeight*Scale);
    if (G.Top<>Y)or(G.Width<>W)or(G.Height<>H)
    then G.SetBounds(0,Y,W,H);
    Inc(Y,H);
  end;
  UnlockGroups;
end;

procedure TFormPipe.FormDestroy(Sender: TObject);
var
  i:Integer;
begin
  for i:=0 to Groups.Count-1
  do Group[i].Parent:=nil;
  Groups.Free;
end;

procedure TFormPipe.FormConstrainedResize(Sender: TObject; var MinWidth,
  MinHeight, MaxWidth, MaxHeight: Integer);
begin
  if Groups.Count=0 then exit;
  MinWidth:=Group[0].Constraints.MinWidth+(Width-ClientWidth);
end;

procedure TFormPipe.miScrollLockClick(Sender: TObject);
begin
  ScrollLock:=not miScrollLock.Checked;
end;

procedure TFormPipe.SaveCfg(Cfg: TIniFile);
begin
  Cfg.WriteFloat(Section,'TimeCapacity',TimeCapacity);
  if WindowState=wsNormal then begin
    Cfg.WriteInteger(Section,'Left',Left);
    Cfg.WriteInteger(Section,'Top',Top);
    Cfg.WriteInteger(Section,'Width',Width);
    Cfg.WriteInteger(Section,'Height',Height);
  end;
end;

procedure TFormPipe.LockGroups;
var
  i:Integer;
begin
  for i:=0 to Groups.Count-1
  do Group[i].LockGraphs;
end;

procedure TFormPipe.UnlockGroups;
var
  i:Integer;
begin
  for i:=0 to Groups.Count-1
  do Group[i].UnlockGraphs;
end;

constructor TFormPipe.CreateFromIniSection(AOwner: TComponent;
  Cfg: TIniFile; const Section: String);
var
  L,T,W,H:Integer;
  FF:TPoint;
  hSysMenu:HMENU;
  i:Integer;
begin
  inherited Create(AOwner);
  DoubleBuffered:=True;
  Groups:=TList.Create;
  Self.Section:=Section;
  FF.x:=0;
  FF.y:=Canvas.TextHeight('0')*6 div 8;
  // Read configuration
  L:=Cfg.ReadInteger(Section,'Left',Left);
  T:=Cfg.ReadInteger(Section,'Top',Top);
  W:=Cfg.ReadInteger(Section,'Width',Width);
  H:=Cfg.ReadInteger(Section,'Height',Height);
  FTimeCapacity:=Cfg.ReadFloat(Section,'TimeCapacity',5*dtOneMinute);
  SetBounds(L,T,W,H);
  hSysMenu:=GetSystemMenu(Handle,False);
  EnableMenuItem(hSysMenu,SC_CLOSE,MF_BYCOMMAND or MF_GRAYED);
  InsertMenu(hSysMenu,0,MF_BYPOSITION or MF_SEPARATOR,0,'');
  for i:=menuSys.Items.Count-1 downto 0
  do AppendItemToMenu(menuSys.Items[i],hSysMenu);
end;

procedure TFormPipe.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=Application.Terminated;
end;

function TFormPipe.Get_Group(i: Integer): TFrameGroup;
begin
  Result:=Groups[i];
end;

procedure TFormPipe.FormKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    'q','й':miArcViewDec001.Click;
    'e','у':miArcViewInc001.Click;
    'Q','Й':miArcViewDec005.Click;
    'E','У':miArcViewInc005.Click;
    'a','ф':miArcViewDec010.Click;
    'd','в':miArcViewInc010.Click;
    'A','Ф':miArcViewDec050.Click;
    'D','В':miArcViewInc050.Click;
    'z','я':miArcViewDec100.Click;
    'c','с':miArcViewInc100.Click;
    'Z','Я':miArcViewDec500.Click;
    'C','С':miArcViewInc500.Click;
  end;
end;

procedure TFormPipe.miCopyClick(Sender: TObject);
begin
  Deactivate;
  Negative:=Sender=miCopyForPrinting;
  CopyToClipboard;
  if Negative then Negative:=False;
  Activate;
end;

procedure TFormPipe.miAnyCapacityClick(Sender: TObject);
var
  mi:TMenuItem absolute Sender;
  CT:TDateTime;
begin
  CT:=mi.Tag*dtOneMinute;
  TimeCapacity:=CT;
end;

procedure TFormPipe.Set_TimeCapacity(const Value: TDateTime);
var
  i:Integer;
  V:TDateTime;
begin
  V:=Value;
  if V<dtOneSecond*10 then begin
    V:=dtOneSecond*10;
    miDecCapacity.Enabled:=False;
  end
  else miDecCapacity.Enabled:=True;
  if V>dtOneHour*4 then begin
    V:=dtOneHour*4;
    miIncCapacity.Enabled:=False;
  end
  else miIncCapacity.Enabled:=True;
  FTimeCapacity:=V;
  for i:=0 to Groups.Count-1
  do Group[i].TimeCapacity:=V;
end;

function TFormPipe.Get_TimeCapacity: TDateTime;
begin
  Result:=FTimeCapacity;
end;

procedure TFormPipe.InsertGroup(G: TFrameGroup);
begin
  if ActiveGroup=nil then ActiveGroup:=G;
  G.TimeCapacity:=FTimeCapacity;
  G.Parent:=Self;
  G.SpyMode:=SpyMode;
  G.Negative:=miNegative.Checked;
  G.OnExit(G);
  Groups.Add(G);
end;

procedure TFormPipe.AnyArcViewClick(Sender: TObject);
begin
  Application.ProcessMessages;
  ScrollArcView(TimeCapacity*0.01*TComponent(Sender).Tag);
end;

procedure TFormPipe.ScrollArcView(Step: TDateTime);
begin
  if SpyMode
  then ArcEndTime:=SpyEndTime
  else ArcEndTime:=ArcEndTime+Step;
end;

function TFormPipe.Get_SpyMode: Boolean;
begin
  Result:=miSpyMode.Checked;
end;

procedure TFormPipe.Set_SpyMode(const Value: Boolean);
var
  i:Integer;
begin
  miSpyMode.Checked:=Value;
  for i:=0 to Groups.Count-1
  do Group[i].SpyMode:=Value;
end;

function TFormPipe.Get_ScrollLock: Boolean;
begin
  Result:=miScrollLock.Checked;
end;

procedure TFormPipe.Set_ScrollLock(const Value: Boolean);
begin
  miScrollLock.Checked:=Value;
  if Value then ArcEndTime:=ActiveGroup.ArcEndTime;
end;

procedure TFormPipe.miSpyModeClick(Sender: TObject);
begin
  SpyMode:=not miSpyMode.Checked; // вкл/выкл режим слежения
end;

procedure TFormPipe.miNegativeClick(Sender: TObject);
begin
  Negative:=not miNegative.Checked;
end;

procedure TFormPipe.QueryArcView(Time: TDateTime);
begin
  ArcEndTime:=Time;
end;

procedure TFormPipe.NotifyActivity(Sender: TObject);
begin
  ActiveGroup:=TFrameGroup(Sender);
end;

function TFormPipe.Get_ArcEndTime: TDateTime;
begin
  Result:=ActiveGroup.ArcEndTime;
end;

function TFormPipe.Get_SpyEndTime: TDateTime;
var
  i:Integer;
  Tmp:TDateTime;
begin
  Result:=0;
  for i:=0 to Groups.Count-1 do begin
    Tmp:=Group[i].SpyEndTime;
    if Result<Tmp then Result:=Tmp;
  end;
end;

procedure TFormPipe.Set_ArcEndTime(const Value: TDateTime);
var
  i:Integer;
begin
  if ScrollLock then begin
    for i:=0 to Groups.Count-1
    do Group[i].ArcEndTime:=Value
  end
  else ActiveGroup.ArcEndTime:=Value;
  if SpyMode then SpyMode:=False;
end;

procedure TFormPipe.Set_Negative(const Value: Boolean);
var
  i:Integer;
begin
  miNegative.Checked:=Value;
  for i:=0 to Groups.Count-1
  do Group[i].Negative:=Value;
end;

procedure TFormPipe.TimerProc;
begin

end;

procedure TFormPipe.WMSysCommand(var Message: TWMSysCommand);
begin
  if (Message.CmdType and $F000<>0) or not menuSys.DispatchCommand(Message.CmdType)
  then inherited;
end;

function TFormPipe.IsShortCut(var Message: TWMKey): Boolean;
begin
  Result:=menuSys.IsShortCut(Message) or inherited IsShortCut(Message);
end;

procedure TFormPipe.miDecCapacityClick(Sender: TObject);
begin
  TimeCapacity:=TimeCapacity*0.75;
end;

procedure TFormPipe.miIncCapacityClick(Sender: TObject);
begin
  TimeCapacity:=TimeCapacity*1.33333333333;
end;

procedure TFormPipe.CopyToClipboard;
var
  i,Y:Integer;
  BM:TBitmap;
  R:TRect;
begin
  BM:=TBitmap.Create;
  Y:=0;
  for i:=0 to Groups.Count-1
  do Inc(Y,Group[i].Height);
  BM.Width:=ActiveGroup.ActiveGraph.Width+4;
  BM.Height:=Y+3;
  BM.Canvas.Brush.Color:=clSilver;
  R.Top:=0; R.Left:=0; R.Right:=BM.Width; R.Bottom:=BM.Height;
  BM.Canvas.FillRect(R);
  BM.Canvas.Brush.Color:=clGray;
  BM.Canvas.FrameRect(R);
  Inc(R.Top); Inc(R.Left); Dec(R.Right); Dec(R.Bottom);
  BM.Canvas.FrameRect(R);
  Y:=1;
  for i:=0 to Groups.Count-1 do begin
    Group[i].MyPaintTo(BM.Canvas.Handle,2,Y);
    Inc(Y,Group[i].Height);
  end;
  Clipboard.Assign(BM);
  BM.Free;
end;

function TFormPipe.Get_Negative: Boolean;
begin
  Result:=miNegative.Checked;
end;

procedure TFormPipe.miGraphOptionClick(Sender: TObject);
begin
  ActiveGroup.ActiveGraph.SpdBtnOptions.Click;
end;

procedure TFormPipe.miGroupOptionsClick(Sender: TObject);
begin
  ActiveGroup.SpdBtnOptions.Click;
end;

procedure TFormPipe.FormDeactivate(Sender: TObject);
begin
  ActiveGroup.OnExit(Self);
  ActiveGroup.ActiveGraph.OnExit(Self);
  ActiveControl:=BtnFake;
end;

procedure TFormPipe.miCalculateClick(Sender: TObject);
begin
  if ActiveGroup.SpdBtnCalculation.Enabled
  then ActiveGroup.SpdBtnCalculation.Click;
end;

procedure TFormPipe.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  Delta:Integer;
begin
  if (Shift=[]) and VertScrollBar.Visible then begin
    Handled:=True;
    Delta:=-VertScrollBar.Increment*WheelDelta div 40;
    VertScrollBar.Position:=VertScrollBar.Position+Delta;
  end;
end;

procedure TFormPipe.miSetArcTimeClick(Sender: TObject);
begin
  ActiveGroup.SpdBtnSetArcTime.Click;
end;

procedure TFormPipe.miZoomOutVClick(Sender: TObject);
begin
  ActiveGroup.ActiveGraph.SpdBtnZoomOut.Click;
end;

procedure TFormPipe.miZoomInVClick(Sender: TObject);
begin
  ActiveGroup.ActiveGraph.SpdBtnZoomIn.Click;
end;

end.


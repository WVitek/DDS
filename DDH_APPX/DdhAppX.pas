unit DdhAppX;

interface

uses
  SysUtils, Windows, Messages, Classes,
  Graphics, Controls, Forms, Dialogs, ShellApi, Menus;

type
  TDdhAppExt = class(TComponent)
  private
    // design time clone or runtime Application
    CurrApp: TApplication;
    // window procedures
    OldWndProc, NewWndProc: Pointer;
    // tray support
    fTrayIconActive: Boolean;
    fTrayIcon: TIcon;
    fTrayPopup: TPopupMenu;
    nid: TNotifyIconData;
    fOnTrayDefault: TNotifyEvent;
    fOnLBtnDown: TNotifyEvent;
    WM_TaskbarCreated:Cardinal;
    procedure IconTrayWndProc (var Msg: TMessage);
  protected
    // property and event access methods
    function GetIcon: TIcon;
    procedure SetIcon (Value: TIcon);
    function GetTitle: string;
    procedure SetTitle(Value: string);
    function GetHelpFile: string;
    procedure SetHelpFile(Value: string);
    function GetHintColor: TColor;
    procedure SetHintColor(Value: TColor);
    function GetHintPause: Integer;
    procedure SetHintPause(Value: Integer);
    function GetHintShortPause: Integer;
    procedure SetHintShortPause(Value: Integer);
    function GetHintHidePause: Integer;
    procedure SetHintHidePause(Value: Integer);
    function GetShowHint: Boolean;
    procedure SetShowHint(Value: Boolean);
    function GetOnActivate: TNotifyEvent;
    procedure SetOnActivate(Value: TNotifyEvent);
    function GetOnDeactivate: TNotifyEvent;
    procedure SetOnDeactivate(Value: TNotifyEvent);
    function GetOnException: TExceptionEvent;
    procedure SetOnException(Value: TExceptionEvent);
    function GetOnIdle: TIdleEvent;
    procedure SetOnIdle(Value: TIdleEvent);
    function GetOnHelp: THelpEvent;
    procedure SetOnHelp(Value: THelpEvent);
    function GetOnHint: TNotifyEvent;
    procedure SetOnHint(Value: TNotifyEvent);
    function GetOnMessage: TMessageEvent;
    procedure SetOnMessage(Value: TMessageEvent);
    function GetOnMinimize: TNotifyEvent;
    procedure SetOnMinimize(Value: TNotifyEvent);
    function GetOnRestore: TNotifyEvent;
    procedure SetOnRestore(Value: TNotifyEvent);
    function GetOnShowHint: TShowHintEvent;
    procedure SetOnShowHint(Value: TShowHintEvent);
    procedure SetTrayIconActive (Value: Boolean);
    procedure SetTrayIcon (Value: TIcon);
    procedure IconChange (Sender: TObject);
    procedure SetTrayHint (Value: string);
    function GetTrayHint: string;
    procedure SetTrayPopup (Value: TPopupMenu);
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // TApplication properties
    property Icon: TIcon
      read GetIcon  write SetIcon ;
    property Title: string
      read GetTitle write SetTitle;
    property HelpFile: string
      read GetHelpFile write SetHelpFile;
    property HintColor: TColor
      read GetHintColor write SetHintColor default clInfoBk;
    property HintPause: Integer
      read GetHintPause write SetHintPause default 500;
    property HintShortPause: Integer
      read GetHintShortPause write SetHintShortPause default 50;
    property HintHidePause: Integer
      read GetHintHidePause write SetHintHidePause default 2500;
    property ShowHint: Boolean
      read GetShowHint write SetShowHint default False;
    // tray icon properties
    property TrayIconActive: Boolean
      read fTrayIconActive write SetTrayIconActive default False;
    property TrayIcon: TIcon
      read fTrayIcon write SetTrayIcon;
    property TrayHint: string
      read GetTrayHint write SetTrayHint;
    property TrayPopup: TPopupMenu
      read fTrayPopup write SetTrayPopup;
    property OnTrayDefault: TNotifyEvent
      read fOnTrayDefault write fOnTrayDefault;
    property OnLBtnDown: TNotifyEvent
      read fOnLBtnDown write fOnLBtnDown;
    // TApplication events
    property OnActivate: TNotifyEvent
      read GetOnActivate write SetOnActivate;
    property OnDeactivate: TNotifyEvent
      read GetOnDeactivate write SetOnDeactivate;
    property OnException: TExceptionEvent
      read GetOnException write SetOnException;
    property OnIdle: TIdleEvent
      read GetOnIdle write SetOnIdle;
    property OnHelp: THelpEvent
      read GetOnHelp write SetOnHelp;
    property OnHint: TNotifyEvent
      read GetOnHint write SetOnHint;
    property OnMessage: TMessageEvent
      read GetOnMessage write SetOnMessage;
    property OnMinimize: TNotifyEvent
      read GetOnMinimize write SetOnMinimize;
    property OnRestore: TNotifyEvent
      read GetOnRestore write SetOnRestore;
    property OnShowHint: TShowHintEvent
      read GetOnShowHint write SetOnShowHint;
  end;

procedure Register;

const
  WM_TrayIconMsg = wm_User;

implementation

var
  AppCompCounter: Integer;

constructor TDdhAppExt.Create(AOwner: TComponent);
begin
  // check if already created
  Inc (AppCompCounter);
  if AppCompCounter > 1
  then raise Exception.Create('Duplicated DdhAppExt component');
  
  inherited Create(AOwner);

  // application object initialization
  if csDesigning in ComponentState then begin
    CurrApp := TApplication.Create (nil);
    CurrApp.Icon := nil;
    CurrApp.Title := '';
    CurrApp.HelpFile := '';
  end
  else CurrApp := Application;

  // tray icon initialization
  fTrayIconActive := False;
  fTrayIcon := TIcon.Create;
  fTrayIcon.OnChange := IconChange;

  nid.cbSize := sizeof (nid);
  nid.wnd := CurrApp.Handle;
  nid.uID := 1; // icon ID
  nid.uCallBackMessage := WM_TrayIconMsg;
  nid.hIcon := CurrApp.Icon.Handle;
  StrLCopy (nid.szTip, PChar('Tip'), 64);
  nid.uFlags := nif_Message or nif_Icon or nif_Tip;

  // subclass the application
  if not (csDesigning in ComponentState) then begin
    NewWndProc := MakeObjectInstance(IconTrayWndProc);
    OldWndProc := Pointer( SetWindowLong (
      CurrApp.Handle, gwl_WndProc, Longint (NewWndProc)));
  end
  else begin
    // default values
    NewWndProc := nil;
    OldWndPRoc := nil;
  end;
  WM_TaskbarCreated:=RegisterWindowMessage('TaskbarCreated');
end;

destructor TDdhAppExt.Destroy;
begin
  // remove the application window procedure
  if not (csDesigning in ComponentState) then begin
    // re-install the original window procedure
    SetWindowLong (CurrApp.Handle, gwl_WndProc, Longint (OldWndProc));
    // free the object instance
    if Assigned (NewWndProc)
    then FreeObjectInstance (NewWndProc);
  end;
  Dec (AppCompCounter);
  // remove the tray icon
  if fTrayIconActive
  then Shell_NotifyIcon (NIM_DELETE, @nid);
  fTrayIcon.Free;
  // default destructor
  inherited Destroy;
end;

procedure TDdhAppExt.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification (AComponent, Operation);
  if (Operation = opRemove) and (AComponent = fTrayPopup)
  then fTrayPopup := nil;
end;

// property access methods

function TDdhAppExt.GetIcon : TIcon;
begin
  Result := CurrApp.Icon ;
end;

procedure TDdhAppExt.SetIcon (Value: TIcon);
begin
  CurrApp.Icon := Value;
end;

function TDdhAppExt.GetTitle: string;
begin
  Result := CurrApp.Title;
end;

procedure TDdhAppExt.SetTitle(Value: string);
begin
  CurrApp.Title := Value;
end;

function TDdhAppExt.GetHelpFile: string;
begin
  Result := CurrApp.HelpFile;
end;

procedure TDdhAppExt.SetHelpFile(Value: string);
begin
  CurrApp.HelpFile := Value;
end;

function TDdhAppExt.GetHintColor: TColor;
begin
  Result := CurrApp.HintColor;
end;

procedure TDdhAppExt.SetHintColor(Value: TColor);
begin
  CurrApp.HintColor := Value;
end;

function TDdhAppExt.GetHintPause: Integer;
begin
  Result := CurrApp.HintPause;
end;

procedure TDdhAppExt.SetHintPause(Value: Integer);
begin
  CurrApp.HintPause := Value;
end;

function TDdhAppExt.GetHintShortPause: Integer;
begin
  Result := CurrApp.HintShortPause;
end;

procedure TDdhAppExt.SetHintShortPause(Value: Integer);
begin
  CurrApp.HintShortPause := Value;
end;

function TDdhAppExt.GetHintHidePause: Integer;
begin
  Result := CurrApp.HintHidePause;
end;

procedure TDdhAppExt.SetHintHidePause(Value: Integer);
begin
  CurrApp.HintHidePause := Value;
end;

function TDdhAppExt.GetShowHint: Boolean;
begin
  Result := CurrApp.ShowHint;
end;

procedure TDdhAppExt.SetShowHint(Value: Boolean);
begin
  CurrApp.ShowHint := Value;
end;

function TDdhAppExt.GetOnActivate: TNotifyEvent;
begin
  Result := CurrApp.OnActivate;
end;

procedure TDdhAppExt.SetOnActivate(Value: TNotifyEvent);
begin
  CurrApp.OnActivate := Value;
end;

function TDdhAppExt.GetOnDeactivate: TNotifyEvent;
begin
  Result := CurrApp.OnDeactivate;
end;

procedure TDdhAppExt.SetOnDeactivate(Value: TNotifyEvent);
begin
  CurrApp.OnDeactivate := Value;
end;

function TDdhAppExt.GetOnException: TExceptionEvent;
begin
  Result := CurrApp.OnException;
end;

procedure TDdhAppExt.SetOnException(Value: TExceptionEvent);
begin
  CurrApp.OnException := Value;
end;

function TDdhAppExt.GetOnIdle: TIdleEvent;
begin
  Result := CurrApp.OnIdle;
end;

procedure TDdhAppExt.SetOnIdle(Value: TIdleEvent);
begin
  CurrApp.OnIdle := Value;
end;

function TDdhAppExt.GetOnHelp: THelpEvent;
begin
  Result := CurrApp.OnHelp;
end;

procedure TDdhAppExt.SetOnHelp(Value: THelpEvent);
begin
  CurrApp.OnHelp := Value;
end;

function TDdhAppExt.GetOnHint: TNotifyEvent;
begin
  Result := CurrApp.OnHint;
end;

procedure TDdhAppExt.SetOnHint(Value: TNotifyEvent);
begin
  CurrApp.OnHint := Value;
end;

function TDdhAppExt.GetOnMessage: TMessageEvent;
begin
  Result := CurrApp.OnMessage;
end;

procedure TDdhAppExt.SetOnMessage(Value: TMessageEvent);
begin
  CurrApp.OnMessage := Value;
end;

function TDdhAppExt.GetOnMinimize: TNotifyEvent;
begin
  Result := CurrApp.OnMinimize;
end;

procedure TDdhAppExt.SetOnMinimize(Value: TNotifyEvent);
begin
  CurrApp.OnMinimize := Value;
end;

function TDdhAppExt.GetOnRestore: TNotifyEvent;
begin
  Result := CurrApp.OnRestore;
end;

procedure TDdhAppExt.SetOnRestore(Value: TNotifyEvent);
begin
  CurrApp.OnRestore := Value;
end;

function TDdhAppExt.GetOnShowHint: TShowHintEvent;
begin
  Result := CurrApp.OnShowHint;
end;

procedure TDdhAppExt.SetOnShowHint(Value: TShowHintEvent);
begin
  CurrApp.OnShowHint := Value;
end;

// tray icon support

procedure TDdhAppExt.SetTrayIconActive (Value: Boolean);
begin
  if Value <> fTrayIconActive then begin
    fTrayIconActive := Value;
    if not (csDesigning in ComponentState) then begin
      if fTrayIconActive
      then Shell_NotifyIcon (NIM_ADD, @nid)
      else Shell_NotifyIcon (NIM_DELETE, @nid);
    end;
  end;
end;

procedure TDdhAppExt.SetTrayIcon (Value: TIcon);
begin
  fTrayIcon.Assign (Value);
end;

procedure TDdhAppExt.IconChange (Sender: TObject);
begin
  if not (fTrayIcon.Empty)
  then nid.hIcon := fTrayIcon.Handle
  else nid.hIcon := CurrApp.MainForm.Icon.Handle;
  if fTrayIconActive and not (csDesigning in ComponentState)
  then Shell_NotifyIcon (NIM_MODIFY, @nid);
end;

function TDdhAppExt.GetTrayHint: string;
begin
  Result := string (nid.szTip);
end;

procedure TDdhAppExt.SetTrayHint (Value: string);
begin
  StrLCopy (nid.szTip, PChar(Value), 64);
  if fTrayIconActive and not (csDesigning in ComponentState)
  then Shell_NotifyIcon (NIM_MODIFY, @nid);
end;

procedure TDdhAppExt.SetTrayPopup (Value: TPopupMenu);
begin
  if Value <> fTrayPopup then begin
    fTrayPopup := Value;
    if Assigned(fTrayPopup)
    then fTrayPopup.FreeNotification(Self);
  end;
end;

procedure TDdhAppExt.IconTrayWndProc (var Msg: TMessage);
var
  Pt: TPoint;
begin
  if Msg.Msg = WM_TaskbarCreated then begin
    // reinstall tray icon
    fTrayIconActive:=False;
    TrayIconActive:=True;
    exit;
  end;
  if (Msg.Msg = WM_TrayIconMsg)
  then case Msg.lParam of
    WM_RButtonDown:
      if Assigned(fTrayPopup) then begin
        if CurrApp<>nil then SetForegroundWindow(CurrApp.MainForm.Handle);
        GetCursorPos(Pt);
        fTrayPopup.Popup(Pt.x, Pt.y);
        exit;
      end;
    WM_LButtonDown: if Assigned(fOnLBtnDown) then begin
      fOnLBtnDown(Self);
      exit;
    end;
    WM_LButtonDblClk: if Assigned(fOnTrayDefault) then begin
      if CurrApp<>nil then SetForegroundWindow(CurrApp.MainForm.Handle);
      fOnTrayDefault (self);
      exit;
    end;
  end;
  // original window procedure
  if CurrApp<>nil then begin
    if Msg.Msg=WM_TrayIconMsg
    then PostMessage(CurrApp.MainForm.Handle,Msg.Msg,Msg.WParam,Msg.LParam)
    else Msg.Result := CallWindowProc (OldWndProc, CurrApp.Handle,
      Msg.Msg, Msg.WParam, Msg.LParam);
  end;
end;

// component registration

procedure Register;
begin
  RegisterComponents('DDHB', [TDdhAppExt]);
end;

initialization
  AppCompCounter := 0;
end.


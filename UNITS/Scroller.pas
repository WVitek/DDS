unit Scroller;

interface

uses
  Classes,Windows,Graphics,Controls,Messages,Forms,Misc;

type
  TBufferedScroller=class;

  TRenderBufferedScrollerEvent=procedure(BS:TBufferedScroller) of object;

  TGetRegionRectEvent=function(
    BS:TBufferedScroller; RegionNum:Integer; var dx,dy:Integer; var R:TRect
  ):Integer of object;

  TFPScrollBar=class;

  TBufferedScroller=class(TCustomControl)
  protected
    FBuffer:TBitmap;
    FHorzSB, FVertSB: TFPScrollBar;
    FVSize:TPoint;
    FDelta,FOldDelta:TPoint;
    FFixedField:TPoint;
    renderLockCnt: Integer;
    setvLockCnt: Integer;
    needRender: Boolean;
    needRepaint: Boolean;
    needSetVSize: Boolean;
    validBufferSize: Boolean;
    FUseScrollWindow: Boolean;
    FOnBeforeScroll,FOnAfterScroll,FOnMouseLeave:TNotifyEvent;
    FOnRender:TRenderBufferedScrollerEvent;
    FOnGetRegionRect:TGetRegionRectEvent;
    procedure paint; override;
    procedure renderer; virtual;
    procedure Resize; override;
  private
    function  GetClientSize: TPoint;
    procedure SetDelta(Value: TPoint);
    procedure ScrollProc(SB: TObject);
    procedure resizeBuffer;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure CMMouseLeave(var Msg:TMsg); message CM_MOUSELEAVE;
    procedure SetVSize(const Value: TPoint);
    procedure CalcAndSetPageSize(const CS,VS:TPoint);
    function GetPixelFormat: TPixelFormat;
    procedure SetPixelFormat(const Value: TPixelFormat);
    procedure ChangeSize;
    function GetBuffer: TBitmap;
    procedure Set_HorzSB(const Value: TFPScrollBar);
    procedure Set_VertSB(const Value: TFPScrollBar);
  public
    BufferChanged:Boolean;
    procedure lockRender;
    procedure lockSetV;
    procedure render(Repaint:Boolean);
    procedure unlockRender;
    procedure unlockSetV;
    constructor create(AOwner: TComponent); override;
    destructor destroy; override;
    //
    property Buffer:TBitmap read GetBuffer;
    property OldDelta:TPoint read FOldDelta;
    property Delta: TPoint read FDelta write SetDelta stored False;
    property VSize: TPoint read FVSize write SetVSize stored False;
    property FixedField:TPoint read FFixedField write FFixedField;
    property ClientSize: TPoint read GetClientSize;
    property HorzSB:TFPScrollBar read FHorzSB write Set_HorzSB;
    property VertSB:TFPScrollBar read FVertSB write Set_VertSB;
  published
    property OnBeforeScroll: TNotifyEvent read FOnBeforeScroll write FOnBeforeScroll;
    property OnAfterScroll: TNotifyEvent read FOnAfterScroll write FOnAfterScroll;
    property OnGetRegionRect: TGetRegionRectEvent read FOnGetRegionRect write FOnGetRegionRect;
    property OnRender: TRenderBufferedScrollerEvent read FOnRender write FOnRender;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    property PixelFormat:TPixelFormat read GetPixelFormat write SetPixelFormat;
    property UseScrollWindow:Boolean read FUseScrollWindow write FUseScrollWindow;
    //
    property BorderWidth;
    //
    property Align;
    property Anchors;
    property Constraints;
    property MouseCapture;
    property Visible;
    property ParentShowHint;
    property PopupMenu;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

  TUniViewer=class(TBufferedScroller)
  private
    procedure SetRealSize(const Value: TDblPoint);
    procedure SetScale(const Value: TDblPoint);
    function GetRealClientSize: TDblPoint;
    function GetRealDelta: TDblPoint;
    procedure SetRealSizeX(const Value: Double);
    procedure SetRealSizeY(const Value: Double);
    procedure SetScaleX(const Value: Double);
    procedure SetScaleY(const Value: Double);
  protected
    FScale:TDblPoint;
    FRealSize:TDblPoint;
  public
    property RealDelta:TDblPoint read GetRealDelta;
    property RealClientSize:TDblPoint read GetRealClientSize;
    property Scale:TDblPoint read FScale write SetScale;
    property RealSize:TDblPoint read FRealSize write SetRealSize;
  published
    property ScaleX:Double read FScale.X write SetScaleX;
    property ScaleY:Double read FScale.Y write SetScaleY;
    property RealSizeX:Double read FRealSize.X write SetRealSizeX;
    property RealSizeY:Double read FRealSize.Y write SetRealSizeY;
    property HorzSB;
    property VertSB;
  end;

  TFPScrollBar=class(TPersistent)
  private
    procedure SetDisableNoScroll(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetPageSize(Value: Double);
    procedure SetPosition(Value: Double);
    procedure SetVisible(Value: Boolean);
    procedure CutOffPosition(var Pos:Double);
  protected
    FControl: TWinControl;
    FIncrement: Double;
    FKind: TScrollBarKind;
    FOnScroll: TNotifyEvent;
    FPageSize: Double;
    FPosition: Double;
    needRedraw: Boolean;
    FVisible, FDisableNoScroll, FEnabled: Boolean;
    redrawLockCnt: Integer;
    function  GetSize: Integer;
    procedure ScrollMessage(var Msg: TWMScroll);
    procedure update(Immediate:Boolean);
  public
    constructor create(AControl: TWinControl; AKind: TScrollBarKind);
    procedure lockRedraw;
    procedure unlockRedraw;
    procedure Assign(Source:TPersistent);override;
  public
    property OnScroll: TNotifyEvent read FOnScroll write FOnScroll;
    property Position: Double read FPosition write SetPosition;
    property Size: Integer read GetSize;
    property PageSize: Double read FPageSize write SetPageSize;
  published
    property DisableNoScroll:Boolean read FDisableNoScroll write SetDisableNoScroll;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Visible: Boolean read FVisible write SetVisible;
  end;

implementation

const
  MaxInt16=32767;
  OneDivMaxInt16=1/MaxInt16;

function TBufferedScroller.GetClientSize: TPoint;
var
  R:TRect;
begin
  Windows.GetClientRect(Handle,R);
  Result.X:=R.Right-R.Left+1;
  Result.Y:=R.Bottom-R.Top+1;
end;

procedure TBufferedScroller.SetDelta(Value: TPoint);
var
  Flag:Boolean;
begin
  lockRender;
  Flag:=False;
  if (FDelta.x<>Value.x) then begin
    if FVSize.x>0
    then HorzSB.Position:=Value.x/FVSize.x
    else HorzSB.Position:=0;
    Value.x:=Round(HorzSB.Position*FVSize.x);
    if FDelta.x<>Value.x then begin
      FDelta.x:=Value.x;
      Flag:=True;
    end;
  end;
  if (FDelta.y<>Value.y) then begin
    if FVSize.y>0
    then VertSB.Position:=Value.y/FVSize.y
    else VertSB.Position:=0;
    Value.y:=Round(VertSB.Position*FVSize.y);
    if FDelta.y<>Value.y then begin
      FDelta.y:=Value.y;
      Flag:=True;
    end;
  end;
  if Flag then render(True);
  unlockRender;
end;

procedure TBufferedScroller.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
var
  P:TPoint;
begin
  with Msg.MinMaxInfo.ptMinTrackSize do begin
    x:=64; y:=64;
  end;
  P.x:=FVSize.x+FixedField.x;
  P.y:=FVSize.y+FixedField.y;
  Msg.MinMaxInfo.ptMaxTrackSize:=P;
end;

procedure TBufferedScroller.WMHScroll(var Msg: TWMHScroll);
begin
  FHorzSB.ScrollMessage(Msg);
end;

procedure TBufferedScroller.WMVScroll(var Msg: TWMVScroll);
begin
  FVertSB.ScrollMessage(Msg);
end;

constructor TBufferedScroller.create(AOwner: TComponent);
var
  Style,ExStyle:Integer;
begin
  inherited;
  FBuffer:=TBitmap.Create;
  FHorzSB:=TFPScrollBar.create(Self,sbHorizontal);
  FVertSB:=TFPScrollBar.create(Self,sbVertical);
  Parent:=Owner as TWinControl;
  Style:=GetWindowLong(Handle,GWL_STYLE);
  Style:=Style or WS_VSCROLL or WS_HSCROLL;// or WS_BORDER or WS_THICKFRAME;
  SetWindowLong(Handle,GWL_STYLE,Style);
  ExStyle:=GetWindowLong(Handle,GWL_EXSTYLE) or WS_EX_CLIENTEDGE;
  SetWindowLong(Handle,GWL_EXSTYLE,ExStyle);
  SetBounds(0,0,64,64);
  //
  HorzSB.OnScroll:=ScrollProc;
  VertSB.OnScroll:=ScrollProc;
end;

destructor TBufferedScroller.destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TBufferedScroller.CalcAndSetPageSize(const CS, VS: TPoint);
var
  PGS:TDblPoint;
begin
  if VS.x=0 then PGS.x:=1.0 else PGS.x:=(CS.x-FixedField.x)/VS.x;
  if VS.y=0 then PGS.y:=1.0 else PGS.y:=(CS.y-FixedField.y)/VS.y;
  HorzSB.PageSize:=PGS.x;
  VertSB.PageSize:=PGS.y;
end;

procedure TBufferedScroller.lockRender;
begin
  Inc(renderLockCnt);
end;

procedure TBufferedScroller.renderer;
begin
  if Assigned(FOnRender) then FOnRender(Self);
end;

procedure TBufferedScroller.unlockRender;
begin
  Dec(renderLockCnt);
  if (renderLockCnt=0) and needRender then render(True);
end;

procedure TBufferedScroller.render(Repaint:Boolean);
begin
  needRender:=true;
  needRepaint:=needRepaint or Repaint;
  if renderLockCnt>0 then exit;
  renderer;
  needRender:=False;
  if needRepaint then Self.Repaint else Self.Update;
  needRepaint:=False;
end;

procedure TBufferedScroller.ScrollProc(SB: TObject);
var
  dx,dy,adx,ady:Integer;
  i,RegCnt:Integer;
  R,CR:TRect;
begin
  if Assigned(FOnBeforeScroll) then FOnBeforeScroll(Self);
  if SB=HorzSB then FDelta.x:=round(HorzSB.Position*FVSize.x)
  else if SB=VertSB then FDelta.y:=round(VertSB.Position*FVSize.y);
  dx:=FOldDelta.x-FDelta.x;
  dy:=FOldDelta.y-FDelta.y;
  if (dx<>0)or(dy<>0) then begin
    if (renderLockCnt=0) then begin
      renderer;
      if FUseScrollWindow then begin
        CR:=GetClientRect;
        if Assigned(OnGetRegionRect) then begin
          R:=CR; adx:=dx; ady:=dy;
          RegCnt:=OnGetRegionRect(Self,0,adx,ady,CR);
          for i:=1 to RegCnt do begin
            R:=CR; adx:=dx; ady:=dy;
            OnGetRegionRect(Self,i,adx,ady,R);
            ScrollWindow(Handle,adx,ady,nil,@R);
          end;
        end
        else ScrollWindow(Handle,dx,dy,nil,nil);
      end
      else Invalidate;
      update;
    end;
  end;
  if Assigned(FOnAfterScroll) then FOnAfterScroll(Self);
  FOldDelta:=FDelta;
end;

procedure TBufferedScroller.paint;
begin
  if renderLockCnt>0 then exit;
  if needRender then render(true);
  Canvas.draw(0,0,Buffer);
end;

procedure TBufferedScroller.resizeBuffer;
var
  CS:TPoint;
begin
  CS:=ClientSize;
  FBuffer.Width :=CS.x;
  FBuffer.Height:=CS.y;
  validBufferSize:=True;
end;

procedure TBufferedScroller.SetVSize(const Value: TPoint);
begin
  FVSize := Value;
  if (setvLockCnt>0) then begin
    needSetVSize:=True;
    exit;
  end;
  needSetVSize:=False;
  CalcAndSetPageSize(ClientSize,Value);
  FDelta.x:=Round(HorzSB.Position*FVSize.x);
  FDelta.y:=Round(VertSB.Position*FVSize.y);
  FOldDelta:=FDelta;
  render(true);
end;

procedure TBufferedScroller.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  // do nothing
end;

{ TFPScrollBar }

procedure TFPScrollBar.Assign(Source: TPersistent);
begin
  if Source is TFPScrollBar then begin
    lockRedraw;
    Position:=TFPScrollBar(Source).Position;
    PageSize:=TFPScrollBar(Source).PageSize;
    Visible:=TFPScrollBar(Source).Visible;
    unlockRedraw;
  end;
  inherited Assign(Source);
end;

constructor TFPScrollBar.create(AControl: TWinControl; AKind: TScrollBarKind);
begin
  inherited create;
  FControl:=AControl;
  FKind:=AKind;
  FPosition:=0;
  FPageSize:=1;
  FIncrement:=0.001;
  FEnabled:=True;
end;

procedure TFPScrollBar.CutOffPosition(var Pos: Double);
begin
  if Pos<0 then Pos:=0 else if Pos+FPageSize>1 then Pos:=1-FPageSize;
end;

function TFPScrollBar.GetSize: Integer;
begin
  if Visible then begin
    if FKind=sbVertical
    then Result:=GetSystemMetrics(SM_CXVSCROLL)
    else Result:=GetSystemMetrics(SM_CYHSCROLL);
  end
  else Result:=0;
end;

procedure TFPScrollBar.lockRedraw;
begin
  inc(redrawLockCnt);
end;

procedure TFPScrollBar.ScrollMessage(var Msg: TWMScroll);
begin
  if not Visible or not Enabled then exit;
  with Msg do
    case ScrollCode of
      SB_LINEUP:   SetPosition(FPosition - FIncrement);
      SB_LINEDOWN: SetPosition(FPosition + FIncrement);
      SB_PAGEUP:   SetPosition(FPosition - FPageSize);
      SB_PAGEDOWN: SetPosition(FPosition + FPageSize);
      SB_TOP:      SetPosition(0);
      SB_BOTTOM:   SetPosition(1);
      SB_THUMBPOSITION: SetPosition(Pos*OneDivMaxInt16);
      SB_THUMBTRACK:    SetPosition(Pos*OneDivMaxInt16);
      SB_ENDSCROLL:;
    end;
end;

procedure TFPScrollBar.SetDisableNoScroll(const Value: Boolean);
begin
  FDisableNoScroll := Value;
  update(False);
end;

procedure TFPScrollBar.SetEnabled(const Value: Boolean);
var
  Code:Cardinal;
  Arrows:Cardinal;
begin
  if FEnabled<>Value then begin
    FEnabled:=Value;
    if FKind=sbHorizontal then Code:=SB_HORZ else Code:=SB_VERT;
    if Value then begin
      Arrows:=ESB_ENABLE_BOTH;
      if Visible then update(False);
    end
    else Arrows:=ESB_DISABLE_BOTH;
    EnableScrollBar(FControl.Handle,Code,Arrows);
  end;
end;

procedure TFPScrollBar.SetPageSize(Value: Double);
begin
  if (FPageSize <> Value) then begin
    if Value < 0 then Value := 0
    else if 1 < Value then Value := 1;
    FPageSize := Value;
    CutOffPosition(FPosition);
    update(False);
  end;
end;

procedure TFPScrollBar.SetPosition(Value: Double);
begin
  CutOffPosition(Value);
  if (FPosition<>Value) then begin
    FPosition := Value;
    if Assigned(FOnScroll) then FOnScroll(Self);
    update(False);
  end;
end;

procedure TFPScrollBar.SetVisible(Value: Boolean);
var
  Code:Cardinal;
begin
  if FVisible<>Value then begin
    FVisible:=Value;
    if FKind=sbHorizontal
    then Code:=SB_HORZ
    else Code:=SB_VERT;
    ShowScrollBar(FControl.Handle,Code,Value);
    update(True);
  end;
end;

procedure TFPScrollBar.unlockRedraw;
begin
  if redrawLockCnt=0 then exit;
  Dec(redrawLockCnt);
  if (redrawLockCnt=0) and needRedraw then update(False);
end;

procedure TFPScrollBar.update;
var
  ScrollInfo:TScrollInfo;
  Code:Cardinal;
begin
  if not Immediate and (not Visible or not Enabled) then exit;
  needRedraw:=True;
  if redrawLockCnt>0 then exit;
  if FKind=sbHorizontal
  then Code:=SB_HORZ
  else Code:=SB_VERT;
  ScrollInfo.cbSize:=SizeOf(ScrollInfo);
  ScrollInfo.fMask:=SIF_ALL;
  if DisableNoScroll
  then ScrollInfo.fMask:=ScrollInfo.fMask or SIF_DISABLENOSCROLL;
  CutOffPosition(FPosition);
{
  if (FPageSize<1)
  then ScrollInfo.nMin:=0
  else ScrollInfo.nMin:=MaxInt16;
}
  ScrollInfo.nMin:=0;
  ScrollInfo.nMax:=MaxInt16;
  ScrollInfo.nPage:=round(FPageSize*MaxInt16);
  ScrollInfo.nPos:=round(FPosition*MaxInt16);
  ScrollInfo.nTrackPos:=ScrollInfo.nPos;
  SetScrollInfo(FControl.Handle, Code, ScrollInfo, True);
  needRedraw:=False;
end;

{ TUniViewer }

function TUniViewer.GetRealClientSize: TDblPoint;
var
  CS:TPoint;
begin
  CS:=ClientSize;
  Result.x:=(CS.x-FixedField.x)/FScale.x;
  Result.y:=(CS.y-FixedField.y)/FScale.y;
end;

function TUniViewer.GetRealDelta: TDblPoint;
begin
  Result.x:=Delta.x/FScale.x;
  Result.y:=Delta.y/FScale.y;
end;

procedure TUniViewer.SetRealSize(const Value: TDblPoint);
var
  NVS:TPoint; // New VSize
begin
  FRealSize:=Value;
  try
    NVS.x:=Round(Value.x*FScale.x);
    NVS.y:=Round(Value.y*FScale.y);
    VSize:=NVS;
  except
  end;
end;

procedure TUniViewer.SetRealSizeX(const Value: Double);
var
  P:TDblPoint;
begin
  P.X:=Value; P.Y:=FRealSize.Y; SetRealSize(P);
end;

procedure TUniViewer.SetRealSizeY(const Value: Double);
var
  P:TDblPoint;
begin
  P.X:=FRealSize.X; P.Y:=Value; SetRealSize(P);
end;

procedure TUniViewer.SetScale(const Value: TDblPoint);
var
  NVS:TPoint; // New VSize
begin
  FScale:=Value;
  NVS.x:=Round(FRealSize.x*Value.x);
  NVS.y:=Round(FRealSize.y*Value.y);
  VSize:=NVS;
end;

procedure TUniViewer.SetScaleX(const Value: Double);
var
  P:TDblPoint;
begin
  P.X:=Value; P.Y:=FScale.Y; SetScale(P);
end;

procedure TUniViewer.SetScaleY(const Value: Double);
var
  P:TDblPoint;
begin
  P.X:=FScale.X; P.Y:=Value; SetScale(P);
end;

function TBufferedScroller.GetPixelFormat: TPixelFormat;
begin
  Result:=Buffer.PixelFormat;
end;

procedure TBufferedScroller.SetPixelFormat(const Value: TPixelFormat);
begin
  FBuffer.PixelFormat:=Value;
end;

procedure TBufferedScroller.Resize;
begin
  ChangeSize;
  inherited;
end;

procedure TBufferedScroller.ChangeSize;
var
  CS,D:TPoint;
begin
  lockRender;
  CS:=GetClientSize;
  D:=Delta;
  if D.x+CS.x>FVSize.x then begin
    D.x:=FVSize.x-CS.x; if D.x<0 then D.x:=0;
  end;
  if D.y+CS.y>FVSize.y then begin
    D.y:=FVSize.y-CS.y; if D.y<0 then D.y:=0;
  end;
  CalcAndSetPageSize(CS,FVSize);
  Delta:=D;
  //
  validBufferSize:=False;
  if FBuffer<>nil then render(True);
  unlockRender;
end;

function TBufferedScroller.GetBuffer: TBitmap;
begin
  if not validBufferSize then resizeBuffer;
  Result:=FBuffer;
end;

procedure TBufferedScroller.lockSetV;
begin
  Inc(setvLockCnt);
end;

procedure TBufferedScroller.unlockSetV;
begin
  Dec(setvLockCnt);
  if (setvLockCnt=0) and needSetVSize then SetVSize(FVSize);
end;

procedure TBufferedScroller.CMMouseLeave(var Msg: TMsg);
begin
  if Assigned(FOnMouseLeave) then FOnMouseLeave(Self);
end;

procedure TBufferedScroller.Set_HorzSB(const Value: TFPScrollBar);
begin
  FHorzSB.Assign(Value);
end;

procedure TBufferedScroller.Set_VertSB(const Value: TFPScrollBar);
begin
  FVertSB.Assign(Value);
end;

end.

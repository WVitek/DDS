{$LONGSTRINGS ON}
unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Contnrs, IniFiles, Menus, ExtCtrls, DdhAppX, MPlayer,
  DblGraphics, ArchManThd, Misc, UFormPipe, UFrameGroup;

type
  TPipe=class;

  TFormMain = class(TForm)
    Timer: TTimer;
    AppExt: TDdhAppExt;
    PopupMenu: TPopupMenu;
    pmiExit: TMenuItem;
    pmiAbout: TMenuItem;
    pmiLine1: TMenuItem;
    pmiHide: TMenuItem;
    pmiShow: TMenuItem;
    MediaPlayer: TMediaPlayer;
    miGroupByPipe: TMenuItem;
    miGroupByGroup: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure pmiExitClick(Sender: TObject);
    procedure pmiHideClick(Sender: TObject);
    procedure pmiShowClick(Sender: TObject);
    procedure AppExtTrayDefault(Sender: TObject);
    procedure pmiAboutClick(Sender: TObject);
    procedure miGroupByPipeClick(Sender: TObject);
    procedure miGroupByGroupClick(Sender: TObject);
    procedure AppExtDeactivate(Sender: TObject);
  private
    { Private declarations }
    function Get_MediaFileNameI(i: Integer): AnsiString;
    procedure Set_MediaFileNameI(i: Integer; const Value: AnsiString);
    function Get_MediaFileNameO(O: Pointer): AnsiString;
    procedure Set_MediaFileNameO(O: Pointer; const Value: AnsiString);
    function Get_CurMediaFile: AnsiString;
    function Get_CurMediaOwner: Pointer;
    function Get_Pipe(i: Integer): TPipe;
  protected
    procedure EnablePipeForms(Enabled:Boolean);
    procedure ShowPipeForms;
    procedure HidePipeForms;
    procedure ClosePipeForms;
  public
    { Public declarations }
    Ini,Cfg:TIniFile;
    Pipes:TObjectList;
    PlayQueue:TByteStringList;
    Alpha1,Alpha2:Double;
    CorrBlockLen:Integer;
    CorrelatorEnabled:Boolean;
    procedure SaveCfg;
    procedure PlayMedia(Owner:Pointer; FileName:String);
    procedure StopMedia(Owner:Pointer);
    procedure PlayNextMedia;
    function GetArcPipFilePath:String;
    function GetTmpPipFilePath:String;
    function GetPipViewerPath(TrackID:Integer):String;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    procedure FlashAnalizForm;
    procedure CheckCorrelator(SpyMode:Boolean);
  public
    property MediaFileNameI[i:Integer]:AnsiString read Get_MediaFileNameI write Set_MediaFileNameI;
    property MediaFileNameO[O:Pointer]:AnsiString read Get_MediaFileNameO write Set_MediaFileNameO;
    property CurMediaFile:AnsiString read Get_CurMediaFile;
    property CurMediaOwner:Pointer read Get_CurMediaOwner;
    property Pipe[i:Integer]:TPipe read Get_Pipe;
  end;

  TPipe=class(TObject)
  private
    function Get_Group(i: Integer): TFrameGroup;
  public
    Section:String;
    Caption:String;
    Groups:TStringList;
    constructor CreateFromIniSection(Ini,Cfg:TIniFile; Section:String);
    procedure SaveCfg(Cfg:TIniFile);
    destructor Destroy;override;
    function CreatePipeForm:TFormPipe;
    function CreateGroupForms:TFormPipe;
    procedure TimerProc;
    property Group[i:Integer]:TFrameGroup read Get_Group;
  end;

var
  FormMain: TFormMain;

function Palette256:PPalette;

implementation

uses
  FileCtrl,DataTypes2,UFormAnaliz;

{$R *.DFM}

type
  TFakedForm=class(TForm)
  end;

const
  Section='Config';
var
  P:TPalette;

function Palette256:PPalette;
begin
  Result:=@P;
end;

procedure SetMIVD(MI:TMenuItem; Flag:Boolean);
begin
  MI.Visible:=Flag;
  MI.Default:=Flag;
end;

procedure TFormMain.FormCreate(Sender: TObject);

  procedure InitPalette;
  const
    dC=255/3;
  Var
    r,g,b,i : Integer;
  Begin
    // init palette
    FillChar(P,SizeOf(P),0);
    i:=0;
    for r:=0 to 3 do for g:=0 to 3 do for b:=0 to 3 do begin
      P.Entry[i].R:=Round(r*dC);
      P.Entry[i].G:=Round(g*dC);
      P.Entry[i].B:=Round(b*dC);
      Inc(i);
    end;
    P.Ver:=$300;
    P.Num:=256;
  End;

  procedure SetupColorMixTbl;
  const
    scl=1/3;
  var
    i,j,k:Integer;
    ir,ig,ib,w:Single;
    kr,kg,kb:Integer;
  begin
    for i:=0 to 63 do begin
      for j:=0 to 3 do begin
        w:=j*scl;
        ir:=(i shr 4) and 3 * w;
        ig:=(i shr 2) and 3 * w;
        ib:=(i shr 0) and 3 * w;
        w:=(3-j)*scl;
        for k:=0 to 63 do begin
          kr:=Round( (k shr 4) and 3 * w + ir);
          kg:=Round( (k shr 2) and 3 * w + ig);
          kb:=Round( (k shr 0) and 3 * w + ib);
          MixTbl[i,j,k]:=kr shl 4 + kg shl 2 + kb;
        end;
      end;
    end;
  end;

var
  Cnt:Integer;
  i:Integer;
  P:TPipe;
  S:String;
begin
  InitFormattingVariables;
  Randomize;
  InitPalette;
  SetupColorMixTbl;
  Pipes:=TObjectList.Create;
  PlayQueue:=TByteStringList.Create;
  if ParamCount=0
  then Ini:=TIniFile.Create(GetModuleFullName+'.ini')
  else Ini:=TIniFile.Create(ExpandFileName(ParamStr(1)));
  Cfg:=TIniFile.Create(ChangeFileExt(Ini.FileName,'.mcf'));
// LoadFromIni
  if not DataTypes2.Initialize(Ini.ReadString(Section,'Server','127.0.0.1'))
  then begin
    Halt(1);
    Sleep(1000);
  end;
  AppExt.TrayHint:=Ini.ReadString(Section,'TrayHint','Monitor');
  Application.Title:=Ini.ReadString(Section,'AppName','Monitor');
  Alpha1:=Ini.ReadFloat(Section,'Alpha1',0.9);
  Alpha2:=Ini.ReadFloat(Section,'Alpha2',0.95);
  CorrBlockLen:=Ini.ReadInteger(Section,'CorrBlockLen',15);
  //
  Cnt:=Ini.ReadInteger(Section,'PipeCount',0);
  for i:=1 to Cnt do begin
    S:=Ini.ReadString(Section,Format('Pipe%.2d',[i]),'');
    if S='' then continue;
    P:=TPipe.CreateFromIniSection(Ini,Cfg,S);
    if P<>nil then Pipes.Add(P);
  end;
  if Cfg.ReadBool(Section,'Grouping',True)
  then miGroupByPipe.Click
  else miGroupByGroup.Click;
  ShowWindow(Application.Handle,0);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
var
  i:Integer;
begin
  ClosePipeForms;
  SaveCfg;
  for i:=0 to PlayQueue.Count-1 do MediaFileNameI[i]:='';
  PlayQueue.Free;
  Pipes.Free;
  Cfg.Free;
  Ini.Free;
  DataTypes2.Finalize;
end;

procedure TFormMain.SaveCfg;
var
  i:Integer;
  P:TPipe;
begin
  Cfg.WriteBool(Section,'Grouping',not miGroupByPipe.Visible);
  for i:=0 to Pipes.Count-1 do begin
    P:=TPipe(Pipes[i]);
    P.SaveCfg(Cfg);
  end;
end;

procedure TFormMain.TimerTimer(Sender: TObject);
var
  i:Integer;
begin
  Timer.Tag:=Timer.Tag+Integer(Timer.Interval);
  if Timer.Tag>=1000 then begin
    Timer.Tag:=Timer.Tag mod 1000;
    for i:=0 to Pipes.Count-1
    do TPipe(Pipes[i]).TimerProc;
  end;
  if FormAnaliz<>nil then FormAnaliz.TimerProc(Timer.Interval);
end;

procedure TFormMain.pmiExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.pmiHideClick(Sender: TObject);
begin
  HidePipeForms;
  if FormAnaliz<>nil then FormAnaliz.Hide;
  SetMIVD(pmiHide,False);
  SetMIVD(pmiShow,True);
end;

procedure TFormMain.pmiShowClick(Sender: TObject);
begin
  if FormAnaliz<>nil then FormAnaliz.Show;
  ShowPipeForms;
  SetMIVD(pmiShow,False);
  SetMIVD(pmiHide,True);
end;

procedure TFormMain.AppExtTrayDefault(Sender: TObject);
begin
  if pmiHide.Visible then begin
    if Application.Active then pmiHide.Click;
  end
  else if pmiShow.Visible then pmiShow.Click;
  SetForegroundWindow(Handle);
end;

procedure TFormMain.pmiAboutClick(Sender: TObject);
var
  Buf:array[0..65535] of Char;
  lpFFI:^VS_FIXEDFILEINFO;
  Len:Cardinal;
  Ver:String;
begin
  if GetFileVersionInfo(PChar(GetModuleFullName+'.exe'),0,SizeOf(Buf),@Buf)
    and VerQueryValue(@Buf,'\',Pointer(lpFFI),Len)
  then begin
    Ver:=
      'Build № '+IntToStr(LowWord(lpFFI.dwFileVersionLS))+#13;
  end
  else Ver:=GetErrorMsg(GetLastError);
  Application.MessageBox(
    PChar(
      'СКУ'#13#13+
      'Монитор визуального контроля'#13+Ver+#13+
      '(c) 2000-2003 ООО "Компания Телекомнур", г. Уфа'#13#13+
      'e-mail: test@mail.rb.ru'
    ),
    'О программе',
    MB_ICONINFORMATION or MB_OK or MB_TOPMOST);
end;

procedure TFormMain.PlayMedia(Owner:Pointer; FileName: String);
begin
  MediaFileNameO[Owner]:=FileName;
  if MediaPlayer.Mode<>mpPlaying then PlayNextMedia;
end;

procedure TFormMain.StopMedia(Owner:Pointer);
begin
  MediaFileNameO[Owner]:='';
  if (MediaPlayer.Mode=mpPlaying) and (Pointer(MediaPlayer.Tag)=Owner) then begin
    MediaPlayer.Close;
    MediaPlayer.Tag:=0;
    PlayNextMedia;
  end;
end;

function TFormMain.Get_MediaFileNameI(i: Integer): AnsiString;
begin
  Result:=AnsiString(PlayQueue.Objects[i]);
end;

function TFormMain.Get_MediaFileNameO(O: Pointer): AnsiString;
var
  i:Integer;
  S:String;
begin
  SetLength(S,4);
  Move(O,S[1],4);
  i:=PlayQueue.IndexOf(S);
  if i=-1 then Result:='' else Result:=MediaFileNameI[i];
end;

procedure TFormMain.Set_MediaFileNameI(i: Integer;
  const Value: AnsiString);
begin
  PlayQueue.Objects[i]:=TObject(Value);
end;

procedure TFormMain.Set_MediaFileNameO(O: Pointer;
  const Value: AnsiString);
var
  i:Integer;
  S:String;
begin
  SetLength(S,4);
  Move(O,S[1],4);
  i:=PlayQueue.IndexOf(S);
  if i=-1 then PlayQueue.AddObject(S,TObject(Value))
  else MediaFileNameI[i]:=Value;
end;

function TFormMain.Get_CurMediaFile: AnsiString;
begin
  Result:=MediaFileNameI[0];
end;

procedure TFormMain.PlayNextMedia;
var
  i:Integer;
  T:TObject;
  S:String;
begin
  i:=PlayQueue.Count-1;
  repeat
    Dec(i);
    S:=PlayQueue[0]; T:=PlayQueue.Objects[0]; PlayQueue.Delete(0);
    PlayQueue.AddObject(S,T);
  until (i<=0) or (CurMediaFile<>'');
  if (CurMediaFile='') or (MediaPlayer.Mode=mpPlaying) then exit;
  try
    MediaPlayer.Close;
    MediaPlayer.Tag := Integer(CurMediaOwner);
    MediaPlayer.FileName := CurMediaFile;
    MediaPlayer.Open;
    MediaPlayer.Play;
  except
  end;
end;

function TFormMain.Get_CurMediaOwner: Pointer;
begin
  Move(PlayQueue[0][1],Result,4);
end;

procedure TFormMain.ClosePipeForms;
var
  i:Integer;
  C:TComponent;
  PF:TFormPipe absolute C;
begin
  HidePipeForms;
  for i:=ComponentCount-1 downto 0 do begin
    C:=Components[i];
    if C is TFormPipe then begin
      PF.SaveCfg(Cfg);
      PF.Free;
    end;
  end;
end;

{ TPipe }

destructor TPipe.Destroy;
var
  i:Integer;
begin
  for i:=0 to Groups.Count-1 do Group[i].Free;
  Groups.Free;
  inherited;
end;

constructor TPipe.CreateFromIniSection(Ini,Cfg: TIniFile; Section: String);
var
  i:Integer;
  S:String;
  PipeIni:TIniFile;
  G:TFrameGroup;
begin
  inherited Create;
  Self.Section:=Section;
  Groups:=TStringList.Create;
  Caption:=Ini.ReadString(Section,'Caption','НПП');
  PipeIni:=TIniFile.Create(Ini.ReadString(Section,'Ini','NPP_'+Section));
  try
    for i:=1 to Ini.ReadInteger(Section,'GroupCount',0) do begin
      S:=Ini.ReadString(Section,Format('Group%.2d',[i]),'');
      if S='' then continue;
      G:=TFrameGroup.CreateFromIniSection(FormMain,PipeIni,Cfg,S);
      if G<>nil then Groups.AddObject(S,G);
    end;
  finally
    PipeIni.Free;
  end;
end;

procedure TPipe.SaveCfg(Cfg: TIniFile);
var
  i:Integer;
begin
  for i:=0 to Groups.Count-1 do Group[i].SaveCfg(Cfg);
end;

function TPipe.CreatePipeForm:TFormPipe;
var
  i:Integer;
begin
  Result:=TFormPipe.CreateFromIniSection(FormMain,FormMain.Cfg,Section);
  for i:=0 to Groups.Count-1
  do Result.InsertGroup(Group[i]);
  Result.Caption:=Caption;
end;

procedure TPipe.TimerProc;
var
  i:Integer;
begin
  for i:=0 to Groups.Count-1
  do Group[i].TimerProc;
end;

function TPipe.Get_Group(i: Integer): TFrameGroup;
begin
  Result:=TFrameGroup(Groups.Objects[i]);
end;

procedure TFormMain.miGroupByPipeClick(Sender: TObject);
var
  i:Integer;
begin
  miGroupByPipe.Visible:=False; miGroupByPipe.Enabled:=False;
  miGroupByGroup.Visible:=True; miGroupByGroup.Enabled:=True;
  ClosePipeForms;
  for i:=0 to Pipes.Count-1
  do Pipe[i].CreatePipeForm;
  pmiShow.Click;
end;

procedure TFormMain.miGroupByGroupClick(Sender: TObject);
var
  i:Integer;
begin
  miGroupByPipe.Visible:=True;   miGroupByPipe.Enabled:=True;
  miGroupByGroup.Visible:=False; miGroupByGroup.Enabled:=False;
  ClosePipeForms;
  for i:=0 to Pipes.Count-1
  do Pipe[i].CreateGroupForms;
  pmiShow.Click;
end;

function TFormMain.Get_Pipe(i: Integer): TPipe;
begin
  Result:=TPipe(Pipes[i]);
end;

function TPipe.CreateGroupForms:TFormPipe;
var
  i:Integer;
begin
  Result:=nil;
  for i:=0 to Groups.Count-1 do begin
    Result:=TFormPipe.CreateFromIniSection(FormMain,FormMain.Cfg,Groups[i]);
    Result.InsertGroup(Group[i]);
    Result.Caption:=Group[i].Caption;
  end;
end;

procedure TFormMain.EnablePipeForms(Enabled: Boolean);
var
  i:Integer;
begin
  for i:=0 to ComponentCount-1 do
    if Components[i] is TFormPipe
    then TFormPipe(Components[i]).Enabled:=Enabled;
end;

procedure TFormMain.HidePipeForms;
var
  i:Integer;
begin
  EnablePipeForms(False);
  for i:=0 to ComponentCount-1 do
    if Components[i] is TFormPipe
    then TFormPipe(Components[i]).Hide;
end;

procedure TFormMain.ShowPipeForms;
var
  i:Integer;
begin
  for i:=0 to ComponentCount-1 do
    if Components[i] is TFormPipe
    then TFormPipe(Components[i]).Show;
  EnablePipeForms(True);
  SetZOrder(True);
end;

procedure TFormMain.AppExtDeactivate(Sender: TObject);
var
  A:TForm;
begin
  A:=Screen.ActiveForm;
  if (A<>nil) and Assigned(A.OnDeactivate)
  then A.OnDeactivate(A);
end;

function TFormMain.GetArcPipFilePath: String;
begin
  Result:=Ini.ReadString(Section,'ArcPipFile',
    'C:\TEMP\PIP\%NPP_ID%%SectID%_%Year%_%Month%_%Day%.pip');
end;

function TFormMain.GetPipViewerPath(TrackID: Integer): String;
var
  i:Integer;
  W:WideString;
  SR:TSearchRec;
  ValidPV:Boolean;
  SrcPVFile,PVFile,PVPath:String;
  SrcPVSize,PVSize:Integer;
  Src,Dst:TFileStream;
  ErrMsg:String;
begin
  ErrMsg:='';
  // Получаем в SrcPVFile путь и имя исходного файла просмотрщика архивов
  SrcPVFile:=Ini.ReadString(Section,'SrcPipViewer','C:\SKU\pipview.exe');
  // Считываем размер файла SrcPVFile (0, если файл не существует)
  if FindFirst(SrcPVFile,faAnyFile,SR)=0
  then SrcPVSize:=SR.Size
  else SrcPVSize:=-1;
  FindClose(SR);
  // Получаем в PVFile путь и имя файла просмотрщика архивов
  AM2.applySubstitutions(
    Ini.ReadString(Section,'PipViewer','C:\TEMP\PIP\pv_%NPP_ID%%SectID%.exe'),
    TrackID,Now,W
  );
  PVFile:=W;
  // Получаем результат проверки файла PVFile в переменной ValidPV
  // (Суть проверки: файл существует и размер совпадает с размером SrcPVFile)
  ValidPV:=False;
  if FindFirst(PVFile,faReadOnly or faHidden or faSysFile or faArchive,SR)=0
  then begin
    PVSize:=SR.Size;
    ValidPV:=(SrcPVSize<0) or (PVSize=SrcPVSize);
  end
  else PVSize:=-1;
  FindClose(SR);
  if not ValidPV then begin
    i:=Length(PVFile);
    while (i>0) and (PVFile[i]<>'\') do Dec(i);
    PVPath:=Copy(PVFile,1,i-1);
    if not ForceDirectories(PVPath)
    then ErrMsg:='Не могу создать структуру каталогов'#13+PVPath
    else begin
      try
        Src:=TFileStream.Create(SrcPVFile,fmOpenRead);
        try
          try
            if PVSize<0
            then Dst:=TFileStream.Create(PVFile,fmCreate)
            else Dst:=TFileStream.Create(PVFile,fmOpenWrite);
            try
              try
                Dst.CopyFrom(Src,Src.Size);
              except
                ErrMsg:='Не могу скопировать файл'#13+SrcPVFile+
                  #13'в файл'#13+PVFile;
              end;
            finally
              Dst.Free;
            end
          except
            ErrMsg:='Ну могу создать файл'#13+PVFile;
          end;
        finally
          Src.Free;
        end;
      except
        ErrMsg:='Не могу открыть исходный файл'#13+SrcPVFile;
      end;
    end;
  end;
  if ErrMsg<>'' then begin
    Application.MessageBox(PChar(ErrMsg),
      'Ошибка при запуске просмотрщика архивов', MB_OK or MB_ICONERROR
    );
    Result:='';
  end
  else Result:=PVFile;
end;

function TFormMain.GetTmpPipFilePath: String;
begin
  Result:=Ini.ReadString(Section,'TmpPipFile',
    'C:\TEMP\PIP\Temp_%NPP_ID%%SectID%.pip');
end;

function TFormMain.IsShortCut(var Message: TWMKey): Boolean;
begin
  Result:=PopupMenu.IsShortCut(Message) or inherited IsShortCut(Message);
end;

procedure TFormMain.FlashAnalizForm;
begin
  if FormAnaliz=nil
  then FormAnaliz:=TFormAnaliz.Create(Self)
  else begin
    FormAnaliz.Free;
    FormAnaliz:=nil;
  end;
  CorrelatorEnabled:=FormAnaliz<>nil;
end;

procedure TFormMain.CheckCorrelator(SpyMode: Boolean);
var
  SCE:Boolean;
begin
  SCE:=CorrelatorEnabled;
  if (CorrelatorEnabled and not SpyMode) xor (FormAnaliz<>nil)
  then FlashAnalizForm;
  CorrelatorEnabled:=SCE;
end;

end.

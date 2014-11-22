program ConvINI;
{$APPTYPE CONSOLE}
uses
  SysUtils,IniFiles;

var
  SIni,DIni:TIniFile;
  SrcIni,DstIni,Cfg:TIniFile;
  SS,DS:String;

function CopyParam(Ident:String;Default:String):String;
begin
  Result:=SIni.ReadString(SS,Ident,Default);
  DIni.WriteString(DS,Ident,Result);
end;

procedure Conv_FPG(SrcS,DstS:String);
var
  SensIni:TIniFile;
  SID:String;
begin
  SIni:=SrcIni; SS:=SrcS;
  DIni:=DstIni; DS:=DstS;
  // to new INI
  SID:=CopyParam('SensorID','ZZZ');
  // to sensor's INI
  SensIni:=TIniFile.Create('Sensors\'+SID+'.ini');
  DIni:=SensIni; DS:='Info';
  DIni.WriteString(DS,'SensorID',SID);
  CopyParam('Caption','');
  CopyParam('Km','');
  SensIni.Free;
  // to monitor configuration file
  DIni:=Cfg; DS:=DstS;
  CopyParam('DDSHigh','0');
  CopyParam('ValueHigh','');
  CopyParam('DDSLow','0');
  CopyParam('ValueLow','');
  CopyParam('DDSUseFilter','0');
  CopyParam('Alpha','');
  CopyParam('AlphaView','');
  CopyParam('HighAutoOn','');
  CopyParam('HighScale','');
  CopyParam('HighAlpha','');
  CopyParam('HighMin','');
  CopyParam('HighMax','');
  CopyParam('LowAutoOn','');
  CopyParam('LowScale','');
  CopyParam('LowAlpha','');
  CopyParam('LowMin','');
  CopyParam('LowMax','');
  CopyParam('MinGraphHeight','');
  CopyParam('ShowGraph','1');
  CopyParam('ShowAvgGraph','0');
  CopyParam('MaxNoDataTime','');
  CopyParam('AutoCenterOn','1');
  CopyParam('AutoCenterType','');
end;

procedure Conv_PipeForm(SrcS,DstS:String);
var
  i,e,Cnt:Integer;
  FrameName:String;
begin
  SIni:=SrcIni; SS:=SrcS;
  DIni:=DstIni; DS:=DstS;
  // to new INI
  CopyParam('Caption','');
  CopyParam('RecsPerDay','86400');
  Val(CopyParam('FrameCount','0'),Cnt,e); if e<>0 then Cnt:=0;
  CopyParam('PipViewer','');
  CopyParam('ArcPipFile','');
  CopyParam('TmpPipFile','');
  // to monitor configuration file
  DIni:=Cfg; DS:=DstS;
  CopyParam('DDSWinWidth','');
  CopyParam('DDSLineLen','');
  CopyParam('AlarmNoSound','');
  CopyParam('AlarmSingle','');
  CopyParam('AlarmNoData','');
  CopyParam('AlarmSpeaker','');
  CopyParam('AlarmMedia','');
  CopyParam('MediaFile','');
  CopyParam('WaveSpeed','1100');
  CopyParam('TimeDelta','');
  CopyParam('Left','');
  CopyParam('Top','');
  CopyParam('Width','');
  CopyParam('Height','');
  CopyParam('ZoomWinWidth','');
  //*** frames
  for i:=1 to Cnt do begin
    FrameName:='Frame'+IntToStr(i);
    Conv_FPG(
      SrcIni.ReadString(SrcS,FrameName,''),
      DstS+'.'+FrameName
    );
  end;
end;

const
  Section:String='Config';
var
  i,e,Cnt:Integer;
  PFName:String;
begin
  if ParamCount<>2 then begin
    Write(
      '*** SKU monitor INI files convertor ***'#13#10+
      'Usage: ConvINI <Source INI> <Destination INI>'
    );
    exit;
  end;
  SrcIni:=TIniFile.Create(ExpandFileName(ParamStr(1)));
  DstIni:=TIniFile.Create(ExpandFileName(ParamStr(2)));
  Cfg:=TIniFile.Create(ChangeFileExt(DstIni.FileName,'.mcf'));
  // to new INI
  SIni:=SrcIni; SS:=Section;
  DIni:=DstIni; DS:=Section;
  CopyParam('Server','127.0.0.1');
  CopyParam('TrayHint','Monitor');
  CopyParam('AppName','Monitor');
  Val(CopyParam('PipeFormCount','0'),Cnt,e); if e<>0 then Cnt:=0;
  for i:=1 to Cnt do begin
    PFName:='PipeForm'+IntToStr(i);
    Conv_PipeForm(
      SrcIni.ReadString(Section,PFName,''),
      PFName
    );
  end;
  Cfg.Free;
  DstIni.Free;
  SrcIni.Free;
end.

object FrmMain: TFrmMain
  Left = 131
  Top = 192
  Width = 568
  Height = 169
  Caption = 'СКУ : Синхронизация архива (++Grp)'
  Color = clBtnFace
  Constraints.MinHeight = 128
  Constraints.MinWidth = 512
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 338
    Top = 0
    Width = 6
    Height = 123
    Cursor = crHSplit
    Align = alRight
    Beveled = True
  end
  object sgTracks: TStringGrid
    Left = 344
    Top = 0
    Width = 216
    Height = 123
    Align = alRight
    ColCount = 2
    DefaultColWidth = 48
    DefaultRowHeight = 20
    RowCount = 2
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
    ParentFont = False
    TabOrder = 0
    OnDrawCell = sgConnsDrawCell
    ColWidths = (
      50
      156)
    RowHeights = (
      20
      20)
  end
  object sgConns: TStringGrid
    Left = 0
    Top = 0
    Width = 338
    Height = 123
    Align = alClient
    ColCount = 2
    DefaultColWidth = 48
    DefaultRowHeight = 20
    RowCount = 2
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
    ParentFont = False
    TabOrder = 1
    OnDrawCell = sgConnsDrawCell
    ColWidths = (
      104
      224)
    RowHeights = (
      20
      20)
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 123
    Width = 560
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object Timer: TTimer
    Interval = 100
    OnTimer = TimerTimer
    Left = 122
    Top = 72
  end
  object AppExt: TDdhAppExt
    HintShortPause = 0
    TrayHint = 'Tip'
    Left = 156
    Top = 72
  end
end

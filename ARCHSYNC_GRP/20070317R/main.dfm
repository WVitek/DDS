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
    Top = 26
    Width = 6
    Height = 97
    Cursor = crHSplit
    Align = alRight
    Beveled = True
  end
  object sgTracks: TStringGrid
    Left = 344
    Top = 26
    Width = 216
    Height = 97
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
    Top = 26
    Width = 338
    Height = 97
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 560
    Height = 26
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object SpdBtnResync: TSpeedButton
      Left = 2
      Top = 1
      Width = 24
      Height = 24
      Hint = 'Инициировать синхронизацию времени'
      Flat = True
      Glyph.Data = {
        7E010000424D7E01000000000000760000002800000016000000160000000100
        0400000000000801000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
        EEEEEEEEEE00000000000000000000000E000EEEEEEEEEEEEEEEEEEE0E000EEE
        EEEEEE0EEEEEEEEE0E000EEEEE0EEEEEEE0EEEEE0E000EEEEEEEEEEEEEEEEEEE
        0E000EEEEEEEEEEEEEEEEEEE0E000EE0EEEEEEEEEEEEE0EE0E000EEEEEEEEEEE
        EEEEEEEE0E000EEEEEEEEEEEEEEEEEEE0E000EEEEEEEEE0EEEEEEEEE0E000E0E
        EEEEE000000EEE0E0E000EEEEEEEEE0EEEEEEEEE0E000EEEEEEEEE0EEEEEEEEE
        0E000EEEEEEEEE0EEEEEEEEE0E000EE0EEEEEE0EEEEEE0EE0E000EEEEEEEEE0E
        EEEEEEEE0E000EEEEEEEEE0EEEEEEEEE0E000EEEEE0EEEEEEE0EEEEE0E000EEE
        EEEEEE0EEEEEEEEE0E000EEEEEEEEEEEEEEEEEEE0E0000000000000000000000
        0E00}
      ParentShowHint = False
      ShowHint = True
      OnClick = SpdBtnResyncClick
    end
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

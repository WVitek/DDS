object FormMain: TFormMain
  Left = 142
  Top = 331
  AutoScroll = False
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'NetMultiLoader'
  ClientHeight = 423
  ClientWidth = 632
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001001010100000000000280100001600000028000000100000002000
    00000100040000000000C0000000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    0000000000000009B9B9B9B000000006666666600000000EEEEEEEE00000000E
    E7777EEE000000EE777777EE000000EE777777EE000000EE777777EE000000EF
    E7777EFE000000EE797777EE000000EE777777EE000000EE777777EE0000000E
    E7777EE00000000EEEEEEEE00000000EE6666EE000000000088880000000F007
    0000E0070000E0070000E0030000E0030000C0030000C0030000C0030000C003
    0000C0030000C0030000C0070000E0070000E0070000E00F0000F87F0000}
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object TreeView: TTreeView
    Left = 0
    Top = 0
    Width = 113
    Height = 423
    Align = alLeft
    Indent = 19
    ReadOnly = True
    TabOrder = 0
    OnChange = TreeViewChange
  end
  object AppExt: TDdhAppExt
    Icon.Data = {
      0000010001001010100000000000280100001600000028000000100000002000
      00000100040000000000C0000000000000000000000000000000000000000000
      000000008000008000000080800080000000800080008080000080808000C0C0
      C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
      0000000000000009B9B9B9B000000006666666600000000EEEEEEEE00000000E
      E7777EEE000000EE777777EE000000EE777777EE000000EE777777EE000000EF
      E7777EFE000000EE797777EE000000EE777777EE000000EE777777EE0000000E
      E7777EE00000000EEEEEEEE00000000EE6666EE000000000088880000000F007
      0000E0070000E0070000E0030000E0030000C0030000C0030000C0030000C003
      0000C0030000C0030000C0070000E0070000E0070000E00F0000F87F0000}
    Title = 'MultiLoader7188'
    HintShortPause = 0
    TrayIconActive = True
    TrayIcon.Data = {
      0000010001001010100000000000280100001600000028000000100000002000
      00000100040000000000C0000000000000000000000000000000000000000000
      000000008000008000000080800080000000800080008080000080808000C0C0
      C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
      0000000000000009B9B9B9B000000006666666600000000EEEEEEEE00000000E
      E7777EEE000000EE777777EE000000EE777777EE000000EE777777EE000000EF
      E7777EFE000000EE797777EE000000EE777777EE000000EE777777EE0000000E
      E7777EE00000000EEEEEEEE00000000EE6666EE000000000088880000000F007
      0000E0070000E0070000E0030000E0030000C0030000C0030000C0030000C003
      0000C0030000C0030000C0070000E0070000E0070000E00F0000F87F0000}
    TrayHint = 'Tip'
    TrayPopup = PopupMenu
    OnTrayDefault = AppExtTrayDefault
    OnLBtnDown = AppExtTrayDefault
    Left = 16
    Top = 16
  end
  object PopupMenu: TPopupMenu
    Left = 16
    Top = 64
    object pmiShowHide: TMenuItem
      Bitmap.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
        EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
        EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
        EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
        EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE}
      Caption = '�������� / ��������'
      Default = True
      OnClick = AppExtTrayDefault
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object pmiAbout: TMenuItem
      Bitmap.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
        EEEEE00000000000000EE0EEEEEEEEEEEE0EE0EE70000007EE0EE0EEEE7007EE
        EE0EE0EEEE7007EEEE0EE0EEEE7007EEEE0EE0EEEE7007EEEE0EE0EEEE7007EE
        EE0EE0EE700007EEEE0EE0EEEEEEEEEEEE0EE0EEEE7007EEEE0EE0EEEE7007EE
        EE0EE0EEEEEEEEEEEE0EE00000000000000EEEEEEEEEEEEEEEEE}
      Caption = '� ��������� ...'
      OnClick = pmiAboutClick
    end
    object pmiClose: TMenuItem
      Bitmap.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
        EEEEE00000000000000EE0EEEEEEEEEEEE0EE0E00EEEEEE00E0EE0E000EEEE00
        0E0EE0EE000EE000EE0EE0EEE000000EEE0EE0EEEE0000EEEE0EE0EEEE0000EE
        EE0EE0EEE000000EEE0EE0EE000EE000EE0EE0E000EEEE000E0EE0E00EEEEEE0
        0E0EE0EEEEEEEEEEEE0EE00000000000000EEEEEEEEEEEEEEEEE}
      Caption = '�������'
      OnClick = pmiCloseClick
    end
  end
  object NMUDP: TNMUDP
    RemotePort = 0
    LocalPort = 19864
    ReportLevel = 1
    OnInvalidHost = NMUDPInvalidHost
    OnBufferInvalid = NMUDPBufferInvalid
    Left = 16
    Top = 112
  end
  object Timer: TTimer
    OnTimer = TimerTimer
    Left = 16
    Top = 160
  end
  object TimerProcessIO: TTimer
    Interval = 5
    OnTimer = ProcessIO
    Left = 16
    Top = 256
  end
end

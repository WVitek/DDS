object FormDataCol: TFormDataCol
  Left = 298
  Top = 296
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = '��� : ���� ������'
  ClientHeight = 65
  ClientWidth = 385
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object AppExt: TDdhAppExt
    HintShortPause = 0
    TrayIconActive = True
    TrayIcon.Data = {
      0000010001001010100000000000280100001600000028000000100000002000
      00000100040000000000C0000000000000000000000000000000000000000000
      000000008000008000000080800080000000800080008080000080808000C0C0
      C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
      00000000000000000000000000000000000BE00000000000000BE00000000000
      000000000000000000000000000000EE00FFFF00BB0000EE00FFFF00BB000000
      00FFFF0000000000000000000000000000000000000000000000000000000000
      000DD00000000000000DD00000000000000DD00000000000000000000000FE7F
      0000FE7F0000F81F0000FC3F0000DE7B0000C81300000000000000000000C813
      0000D81B0000FE7F0000FE7F0000F00F0000F81F0000FC3F0000FE7F0000}
    TrayHint = '��� : ���� ������'
    TrayPopup = TrayPopupMenu
    OnLBtnDown = AppExtLBtnDown
    Left = 8
    Top = 8
  end
  object TrayPopupMenu: TPopupMenu
    Left = 48
    Top = 8
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
end

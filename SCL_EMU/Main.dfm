object Form1: TForm1
  Left = 245
  Top = 170
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Имитатор одноканального загрузчика'
  ClientHeight = 44
  ClientWidth = 321
  Color = clBtnFace
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
  object StTxtP1: TStaticText
    Left = 32
    Top = 8
    Width = 100
    Height = 35
    AutoSize = False
    Caption = '0.0000'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object StTxtP2: TStaticText
    Left = 176
    Top = 8
    Width = 100
    Height = 35
    AutoSize = False
    Caption = '0.0000'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object CheckBox: TCheckBox
    Left = 144
    Top = 16
    Width = 13
    Height = 17
    Hint = 'Ускоренный режим выдачи'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
  end
  object NMUDP1: TNMUDP
    RemoteHost = '127.0.0.1'
    RemotePort = 0
    LocalPort = 0
    ReportLevel = 1
    Top = 8
  end
  object Timer: TTimer
    OnTimer = TimerTimer
    Left = 288
    Top = 8
  end
end

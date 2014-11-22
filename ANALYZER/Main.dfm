object Form1: TForm1
  Left = 213
  Top = 125
  Width = 427
  Height = 395
  Caption = 'Form1'
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
  object Button1: TButton
    Left = 336
    Top = 336
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 417
    Height = 161
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
  object Memo2: TMemo
    Left = 0
    Top = 163
    Width = 417
    Height = 161
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
    WordWrap = False
  end
  object stTime: TStaticText
    Left = 8
    Top = 336
    Width = 58
    Height = 17
    AutoSize = False
    Caption = '0:00:00'
    TabOrder = 3
  end
end

object MainForm: TMainForm
  Left = 278
  Top = 244
  BorderStyle = bsSingle
  Caption = 'СКУ : Менеджер архива'
  ClientHeight = 54
  ClientWidth = 232
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Timer: TTimer
    OnTimer = TimerTimer
    Left = 8
    Top = 8
  end
end

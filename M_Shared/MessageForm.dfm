object FormMessage: TFormMessage
  Left = 255
  Top = 167
  ActiveControl = BtnOk
  BorderStyle = bsDialog
  ClientHeight = 244
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 6
    Top = 4
    Width = 387
    Height = 205
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
  end
  object BtnOk: TButton
    Left = 162
    Top = 215
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object BtnMap: TButton
    Left = 6
    Top = 215
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Карта'
    Default = True
    TabOrder = 2
    OnClick = BtnMapClick
  end
end

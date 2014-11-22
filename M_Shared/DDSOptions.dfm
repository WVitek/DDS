object FormDDSOptions: TFormDDSOptions
  Left = 279
  Top = 270
  BorderStyle = bsDialog
  Caption = 'Настройки'
  ClientHeight = 117
  ClientWidth = 321
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object BtnOk: TButton
    Left = 65
    Top = 88
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = BtnOkClick
  end
  object BtnCancel: TButton
    Left = 153
    Top = 88
    Width = 75
    Height = 25
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 1
  end
  object BtnApply: TButton
    Left = 241
    Top = 88
    Width = 75
    Height = 25
    Caption = 'Применить'
    ModalResult = 4
    TabOrder = 2
    OnClick = BtnOkClick
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 6
    Width = 308
    Height = 75
    Caption = ' Настройки упрощенной СКУ '
    TabOrder = 3
    object cbOtn: TCheckBox
      Left = 8
      Top = 20
      Width = 225
      Height = 17
      Caption = 'Допустимое относительное отклонение'
      TabOrder = 0
    end
    object edOtn: TEdit
      Left = 235
      Top = 18
      Width = 66
      Height = 21
      TabOrder = 1
      Text = '0'
    end
    object edAbs: TEdit
      Left = 235
      Top = 42
      Width = 66
      Height = 21
      TabOrder = 2
      Text = '0'
    end
    object cbAbs: TCheckBox
      Left = 8
      Top = 44
      Width = 209
      Height = 17
      Caption = 'Допустимое абсолютное отклонение'
      TabOrder = 3
    end
  end
end

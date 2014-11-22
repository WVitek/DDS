object FormConv: TFormConv
  Left = 312
  Top = 332
  BorderStyle = bsDialog
  Caption = 'Преобразование'
  ClientHeight = 132
  ClientWidth = 231
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  ShowHint = True
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 7
    Top = 8
    Width = 154
    Height = 27
    Caption = 'Y(X0=    )='
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 7
    Top = 37
    Width = 154
    Height = 27
    Caption = 'Y(X1=    )='
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 77
    Top = 66
    Width = 84
    Height = 27
    Caption = 'Ymin ='
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object edX0: TEdit
    Left = 80
    Top = 11
    Width = 49
    Height = 21
    Hint = 'X0 (от 0 до 1 опорного напряжения Vref АЦП)'
    TabOrder = 0
    Text = 'X0'
  end
  object edX1: TEdit
    Left = 80
    Top = 40
    Width = 49
    Height = 21
    Hint = 'X1 (от 0 до 1 опорного напряжения Vref АЦП)'
    TabOrder = 2
    Text = 'X1'
  end
  object edY1: TEdit
    Left = 168
    Top = 40
    Width = 56
    Height = 21
    Hint = 'Соответствующее замеренному X1 значение физической величины Y1'
    TabOrder = 3
    Text = 'Y1'
  end
  object edY0: TEdit
    Left = 168
    Top = 11
    Width = 56
    Height = 21
    Hint = 'Соответствующее замеренному X0 значение физической величины Y0'
    TabOrder = 1
    Text = 'Y0'
  end
  object BtnOk: TButton
    Left = 7
    Top = 100
    Width = 68
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'ОК'
    Default = True
    TabOrder = 5
    OnClick = BtnOkClick
  end
  object BtnCancel: TButton
    Left = 78
    Top = 100
    Width = 68
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 6
  end
  object edYmin: TEdit
    Left = 168
    Top = 69
    Width = 56
    Height = 21
    Hint = 'Минимальное корректное значение измеряемой физической величины'
    TabOrder = 4
    Text = 'Ymin'
  end
  object BtnApply: TButton
    Left = 156
    Top = 100
    Width = 68
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Применить'
    TabOrder = 7
    OnClick = BtnApplyClick
  end
end

object FormConversion: TFormConversion
  Left = 245
  Top = 170
  BorderStyle = bsDialog
  Caption = 'Преобразование'
  ClientHeight = 177
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object rgADCRange: TRadioGroup
    Left = 0
    Top = 0
    Width = 113
    Height = 177
    Caption = ' Диапазон АЦП '
    Items.Strings = (
      '+/- 15 mV'
      '+/- 50 mV'
      '+/- 100 mV'
      '+/- 150 mV'
      '+/- 500 mV'
      '+/- 1 V'
      '+/- 2.5 V'
      '+/- 5 V'
      '+/- 10 V'
      '+/- 20 mA (2.5V)')
    TabOrder = 0
  end
  object GroupBoxSrc: TGroupBox
    Left = 118
    Top = 0
    Width = 145
    Height = 128
    Caption = ' Измеряемая величина '
    TabOrder = 1
    object pcSource: TPageControl
      Left = 8
      Top = 16
      Width = 129
      Height = 105
      ActivePage = tsCurrent
      HotTrack = True
      MultiLine = True
      TabOrder = 0
      object tsCurrent: TTabSheet
        Caption = 'Ток'
        object Label3: TLabel
          Left = 24
          Top = 55
          Width = 17
          Height = 13
          Caption = 'R ='
        end
        object Label1: TLabel
          Left = 20
          Top = 9
          Width = 21
          Height = 13
          Caption = 'I a ='
        end
        object Label2: TLabel
          Left = 20
          Top = 31
          Width = 21
          Height = 13
          Caption = 'I b ='
        end
        object edR: TEdit
          Left = 48
          Top = 52
          Width = 57
          Height = 21
          Hint = 'Сопротивление шунта, Ом'
          TabOrder = 2
        end
        object edIa: TEdit
          Left = 48
          Top = 4
          Width = 57
          Height = 21
          Hint = 'Минимальное значение тока, Ампер'
          TabOrder = 0
        end
        object edIb: TEdit
          Left = 48
          Top = 28
          Width = 57
          Height = 21
          Hint = 'Максимальное значение тока, Ампер'
          TabOrder = 1
        end
      end
      object tsVoltage: TTabSheet
        Caption = 'Напряжение'
        ImageIndex = 1
        object Label4: TLabel
          Left = 15
          Top = 9
          Width = 26
          Height = 13
          Caption = 'U a ='
        end
        object Label5: TLabel
          Left = 15
          Top = 31
          Width = 26
          Height = 13
          Caption = 'U b ='
        end
        object edUa: TEdit
          Left = 48
          Top = 4
          Width = 57
          Height = 21
          Hint = 'Минимальное значение разности потенциалов, Вольт'
          TabOrder = 0
        end
        object edUb: TEdit
          Left = 48
          Top = 28
          Width = 57
          Height = 21
          Hint = 'Максимальное значение разности потенциалов, Вольт'
          TabOrder = 1
        end
      end
    end
  end
  object GroupBoxDst: TGroupBox
    Left = 267
    Top = 0
    Width = 131
    Height = 128
    Caption = ' Величина результата '
    TabOrder = 2
    object Label6: TLabel
      Left = 33
      Top = 49
      Width = 25
      Height = 13
      Caption = 'X a ='
    end
    object Label7: TLabel
      Left = 33
      Top = 71
      Width = 25
      Height = 13
      Caption = 'X b ='
    end
    object Label8: TLabel
      Left = 23
      Top = 25
      Width = 35
      Height = 13
      Caption = 'X min ='
    end
    object edXa: TEdit
      Left = 64
      Top = 44
      Width = 61
      Height = 21
      Hint = 'Минимальное значение физической величины'
      TabOrder = 1
    end
    object edXb: TEdit
      Left = 64
      Top = 68
      Width = 61
      Height = 21
      Hint = 'Максимальное значение физической величины'
      TabOrder = 2
    end
    object edXm: TEdit
      Left = 64
      Top = 20
      Width = 61
      Height = 21
      Hint = 'Минимальное допустимое значение физической величины'
      TabOrder = 0
    end
  end
  object BtnOk: TButton
    Left = 133
    Top = 142
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = BtnOkClick
  end
  object BtnCancel: TButton
    Left = 221
    Top = 142
    Width = 75
    Height = 25
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 4
  end
  object BtnApply: TButton
    Left = 309
    Top = 142
    Width = 75
    Height = 25
    Caption = 'Применить'
    TabOrder = 5
    OnClick = BtnApplyClick
  end
end

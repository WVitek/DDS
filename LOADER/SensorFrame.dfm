object FrameSensor: TFrameSensor
  Left = 0
  Top = 0
  Width = 387
  Height = 101
  Enabled = False
  TabOrder = 0
  object gbSensor: TGroupBox
    Left = 0
    Top = 0
    Width = 387
    Height = 101
    Align = alClient
    TabOrder = 0
    object Label1: TLabel
      Left = 183
      Top = 13
      Width = 133
      Height = 13
      Caption = 'Заводской номер датчика'
    end
    object Label2: TLabel
      Left = 197
      Top = 79
      Width = 121
      Height = 13
      Caption = 'Номер датчика на шине'
    end
    object Label3: TLabel
      Left = 18
      Top = 79
      Width = 120
      Height = 13
      Caption = 'Сетевой номер датчика'
    end
    object Label4: TLabel
      Left = 7
      Top = 35
      Width = 93
      Height = 13
      Caption = 'Давление, кг/см2'
    end
    object Label5: TLabel
      Left = 7
      Top = 57
      Width = 84
      Height = 13
      Caption = 'Температура, °C'
    end
    object Label6: TLabel
      Left = 235
      Top = 57
      Width = 80
      Height = 13
      Caption = 'Смещение нуля'
    end
    object Label7: TLabel
      Left = 196
      Top = 35
      Width = 120
      Height = 13
      Caption = 'Коэффициент усиления'
    end
    object edFactoryNum: TEdit
      Left = 322
      Top = 10
      Width = 60
      Height = 21
      TabOrder = 4
    end
    object edBusNumber: TEdit
      Left = 322
      Top = 76
      Width = 30
      Height = 21
      TabOrder = 7
    end
    object edNetNumber: TEdit
      Left = 142
      Top = 76
      Width = 36
      Height = 21
      TabOrder = 8
    end
    object cbOn: TCheckBox
      Left = 7
      Top = 9
      Width = 73
      Height = 17
      Caption = 'Включено'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object stPressure: TStaticText
      Left = 103
      Top = 33
      Width = 74
      Height = 18
      Alignment = taRightJustify
      AutoSize = False
      Caption = '00.000 '
      Color = clBackground
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -15
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 2
    end
    object stTemperature: TStaticText
      Left = 103
      Top = 55
      Width = 74
      Height = 18
      Alignment = taRightJustify
      AutoSize = False
      Caption = '0.000 '
      Color = clBackground
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -15
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 3
    end
    object stCount: TStaticText
      Left = 103
      Top = 11
      Width = 74
      Height = 18
      Alignment = taRightJustify
      AutoSize = False
      Caption = '0 '
      Color = clBackground
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -15
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 1
    end
    object edCoeffK: TEdit
      Left = 322
      Top = 32
      Width = 45
      Height = 21
      TabOrder = 5
    end
    object edCoeffB: TEdit
      Left = 322
      Top = 54
      Width = 45
      Height = 21
      TabOrder = 6
    end
  end
end

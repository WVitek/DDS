object FrameSensor: TFrameSensor
  Left = 0
  Top = 0
  Width = 201
  Height = 103
  Enabled = False
  TabOrder = 0
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 201
    Height = 103
    Align = alClient
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 0
    object Label3: TLabel
      Left = 15
      Top = 33
      Width = 120
      Height = 13
      Caption = 'Сетевой номер датчика'
    end
    object Label7: TLabel
      Left = 13
      Top = 56
      Width = 120
      Height = 13
      Caption = 'Коэффициент усиления'
    end
    object Label6: TLabel
      Left = 52
      Top = 79
      Width = 80
      Height = 13
      Caption = 'Смещение нуля'
    end
    object cbRepair: TCheckBox
      Left = 7
      Top = 9
      Width = 66
      Height = 17
      Hint = 'Убрать галочку, если ремонт'
      Caption = 'ремонт'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = cbRepairClick
    end
    object stStatus: TStaticText
      Left = 80
      Top = 8
      Width = 113
      Height = 18
      Alignment = taRightJustify
      AutoSize = False
      Caption = '000 | 00.000 '
      Color = clBackground
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 1
    end
    object edNetNumber: TEdit
      Left = 139
      Top = 30
      Width = 36
      Height = 21
      TabOrder = 2
    end
    object edCoeffK: TEdit
      Left = 139
      Top = 53
      Width = 45
      Height = 21
      TabOrder = 3
    end
    object edCoeffB: TEdit
      Left = 139
      Top = 76
      Width = 45
      Height = 21
      TabOrder = 4
    end
  end
end

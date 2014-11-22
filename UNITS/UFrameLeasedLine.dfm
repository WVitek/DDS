object FrameLeasedLine: TFrameLeasedLine
  Left = 0
  Top = 0
  Width = 452
  Height = 280
  TabOrder = 0
  object gbLine: TGroupBox
    Left = 0
    Top = 0
    Width = 143
    Height = 280
    Align = alLeft
    Caption = ' Выделенная линия '
    Constraints.MinHeight = 280
    TabOrder = 0
    object Label5: TLabel
      Left = 9
      Top = 157
      Width = 124
      Height = 13
      Alignment = taCenter
      Anchors = [akLeft, akBottom]
      AutoSize = False
      Caption = 'Состояние:'
    end
    object BtnChange: TButton
      Left = 5
      Top = 105
      Width = 132
      Height = 25
      Caption = 'Внесение изменений'
      TabOrder = 0
      OnClick = BtnChangeClick
    end
    object Panel: TPanel
      Left = 5
      Top = 14
      Width = 132
      Height = 91
      Enabled = False
      TabOrder = 1
      object Label1: TLabel
        Left = 4
        Top = 4
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'COM-порт'
      end
      object Label3: TLabel
        Left = 4
        Top = 44
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Скорость порта'
      end
      object edPort: TEdit
        Left = 4
        Top = 18
        Width = 124
        Height = 21
        TabOrder = 0
      end
      object comboBaudRate: TComboBox
        Left = 4
        Top = 60
        Width = 124
        Height = 21
        ItemHeight = 13
        TabOrder = 1
        Items.Strings = (
          '600'
          '1200'
          '2400'
          '4800'
          '9600'
          '14400'
          '19200'
          '38400'
          '57600'
          '115200')
      end
    end
    object cbWorking: TCheckBox
      Left = 14
      Top = 135
      Width = 113
      Height = 17
      Caption = 'Работа'
      TabOrder = 2
      OnClick = cbWorkingClick
    end
    object stModemState: TStaticText
      Left = 5
      Top = 171
      Width = 132
      Height = 30
      Alignment = taCenter
      Anchors = [akLeft, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      Caption = '- - -'
      TabOrder = 3
    end
    object stInfoO: TStaticText
      Left = 5
      Top = 232
      Width = 132
      Height = 17
      Hint = 'Отправлено: [байт/пакетов в секунду]   [всего килобайт]'
      Alignment = taCenter
      Anchors = [akLeft, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      Caption = 'T:0000/000 000000K'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object stInfoI: TStaticText
      Left = 5
      Top = 208
      Width = 132
      Height = 17
      Hint = 'Получено: [байт/пакетов в секунду]   [всего килобайт]'
      Alignment = taCenter
      Anchors = [akLeft, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      Caption = 'R:0000/000 000000K'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
    end
    object stConnTime: TStaticText
      Left = 5
      Top = 256
      Width = 132
      Height = 17
      Hint = 'Время на связи ([сутки:]часы:минуты:секунды)'
      Alignment = taRightJustify
      Anchors = [akLeft, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      Caption = '00:00:00 '
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
  end
  object GroupBox2: TGroupBox
    Left = 143
    Top = 0
    Width = 309
    Height = 280
    Align = alClient
    Caption = ' События '
    TabOrder = 1
    object Memo: TMemo
      Left = 2
      Top = 15
      Width = 305
      Height = 263
      Align = alClient
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
end

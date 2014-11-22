object FrameMain: TFrameMain
  Left = 0
  Top = 0
  Width = 452
  Height = 400
  TabOrder = 0
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 142
    Height = 400
    Align = alLeft
    Caption = ' Модем '
    TabOrder = 0
    object Label5: TLabel
      Left = 9
      Top = 277
      Width = 124
      Height = 13
      Alignment = taCenter
      Anchors = [akLeft, akBottom]
      AutoSize = False
      Caption = 'Состояние модема:'
    end
    object BtnChange: TButton
      Left = 5
      Top = 177
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
      Height = 163
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
      object Label2: TLabel
        Left = 4
        Top = 84
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Тарификация по (сек)'
      end
      object Label6: TLabel
        Left = 4
        Top = 124
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Макс. время связи (сек)'
      end
      object edPort: TEdit
        Left = 4
        Top = 18
        Width = 124
        Height = 21
        TabOrder = 0
      end
      object edTarifUnit: TEdit
        Left = 4
        Top = 98
        Width = 124
        Height = 21
        Hint = 'Единица тарификации'
        TabOrder = 2
      end
      object comboBaudRate: TComboBox
        Left = 4
        Top = 60
        Width = 124
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 1
        Items.Strings = (
          '110'
          '300'
          '600'
          '1200'
          '2400'
          '4800'
          '9600'
          '14400'
          '19200'
          '38400'
          '56000'
          '57600'
          '115200'
          '128000'
          '256000')
      end
      object edMaxConnTime: TEdit
        Left = 4
        Top = 138
        Width = 124
        Height = 21
        Hint = 
          'Макс. время занятия модемом линии (округляется в большую сторону' +
          ' до кратного единице тарификации)'
        TabOrder = 3
      end
    end
    object cbWorking: TCheckBox
      Left = 14
      Top = 206
      Width = 113
      Height = 17
      Caption = 'Опрос запущен'
      TabOrder = 2
      OnClick = cbWorkingClick
    end
    object cbLeased: TCheckBox
      Left = 14
      Top = 222
      Width = 123
      Height = 17
      Hint = 'Запретить автоматическое разъединение'
      Caption = 'Режим "выделенки"'
      TabOrder = 3
      OnClick = cbLeasedClick
    end
    object stModemState: TStaticText
      Left = 5
      Top = 291
      Width = 132
      Height = 30
      Alignment = taCenter
      Anchors = [akLeft, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      Caption = '- - -'
      TabOrder = 4
    end
    object stInfoO: TStaticText
      Left = 5
      Top = 352
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
      TabOrder = 5
    end
    object stInfoI: TStaticText
      Left = 5
      Top = 328
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
      TabOrder = 6
    end
    object stConnTime: TStaticText
      Left = 5
      Top = 376
      Width = 132
      Height = 17
      Hint = 'Длительность соединения ([сутки:]часы:минуты:секунды)'
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
      TabOrder = 7
    end
  end
  object GroupBox2: TGroupBox
    Left = 142
    Top = 0
    Width = 310
    Height = 400
    Align = alClient
    Caption = ' События '
    TabOrder = 1
    object Memo: TMemo
      Left = 2
      Top = 15
      Width = 306
      Height = 234
      Anchors = [akLeft, akTop, akRight, akBottom]
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
    object Memo7188: TMemo
      Left = 2
      Top = 248
      Width = 306
      Height = 133
      Hint = 'Коммуникационные события'
      Anchors = [akLeft, akRight, akBottom]
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 1
    end
    object stARQState: TStaticText
      Left = 2
      Top = 382
      Width = 306
      Height = 15
      Hint = 'Состояние ARQ-приемопередатчика (для отладки)'
      Alignment = taCenter
      Anchors = [akLeft, akRight, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      Caption = 'TxRd=00 TxWr=00   RxRd=00 RxWr=00'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
  end
end

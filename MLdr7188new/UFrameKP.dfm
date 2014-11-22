object FrameKP: TFrameKP
  Left = 0
  Top = 0
  Width = 497
  Height = 285
  TabOrder = 0
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 142
    Height = 285
    Align = alLeft
    Caption = ' КП СКУ '
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    object Label5: TLabel
      Left = 9
      Top = 198
      Width = 124
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Caption = 'Последние данные за:'
    end
    object cbDialRequest: TCheckBox
      Left = 13
      Top = 178
      Width = 113
      Height = 16
      Hint = 'Запросить однократный внеочередной дозвон до КП'
      Caption = 'Запросить дозвон'
      TabOrder = 3
      OnClick = cbDialRequestClick
    end
    object Panel: TPanel
      Left = 5
      Top = 14
      Width = 132
      Height = 131
      Enabled = False
      TabOrder = 0
      object Label1: TLabel
        Left = 4
        Top = 4
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Название КП'
      end
      object Label2: TLabel
        Left = 4
        Top = 132
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = '№ телефона'
        Visible = False
      end
      object Label3: TLabel
        Left = 4
        Top = 44
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = '№ КП'
      end
      object Label4: TLabel
        Left = 4
        Top = 84
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Автодозвон через (мин)'
      end
      object edName: TEdit
        Left = 4
        Top = 18
        Width = 124
        Height = 21
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 0
      end
      object edPhoneNum: TEdit
        Left = 4
        Top = 146
        Width = 124
        Height = 21
        TabOrder = 3
        Visible = False
      end
      object edAddress: TEdit
        Left = 4
        Top = 58
        Width = 124
        Height = 21
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 1
      end
      object edInterval: TEdit
        Left = 4
        Top = 98
        Width = 124
        Height = 21
        Hint = 
          'Укажите интервал для автоматического дозвона (0 - автодозвон отк' +
          'лючен)'
        TabOrder = 2
      end
    end
    object BtnKvit: TButton
      Left = 5
      Top = 256
      Width = 132
      Height = 25
      Hint = 
        'С событиями, произошедшими с прошлого квитирования до сего момен' +
        'та, ознакомлен :-)'
      Anchors = [akLeft, akBottom]
      Caption = 'Квитировать события'
      TabOrder = 4
      OnClick = BtnKvitClick
    end
    object BtnChange: TButton
      Left = 5
      Top = 145
      Width = 132
      Height = 25
      Caption = 'Внесение изменений'
      TabOrder = 1
      OnClick = BtnChangeClick
    end
    object stLastConnect: TStaticText
      Left = 10
      Top = 213
      Width = 121
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = '0000.00.00 00:00.00'
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 142
    Top = 0
    Width = 355
    Height = 285
    Align = alClient
    Caption = ' События '
    TabOrder = 1
    object Memo: TMemo
      Left = 4
      Top = 14
      Width = 347
      Height = 267
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
end

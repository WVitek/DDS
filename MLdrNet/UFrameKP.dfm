object FrameKP: TFrameKP
  Left = 0
  Top = 0
  Width = 473
  Height = 343
  TabOrder = 0
  object gbKP: TGroupBox
    Left = 0
    Top = 0
    Width = 142
    Height = 343
    Align = alLeft
    Caption = ' КП СКУ '
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    object Label5: TLabel
      Left = 9
      Top = 179
      Width = 124
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Caption = 'Последние данные за:'
    end
    object Panel: TPanel
      Left = 5
      Top = 14
      Width = 132
      Height = 123
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
        Top = 82
        Width = 124
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Задержка данных, сек.'
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
      object edAddress: TEdit
        Left = 4
        Top = 58
        Width = 124
        Height = 21
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 1
      end
      object edDataLag: TEdit
        Left = 4
        Top = 97
        Width = 124
        Height = 21
        Hint = 
          'Чем больше задержка, тем крупнее передаваемые пакеты данных и ме' +
          'ньше расход трафика'
        TabOrder = 2
      end
    end
    object BtnChange: TButton
      Left = 5
      Top = 137
      Width = 132
      Height = 25
      Caption = 'Внесение изменений'
      TabOrder = 1
      OnClick = BtnChangeClick
    end
    object stLastConnect: TStaticText
      Left = 10
      Top = 194
      Width = 121
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = '0000.00.00 00:00.00'
      TabOrder = 2
    end
    object BtnKvit: TButton
      Left = 5
      Top = 210
      Width = 132
      Height = 25
      Hint = 
        'С событиями, произошедшими с прошлого квитирования до сего момен' +
        'та, ознакомлен :-)'
      Caption = 'Квитировать события'
      TabOrder = 3
      OnClick = BtnKvitClick
    end
  end
  object gbEvents: TGroupBox
    Left = 142
    Top = 0
    Width = 331
    Height = 343
    Align = alClient
    Caption = ' События '
    TabOrder = 1
    object lblCommMsg: TLabel
      Left = 9
      Top = 178
      Width = 143
      Height = 13
      Anchors = [akLeft, akBottom]
      Caption = 'Коммуникационный обмен :'
    end
    object Memo: TMemo
      Left = 2
      Top = 15
      Width = 327
      Height = 162
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
    object memoComm: TMemo
      Left = 2
      Top = 192
      Width = 327
      Height = 149
      Align = alBottom
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 1
      WordWrap = False
    end
  end
  object OpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Укажите файл для загрузки в контроллер'
    Left = 16
    Top = 304
  end
end

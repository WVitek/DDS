object FrameSensor: TFrameSensor
  Left = 0
  Top = 0
  Width = 363
  Height = 58
  Enabled = False
  TabOrder = 0
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 363
    Height = 58
    Align = alClient
    BevelInner = bvRaised
    BevelOuter = bvLowered
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object Label4: TLabel
      Left = 252
      Top = 10
      Width = 13
      Height = 13
      Caption = 'X='
    end
    object Label1: TLabel
      Left = 90
      Top = 35
      Width = 84
      Height = 13
      Caption = '������� ������'
    end
    object Label2: TLabel
      Left = 160
      Top = 10
      Width = 20
      Height = 13
      Caption = 'dU='
    end
    object Label3: TLabel
      Left = 9
      Top = 35
      Width = 38
      Height = 13
      Caption = '������'
    end
    object cbOn: TCheckBox
      Left = 7
      Top = 9
      Width = 74
      Height = 17
      Caption = 'cbOn'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = cbOnClick
    end
    object stCount: TStaticText
      Left = 81
      Top = 8
      Width = 74
      Height = 16
      Hint = '���������� ������� � ��������'
      Alignment = taCenter
      AutoSize = False
      Caption = '0 �� 0'
      Color = clBlack
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 1
    end
    object stResult: TStaticText
      Left = 269
      Top = 8
      Width = 84
      Height = 16
      Hint = '��������� ���������� ��������'
      Alignment = taCenter
      AutoSize = False
      Caption = '00.000'
      Color = clBlack
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -15
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 3
    end
    object stX: TStaticText
      Left = 182
      Top = 8
      Width = 62
      Height = 16
      Hint = '��������� ���������, �����'
      Alignment = taCenter
      AutoSize = False
      Caption = '00.000'
      Color = clBlack
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 2
    end
    object edQueryCmd: TEdit
      Left = 179
      Top = 31
      Width = 39
      Height = 21
      Hint = 
        '������� ������ ����������� ����� ��� ��������� ���������� ������' +
        '���'
      TabOrder = 5
    end
    object edPeriod: TEdit
      Left = 52
      Top = 31
      Width = 29
      Height = 21
      Hint = 
        '����� ������� ������ ������������ ������ ����� � ������ ��������' +
        '���'
      TabOrder = 4
    end
    object BtnConversion: TButton
      Left = 241
      Top = 28
      Width = 113
      Height = 25
      Hint = '��������� �������������� � ���������� ��������'
      Caption = '�������������� ...'
      TabOrder = 6
      OnClick = BtnConversionClick
    end
  end
end

object FrameAnalog: TFrameAnalog
  Left = 0
  Top = 0
  Width = 503
  Height = 354
  TabOrder = 0
  object Panel: TPanel
    Left = 4
    Top = 30
    Width = 261
    Height = 100
    Enabled = False
    TabOrder = 0
    object Label7: TLabel
      Left = 89
      Top = 8
      Width = 98
      Height = 13
      Caption = '����                 (��)'
    end
    object Label6: TLabel
      Left = 38
      Top = 55
      Width = 77
      Height = 13
      Caption = '��������� ���'
    end
    object Label1: TLabel
      Left = 38
      Top = 31
      Width = 77
      Height = 13
      Caption = '��������� ���'
    end
    object Label2: TLabel
      Left = 18
      Top = 77
      Width = 176
      Height = 13
      Caption = '����������� ������ ��������� ='
    end
    object Label3: TLabel
      Left = 166
      Top = 31
      Width = 28
      Height = 13
      Caption = '(�)   ='
    end
    object Label4: TLabel
      Left = 166
      Top = 55
      Width = 28
      Height = 13
      Caption = '(�)   ='
    end
    object edR: TEdit
      Left = 118
      Top = 5
      Width = 45
      Height = 21
      TabOrder = 0
    end
    object edIb: TEdit
      Left = 118
      Top = 51
      Width = 45
      Height = 21
      TabOrder = 2
    end
    object edIa: TEdit
      Left = 118
      Top = 28
      Width = 45
      Height = 21
      TabOrder = 1
    end
    object edXmin: TEdit
      Left = 199
      Top = 74
      Width = 54
      Height = 21
      Hint = '��������, ��������� ���� �������� ��������� �� ���������� ����'
      TabOrder = 5
    end
    object edXa: TEdit
      Left = 199
      Top = 28
      Width = 54
      Height = 21
      TabOrder = 3
    end
    object edXb: TEdit
      Left = 199
      Top = 51
      Width = 54
      Height = 21
      TabOrder = 4
    end
  end
  object BtnChange: TButton
    Left = 4
    Top = 130
    Width = 261
    Height = 25
    Caption = '�������� ���������'
    TabOrder = 1
    OnClick = BtnChangeClick
  end
  object cbOn: TCheckBox
    Left = 9
    Top = 8
    Width = 104
    Height = 17
    Hint = '�������� "�������" �������� ������� ���� �� ������� �������'
    Caption = 'cbOn'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnClick = cbOnClick
  end
  object stStatus: TStaticText
    Left = 120
    Top = 7
    Width = 113
    Height = 18
    Hint = 
      '���� �����: Com - ����������������, Rng - �������� ���, Err - ��' +
      '����'
    Alignment = taRightJustify
    AutoSize = False
    Caption = '000 | 00.000 '
    Color = clBlack
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clLime
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    TabOrder = 3
  end
end

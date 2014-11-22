object FrameAnalog: TFrameAnalog
  Left = 0
  Top = 0
  Width = 503
  Height = 354
  TabOrder = 0
  object Panel: TPanel
    Left = 4
    Top = 30
    Width = 192
    Height = 59
    Enabled = False
    TabOrder = 0
    object Label7: TLabel
      Left = 34
      Top = 10
      Width = 98
      Height = 13
      Anchors = [akLeft, akBottom]
      Caption = 'Шунт                 (Ом)'
    end
    object Label6: TLabel
      Left = 7
      Top = 33
      Width = 177
      Height = 13
      Anchors = [akLeft, akBottom]
      Caption = 'Датчик на                 (кгс)  (4-20 мА)'
    end
    object edR: TEdit
      Left = 63
      Top = 7
      Width = 45
      Height = 21
      Anchors = [akLeft, akBottom]
      TabOrder = 0
    end
    object edP: TEdit
      Left = 63
      Top = 30
      Width = 45
      Height = 21
      Anchors = [akLeft, akBottom]
      TabOrder = 1
    end
  end
  object BtnChange: TButton
    Left = 4
    Top = 89
    Width = 192
    Height = 25
    Caption = 'Внесение изменений'
    TabOrder = 1
    OnClick = BtnChangeClick
  end
  object cbOn: TCheckBox
    Left = 9
    Top = 8
    Width = 66
    Height = 17
    Hint = 'Убранная "галочка" заменяет признак сбоя на признак ремонта'
    Caption = 'cbOn'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnClick = cbOnClick
  end
  object stStatus: TStaticText
    Left = 74
    Top = 7
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
    TabOrder = 3
  end
end

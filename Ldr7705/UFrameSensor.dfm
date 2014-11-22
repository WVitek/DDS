object FrameSensor: TFrameSensor
  Left = 0
  Top = 0
  Width = 411
  Height = 45
  AutoScroll = False
  TabOrder = 0
  object GroupBox: TGroupBox
    Left = 0
    Top = 0
    Width = 411
    Height = 45
    Align = alClient
    Caption = ' Sensor '
    TabOrder = 0
    object stStatus: TStaticText
      Left = 24
      Top = 16
      Width = 327
      Height = 17
      Hint = 
        'Доля полной шкалы Vref; #замеров на выдачу, Значение физической ' +
        'величины'
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Status'
      Color = clBlack
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clLime
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 0
    end
    object cbOn: TCheckBox
      Left = 7
      Top = 16
      Width = 17
      Height = 17
      Hint = 'Enable sensor'
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = cbOnClick
    end
    object BtnConv: TButton
      Left = 358
      Top = 15
      Width = 42
      Height = 19
      Hint = 'Настройка преобразование замеренной величины в физическую'
      Anchors = [akTop, akRight]
      Caption = 'Conv.'
      TabOrder = 2
      OnClick = BtnConvClick
    end
  end
end

object FrameSeqOptions: TFrameSeqOptions
  Left = 0
  Top = 0
  Width = 352
  Height = 115
  TabOrder = 0
  object Label1: TLabel
    Left = 5
    Top = 7
    Width = 105
    Height = 13
    Caption = 'Начальное значение'
  end
  object Label2: TLabel
    Left = 4
    Top = 48
    Width = 200
    Height = 13
    Caption = 'Формула вычисления нового значение'
  end
  object Label3: TLabel
    Left = 4
    Top = 92
    Width = 182
    Height = 13
    Caption = 'Длина буфера последовательности'
  end
  object edInitialValue: TEdit
    Left = 4
    Top = 21
    Width = 344
    Height = 21
    TabOrder = 0
  end
  object edNewValue: TEdit
    Left = 4
    Top = 62
    Width = 344
    Height = 21
    TabOrder = 1
  end
  object edBufLength: TEdit
    Left = 192
    Top = 90
    Width = 77
    Height = 21
    TabOrder = 2
  end
end

object FormDateTime: TFormDateTime
  Left = 278
  Top = 279
  BorderStyle = bsDialog
  Caption = 'Укажите дату и время'
  ClientHeight = 95
  ClientWidth = 203
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object DatePicker: TDateTimePicker
    Left = 48
    Top = 8
    Width = 89
    Height = 21
    CalAlignment = dtaLeft
    Date = 36856.9288828704
    Time = 36856.9288828704
    DateFormat = dfShort
    DateMode = dmComboBox
    Kind = dtkDate
    ParseInput = False
    TabOrder = 0
  end
  object TimePicker: TDateTimePicker
    Left = 48
    Top = 35
    Width = 89
    Height = 21
    CalAlignment = dtaLeft
    Date = 36856
    Time = 36856
    DateFormat = dfShort
    DateMode = dmComboBox
    Kind = dtkTime
    ParseInput = False
    TabOrder = 1
    OnChange = TimePickerChange
  end
  object StaticText1: TStaticText
    Left = 6
    Top = 11
    Width = 30
    Height = 17
    Caption = 'Дата'
    TabOrder = 2
  end
  object StaticText2: TStaticText
    Left = 6
    Top = 38
    Width = 37
    Height = 17
    Caption = 'Время'
    TabOrder = 3
  end
  object BtnDayStart: TButton
    Left = 142
    Top = 35
    Width = 57
    Height = 21
    Caption = 'Полночь'
    Enabled = False
    TabOrder = 4
    OnClick = BtnDayStartClick
  end
  object BtnOk: TButton
    Left = 24
    Top = 64
    Width = 75
    Height = 25
    Caption = 'ОК'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object BtnCancel: TButton
    Left = 104
    Top = 64
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 6
  end
end

object DateForm: TDateForm
  Left = 269
  Top = 247
  ActiveControl = ButtonOk
  BorderStyle = bsDialog
  Caption = 'Укажите дату'
  ClientHeight = 116
  ClientWidth = 208
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 23
    Top = 10
    Width = 27
    Height = 16
    Caption = 'Год'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 15
    Top = 43
    Width = 37
    Height = 16
    Caption = 'Дата'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object ButtonOk: TButton
    Left = 16
    Top = 80
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object ButtonCancel: TButton
    Left = 109
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 1
  end
  object DateTimePicker: TDateTimePicker
    Left = 56
    Top = 40
    Width = 129
    Height = 24
    CalAlignment = dtaLeft
    Date = 37090.7756280093
    Time = 37090.7756280093
    DateFormat = dfShort
    DateMode = dmComboBox
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Kind = dtkDate
    MinDate = 36526
    ParseInput = False
    ParentFont = False
    TabOrder = 2
    OnChange = DateTimePickerChange
  end
  object UpDownYear: TUpDown
    Left = 113
    Top = 8
    Width = 16
    Height = 24
    Associate = EditYear
    Min = 2000
    Max = 2000
    Position = 2000
    TabOrder = 3
    Thousands = False
    Wrap = False
  end
  object EditYear: TEdit
    Left = 56
    Top = 8
    Width = 57
    Height = 24
    AutoSelect = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    Text = '2000'
    OnChange = EditYearChange
  end
end

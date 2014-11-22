object FormMain: TFormMain
  Left = 441
  Top = 208
  BorderStyle = bsSingle
  Caption = 'Подсчет простоев СКУ'
  ClientHeight = 352
  ClientWidth = 431
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 9
    Width = 81
    Height = 13
    Caption = 'Начальная дата'
  end
  object Label2: TLabel
    Left = 199
    Top = 9
    Width = 74
    Height = 13
    Caption = 'Конечная дата'
  end
  object Label3: TLabel
    Left = 10
    Top = 35
    Width = 316
    Height = 13
    Caption = 'Список датчиков (взят из файла SensList.txt в текущей папке):'
  end
  object Label4: TLabel
    Left = 8
    Top = 291
    Width = 417
    Height = 29
    Anchors = [akLeft, akRight, akBottom]
    AutoSize = False
    Caption = 
      'Файлы отчета с именами вида "Простои *.txt" сохраняются в текуще' +
      'й папке в формате, удобном для импорта в Microsoft Excel'
    WordWrap = True
  end
  object dtpBegin: TDateTimePicker
    Left = 97
    Top = 6
    Width = 88
    Height = 21
    CalAlignment = dtaLeft
    Date = 37987.8682564583
    Time = 37987.8682564583
    DateFormat = dfShort
    DateMode = dmUpDown
    Kind = dtkDate
    ParseInput = False
    TabOrder = 0
  end
  object dtpEnd: TDateTimePicker
    Left = 281
    Top = 6
    Width = 88
    Height = 21
    CalAlignment = dtaLeft
    Date = 38292.8682564583
    Time = 38292.8682564583
    DateFormat = dfShort
    DateMode = dmUpDown
    Kind = dtkDate
    ParseInput = False
    TabOrder = 1
  end
  object memoList: TMemo
    Left = 6
    Top = 51
    Width = 421
    Height = 235
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Button: TButton
    Left = 349
    Top = 321
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Старт'
    Default = True
    TabOrder = 4
    OnClick = ButtonClick
  end
  object stStatus: TStaticText
    Left = 7
    Top = 325
    Width = 335
    Height = 17
    Alignment = taCenter
    Anchors = [akLeft, akRight, akBottom]
    AutoSize = False
    BorderStyle = sbsSingle
    TabOrder = 3
  end
end

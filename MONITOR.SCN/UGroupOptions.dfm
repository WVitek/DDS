object GroupOptions: TGroupOptions
  Left = 309
  Top = 189
  Anchors = [akTop, akRight]
  BorderStyle = bsDialog
  Caption = 'Настройки'
  ClientHeight = 288
  ClientWidth = 383
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  ShowHint = True
  PixelsPerInch = 96
  TextHeight = 13
  object gbDDS: TGroupBox
    Left = 4
    Top = 142
    Width = 374
    Height = 112
    Anchors = [akLeft, akTop, akRight]
    Caption = ' Параметры алгоритмов '
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object lblAlpha1: TLabel
      Left = 20
      Top = 44
      Width = 216
      Height = 15
      Hint = 
        'Коэффициент экспоненциального затухания при движении волны в сто' +
        'рону увеличения километража'
      Caption = 'Alpha затухания 1 (прямой ход волны)'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object lblAlpha2: TLabel
      Left = 9
      Top = 66
      Width = 228
      Height = 15
      Hint = 
        'Коэффициент экспоненциального затухания при движении волны в сто' +
        'рону уменьшения километража'
      Caption = 'Alpha затухания 2 (обратный ход волны)'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object stWaveSpeed: TStaticText
      Left = 16
      Top = 22
      Width = 225
      Height = 19
      Caption = 'Скорость распространения волны, м/с'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object edWaveSpeed: TEdit
      Left = 245
      Top = 20
      Width = 62
      Height = 21
      Hint = 'Расчет возможен в режиме просмотра архива'
      Anchors = [akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object BtnCalcWaveSpeed: TButton
      Left = 310
      Top = 20
      Width = 57
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Расчет'
      Enabled = False
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = BtnCalcWaveSpeedClick
    end
    object stLineLen: TStaticText
      Left = 37
      Top = 88
      Width = 201
      Height = 19
      Caption = 'Длина ограничивающих линий, сек'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
    end
    object edDDSLineLen: TEdit
      Left = 245
      Top = 86
      Width = 49
      Height = 21
      Anchors = [akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object edAlpha1: TEdit
      Left = 245
      Top = 42
      Width = 62
      Height = 21
      Hint = 'Расчет возможен при открытом окне анализатора'
      Anchors = [akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object edAlpha2: TEdit
      Left = 245
      Top = 64
      Width = 62
      Height = 21
      Hint = 'Расчет возможен при открытом окне анализатора'
      Anchors = [akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
    end
    object BtnCalcAlpha1: TButton
      Left = 310
      Top = 42
      Width = 57
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Расчет'
      Enabled = False
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = BtnCalcAlpha1Click
    end
    object BtnCalcAlpha2: TButton
      Left = 310
      Top = 64
      Width = 57
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Расчет'
      Enabled = False
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = BtnCalcAlpha2Click
    end
  end
  object BtnOk: TButton
    Left = 130
    Top = 259
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = BtnOkClick
  end
  object BtnCancel: TButton
    Left = 217
    Top = 259
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Отмена'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 3
  end
  object BtnApply: TButton
    Left = 304
    Top = 259
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Применить'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = BtnApplyClick
  end
  object gbAlarm: TGroupBox
    Left = 4
    Top = 4
    Width = 374
    Height = 133
    Anchors = [akLeft, akTop, akRight]
    Caption = ' Сигнализация '
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object cbAlarmSingle: TCheckBox
      Left = 8
      Top = 35
      Width = 361
      Height = 17
      Caption = 'Срабатывать на отклонение давления на любом датчике'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object cbAlarmNoSound: TCheckBox
      Left = 8
      Top = 18
      Width = 305
      Height = 17
      Caption = 'Беззвучная сигнализация для этого участка'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object cbAlarmNoData: TCheckBox
      Left = 8
      Top = 53
      Width = 265
      Height = 17
      Caption = 'Срабатывать при пропадании данных'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object cbAlarmSpeaker: TCheckBox
      Left = 8
      Top = 71
      Width = 281
      Height = 17
      Caption = 'Выдача звукового сигнала через PC Speaker'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object cbAlarmMedia: TCheckBox
      Left = 8
      Top = 90
      Width = 217
      Height = 17
      Caption = 'Воспроизводить аудио-файл :'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object btnMediaFile: TButton
      Left = 28
      Top = 108
      Width = 339
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      Caption = 'btnMediaFile'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = btnMediaFileClick
    end
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'wav'
    Filter = 'Файлы аудио (*.wav; *.mid; *.rmi)|*.wav; *.mid; *.rmi'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Выберите файл для воспроизведения'
    Left = 316
    Top = 76
  end
end

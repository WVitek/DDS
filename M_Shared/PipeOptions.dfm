object FormPipeOptions: TFormPipeOptions
  Left = 308
  Top = 189
  BorderStyle = bsDialog
  Caption = 'Настройки'
  ClientHeight = 250
  ClientWidth = 359
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object gbDDS: TGroupBox
    Left = 4
    Top = 142
    Width = 350
    Height = 75
    Caption = ' Настройки системы обнаружения '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object StaticText2: TStaticText
      Left = 10
      Top = 23
      Width = 273
      Height = 17
      Caption = 'Скорость распространения волны                       (м/с)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object edWaveSpeed: TEdit
      Left = 190
      Top = 20
      Width = 62
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object BtnCalcWaveSpeed: TButton
      Left = 283
      Top = 20
      Width = 57
      Height = 21
      Caption = 'Расчет'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = BtnCalcWaveSpeedClick
    end
    object StaticText3: TStaticText
      Left = 10
      Top = 48
      Width = 240
      Height = 17
      Caption = 'Длина ограничивающих линий                   (сек)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object edDDSLineLen: TEdit
      Left = 170
      Top = 45
      Width = 49
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
  end
  object BtnOk: TButton
    Left = 106
    Top = 223
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = BtnOkClick
  end
  object BtnCancel: TButton
    Left = 193
    Top = 223
    Width = 75
    Height = 25
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 3
  end
  object BtnApply: TButton
    Left = 280
    Top = 223
    Width = 75
    Height = 25
    Caption = 'Применить'
    TabOrder = 4
    OnClick = BtnApplyClick
  end
  object gbAlarm: TGroupBox
    Left = 4
    Top = 4
    Width = 350
    Height = 133
    Caption = ' Сигнализация '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object cbAlarmSingle: TCheckBox
      Left = 8
      Top = 35
      Width = 313
      Height = 17
      Caption = 'Срабатывать на отклонение давления на любом датчике'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object cbAlarmNoSound: TCheckBox
      Left = 8
      Top = 18
      Width = 249
      Height = 17
      Caption = 'Беззвучная сигнализация для этого участка'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object cbAlarmNoData: TCheckBox
      Left = 8
      Top = 53
      Width = 217
      Height = 17
      Caption = 'Срабатывать при пропадании данных'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object cbAlarmSpeaker: TCheckBox
      Left = 8
      Top = 71
      Width = 257
      Height = 17
      Caption = 'Выдача звукового сигнала через PC Speaker'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object cbAlarmMedia: TCheckBox
      Left = 8
      Top = 90
      Width = 169
      Height = 17
      Caption = 'Воспроизводить аудио-файл :'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object btnMediaFile: TButton
      Left = 28
      Top = 108
      Width = 314
      Height = 18
      Caption = 'btnMediaFile'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
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

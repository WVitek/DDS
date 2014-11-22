object FormSensorOptions: TFormSensorOptions
  Left = 396
  Top = 127
  BorderStyle = bsDialog
  Caption = 'Настройки (по датчику)'
  ClientHeight = 292
  ClientWidth = 427
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
  object BtnOk: TButton
    Left = 348
    Top = 9
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = BtnOkClick
  end
  object BtnCancel: TButton
    Left = 348
    Top = 40
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 4
  end
  object BtnApply: TButton
    Left = 348
    Top = 71
    Width = 75
    Height = 25
    Caption = 'Применить'
    TabOrder = 5
    OnClick = BtnApplyClick
  end
  object GroupBox1: TGroupBox
    Left = 3
    Top = 1
    Width = 340
    Height = 181
    Caption = ' Параметры слежения за скачками давления '
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object PageControl1: TPageControl
      Left = 4
      Top = 18
      Width = 332
      Height = 159
      ActivePage = TabSheet1
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = 'Повышение давления'
        object cbHigh: TCheckBox
          Left = 4
          Top = 0
          Width = 209
          Height = 17
          Caption = 'Отслеживать повышение давления'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object rbtnHighManual: TRadioButton
          Left = 3
          Top = 20
          Width = 245
          Height = 17
          Caption = 'Допустимое отклонение задается вручную'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
        object rbtnHighAuto: TRadioButton
          Left = 3
          Top = 39
          Width = 321
          Height = 17
          Caption = 'Допустимое отклонение рассчитывается автоматом'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
        end
        object pnlAutoHigh: TPanel
          Left = 14
          Top = 57
          Width = 308
          Height = 70
          BevelOuter = bvLowered
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 4
          object StaticText8: TStaticText
            Left = 6
            Top = 48
            Width = 203
            Height = 17
            Caption = 'Диапазон допуска    от                       до'
            TabOrder = 5
          end
          object StaticText6: TStaticText
            Left = 7
            Top = 5
            Width = 186
            Height = 17
            Caption = 'Автомат - коэффициент инертности'
            TabOrder = 0
          end
          object edHighAlpha: TComboBox
            Left = 194
            Top = 2
            Width = 81
            Height = 21
            ItemHeight = 13
            MaxLength = 5
            TabOrder = 1
            Items.Strings = (
              '0.9000'
              '0.9200'
              '0.9500'
              '0.9800'
              '0.9900'
              '0.9920'
              '0.9950'
              '0.9980'
              '0.9990'
              '0.9992'
              '0.9995'
              '0.9998'
              '0.9999')
          end
          object StaticText7: TStaticText
            Left = 7
            Top = 27
            Width = 185
            Height = 17
            Caption = 'Автомат - коэффициент умножения'
            TabOrder = 2
          end
          object edHighScale: TComboBox
            Left = 194
            Top = 24
            Width = 63
            Height = 21
            ItemHeight = 13
            MaxLength = 5
            TabOrder = 3
            Items.Strings = (
              '2'
              '3'
              '4'
              '5'
              '6'
              '7'
              '8'
              '9'
              '10')
          end
          object edHighMin: TEdit
            Left = 128
            Top = 46
            Width = 52
            Height = 21
            TabOrder = 4
          end
          object edHighMax: TEdit
            Left = 208
            Top = 46
            Width = 52
            Height = 21
            TabOrder = 6
          end
        end
        object edHigh: TEdit
          Left = 246
          Top = 18
          Width = 52
          Height = 23
          TabOrder = 2
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Понижение давления'
        ImageIndex = 1
        object cbLow: TCheckBox
          Left = 4
          Top = 0
          Width = 209
          Height = 17
          Caption = 'Отслеживать понижение давления'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object rbtnLowManual: TRadioButton
          Left = 3
          Top = 20
          Width = 245
          Height = 17
          Caption = 'Допустимое отклонение задается вручную'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
        object rbtnLowAuto: TRadioButton
          Left = 3
          Top = 39
          Width = 321
          Height = 17
          Caption = 'Допустимое отклонение рассчитывается автоматом'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
        end
        object pnlAutoLow: TPanel
          Left = 14
          Top = 57
          Width = 308
          Height = 70
          BevelOuter = bvLowered
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 4
          object StaticText9: TStaticText
            Left = 6
            Top = 48
            Width = 203
            Height = 17
            Caption = 'Диапазон допуска    от                       до'
            TabOrder = 5
          end
          object StaticText10: TStaticText
            Left = 7
            Top = 5
            Width = 186
            Height = 17
            Caption = 'Автомат - коэффициент инертности'
            TabOrder = 0
          end
          object edLowAlpha: TComboBox
            Left = 194
            Top = 2
            Width = 81
            Height = 21
            ItemHeight = 13
            MaxLength = 5
            TabOrder = 1
            Items.Strings = (
              '0.9000'
              '0.9200'
              '0.9500'
              '0.9800'
              '0.9900'
              '0.9920'
              '0.9950'
              '0.9980'
              '0.9990'
              '0.9992'
              '0.9995'
              '0.9998'
              '0.9999')
          end
          object StaticText11: TStaticText
            Left = 7
            Top = 27
            Width = 185
            Height = 17
            Caption = 'Автомат - коэффициент умножения'
            TabOrder = 2
          end
          object edLowScale: TComboBox
            Left = 194
            Top = 24
            Width = 63
            Height = 21
            ItemHeight = 13
            MaxLength = 5
            TabOrder = 3
            Items.Strings = (
              '2'
              '3'
              '4'
              '5'
              '6'
              '7'
              '8'
              '9'
              '10')
          end
          object edLowMin: TEdit
            Left = 128
            Top = 46
            Width = 52
            Height = 21
            TabOrder = 4
          end
          object edLowMax: TEdit
            Left = 208
            Top = 46
            Width = 52
            Height = 21
            TabOrder = 6
          end
        end
        object edLow: TEdit
          Left = 246
          Top = 18
          Width = 52
          Height = 23
          TabOrder = 2
        end
      end
    end
    object cbUseAlpha: TCheckBox
      Left = 7
      Top = 181
      Width = 209
      Height = 17
      Caption = 'Слежение по сглаженному графику'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Visible = False
    end
  end
  object GroupBox2: TGroupBox
    Left = 3
    Top = 183
    Width = 340
    Height = 38
    Caption = ' График '
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object StaticText2: TStaticText
      Left = 7
      Top = 64
      Width = 182
      Height = 17
      Caption = 'Сглаживание в режиме просмотра'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Visible = False
    end
    object edMinGraphHeight: TEdit
      Left = 219
      Top = 12
      Width = 57
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object StaticText3: TStaticText
      Left = 6
      Top = 16
      Width = 212
      Height = 17
      Caption = 'Мин. высота графика при автомасштабе'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object edAlphaArc: TComboBox
      Left = 195
      Top = 60
      Width = 81
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      MaxLength = 5
      ParentFont = False
      TabOrder = 1
      Visible = False
      Items.Strings = (
        '0.9000'
        '0.9200'
        '0.9500'
        '0.9800'
        '0.9900')
    end
    object StaticText5: TStaticText
      Left = 7
      Top = 42
      Width = 177
      Height = 17
      Caption = 'Сглаживание в режиме слежения'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      Visible = False
    end
    object edAlphaSpy: TComboBox
      Left = 195
      Top = 38
      Width = 81
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      MaxLength = 5
      ParentFont = False
      TabOrder = 0
      Visible = False
      Items.Strings = (
        '0.9000'
        '0.9200'
        '0.9500'
        '0.9800'
        '0.9900')
    end
  end
  object GroupBox3: TGroupBox
    Left = 3
    Top = 222
    Width = 340
    Height = 64
    Caption = ' Датчик '
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object StaticText1: TStaticText
      Left = 6
      Top = 18
      Width = 298
      Height = 17
      Caption = 'Возможна задержка поступления данных до              (сек)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object edMaxNoDataTime: TEdit
      Left = 237
      Top = 14
      Width = 37
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object StaticText4: TStaticText
      Left = 6
      Top = 41
      Width = 224
      Height = 17
      Caption = 'Положение датчика на НПП                   (км)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object edKilometer: TEdit
      Left = 153
      Top = 37
      Width = 51
      Height = 21
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
  end
end

object FrameUDPLine: TFrameUDPLine
  Left = 0
  Top = 0
  Width = 409
  Height = 375
  TabOrder = 0
  object GroupBox2: TGroupBox
    Left = 0
    Top = 0
    Width = 409
    Height = 322
    Align = alClient
    Caption = ' События '
    TabOrder = 0
    object Memo: TMemo
      Left = 2
      Top = 15
      Width = 405
      Height = 305
      Align = alClient
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
  object gbStat: TGroupBox
    Left = 0
    Top = 322
    Width = 409
    Height = 53
    Align = alBottom
    Caption = ' Объем принятых (Rx) и переданных (Tx) данных  '
    TabOrder = 1
    object LabelStatSec: TLabel
      Left = 51
      Top = 15
      Width = 56
      Height = 15
      Caption = 'Всего : '
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
    end
    object LabelStatAll: TLabel
      Left = 16
      Top = 32
      Width = 91
      Height = 15
      Caption = 'За секунду : '
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
    end
    object lblStatAll: TLabel
      Left = 111
      Top = 15
      Width = 7
      Height = 15
      Hint = 'байт/пакетов'
      Caption = '1'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
    end
    object lblStatSec: TLabel
      Left = 111
      Top = 32
      Width = 7
      Height = 15
      Hint = 'байт/пакетов'
      Caption = '2'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
    end
  end
end

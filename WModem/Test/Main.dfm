object FormMain: TFormMain
  Left = 280
  Top = 158
  Width = 539
  Height = 321
  Caption = 'FormMain'
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 89
    Height = 294
    Align = alLeft
    BevelInner = bvRaised
    BevelOuter = bvLowered
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 59
      Height = 13
      Caption = 'COM name :'
    end
    object cbDSR: TCheckBox
      Left = 7
      Top = 80
      Width = 75
      Height = 17
      Hint = 'Data Set Ready'
      Caption = 'DSR'
      Enabled = False
      TabOrder = 0
    end
    object cbCTS: TCheckBox
      Left = 7
      Top = 96
      Width = 75
      Height = 17
      Hint = 'Clear To Send'
      Caption = 'CTS'
      Enabled = False
      TabOrder = 1
    end
    object cbRLSD: TCheckBox
      Left = 7
      Top = 112
      Width = 75
      Height = 17
      Hint = 'Receive Lines Signal Detected (Carrier Detected)'
      Caption = 'RLSD (CD)'
      Enabled = False
      TabOrder = 2
    end
    object edComName: TEdit
      Left = 8
      Top = 24
      Width = 72
      Height = 21
      TabOrder = 3
      Text = 'COM3'
    end
    object btnOpen: TButton
      Left = 8
      Top = 49
      Width = 72
      Height = 22
      Caption = 'Open'
      TabOrder = 4
      OnClick = btnOpenClick
    end
  end
  object Panel2: TPanel
    Left = 89
    Top = 0
    Width = 442
    Height = 294
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Memo: TMemo
      Left = 0
      Top = 0
      Width = 442
      Height = 253
      Align = alClient
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
    object pnlConnect: TPanel
      Left = 0
      Top = 253
      Width = 442
      Height = 41
      Align = alBottom
      BevelInner = bvRaised
      BevelOuter = bvLowered
      TabOrder = 1
      object edConnectCmd: TEdit
        Left = 8
        Top = 11
        Width = 345
        Height = 21
        TabOrder = 0
      end
      object btnConnect: TButton
        Left = 360
        Top = 9
        Width = 75
        Height = 25
        Caption = 'Connect'
        Default = True
        TabOrder = 1
        OnClick = btnConnectClick
      end
    end
  end
  object Modem: TModem
    DeviceName = 'Com2'
    MonitorEvents = [evBreak, evCts, evDsr, evError, evRing, evRlsd, evRxChar, evRxFlag, evTxEmpty]
    Options = []
    OnCts = CommCts
    OnDsr = CommDsr
    OnModemRxChar = CommRxChar
    OnModemResponse = ModemModemResponse
    Left = 8
    Top = 152
  end
end

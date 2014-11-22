object FormScanner: TFormScanner
  Left = 325
  Top = 170
  Width = 316
  Height = 382
  BorderStyle = bsSizeToolWin
  Caption = 'Сканер'
  Color = clBtnFace
  Constraints.MinWidth = 316
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object stStatus: TStaticText
    Left = 0
    Top = 338
    Width = 308
    Height = 17
    Align = alBottom
    AutoSize = False
    BorderStyle = sbsSunken
    TabOrder = 0
  end
  object gbControls: TGroupBox
    Left = 0
    Top = 0
    Width = 308
    Height = 49
    Align = alTop
    Caption = ' Диапазон сканирования '
    TabOrder = 1
    object Label1: TLabel
      Left = 7
      Top = 23
      Width = 6
      Height = 13
      Caption = 'с'
    end
    object Label2: TLabel
      Left = 130
      Top = 23
      Width = 12
      Height = 13
      Caption = 'по'
    end
    object meStartTime: TMaskEdit
      Left = 17
      Top = 20
      Width = 107
      Height = 21
      EditMask = '9999-99-99 99:99:99;1;0'
      MaxLength = 19
      TabOrder = 0
      Text = '    -  -     :  :  '
    end
    object meStopTime: TMaskEdit
      Left = 148
      Top = 20
      Width = 106
      Height = 21
      EditMask = '9999-99-99 99:99:99;1;0'
      MaxLength = 19
      TabOrder = 1
      Text = '    -  -     :  :  '
    end
    object BtnStart: TButton
      Left = 260
      Top = 8
      Width = 40
      Height = 19
      Hint = 'Запустить сканирование архива'
      Caption = 'Скан.'
      Default = True
      TabOrder = 2
      OnClick = BtnStartClick
    end
    object BtnSpy: TButton
      Left = 260
      Top = 27
      Width = 40
      Height = 19
      Hint = 'Запустить в режиме слежения'
      Caption = 'Слеж.'
      TabOrder = 3
      OnClick = BtnStartClick
    end
  end
  object sgLog: TStringGrid
    Left = 0
    Top = 49
    Width = 308
    Height = 289
    Align = alClient
    ColCount = 8
    DefaultRowHeight = 20
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColMoving, goThumbTracking]
    TabOrder = 2
    OnClick = sgLogClick
    OnColumnMoved = sgLogColumnMoved
    OnDblClick = sgLogClick
    OnMouseDown = sgLogMouseDown
    ColWidths = (
      109
      56
      48
      55
      58
      57
      64
      56)
  end
end

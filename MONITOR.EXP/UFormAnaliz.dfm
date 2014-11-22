object FormAnaliz: TFormAnaliz
  Left = 365
  Top = 205
  Width = 164
  Height = 201
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSizeToolWin
  Caption = 'Анализатор'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  ShowHint = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object pbGraphs: TPaintBox
    Left = 0
    Top = 22
    Width = 156
    Height = 73
    Hint = 'Голубой - Расчетный график; Зеленый - Реальный график'
    OnDblClick = pbGraphsDblClick
    OnPaint = pbGraphsPaint
  end
  object pbCorrGraph: TPaintBox
    Left = 0
    Top = 97
    Width = 156
    Height = 71
    Hint = 'Z[DT] = График корреляционной функции (меры сходства)'
    Anchors = [akLeft]
    OnMouseDown = pbCorrGraphMouseDown
    OnPaint = pbCorrGraphPaint
  end
  object cbCorrBlock: TComboBox
    Left = 0
    Top = 0
    Width = 73
    Height = 21
    Hint = 
      'Длина анализируемого блока, сек (для малых перепадов выбрать бол' +
      'ьшую)'
    Style = csDropDownList
    DropDownCount = 6
    ItemHeight = 13
    TabOrder = 0
    OnChange = cbCorrBlockChange
    OnKeyPress = FormKeyPress
    Items.Strings = (
      '5'
      '10'
      '15'
      '20'
      '30'
      '60'
      '90'
      '120')
  end
  object cbSetVisir: TCheckBox
    Left = 79
    Top = 2
    Width = 76
    Height = 17
    Hint = 
      'Автоматически устанавливать визир в точку максимума корреляционн' +
      'ой функции'
    Caption = 'Автовизир'
    Checked = True
    State = cbChecked
    TabOrder = 1
    OnClick = cbSetVisirClick
    OnKeyPress = FormKeyPress
  end
end

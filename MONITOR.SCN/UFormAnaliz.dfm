object FormAnaliz: TFormAnaliz
  Left = 365
  Top = 190
  Width = 190
  Height = 203
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSizeToolWin
  Caption = 'Анализатор'
  Color = clBtnFace
  Constraints.MinHeight = 200
  Constraints.MinWidth = 190
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
    Top = 26
    Width = 156
    Height = 73
    Hint = 'Голубой - Расчетный график; Зеленый - Реальный график'
    OnMouseUp = pbGraphsMouseUp
    OnPaint = pbGraphsPaint
  end
  object pbCorrGraph: TPaintBox
    Left = 0
    Top = 104
    Width = 156
    Height = 71
    Hint = 'Z[DT] = График функции подобия'
    Anchors = [akLeft]
    OnMouseDown = pbCorrGraphMouseDown
    OnPaint = pbCorrGraphPaint
  end
  object cbCorrBlock: TComboBox
    Left = 0
    Top = 2
    Width = 57
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
      '4'
      '8'
      '16'
      '24'
      '32'
      '48'
      '64'
      '96'
      '128'
      '192'
      '256')
  end
  object cbSetVisir: TCheckBox
    Left = 102
    Top = 4
    Width = 76
    Height = 17
    Hint = 
      'Автоматически устанавливать визир в точку максимума корреляционн' +
      'ой функции'
    Caption = 'Автовизир'
    Checked = True
    State = cbChecked
    TabOrder = 2
    OnClick = cbSetVisirClick
    OnKeyPress = FormKeyPress
  end
  object cbFilterLen: TComboBox
    Left = 59
    Top = 2
    Width = 40
    Height = 21
    Hint = 'К-во значений для расчета фильтра скользящего среднего'
    Style = csDropDownList
    DropDownCount = 5
    ItemHeight = 13
    TabOrder = 1
    OnChange = cbFilterLenChange
    OnKeyPress = FormKeyPress
    Items.Strings = (
      '1'
      '3'
      '7'
      '11'
      '23')
  end
end

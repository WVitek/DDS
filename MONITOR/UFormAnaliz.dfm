object FormAnaliz: TFormAnaliz
  Left = 234
  Top = 157
  Width = 164
  Height = 176
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Коррелятор'
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
    Top = 0
    Width = 105
    Height = 73
    Hint = 'Голубой - Исходный график; Зеленый - Коррелируемый график'
    OnPaint = pbGraphsPaint
  end
  object pbCorrGraph: TPaintBox
    Left = 0
    Top = 74
    Width = 130
    Height = 71
    Hint = 
      'Зависимость коэффициент корреляции Ro от разницы во времени DT п' +
      'рихода волн'
    OnMouseDown = pbCorrGraphMouseDown
    OnPaint = pbCorrGraphPaint
  end
end

object FormAnaliz: TFormAnaliz
  Left = 234
  Top = 157
  Width = 164
  Height = 176
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = '����������'
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
    Hint = '������� - �������� ������; ������� - ������������� ������'
    OnPaint = pbGraphsPaint
  end
  object pbCorrGraph: TPaintBox
    Left = 0
    Top = 74
    Width = 130
    Height = 71
    Hint = 
      '����������� ����������� ���������� Ro �� ������� �� ������� DT �' +
      '������ ����'
    OnMouseDown = pbCorrGraphMouseDown
    OnPaint = pbCorrGraphPaint
  end
end

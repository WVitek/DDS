object FormPipe: TFormPipe
  Left = 242
  Top = 196
  Width = 344
  Height = 222
  HorzScrollBar.Visible = False
  VertScrollBar.Tracking = True
  ActiveControl = BtnFake
  Anchors = []
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'FormPipe'
  Color = clBtnFace
  Enabled = False
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Courier New'
  Font.Style = [fsBold]
  Icon.Data = {
    0000010001001010100000000000280100001600000028000000100000002000
    00000100040000000000C0000000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF003333
    333333333333300000000000000330FFFFFFFFFFFF0330FFFFFF000FFF0330FF
    FF00FFF00003300000FFFFFFFF0330FFFFFFFFFFFF0330FFFFFFFFFFFF0330FF
    FFFFF000FF033000FFF00FFF000330FF000FFFFFFF0330FFFFFFFFFFFF0330FF
    FFFFFFFFFF033000000000000003333333333333333333333333333333330000
    00007FFE00004002000040020000400200004002000040020000400200004002
    0000400200004002000040020000400200007FFE00000000000000000000}
  KeyPreview = True
  OldCreateOrder = False
  Position = poDefault
  Scaled = False
  ShowHint = True
  OnActivate = FormActivate
  OnCloseQuery = FormCloseQuery
  OnConstrainedResize = FormConstrainedResize
  OnDestroy = FormDestroy
  OnDeactivate = FormDeactivate
  OnKeyPress = FormKeyPress
  OnMouseWheel = FormMouseWheel
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 16
  object Bevel: TBevel
    Left = 0
    Top = 0
    Width = 4
    Height = 128
    Shape = bsLeftLine
  end
  object BtnFake: TButton
    Left = 0
    Top = 0
    Width = 16
    Height = 16
    TabOrder = 0
    TabStop = False
  end
  object menuSys: TPopupMenu
    AutoLineReduction = maManual
    Left = 8
    Top = 32
    object miMode: TMenuItem
      Caption = 'Режим'
      object miSpyMode: TMenuItem
        Caption = 'Слежение'
        Checked = True
        GroupIndex = 1
        ShortCut = 32776
        OnClick = miSpyModeClick
      end
      object miScrollLock: TMenuItem
        Caption = 'Синхронный просмотр архивов'
        Checked = True
        GroupIndex = 2
        ShortCut = 49235
        OnClick = miScrollLockClick
      end
    end
    object miCapacity: TMenuItem
      Caption = 'Емкость по оси времени'
      object miDecCapacity: TMenuItem
        Caption = 'Уменьшить'
        ShortCut = 16457
        OnClick = miDecCapacityClick
      end
      object miIncCapacity: TMenuItem
        Caption = 'Увеличить'
        ShortCut = 16469
        OnClick = miIncCapacityClick
      end
      object miCapSep1: TMenuItem
        Caption = '-'
      end
      object miCap001: TMenuItem
        Tag = 1
        Caption = '1 минута'
        GroupIndex = 1
        ShortCut = 16496
        OnClick = miAnyCapacityClick
      end
      object miCap005: TMenuItem
        Tag = 5
        Caption = '5 минут'
        GroupIndex = 1
        ShortCut = 16497
        OnClick = miAnyCapacityClick
      end
      object miCap015: TMenuItem
        Tag = 15
        Caption = '15 минут'
        GroupIndex = 1
        ShortCut = 16498
        OnClick = miAnyCapacityClick
      end
      object miCap030: TMenuItem
        Tag = 30
        Caption = '30 минут'
        GroupIndex = 1
        ShortCut = 16499
        OnClick = miAnyCapacityClick
      end
      object miCap060: TMenuItem
        Tag = 60
        Caption = '1 час'
        GroupIndex = 1
        ShortCut = 16500
        OnClick = miAnyCapacityClick
      end
      object miCap120: TMenuItem
        Tag = 120
        Caption = '2 часа'
        GroupIndex = 1
        ShortCut = 16501
        OnClick = miAnyCapacityClick
      end
      object miCap240: TMenuItem
        Tag = 240
        Caption = '4 часа'
        GroupIndex = 1
        ShortCut = 16502
        OnClick = miAnyCapacityClick
      end
    end
    object miVertScale: TMenuItem
      Caption = 'Датчик'
      object miZoomOutV: TMenuItem
        Caption = 'Уменьшить масштаб графика'
        ShortCut = 33
        OnClick = miZoomOutVClick
      end
      object miZoomInV: TMenuItem
        Caption = 'Увеличить масштаб графика'
        ShortCut = 34
        OnClick = miZoomInVClick
      end
      object miGraphOption: TMenuItem
        Caption = 'Настройки'
        ShortCut = 16463
        OnClick = miGraphOptionClick
      end
    end
    object miImage: TMenuItem
      Caption = 'Графики'
      object miCopy: TMenuItem
        Caption = 'Копировать в буфер обмена'
        ShortCut = 16451
        OnClick = miCopyClick
      end
      object miCopyForPrinting: TMenuItem
        Caption = 'Копировать для печати'
        ShortCut = 49219
        OnClick = miCopyClick
      end
      object miNegative: TMenuItem
        Caption = 'Негатив'
        ShortCut = 16462
        OnClick = miNegativeClick
      end
    end
    object miArcView: TMenuItem
      Caption = 'Просмотр архива'
      object miArcViewDec001: TMenuItem
        Tag = -1
        Caption = '-001%   [q]'
        OnClick = AnyArcViewClick
      end
      object miArcViewDec005: TMenuItem
        Tag = -5
        Caption = '-005%   [Q]'
        OnClick = AnyArcViewClick
      end
      object miArcViewDec010: TMenuItem
        Tag = -10
        Caption = '-010%   [a]'
        OnClick = AnyArcViewClick
      end
      object miArcViewDec050: TMenuItem
        Tag = -50
        Caption = '-050%   [A]'
        OnClick = AnyArcViewClick
      end
      object miArcViewDec100: TMenuItem
        Tag = -100
        Caption = '-100%   [z]'
        OnClick = AnyArcViewClick
      end
      object miArcViewDec500: TMenuItem
        Tag = -500
        Caption = '-500%   [Z]'
        OnClick = AnyArcViewClick
      end
      object miArcViewInc001: TMenuItem
        Tag = 1
        Break = mbBarBreak
        Caption = '+001%   [e]'
        OnClick = AnyArcViewClick
      end
      object miArcViewInc005: TMenuItem
        Tag = 5
        Caption = '+005%   [E]'
        OnClick = AnyArcViewClick
      end
      object miArcViewInc010: TMenuItem
        Tag = 10
        Caption = '+010%   [d]'
        OnClick = AnyArcViewClick
      end
      object miArcViewInc050: TMenuItem
        Tag = 50
        Caption = '+050%   [D]'
        OnClick = AnyArcViewClick
      end
      object miArcViewInc100: TMenuItem
        Tag = 100
        Caption = '+100%   [c]'
        OnClick = AnyArcViewClick
      end
      object miArcViewInc500: TMenuItem
        Tag = 500
        Caption = '+500%   [C]'
        OnClick = AnyArcViewClick
      end
    end
    object miGroupOptions: TMenuItem
      Caption = 'Настройки участка'
      ShortCut = 49231
      OnClick = miGroupOptionsClick
    end
    object miSetArcTime: TMenuItem
      Caption = 'Перейти к указанной дате/времени'
      ShortCut = 119
      OnClick = miSetArcTimeClick
    end
    object miCalculate: TMenuItem
      Caption = 'Расчет'
      ShortCut = 120
      OnClick = miCalculateClick
    end
    object miAnalizForm: TMenuItem
      Caption = 'Окно анализатора (коррелятора)'
      ShortCut = 122
      OnClick = miAnalizFormClick
    end
  end
end

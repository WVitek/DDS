object FrameGraph: TFrameGraph
  Left = 0
  Top = 0
  Width = 325
  Height = 72
  HorzScrollBar.Visible = False
  Anchors = []
  AutoScroll = False
  Constraints.MinHeight = 72
  Constraints.MinWidth = 240
  Color = clBtnFace
  ParentColor = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  TabStop = True
  OnClick = FrameClick
  OnEnter = FrameEnter
  OnExit = FrameExit
  OnMouseWheel = FrameMouseWheel
  OnResize = FrameResize
  object PnlTools: TPanel
    Left = 243
    Top = 21
    Width = 82
    Height = 38
    Anchors = [akTop, akRight, akBottom]
    BevelOuter = bvNone
    Color = clBlack
    UseDockManager = False
    TabOrder = 1
    OnClick = FrameClick
    object Panel: TPanel
      Left = 1
      Top = 1
      Width = 80
      Height = 36
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelOuter = bvNone
      UseDockManager = False
      TabOrder = 0
      OnClick = FrameClick
      object SpdBtnZoomOut: TSpeedButton
        Left = 2
        Top = 2
        Width = 18
        Height = 18
        Hint = 'Уменьшить масштаб по оси давления'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000FFFFFFFFFFF
          FFFFF77777777777777FF77FFFFFFFFFF77FF777FFFFFFFF777FF7777FFFFFF7
          777FF77777FFFF77777FF777777FF777777FF77777777777777FF77777777777
          777FF777777FF777777FF77777FFFF77777FF7777FFFFFF7777FF777FFFFFFFF
          777FF77FFFFFFFFFF77FF77777777777777FFFFFFFFFFFFFFFFF}
        OnClick = SpdBtnZoomOutClick
      end
      object SpdBtnZoomIn: TSpeedButton
        Left = 21
        Top = 2
        Width = 18
        Height = 18
        Hint = 'Увеличить масштаб по оси давления'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000FFFFFFFFFFF
          FFFFF77777777777777FF777777FF777777FF77777FFFF77777FF7777FFFFFF7
          777FF777FFFFFFFF777FF77FFFFFFFFFF77FF77777777777777FF77777777777
          777FF77FFFFFFFFFF77FF777FFFFFFFF777FF7777FFFFFF7777FF77777FFFF77
          777FF777777FF777777FF77777777777777FFFFFFFFFFFFFFFFF}
        OnClick = SpdBtnZoomInClick
      end
      object SpdBtnAutoZoom: TSpeedButton
        Left = 40
        Top = 2
        Width = 18
        Height = 18
        Hint = 'Режим автомасштаба по оси давления'
        AllowAllUp = True
        GroupIndex = 10
        Down = True
        Flat = True
        Glyph.Data = {
          76020000424D7602000000000000760000002800000040000000100000000100
          0400000000000002000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EFFFFF7777FF
          FFFFEFFFFF7777FFFFFFEFFFFF7777FFFFFFEEEEEEEEEEEEEEEEF777777FF777
          777FF777777FF777777FF777777FF777777FEEEEEEEEEEEEEEEEF777777FF777
          777FF777777FF777777FF777777FF777777F000000FF000000EEF77777FFFF77
          777FF77777FFFF77777FF77777FFFF77777F000000FF000000EEF77777FFFF77
          777FF77777FFFF77777FF77777FFFF77777F00000FFFF00000EEF7777FFFFFF7
          777FF7777FFFFFF7777FF7777FFFFFF7777F00000FFFF00000EEF777F77FF77F
          777FF777F77FF77F777FF777F77FF77F777F0000FFFFFF0000EEF777777FF777
          777FF777777FF777777FF777777FF777777F000F00FF00F000EEF777777FF777
          777FF777777FF777777FF777777FF777777F000000FF000000EEF777F77FF77F
          777FF777F77FF77F777FF777F77FF77F777F000000FF000000EEF7777FFFFFF7
          777FF7777FFFFFF7777FF7777FFFFFF7777F000F00FF00F000EEF77777FFFF77
          777FF77777FFFF77777FF77777FFFF77777F0000FFFFFF0000EEF77777FFFF77
          777FF77777FFFF77777FF77777FFFF77777F00000FFFF00000EEF777777FF777
          777FF777777FF777777FF777777FF777777F00000FFFF00000EEF777777FF777
          777FF777777FF777777FF777777FF777777F000000FF000000EEFFFFFF7777FF
          FFFFFFFFFF7777FFFFFFFFFFFF7777FFFFFF000000FF000000EE}
        NumGlyphs = 4
        OnClick = SpdBtnAutoZoomClick
      end
      object SpdBtnOptions: TSpeedButton
        Left = 60
        Top = 2
        Width = 18
        Height = 18
        Hint = 'Настройки датчика (Ctrl+O)'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00E00FFFFFFFFF
          FFFF0FF077777777777F0FFF07777777777FF0FFF0777777777FF70FFF077777
          777FF770FFF07777777FF7770FFF0077777FF77770FFFF00007FF777770FFFFF
          FF0FF777770FFF000FF0F7777770F07770F0F7777770F0777700F7777770F077
          777FF7777770FF07777FF77777770FF0777FFFFFFFFFF000FFFF}
        OnClick = SpdBtnOptionsClick
      end
      object SBtnRed: TSpeedButton
        Left = 15
        Top = 22
        Width = 12
        Height = 12
        Hint = 'Фильтр Ф1 (экспоненциальный слабый)'
        AllowAllUp = True
        GroupIndex = 1
        Flat = True
        Glyph.Data = {
          96000000424D9600000000000000760000002800000008000000080000000100
          0400000000002000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000FFFFFF0F999
          999FF999999FF999999FF999999FF999999FF999999F0FFFFFF0}
        OnClick = SBtnColorClick
      end
      object SBtnOrange: TSpeedButton
        Left = 28
        Top = 22
        Width = 12
        Height = 12
        Hint = 'Фильтр Ф2 (экспоненциальный сильный)'
        AllowAllUp = True
        GroupIndex = 2
        Flat = True
        Glyph.Data = {
          96000000424D9600000000000000760000002800000008000000080000000100
          0400000000002000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000FFFFFF0FB9B
          9B9FF9B9B9BFFB9B9B9FF9B9B9BFFB9B9B9FF9B9B9BF0FFFFFF0}
        OnClick = SBtnColorClick
      end
      object SBtnYellow: TSpeedButton
        Left = 41
        Top = 22
        Width = 12
        Height = 12
        Hint = 'Фильтр Ф3 (разность между Ф1 и Ф2)'
        AllowAllUp = True
        GroupIndex = 3
        Flat = True
        Glyph.Data = {
          96000000424D9600000000000000760000002800000008000000080000000100
          0400000000002000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000BBBBBB0BBBB
          BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB0BBBBBB0}
        Visible = False
        OnClick = SBtnColorClick
      end
      object SBtnGreen: TSpeedButton
        Left = 54
        Top = 22
        Width = 12
        Height = 12
        Hint = 'Фильтр Ф4 ("кривизна" линии Ф3)'
        AllowAllUp = True
        GroupIndex = 4
        Flat = True
        Glyph.Data = {
          96000000424D9600000000000000760000002800000008000000080000000100
          0400000000002000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000AAAAAA0AAAA
          AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0AAAAAA0}
        Visible = False
        OnClick = SBtnColorClick
      end
      object SBtnWhite: TSpeedButton
        Left = 2
        Top = 22
        Width = 12
        Height = 12
        Hint = 'График исходных данных'
        AllowAllUp = True
        GroupIndex = 9
        Down = True
        Flat = True
        Glyph.Data = {
          96000000424D9600000000000000760000002800000008000000080000000100
          0400000000002000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000FFFFFF0FFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFFFF0}
        OnClick = SBtnColorClick
      end
      object SBtn3Color: TSpeedButton
        Left = 67
        Top = 22
        Width = 12
        Height = 12
        Hint = 'Fourier 2Hz'
        AllowAllUp = True
        GroupIndex = 5
        Flat = True
        Glyph.Data = {
          96000000424D9600000000000000760000002800000008000000080000000100
          0400000000002000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000CDDDDD0CCCC
          DDDDECCCCDDDECCCCCDDEECCCCCDEEECCCCDEEEECCCC0EEEEEC0}
        Visible = False
        OnClick = SBtnColorClick
      end
    end
  end
  object View1: TUniViewer
    Left = 0
    Top = 1
    Width = 243
    Height = 71
    OnGetRegionRect = View1GetRegionRect
    OnRender = View1Render
    OnMouseLeave = View1MouseLeave
    PixelFormat = pf8bit
    UseScrollWindow = False
    Anchors = [akLeft, akTop, akRight, akBottom]
    Constraints.MinWidth = 100
    MouseCapture = False
    PopupMenu = PopupMenu
    OnClick = View1Click
    OnMouseDown = View1MouseDown
    OnMouseMove = View1MouseMove
    OnResize = View1Resize
    ScaleX = 1
    ScaleY = 1
    RealSizeX = 600
    RealSizeY = 56
    HorzSB.DisableNoScroll = True
    HorzSB.Enabled = False
    HorzSB.Visible = False
    VertSB.DisableNoScroll = True
    VertSB.Enabled = False
    VertSB.Visible = False
  end
  object PnlData: TPanel
    Left = 243
    Top = 1
    Width = 82
    Height = 20
    Hint = 'Значение давления'
    Alignment = taRightJustify
    Anchors = [akTop]
    BevelOuter = bvNone
    Caption = '00.000'
    Color = clBlack
    Constraints.MaxHeight = 20
    Constraints.MinHeight = 20
    Constraints.MinWidth = 82
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = FrameClick
  end
  object PnlTime: TPanel
    Left = 243
    Top = 59
    Width = 82
    Height = 13
    Hint = 'Значение времени'
    Alignment = taLeftJustify
    Anchors = [akBottom]
    BevelOuter = bvNone
    Caption = '00:00:00.0'
    Color = clBlack
    Constraints.MaxHeight = 13
    Constraints.MinHeight = 13
    Constraints.MinWidth = 82
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clYellow
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = FrameClick
  end
  object PopupMenu: TPopupMenu
    Left = 11
    Top = 18
    object miCopy: TMenuItem
      Caption = 'Копировать график'
      GroupIndex = 1
      Hint = 'Копировать изображение графика в буфер обмена'
      OnClick = miCopyClick
    end
    object miAutoCenterHelp: TMenuItem
      Caption = 'Для центровки перемещайте мышь с нажатым Ctrl'
      GroupIndex = 1
    end
  end
end

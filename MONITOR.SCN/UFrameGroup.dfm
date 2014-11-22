object FrameGroup: TFrameGroup
  Left = 0
  Top = 0
  Width = 631
  Height = 305
  HorzScrollBar.Visible = False
  VertScrollBar.Tracking = True
  VertScrollBar.Visible = False
  Anchors = [akLeft, akRight]
  AutoScroll = False
  Constraints.MinWidth = 291
  Color = clBlack
  ParentColor = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  OnClick = FrameEnter
  OnConstrainedResize = FrameConstrainedResize
  OnEnter = FrameEnter
  OnExit = FrameExit
  OnResize = FrameResize
  object PnlTools: TPanel
    Left = 0
    Top = 0
    Width = 53
    Height = 305
    Align = alLeft
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 0
    object PnlTools2: TPanel
      Left = 1
      Top = 1
      Width = 51
      Height = 303
      Anchors = [akLeft, akTop, akBottom]
      BevelOuter = bvNone
      UseDockManager = False
      PopupMenu = PopupMenu
      TabOrder = 0
      object SpdBtnGeneratePip: TSpeedButton
        Left = 26
        Top = 20
        Width = 24
        Height = 18
        Hint = '������ � ������� � ������� PIP'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          36010000424D3601000000000000760000002800000016000000100000000100
          040000000000C000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00E00000000000
          0000000000000788888898888888888880000788888898222228888880000788
          8888922888228882200007888888928888822228800007222222988888888888
          8000078888889888888888888000077777777777777777777000078888888889
          88888888800007888888888988CCCCC88000078888888889CCC8888CC0000788
          88888889C8888888800007CCCCCCCCC988888888800007888888888988888888
          8000077777777777777777777000000000000000000000000000}
        OnClick = SpdBtnGeneratePipClick
      end
      object SpdBtnOptions: TSpeedButton
        Left = 1
        Top = 1
        Width = 24
        Height = 18
        Hint = '��������� ������� (Ctrl+Alt+O)'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          36010000424D3601000000000000760000002800000016000000100000000100
          040000000000C000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EFFF00FFFFFF
          FFFFFFFFFF00FEE0FF0EEEEEEEEEEEEEEF00FEE0FFF0EEEEEEEEEEEEEF00FEEE
          0FFF0EEEEEEEEEEEEF00FEEEE0FFF0EEEEEEEEEEEF00FEEEEE0FFF0EEEEEEEEE
          EF00FEEEEEE0FFF00EEEEEEEEF00FEEEEEEE0FFFF0000EEEEF00FEEEEEEEE0FF
          FFFFF0EEEF00FEEEEEEEE0FFF000FF0EEF00FEEEEEEEEE0F0EEE0F0EEF00FEEE
          EEEEEE0F0EEEE00EEF00FEEEEEEEEE0F0EEEEEEEEF00FEEEEEEEEE0FF0EEEEEE
          EF00FEEEEEEEEEE0FF0EEEEEEF00FFFFFFFFFFFF000FFFFFFF00}
        OnClick = SpdBtnOptionsClick
      end
      object SpdBtnROffGOn: TSpeedButton
        Left = 1
        Top = 20
        Width = 24
        Height = 18
        Hint = '������������'
        AllowAllUp = True
        GroupIndex = 4
        Down = True
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000760000002800000058000000100000000100
          040000000000C002000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE77EEEEEEEEEEEEEEEE
          EEEE77EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEE000000EEEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEEEE77EEEEEEEEEEEEE
          EEEEEEE77EEEEEEEEEEEEEEEEEE07711770EEEEEEEEEEEEEE07711770EEEEEEE
          EEEEEEE000000EEEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEE0711111170EEEE
          EEEEEEEE0711111170EEEEEEEEEEEE077AA770EEEEEEEEEEEEEE077AA770EEEE
          EEEEEEEEEE0711111170EEEEEEEEEEEE0711111170EEEEEEEEEEE07AAAAAA70E
          EEEEEEEEEEE07AAAAAA70EEEEEEEEEEEE701111111107EEEEEEEEEE701111111
          177EEEEEEEEEE07AAAAAA70EEEEEEEEEEEE07AAAAAA70EEEEEEEEEEEE7011111
          11107EEEEEEEEEE701111111177EEEEEEEEE70AAAAAAAA07EEEEEEEEEE70AAAA
          AAAA07EEEEEEEEEEEE0711111170EEEEEEEEEEEE0711111170EEEEEEEEEE70AA
          BAAAAA07EEEEEEEEEE70AABAAAAA07EEEEEEEEEEEE0711111170EEEEEEEEEEEE
          0711111170EEEEEEEEEEE07ABBAAA70EEEEEEEEEEEE07ABBAAA70EEEEEEEEEEE
          EEE07711770EEEEEEEEEEEEEE07711770EEEEEEEEEEEE07AAAAAA70EEEEEEEEE
          EEE07AAAAAA70EEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEEE000000EEEEEEEE
          EEEEEE077AA770EEEEEEEEEEEEEE077AA770EEEEEEEEEEEEEEEEEE77EEEEEEEE
          EEEEEEEEEEEE77EEEEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEEE000000EEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE77EEEEE
          EEEEEEEEEEEEEEE77EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE}
        NumGlyphs = 4
        OnClick = SpdBtnSignalClick
        OnDblClick = SpdBtnAlarmDblClick
      end
      object SpdBtnROnGOn: TSpeedButton
        Left = 1
        Top = 20
        Width = 24
        Height = 18
        Hint = '������������'
        AllowAllUp = True
        GroupIndex = 5
        Down = True
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000760000002800000058000000100000000100
          040000000000C002000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE77EEEEEEEEEEEEEEEE
          EEEE77EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEE000000EEEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEEEE77EEEEEEEEEEEEE
          EEEEEEE77EEEEEEEEEEEEEEEEEE07799770EEEEEEEEEEEEEE07799770EEEEEEE
          EEEEEEE000000EEEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEE0799999970EEEE
          EEEEEEEE0799999970EEEEEEEEEEEE077AA770EEEEEEEEEEEEEE077AA770EEEE
          EEEEEEEEEE0799999970EEEEEEEEEEEE0799999970EEEEEEEEEEE07AAAAAA70E
          EEEEEEEEEEE07AAAAAA70EEEEEEEEEEEE709999999907EEEEEEEEEE709999999
          977EEEEEEEEEE07AAAAAA70EEEEEEEEEEEE07AAAAAA70EEEEEEEEEEEE7099B99
          99907EEEEEEEEEE7099B9999977EEEEEEEEE70AAAAAAAA07EEEEEEEEEE70AAAA
          AAAA07EEEEEEEEEEEE079BB99970EEEEEEEEEEEE079BB99970EEEEEEEEEE70AA
          BAAAAA07EEEEEEEEEE70AABAAAAA07EEEEEEEEEEEE0799999970EEEEEEEEEEEE
          0799999970EEEEEEEEEEE07ABBAAA70EEEEEEEEEEEE07ABBAAA70EEEEEEEEEEE
          EEE07799770EEEEEEEEEEEEEE07799770EEEEEEEEEEEE07AAAAAA70EEEEEEEEE
          EEE07AAAAAA70EEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEEE000000EEEEEEEE
          EEEEEE077AA770EEEEEEEEEEEEEE077AA770EEEEEEEEEEEEEEEEEE77EEEEEEEE
          EEEEEEEEEEEE77EEEEEEEEEEEEEEEEE000000EEEEEEEEEEEEEEEE000000EEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE77EEEEE
          EEEEEEEEEEEEEEE77EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE}
        NumGlyphs = 4
        OnClick = SpdBtnSignalClick
        OnDblClick = SpdBtnAlarmDblClick
      end
      object SpdBtnSetArcTime: TSpeedButton
        Left = 1
        Top = 96
        Width = 49
        Height = 16
        Hint = '������� � ��������� ���� � ������� (F8)'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          B6000000424DB6000000000000003E000000280000002F0000000F0000000100
          010000000000780000000000000000000000020000000000000000000000FFFF
          FF000000000000000000FFFFFFFFFFFE00008000000000020000BEA4A191D152
          000094A4A1511152000094A4A1511132000094E4E1591132000094A4A1551552
          000094A4A1959552000094A4A1551B52000094A4A1551B52000094A4A1551152
          00008C6E6199D13200008000000000020000FFFFFFFFFFFE0000}
        OnClick = SpdBtnSetArcTimeClick
      end
      object SpdBtnCalculation: TSpeedButton
        Left = 1
        Top = 78
        Width = 49
        Height = 17
        Hint = '���������� ����� ������ ��� ���������� (F9)'
        AllowAllUp = True
        Enabled = False
        Flat = True
        Glyph.Data = {
          46030000424D460300000000000076000000280000005E0000000F0000000100
          040000000000D002000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00CCCCCCCCCCCC
          CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
          CCCCCCCCCCCCCCCCCC00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFCFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC00FCCCCCCCCCCC
          CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCFCFCCCCCCCCCCCCCCCCCCCCCCCCCCCC
          CCCCCCCCCCCCCCCCFC00FCCFFCCCCCFFCCFFCCFFFFCCCCCCFFCFFFFFFCCCFFCC
          CFCFCC77CCCCC77CC77CC7777CCCCCC77C777777CCC77CCCFC00FCCFFCCCCCFF
          CCFFCFFCCFFCCCCCFFCFFCCFFCCCFFCCCFCFCC77CCCCC77CC77C77CC77CCCCC7
          7C77CC77CCC77CCCFC00FCCFFCCCCCFFCCFFCFFCCFFCCCCCFFCFFCCCCCCCFFCC
          CFCFCC77CCCCC77CC77C77CC77CCCCC77C77CCCCCCC77CCCFC00FCCFFFFFCCFF
          FFFFCFFCCCCCCFFFFFCFFCCCCCCCFFCCCFCFCC77777CC777777C77CCCCCC7777
          7C77CCCCCCC77CCCFC00FCCFFCCFFCFFCCFFCFFCCCCCFFCCFFCFFCCCCCCCFFCC
          CFCFCC77CC77C77CC77C77CCCCC77CC77C77CCCCCCC77CCCFC00FCCFFCCFFCFF
          CCFFCFFCCCCCFFCCFFCFFFFCCCCCFFCCCFCFCC77CC77C77CC77C77CCCCC77CC7
          7C7777CCCCC77CCCFC00FCCFFCCFFCFFCCFFCFFCCCCCFFCCFFCFFCCCCCCCFFCC
          CFCFCC77CC77C77CC77C77CCCCC77CC77C77CCCCCCC77CCCFC00FCCFFCCFFCFF
          CCFFCFFCCFFCFFCCFFCFFCCCCCCCFFCCCFCFCC77CC77C77CC77C77CC77C77CC7
          7C77CCCCCCC77CCCFC00FCCFFCCFFCCFCCFFCFFCCFFCFFCCFFCFFCCFFCCCFFCC
          CFCFCC77CC77CC7CC77C77CC77C77CC77C77CC77CCC77CCCFC00FCCFFFFFCCCC
          FFFFCCFFFFCCFFCCFFCFFFFFFCFFFFFFCFCFCC77777CCCC7777CC7777CC77CC7
          7C777777C777777CFC00FCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
          CFCFCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCFC00FFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFC00}
        NumGlyphs = 2
        OnClick = SpdBtnCalculationClick
      end
      object SpdBtnScrollLock: TSpeedButton
        Left = 1
        Top = 39
        Width = 24
        Height = 18
        Hint = '����� ����������� ����������� ��������'
        AllowAllUp = True
        GroupIndex = 1
        Down = True
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000760000002800000058000000100000000100
          040000000000C002000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEE00000000000000000000EE00000000000000000000EEEEEE
          FFFFFEEEFFEEEFFEEEEEEEFFFFFEEEFFEEEFFEEE00000000000000000000EE00
          000000000000000000EEEEEFFEEEFFEEFFEEEFFEEEEEEFFEEEFFEEFFEEEFFEEE
          000FFFFF000FF000FF00EE000FFFFF000FF000FF00EEEEEFFEEEFFEEFFEEEFFE
          EEEEEFFEEEFFEEFFEEEFFEEE00FF000FF00FF000FF00EE00FF000FF00FF000FF
          00EEEEEFFEEEEEEEFFEEEFFEEEEEEFFEEEEEEEFFEEEFFEEE00FF000FF00FF000
          FF00EE00FF000FF00FF000FF00EEEEEFFEEEEEEEFFEEEFFEEEEEEFFEEEEEEEFF
          EEEFFEEE00FF0000000FF000FF00EE00FF0000000FF000FF00EEEEEFFEEEEEEE
          FFEEEFFEEEEEEFFEEEEEEEFFEEEFFEEE00FF0000000FF000FF00EE00FF000000
          0FF000FF00EEEEEFFEEEEEEEFFEEEFFEEEEEEFFEEEEEEEFFEEEFFEEE00FF0000
          000FF000FF00EE00FF0000000FF000FF00EEEEEFFEEEFFEEFFEEEFFEEEEEEFFE
          EEFFEEFFEEEFFEEE00FF0000000FF000FF00EE00FF0000000FF000FF00EEEEEF
          FEEEFFEEFFEEEFFEEEEEEFFEEEFFEEFFEEEFFEEE00FF000FF00FF000FF00EE00
          FF000FF00FF000FF00EEEEEEFFFFFEEEFFFFFFFEEEEEEEFFFFFEEEFFFFFFFEEE
          00FF000FF00FF000FF00EE00FF000FF00FF000FF00EEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEE000FFFFF000FFFFFFF00EE000FFFFF000FFFFFFF
          00EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE0000000000000000
          0000EE00000000000000000000EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEE00000000000000000000EE00000000000000000000EE}
        NumGlyphs = 4
      end
      object SpdBtnZoomIn: TSpeedButton
        Left = 1
        Top = 58
        Width = 24
        Height = 18
        Hint = '��������� ������� �� ��� ������� (Ctrl+I)'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7E000000424D7E000000000000003E0000002800000016000000100000000100
          010000000000400000000000000000000000020000000000000000000000FFFF
          FF007FFFFC0080000400808404008186040083870400878784008F87C4009F87
          E4009F87E4008F87C4008787840083870400818604008084040080000400FFFF
          FC00}
        PopupMenu = menuCapacity
        OnClick = miDecCapacityClick
      end
      object SpdBtnZoomOut: TSpeedButton
        Left = 26
        Top = 58
        Width = 24
        Height = 18
        Hint = '��������� ������� �� ��� ������� (Ctrl+U)'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7E000000424D7E000000000000003E0000002800000016000000100000000100
          010000000000400000000000000000000000020000000000000000000000FFFF
          FF007FFFFC0080000400880044008C00C4008E01C4008F03C4008F87C4008FCF
          C4008FCFC4008F87C4008F03C4008E01C4008C00C4008800440080000400FFFF
          FC00}
        PopupMenu = menuCapacity
        OnClick = miIncCapacityClick
      end
      object SpdBtnDecSec: TSpeedButton
        Tag = -1
        Left = 1
        Top = 113
        Width = 16
        Height = 16
        Hint = '- 1% <q> - 5% <Q>'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7A000000424D7A000000000000003E000000280000000E0000000F0000000100
          0100000000003C0000000000000000000000020000000000000000000000FFFF
          FF0000000000FFFC00008004000080040000800400008004000080040000BFF4
          0000BFF400008004000080040000800400008004000080040000FFFC0000}
        OnClick = AnyArcViewClick
      end
      object SpdBtnIncSec: TSpeedButton
        Tag = 1
        Left = 34
        Top = 113
        Width = 16
        Height = 16
        Hint = '+ 1% <e> +5% <E>'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7A000000424D7A000000000000003E000000280000000E0000000F0000000100
          0100000000003C0000000000000000000000020000000000000000000000FFFF
          FF0000000000FFFC00008004000083040000830400008304000083040000BFF4
          0000BFF400008304000083040000830400008304000080040000FFFC0000}
        OnClick = AnyArcViewClick
      end
      object SpdBtnDecMin: TSpeedButton
        Tag = -10
        Left = 1
        Top = 128
        Width = 16
        Height = 16
        Hint = '- 10% <a> - 50% <A>'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7A000000424D7A000000000000003E000000280000000E0000000F0000000100
          0100000000003C0000000000000000000000020000000000000000000000FFFF
          FF0000000000FFFC00008004000080040000800400008004000080040000BFF4
          0000BFF400008004000080040000800400008004000080040000FFFC0000}
        OnClick = AnyArcViewClick
      end
      object SpdBtnIncMin: TSpeedButton
        Tag = 10
        Left = 34
        Top = 128
        Width = 16
        Height = 16
        Hint = '+ 10% <d> + 50% <D>'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7A000000424D7A000000000000003E000000280000000E0000000F0000000100
          0100000000003C0000000000000000000000020000000000000000000000FFFF
          FF0000000000FFFC00008004000083040000830400008304000083040000BFF4
          0000BFF400008304000083040000830400008304000080040000FFFC0000}
        OnClick = AnyArcViewClick
      end
      object SpdBtnDecHour: TSpeedButton
        Tag = -100
        Left = 1
        Top = 143
        Width = 16
        Height = 16
        Hint = '- 100% <z> - 500% <Z>'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7A000000424D7A000000000000003E000000280000000E0000000F0000000100
          0100000000003C0000000000000000000000020000000000000000000000FFFF
          FF0000000000FFFC00008004000080040000800400008004000080040000BFF4
          0000BFF400008004000080040000800400008004000080040000FFFC0000}
        OnClick = AnyArcViewClick
      end
      object SpdBtnIncHour: TSpeedButton
        Tag = 100
        Left = 34
        Top = 143
        Width = 16
        Height = 16
        Hint = '+ 100% <c> + 500% <C>'
        AllowAllUp = True
        Flat = True
        Glyph.Data = {
          7A000000424D7A000000000000003E000000280000000E0000000F0000000100
          0100000000003C0000000000000000000000020000000000000000000000FFFF
          FF0000000000FFFC00008004000083040000830400008304000083040000BFF4
          0000BFF400008304000083040000830400008304000080040000FFFC0000}
        OnClick = AnyArcViewClick
      end
      object SpdBtnSpyMode: TSpeedButton
        Left = 26
        Top = 1
        Width = 24
        Height = 18
        Hint = '����� �������� (Alt+BkSp)'
        AllowAllUp = True
        GroupIndex = 2
        Down = True
        Flat = True
        Glyph.Data = {
          36030000424D3603000000000000760000002800000058000000100000000100
          040000000000C002000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00EFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
          EEEEEEEEEEEEFEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEEEEEEEFEEEEEEEE
          EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEEEEEEEEEEEEFFEEEEE
          EEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFFFFFFEE00000000000000000000EEFEEE
          EEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEEEEEFEE00
          000000000000000000EEFEEEEEEEEEEEEFEEEEEEEFFEEEEEEEEEEEEFEEEEEEEF
          FEEEEEEEEEEEEEEEEEEFEE00000000000000000000EEFEEEEEEEEEEEEEFEEEEE
          EFFEEEEEEEEEEEEEFEEEEEEFFEEEEEEEEEEEFEEEEEEFEE000000000000F00000
          00EEFEEEEEEEEEEEEEFFFEEEEFFEEEEEEEEEEEEEFFFEEEEFFEEEEEEEEEEEEFEE
          EEEFEE0000000000000F000000EEFEEFFFFFFFFFFFFFFFFFFFFEEFFFFFFFFFFF
          FFFFFFFFFEEEEEEEEEEEEFFFEEEFEE0000000000000FFF0000EEFEEFFFFFFFFF
          FFFFFFFFFFFEEFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFEE00FFFFFFFF
          FFFFFFFFFFEEFEEEEEEEEEEEEEFFFEEEEFFEEEEEEEEEEEEEFFFEEEEFFEFFFFFF
          FFFFFFFFFFFFEE00FFFFFFFFFFFFFFFFFFEEFEEEEEEEEEEEEEFEEEEEEFFEEEEE
          EEEEEEEEFEEEEEEFFEEEEEEEEEEEEFFFEEEFEE0000000000000FFF0000EEFEEE
          EEEEEEEEEFEEEEEEEFFEEEEEEEEEEEEFEEEEEEEFFEEEEEEEEEEEEFEEEEEFEE00
          00000000000F000000EEFEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEEEEEEEF
          FEEEEEEEEEEEFEEEEEEFEE000000000000F0000000EEFEEEEEEEEEEEEEEEEEEE
          EFFEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEEEEEFEE000000000000000000
          00EEFEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEEEEEEEE
          EEEFEE00000000000000000000EEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
          FFFFFFFFFFFFFFFFFFFFFFFFFFFFEE00000000000000000000EE}
        NumGlyphs = 4
        OnClick = SpdBtnSpyModeClick
      end
      object stSec: TStaticText
        Left = 17
        Top = 113
        Width = 17
        Height = 16
        Hint = '�������� � ����� = 1/100 ������ ����'
        Alignment = taCenter
        AutoSize = False
        Caption = '1%'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object stMin: TStaticText
        Left = 17
        Top = 128
        Width = 17
        Height = 16
        Hint = '�������� � ����� = 1/10 ������ ����'
        Alignment = taCenter
        AutoSize = False
        Caption = '0.1'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object stHour: TStaticText
        Left = 17
        Top = 144
        Width = 17
        Height = 16
        Hint = '�������� � ����� = ������ ����'
        Alignment = taCenter
        AutoSize = False
        Caption = '1'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
    end
  end
  object pmenuGenPip: TPopupMenu
    AutoHotkeys = maManual
    OwnerDraw = True
    TrackButton = tbLeftButton
    Left = 64
    Top = 32
    object miCaption: TMenuItem
      Caption = '�������'
      Checked = True
      Enabled = False
      OnAdvancedDrawItem = miViewPipAdvancedDrawItem
    end
    object miViewPip: TMenuItem
      Caption = '�������� ������'
      Enabled = False
      OnAdvancedDrawItem = miViewPipAdvancedDrawItem
    end
    object miViewPipLast10Minutes: TMenuItem
      Tag = 10
      Caption = '�� ��������� 10 �����'
      OnClick = miViewLastNMinutesPipClick
    end
    object miViewPipLastHour: TMenuItem
      Tag = 60
      Caption = '�� ��������� ���'
      OnClick = miViewLastNMinutesPipClick
    end
    object miViewPipToday: TMenuItem
      Caption = '�� �������'
      OnClick = miViewLastNthDayPipClick
    end
    object miViewPipYesterday: TMenuItem
      Tag = 1
      Caption = '�� ������� �����'
      OnClick = miViewLastNthDayPipClick
    end
    object miViewPipAnyDay: TMenuItem
      Caption = '�� ������������ ����� ...'
      OnClick = miViewPipAnyDayClick
    end
    object miLine1: TMenuItem
      Caption = '-'
    end
    object miGenPip: TMenuItem
      Caption = '�������� PIP-�����'
      Enabled = False
      OnAdvancedDrawItem = miViewPipAdvancedDrawItem
    end
    object miGenPipYesterday: TMenuItem
      Tag = 1
      Caption = '�� ������� �����'
      OnClick = miGeneratePipClick
    end
    object miGenPipAnyday: TMenuItem
      Caption = '�� ������������ ����� ...'
      OnClick = miGeneratePipClick
    end
    object miLine2: TMenuItem
      Caption = '-'
    end
    object miRunPipViewer: TMenuItem
      Caption = '����������� PIP-������'
      OnClick = miRunPipViewerClick
    end
  end
  object PopupMenu: TPopupMenu
    Left = 12
    Top = 216
    object miCopy: TMenuItem
      Caption = '����������� �����������'
      GroupIndex = 1
      Hint = '����������� ����������� � ����� ������'
      OnClick = miCopyClick
    end
  end
  object menuCapacity: TPopupMenu
    AutoLineReduction = maManual
    OwnerDraw = True
    Left = 12
    Top = 178
    object miCapacity: TMenuItem
      Caption = '     ������� �� ��� �������     '
      Enabled = False
      OnAdvancedDrawItem = miViewPipAdvancedDrawItem
    end
    object miDecCapacity: TMenuItem
      Caption = '���������'
      ShortCut = 16457
      OnClick = miDecCapacityClick
    end
    object miIncCapacity: TMenuItem
      Caption = '���������'
      ShortCut = 16469
      OnClick = miIncCapacityClick
    end
    object miSep1: TMenuItem
      Caption = '-'
    end
    object miCap001: TMenuItem
      Tag = 1
      Caption = '1 ������'
      GroupIndex = 1
      ShortCut = 16496
      OnClick = miAnyCapacityClick
    end
    object miCap005: TMenuItem
      Tag = 5
      Caption = '5 �����'
      GroupIndex = 1
      ShortCut = 16497
      OnClick = miAnyCapacityClick
    end
    object miCap015: TMenuItem
      Tag = 15
      Caption = '15 �����'
      GroupIndex = 1
      ShortCut = 16498
      OnClick = miAnyCapacityClick
    end
    object miCap030: TMenuItem
      Tag = 30
      Caption = '30 �����'
      GroupIndex = 1
      ShortCut = 16499
      OnClick = miAnyCapacityClick
    end
    object miCap060: TMenuItem
      Tag = 60
      Caption = '1 ���'
      GroupIndex = 1
      ShortCut = 16500
      OnClick = miAnyCapacityClick
    end
    object miCap120: TMenuItem
      Tag = 120
      Caption = '2 ����'
      GroupIndex = 1
      ShortCut = 16501
      OnClick = miAnyCapacityClick
    end
    object miCap240: TMenuItem
      Tag = 240
      Caption = '4 ����'
      GroupIndex = 1
      ShortCut = 16502
      OnClick = miAnyCapacityClick
    end
  end
end

object FormMain: TFormMain
  Left = 243
  Top = 129
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Magic Stones 2'
  ClientHeight = 544
  ClientWidth = 544
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 120
  TextHeight = 16
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 528
    Height = 528
    AutoSize = True
    BevelInner = bvLowered
    BevelWidth = 3
    BorderWidth = 2
    Color = clBlack
    TabOrder = 0
    object DXD: TDXDraw
      Left = 8
      Top = 8
      Width = 512
      Height = 512
      AutoInitialize = True
      AutoSize = True
      Color = clBtnFace
      Display.FixedBitCount = True
      Display.FixedRatio = True
      Display.FixedSize = False
      Options = [doAllowReboot, doWaitVBlank, doSystemMemory, doCenter, doDirectX7Mode, doHardware, doSelectDriver]
      SurfaceHeight = 512
      SurfaceWidth = 512
      OnInitialize = Initialize
      TabOrder = 0
      OnClick = Regenerate
    end
  end
  object DXT: TDXTimer
    ActiveOnly = True
    Enabled = True
    Interval = 1
    OnTimer = DXTTimer
    Left = 48
    Top = 48
  end
end

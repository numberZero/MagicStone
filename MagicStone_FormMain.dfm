object Form1: TForm1
  Left = 243
  Top = 129
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Magic Stones 1'
  ClientHeight = 544
  ClientWidth = 544
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
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
    object DXPB: TDXPaintBox
      Left = 8
      Top = 8
      Width = 512
      Height = 512
      AutoStretch = False
      Center = True
      KeepAspect = False
      Stretch = False
      ViewWidth = 0
      ViewHeight = 0
      OnClick = DXPBClick
    end
  end
  object DXT: TDXTimer
    ActiveOnly = True
    Enabled = True
    Interval = 0
    OnTimer = DXTTimer
    Left = 48
    Top = 48
  end
end

object BackMenuForm: TBackMenuForm
  Left = 400
  Top = 200
  VertScrollBar.Increment = 50
  BorderStyle = bsDialog
  Caption = 'BackMenuForm'
  ClientHeight = 457
  ClientWidth = 846
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbText: TLabel
    Left = 224
    Top = 0
    Width = 342
    Height = 23
    Caption = 'Choose a background for your animation'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object scrlbBackground: TScrollBox
    Left = 0
    Top = 29
    Width = 846
    Height = 428
    VertScrollBar.Increment = 50
    Align = alBottom
    BorderStyle = bsNone
    TabOrder = 0
    OnMouseWheelDown = OnMouseWheelDown
    OnMouseWheelUp = OnMouseWheelUp
  end
  object BkPictureDialog: TOpenPictureDialog
    Left = 696
  end
end

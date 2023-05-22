object ProgressForm: TProgressForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Creating video'
  ClientHeight = 75
  ClientWidth = 246
  Color = clBtnFace
  Enabled = False
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object gProgress: TGauge
    Left = 20
    Top = 20
    Width = 200
    Height = 35
    Progress = 0
  end
end

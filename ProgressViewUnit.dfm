object ProgressForm: TProgressForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Creating video'
  ClientHeight = 35
  ClientWidth = 200
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
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object gProgress: TGauge
    Left = 0
    Top = 0
    Width = 200
    Height = 35
    Enabled = False
    Progress = 100
  end
end

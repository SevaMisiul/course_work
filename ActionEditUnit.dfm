object ActionEditForm: TActionEditForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'ActionEditForm'
  ClientHeight = 245
  ClientWidth = 390
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbActionType: TLabel
    Left = 25
    Top = 15
    Width = 86
    Height = 19
    Caption = 'Action type:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbEndTime: TLabel
    Left = 31
    Top = 135
    Width = 69
    Height = 19
    Caption = 'End time:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbStartTime: TLabel
    Left = 25
    Top = 75
    Width = 75
    Height = 19
    Caption = 'Start time:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbStartPointX: TLabel
    Left = 200
    Top = 15
    Width = 53
    Height = 19
    Caption = 'Start X:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbStartPointY: TLabel
    Left = 300
    Top = 15
    Width = 54
    Height = 19
    Caption = 'Start Y:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbEndPointX: TLabel
    Left = 200
    Top = 75
    Width = 47
    Height = 19
    Caption = 'End X:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbEndPointY: TLabel
    Left = 300
    Top = 75
    Width = 48
    Height = 19
    Caption = 'End Y:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object cbActionType: TComboBox
    Left = 25
    Top = 35
    Width = 145
    Height = 27
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object edtTimeStart: TEdit
    Left = 25
    Top = 95
    Width = 145
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 5
  end
  object edtTimeEnd: TEdit
    Left = 25
    Top = 155
    Width = 145
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 6
  end
  object btnCancel: TButton
    Left = 25
    Top = 200
    Width = 75
    Height = 30
    Caption = 'Cancel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 7
  end
  object btnOk: TButton
    Left = 125
    Top = 200
    Width = 75
    Height = 30
    Caption = 'OK'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 1
    ParentFont = False
    TabOrder = 8
  end
  object edtStartPointX: TEdit
    Left = 200
    Top = 35
    Width = 70
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 1
  end
  object edtStartPointY: TEdit
    Left = 300
    Top = 35
    Width = 70
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 2
  end
  object edtEndPointX: TEdit
    Left = 200
    Top = 95
    Width = 70
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 3
  end
  object edtEndPointY: TEdit
    Left = 300
    Top = 95
    Width = 70
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 4
  end
end

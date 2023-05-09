object ObjectOptionsForm: TObjectOptionsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'ObjectOptionsForm'
  ClientHeight = 450
  ClientWidth = 549
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object pbPicture: TPaintBox
    Left = 25
    Top = 25
    Width = 200
    Height = 200
    OnPaint = pbPicturePaint
  end
  object lbHeight: TLabel
    Left = 265
    Top = 60
    Width = 52
    Height = 19
    Caption = 'Height:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbWidth: TLabel
    Left = 410
    Top = 60
    Width = 47
    Height = 19
    Caption = 'Width:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbAngle: TLabel
    Left = 265
    Top = 180
    Width = 47
    Height = 19
    Caption = 'Angle:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbActions: TLabel
    Left = 25
    Top = 255
    Width = 58
    Height = 19
    Caption = 'Actions:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbTop: TLabel
    Left = 265
    Top = 116
    Width = 34
    Height = 19
    Caption = 'Top:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbLeft: TLabel
    Left = 410
    Top = 116
    Width = 32
    Height = 19
    Caption = 'Left:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object edtHeight: TEdit
    Left = 265
    Top = 80
    Width = 120
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 1
    OnChange = edtHeightChange
  end
  object chbIsProportional: TCheckBox
    Left = 265
    Top = 25
    Width = 120
    Height = 20
    Caption = 'Proportional'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object edtAngle: TEdit
    Left = 265
    Top = 200
    Width = 120
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
  object lvActions: TListView
    Left = 25
    Top = 280
    Width = 240
    Height = 150
    Columns = <
      item
        Caption = 'Action type'
        MaxWidth = 100
        MinWidth = 100
        Width = 100
      end
      item
        Caption = 'Start time'
        MaxWidth = 60
        MinWidth = 60
        Width = 60
      end
      item
        Caption = 'End Time'
        MaxWidth = 55
        MinWidth = 55
        Width = 55
      end>
    ColumnClick = False
    ReadOnly = True
    TabOrder = 6
    ViewStyle = vsReport
  end
  object btnAddAction: TButton
    Left = 285
    Top = 280
    Width = 100
    Height = 33
    Action = actAddAction
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
  end
  object btnOk: TButton
    Left = 430
    Top = 397
    Width = 100
    Height = 33
    Caption = 'OK'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 1
    ParentFont = False
    TabOrder = 9
  end
  object btnCancel: TButton
    Left = 285
    Top = 397
    Width = 100
    Height = 33
    Caption = 'Cancel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 8
  end
  object edtWidth: TEdit
    Left = 410
    Top = 80
    Width = 120
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnChange = edtWidthChange
  end
  object edtTop: TEdit
    Left = 265
    Top = 136
    Width = 120
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    NumbersOnly = True
    ParentFont = False
    TabOrder = 3
    OnChange = edtHeightChange
  end
  object edtLeft: TEdit
    Left = 410
    Top = 136
    Width = 120
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnChange = edtWidthChange
  end
  object btnDeleteAction: TButton
    Left = 430
    Top = 280
    Width = 100
    Height = 33
    Action = actDeleteAction
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
  end
  object btnDeleteObject: TButton
    Left = 410
    Top = 197
    Width = 100
    Height = 33
    Caption = 'Delete object'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 3
    ParentFont = False
    TabOrder = 11
  end
  object btnEditAction: TButton
    Left = 285
    Top = 330
    Width = 100
    Height = 33
    Action = actEditAction
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 12
  end
  object actList: TActionList
    OnUpdate = actListUpdate
    Left = 32
    Top = 312
    object actDeleteAction: TAction
      Caption = 'Delete action'
      ShortCut = 8238
      OnExecute = actDeleteActionExecute
    end
    object actEditAction: TAction
      Caption = 'Edit action'
      OnExecute = actEditActionExecute
    end
    object actAddAction: TAction
      Caption = 'Add action'
      OnExecute = actAddActionExecute
    end
  end
end

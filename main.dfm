object FrmDarknet: TFrmDarknet
  Left = 0
  Top = 0
  Caption = 'Darknet - Test'
  ClientHeight = 816
  ClientWidth = 1325
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    1325
    816)
  TextHeight = 15
  object Label1: TLabel
    Left = 12
    Top = 44
    Width = 52
    Height = 15
    Caption = 'Weights : '
  end
  object Label2: TLabel
    Left = 12
    Top = 74
    Width = 83
    Height = 15
    Caption = 'Configuration : '
  end
  object Label3: TLabel
    Left = 12
    Top = 104
    Width = 43
    Height = 15
    Caption = 'Names :'
  end
  object spOpenWeights: TSpeedButton
    Left = 540
    Top = 42
    Width = 23
    Height = 22
    OnClick = spOpenWeightsClick
  end
  object spOpenConfig: TSpeedButton
    Left = 540
    Top = 70
    Width = 23
    Height = 22
    OnClick = spOpenConfigClick
  end
  object spOpenImage: TSpeedButton
    Left = 540
    Top = 99
    Width = 23
    Height = 22
    OnClick = spOpenImageClick
  end
  object Label4: TLabel
    Left = 12
    Top = 8
    Width = 45
    Height = 15
    Caption = 'Network'
  end
  object Label5: TLabel
    Left = 562
    Top = 784
    Width = 35
    Height = 15
    Caption = 'Thresh'
  end
  object Label6: TLabel
    Left = 654
    Top = 782
    Width = 61
    Height = 15
    Caption = 'Overlapped'
  end
  object edWeights: TEdit
    Left = 102
    Top = 41
    Width = 435
    Height = 23
    TabOrder = 1
  end
  object edConfig: TEdit
    Left = 102
    Top = 70
    Width = 435
    Height = 23
    TabOrder = 2
  end
  object ScrollBox: TScrollBox
    Left = 10
    Top = 132
    Width = 1049
    Height = 635
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 5
    ExplicitWidth = 1043
    ExplicitHeight = 634
    object Image: TImage
      Left = -2
      Top = -2
      Width = 1053
      Height = 632
    end
  end
  object edNames: TEdit
    Left = 102
    Top = 99
    Width = 435
    Height = 23
    TabOrder = 3
  end
  object btnLoadNetwork: TButton
    Left = 14
    Top = 778
    Width = 89
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Load network'
    TabOrder = 6
    OnClick = btnLoadNetworkClick
    ExplicitTop = 777
  end
  object btnLoadImage: TButton
    Left = 114
    Top = 778
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Load image'
    TabOrder = 7
    OnClick = btnLoadImageClick
    ExplicitTop = 777
  end
  object btnDetect: TButton
    Left = 773
    Top = 778
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Detect'
    TabOrder = 8
    OnClick = btnDetectClick
    ExplicitTop = 777
  end
  object lb: TListBox
    Left = 1063
    Top = 130
    Width = 243
    Height = 634
    Anchors = [akTop, akRight]
    ItemHeight = 15
    TabOrder = 9
    ExplicitLeft = 1057
  end
  object nbThresh: TNumberBox
    Left = 600
    Top = 779
    Width = 43
    Height = 23
    Mode = nbmFloat
    MaxValue = 1.000000000000000000
    TabOrder = 10
    Value = 0.850000000000000000
  end
  object cbRegisteredNetwork: TComboBox
    Left = 102
    Top = 8
    Width = 461
    Height = 23
    TabOrder = 0
    OnChange = cbRegisteredNetworkChange
  end
  object btnRegisterNetwork: TButton
    Left = 572
    Top = 8
    Width = 125
    Height = 114
    Caption = 'Register Network'
    TabOrder = 4
    OnClick = btnRegisterNetworkClick
  end
  object spOverlapped: TSpinEdit
    Left = 721
    Top = 779
    Width = 46
    Height = 24
    MaxValue = 100
    MinValue = 0
    TabOrder = 11
    Value = 94
  end
  object OpenDialog: TOpenDialog
    Left = 130
    Top = 202
  end
  object OpenPictureDialog: TOpenPictureDialog
    Left = 268
    Top = 200
  end
end

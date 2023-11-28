object fmViewerPDF: TfmViewerPDF
  Left = 0
  Top = 0
  Caption = 'Visualizador de PDF'
  ClientHeight = 483
  ClientWidth = 549
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ViewerPDF: TdxPDFViewer
    Left = 0
    Top = 49
    Width = 549
    Height = 434
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    BorderStyle = cxcbsNone
    ExplicitTop = 51
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 549
    Height = 49
    Align = alTop
    TabOrder = 1
    object Label1: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 541
      Height = 13
      Align = alTop
      Caption = 'Diret'#243'rio'
      ExplicitWidth = 41
    end
    object edDiretorio: TEdit
      AlignWithMargins = True
      Left = 4
      Top = 23
      Width = 541
      Height = 22
      Cursor = crHandPoint
      Align = alClient
      ReadOnly = True
      TabOrder = 0
      OnDblClick = edDiretorioDblClick
      ExplicitHeight = 21
    end
  end
  object tmLooping: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmLoopingTimer
    Left = 272
    Top = 248
  end
  object tiIconeBandeja: TTrayIcon
    PopupMenu = popupOpcoes
    Left = 400
    Top = 216
  end
  object popupOpcoes: TPopupMenu
    Left = 344
    Top = 272
    object popupExibir: TMenuItem
      Caption = 'Exibir aplica'#231#227'o'
      OnClick = popupExibirClick
    end
  end
  object tmInicializar: TTimer
    Enabled = False
    OnTimer = tmInicializarTimer
    Left = 200
    Top = 272
  end
end

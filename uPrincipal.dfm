object fmPrintersSuportMain: TfmPrintersSuportMain
  Left = 0
  Top = 0
  Caption = 'Suporte de impress'#227'o'
  ClientHeight = 490
  ClientWidth = 858
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    858
    490)
  TextHeight = 17
  object Label5: TLabel
    Left = 8
    Top = 126
    Width = 103
    Height = 17
    Caption = 'Fila de impress'#227'o'
  end
  object Label6: TLabel
    Left = 227
    Top = 98
    Width = 38
    Height = 17
    Caption = 'Status:'
  end
  object lbStatus: TLabel
    Left = 271
    Top = 98
    Width = 43
    Height = 17
    Caption = 'Parado'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label8: TLabel
    Left = 379
    Top = 98
    Width = 166
    Height = 17
    Caption = 'Quantidade de impressoras:'
  end
  object lbQuantidade: TLabel
    Left = 551
    Top = 98
    Width = 7
    Height = 17
    Caption = '0'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lbLog: TLabel
    Left = 534
    Top = 39
    Width = 52
    Height = 17
    Cursor = crHandPoint
    Caption = 'Abrir log'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lbLogClick
  end
  object bbStart: TButton
    Left = 8
    Top = 95
    Width = 97
    Height = 25
    Caption = 'Iniciar servi'#231'o'
    TabOrder = 1
    OnClick = bbStartClick
  end
  object bbStop: TButton
    Left = 118
    Top = 95
    Width = 97
    Height = 25
    Caption = 'Parar servi'#231'o'
    Enabled = False
    TabOrder = 2
    OnClick = bbStopClick
  end
  object bbAddImpressora: TButton
    Left = 8
    Top = 454
    Width = 136
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Adicionar impressora'
    TabOrder = 3
    OnClick = bbAddImpressoraClick
    ExplicitTop = 449
  end
  object bbRemoverImpressao: TButton
    Left = 695
    Top = 454
    Width = 139
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Remover impress'#227'o'
    TabOrder = 4
    OnClick = bbRemoverImpressaoClick
    ExplicitLeft = 691
    ExplicitTop = 449
  end
  object gbDadosServico: TGroupBox
    Left = 8
    Top = 2
    Width = 520
    Height = 87
    Caption = 'Servidor de impress'#227'o'
    TabOrder = 0
    object Label1: TLabel
      Left = 9
      Top = 24
      Width = 49
      Height = 17
      Caption = 'Servidor'
    end
    object Label2: TLabel
      Left = 136
      Top = 24
      Width = 95
      Height = 17
      Caption = 'Porta de servi'#231'o'
    end
    object Label4: TLabel
      Left = 371
      Top = 24
      Width = 127
      Height = 17
      Caption = 'Porta de recebimento'
    end
    object Label3: TLabel
      Left = 263
      Top = 24
      Width = 85
      Height = 17
      Caption = 'Porta de envio'
    end
    object edIpServidor: TEdit
      Left = 9
      Top = 47
      Width = 121
      Height = 25
      Hint = 'Ip do servidor onde est'#227'o os servi'#231'os'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Text = '127.0.0.1'
    end
    object edPortaServicoGerenciamento: TEdit
      Left = 136
      Top = 47
      Width = 49
      Height = 25
      Hint = 'Porta do servi'#231'o de gerenciamento'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Text = '9000'
    end
    object edPortaServicoRecebimento: TEdit
      Left = 371
      Top = 47
      Width = 49
      Height = 25
      Hint = 'Porta do servi'#231'o de recebimento de arquivos de impress'#227'o'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      Text = '9200'
    end
    object edPortaServicoEnvio: TEdit
      Left = 263
      Top = 47
      Width = 49
      Height = 25
      Hint = 'Porta do servi'#231'o de envio de arquivos de impress'#227'o'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      Text = '9100'
    end
  end
  object pnlBackground: TPanel
    Left = 8
    Top = 149
    Width = 823
    Height = 299
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'pnlBackground'
    Enabled = False
    TabOrder = 5
    ExplicitWidth = 819
    ExplicitHeight = 294
    object grFilaImpressao: TDBGrid
      Left = 1
      Top = 1
      Width = 821
      Height = 297
      Align = alClient
      DataSource = dsFilaImpressao
      Options = [dgTitles]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -13
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = []
    end
  end
  object cbTestes: TComboBox
    Left = 534
    Top = 8
    Width = 230
    Height = 25
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    ItemIndex = 0
    TabOrder = 6
    Text = 'Testar servi'#231'o online'
    Items.Strings = (
      'Testar servi'#231'o online'
      'Testar envio de registros de impressoras'
      'Testar recebimento de cadastros de impressoras'
      'Testar envio de impress'#227'o'
      'Testar receber registro de impress'#227'o'
      'Receber impress'#245'es pendentes'
      'Executar fila impress'#227'o'
      'Receber Token de autoriza'#231#227'o')
    ExplicitWidth = 226
  end
  object bbExecutarTeste: TButton
    Left = 770
    Top = 8
    Width = 62
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Executar'
    TabOrder = 7
    OnClick = bbExecutarTesteClick
    ExplicitLeft = 766
  end
  object fmtFilaImpressao: TFDMemTable
    Active = True
    FieldDefs = <
      item
        Name = 'ORDEM'
        DataType = ftInteger
      end
      item
        Name = 'DESCRICAO'
        DataType = ftString
        Size = 100
      end
      item
        Name = 'TIPO_ARQUIVO'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'RELATORIO_ENCODED'
        DataType = ftMemo
      end
      item
        Name = 'REGISTRO'
        DataType = ftString
        Size = 50
      end>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 416
    Top = 168
    object fmtFilaImpressaoORDEM: TIntegerField
      DisplayLabel = 'Ordem'
      DisplayWidth = 10
      FieldName = 'ORDEM'
    end
    object fmtFilaImpressaoDESCRICAO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      DisplayWidth = 77
      FieldName = 'DESCRICAO'
      Size = 100
    end
    object fmtFilaImpressaoTIPO_ARQUIVO: TStringField
      DisplayLabel = 'Tipo arq.'
      DisplayWidth = 10
      FieldName = 'TIPO_ARQUIVO'
      Size = 10
    end
    object fmtFilaImpressaoRELATORIO_ENCODED: TMemoField
      FieldName = 'RELATORIO_ENCODED'
      Visible = False
      BlobType = ftMemo
    end
    object fmtFilaImpressaoREGISTRO: TStringField
      DisplayLabel = 'Registro'
      DisplayWidth = 15
      FieldName = 'REGISTRO'
      Size = 50
    end
  end
  object dsFilaImpressao: TDataSource
    AutoEdit = False
    DataSet = fmtFilaImpressao
    OnDataChange = dsFilaImpressaoDataChange
    Left = 424
    Top = 224
  end
  object tiIconeBandeja: TTrayIcon
    PopupMenu = PopupApp
    Left = 688
    Top = 168
  end
  object PopupApp: TPopupMenu
    Left = 592
    Top = 128
    object popupIniciar: TMenuItem
      Caption = 'Iniciar servi'#231'o'
      OnClick = popupIniciarClick
    end
    object popupParar: TMenuItem
      Caption = 'Parar Servi'#231'o'
      OnClick = popupPararClick
    end
    object popupRestaurar: TMenuItem
      Caption = 'Restaurar aplica'#231#227'o'
      OnClick = popupRestaurarClick
    end
  end
  object tmLooping: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = tmLoopingTimer
    Left = 264
    Top = 173
  end
  object tmInicializar: TTimer
    Enabled = False
    OnTimer = tmInicializarTimer
    Left = 264
    Top = 232
  end
end

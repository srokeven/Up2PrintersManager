object fmCadastroImpressoras: TfmCadastroImpressoras
  Left = 0
  Top = 0
  Caption = 'Cadastro de impressoras'
  ClientHeight = 470
  ClientWidth = 907
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object cpCadastroImpressoras: TCardPanel
    Left = 0
    Top = 0
    Width = 907
    Height = 470
    Align = alClient
    ActiveCard = cCadastro
    Caption = 'cpCadastroImpressoras'
    TabOrder = 0
    ExplicitWidth = 903
    ExplicitHeight = 465
    object cListaImpressoras: TCard
      Left = 1
      Top = 1
      Width = 905
      Height = 468
      Caption = 'Lista de impressoras'
      CardIndex = 0
      TabOrder = 0
      object pnlButtonsLista: TPanel
        Left = 0
        Top = 419
        Width = 905
        Height = 49
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 0
        object bbNovo: TButton
          Left = 16
          Top = 6
          Width = 121
          Height = 35
          Caption = 'Novo'
          TabOrder = 0
          OnClick = bbNovoClick
        end
        object bbAlterar: TButton
          Left = 143
          Top = 6
          Width = 121
          Height = 35
          Caption = 'Alterar'
          TabOrder = 1
          OnClick = bbAlterarClick
        end
        object bbRemover: TButton
          Left = 270
          Top = 6
          Width = 121
          Height = 35
          Caption = 'Remover'
          TabOrder = 2
          OnClick = bbRemoverClick
        end
      end
      object pnlBackgroundLista: TPanel
        Left = 0
        Top = 0
        Width = 905
        Height = 419
        Align = alClient
        TabOrder = 1
        object grLista: TDBGrid
          Left = 1
          Top = 1
          Width = 903
          Height = 417
          Align = alClient
          DataSource = dsImpressoras
          Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
          TabOrder = 0
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
        end
      end
    end
    object cCadastro: TCard
      Left = 1
      Top = 1
      Width = 905
      Height = 468
      Caption = 'Cadastro impressora'
      CardIndex = 1
      TabOrder = 1
      ExplicitWidth = 901
      ExplicitHeight = 463
      object pnlButtonsCadastro: TPanel
        Left = 0
        Top = 423
        Width = 905
        Height = 45
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitTop = 418
        ExplicitWidth = 901
        object bbSalvar: TButton
          Left = 16
          Top = 6
          Width = 137
          Height = 35
          Caption = 'Salvar'
          TabOrder = 0
          OnClick = bbSalvarClick
        end
        object bbCancelar: TButton
          Left = 159
          Top = 6
          Width = 137
          Height = 35
          Caption = 'Cancelar'
          TabOrder = 1
          OnClick = bbCancelarClick
        end
      end
      object pnlBackgroundCadastro: TPanel
        Left = 0
        Top = 0
        Width = 905
        Height = 423
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 901
        ExplicitHeight = 418
        DesignSize = (
          905
          423)
        object Label1: TLabel
          Left = 16
          Top = 16
          Width = 43
          Height = 15
          Caption = 'Registro'
          FocusControl = edRegistro
        end
        object Label2: TLabel
          Left = 16
          Top = 66
          Width = 51
          Height = 15
          Caption = 'Descri'#231#227'o'
          FocusControl = edDescricao
        end
        object Label3: TLabel
          Left = 16
          Top = 116
          Width = 80
          Height = 15
          Caption = 'Tipo impress'#227'o'
        end
        object Label4: TLabel
          Left = 16
          Top = 166
          Width = 101
          Height = 15
          Caption = 'Compartilhamento'
          FocusControl = edCompartilhamento
        end
        object Label5: TLabel
          Left = 16
          Top = 216
          Width = 41
          Height = 15
          Caption = 'IP Local'
          FocusControl = edIPLocal
        end
        object Label6: TLabel
          Left = 16
          Top = 266
          Width = 98
          Height = 15
          Caption = 'Nome do Terminal'
          FocusControl = edNomeTerminal
        end
        object sbPrintsSetup: TSpeedButton
          Left = 831
          Top = 187
          Width = 23
          Height = 22
          Anchors = [akTop, akRight]
          Caption = '...'
          OnClick = sbPrintsSetupClick
          ExplicitLeft = 851
        end
        object edRegistro: TDBEdit
          Left = 16
          Top = 37
          Width = 838
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          DataField = 'registro'
          DataSource = dsImpressoras
          TabOrder = 0
          ExplicitWidth = 834
        end
        object edDescricao: TDBEdit
          Left = 16
          Top = 87
          Width = 838
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          DataField = 'descricao'
          DataSource = dsImpressoras
          TabOrder = 1
          ExplicitWidth = 834
        end
        object edCompartilhamento: TDBEdit
          Left = 16
          Top = 187
          Width = 809
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          DataField = 'compartilhamento'
          DataSource = dsImpressoras
          TabOrder = 2
          ExplicitWidth = 805
        end
        object edIPLocal: TDBEdit
          Left = 16
          Top = 237
          Width = 838
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          DataField = 'iplocal'
          DataSource = dsImpressoras
          TabOrder = 3
          ExplicitWidth = 834
        end
        object edNomeTerminal: TDBEdit
          Left = 16
          Top = 287
          Width = 838
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          DataField = 'nometerminal'
          DataSource = dsImpressoras
          TabOrder = 4
          ExplicitWidth = 834
        end
        object cbTipoImpressao: TComboBox
          Left = 16
          Top = 137
          Width = 838
          Height = 23
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          ItemIndex = 0
          TabOrder = 5
          Text = 'Impressora com Driver'
          OnSelect = cbTipoImpressaoSelect
          Items.Strings = (
            'Impressora com Driver'
            'Impressora Generic Text')
          ExplicitWidth = 834
        end
      end
    end
  end
  object fmtImpressoras: TFDMemTable
    Active = True
    BeforePost = fmtImpressorasBeforePost
    FieldDefs = <
      item
        Name = 'registro'
        Attributes = [faRequired]
        DataType = ftString
        Size = 50
      end
      item
        Name = 'descricao'
        Attributes = [faRequired]
        DataType = ftString
        Size = 100
      end
      item
        Name = 'tipoimpressora'
        Attributes = [faRequired]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'compartilhamento'
        Attributes = [faRequired]
        DataType = ftString
        Size = 100
      end
      item
        Name = 'iplocal'
        Attributes = [faRequired]
        DataType = ftString
        Size = 15
      end
      item
        Name = 'nometerminal'
        Attributes = [faRequired]
        DataType = ftString
        Size = 100
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
    Left = 392
    Top = 312
    object fmtImpressorasREGISTRO: TStringField
      DisplayLabel = 'Registro'
      DisplayWidth = 10
      FieldName = 'registro'
      Required = True
      Size = 50
    end
    object fmtImpressorasDESCRICAO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      DisplayWidth = 40
      FieldName = 'descricao'
      Required = True
      Size = 100
    end
    object fmtImpressorasTIPO_IMPRESSAO: TStringField
      DisplayLabel = 'Tipo impress'#227'o'
      FieldName = 'tipoimpressora'
      Required = True
      Size = 10
    end
    object fmtImpressorasCOMPARTILHAMENTO: TStringField
      DisplayLabel = 'Compartilhamento'
      DisplayWidth = 50
      FieldName = 'compartilhamento'
      Required = True
      Size = 100
    end
    object fmtImpressorasIP_LOCAL: TStringField
      DisplayLabel = 'Ip Local'
      FieldName = 'iplocal'
      Required = True
      Size = 15
    end
    object fmtImpressorasNOME_TERMINAL: TStringField
      DisplayLabel = 'Nome Terminal'
      DisplayWidth = 50
      FieldName = 'nometerminal'
      Required = True
      Size = 100
    end
  end
  object dsImpressoras: TDataSource
    AutoEdit = False
    DataSet = fmtImpressoras
    Left = 216
    Top = 312
  end
  object pdDriver: TPrintDialog
    Left = 448
    Top = 240
  end
  object psdSetup: TPrinterSetupDialog
    Left = 560
    Top = 232
  end
end

unit uCadastroImpressora;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.WinXPanels, Data.DB,
  Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Mask,
  Vcl.DBCtrls, System.JSON, DataSetConverter4D, DataSetConverter4D.Impl,
  IdStack, Winapi.WinSock, Vcl.Buttons, Printers;

type
  TfmCadastroImpressoras = class(TForm)
    cpCadastroImpressoras: TCardPanel;
    cListaImpressoras: TCard;
    cCadastro: TCard;
    pnlButtonsLista: TPanel;
    pnlBackgroundLista: TPanel;
    grLista: TDBGrid;
    bbNovo: TButton;
    bbAlterar: TButton;
    bbRemover: TButton;
    fmtImpressoras: TFDMemTable;
    dsImpressoras: TDataSource;
    fmtImpressorasREGISTRO: TStringField;
    fmtImpressorasDESCRICAO: TStringField;
    fmtImpressorasTIPO_IMPRESSAO: TStringField;
    fmtImpressorasCOMPARTILHAMENTO: TStringField;
    fmtImpressorasIP_LOCAL: TStringField;
    fmtImpressorasNOME_TERMINAL: TStringField;
    pnlButtonsCadastro: TPanel;
    pnlBackgroundCadastro: TPanel;
    Label1: TLabel;
    edRegistro: TDBEdit;
    Label2: TLabel;
    edDescricao: TDBEdit;
    Label3: TLabel;
    Label4: TLabel;
    edCompartilhamento: TDBEdit;
    Label5: TLabel;
    edIPLocal: TDBEdit;
    Label6: TLabel;
    edNomeTerminal: TDBEdit;
    cbTipoImpressao: TComboBox;
    bbSalvar: TButton;
    bbCancelar: TButton;
    pdDriver: TPrintDialog;
    psdSetup: TPrinterSetupDialog;
    sbPrintsSetup: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure bbCancelarClick(Sender: TObject);
    procedure bbSalvarClick(Sender: TObject);
    procedure bbNovoClick(Sender: TObject);
    procedure bbAlterarClick(Sender: TObject);
    procedure bbRemoverClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fmtImpressorasBeforePost(DataSet: TDataSet);
    procedure cbTipoImpressaoSelect(Sender: TObject);
    procedure sbPrintsSetupClick(Sender: TObject);
  private
    FConfig: string;
    procedure CarregarImpressoras;
    function GetLocalIP: string;
    function RetornaNomeTerminal: string;
  public
    { Public declarations }
  end;

var
  fmCadastroImpressoras: TfmCadastroImpressoras;

implementation

{$R *.dfm}

uses uUtils;

procedure TfmCadastroImpressoras.bbAlterarClick(Sender: TObject);
begin
  fmtImpressoras.Edit;
  if fmtImpressorasTIPO_IMPRESSAO.AsString = 'PDF' then
    cbTipoImpressao.ItemIndex := 0
  else
    cbTipoImpressao.ItemIndex := 1;
  cpCadastroImpressoras.ActiveCard := cCadastro;
end;

procedure TfmCadastroImpressoras.bbCancelarClick(Sender: TObject);
begin
  fmtImpressoras.Cancel;
  cpCadastroImpressoras.ActiveCard := cListaImpressoras;
end;

procedure TfmCadastroImpressoras.bbNovoClick(Sender: TObject);
begin
  cpCadastroImpressoras.ActiveCard := cCadastro;
  fmtImpressoras.Append;
  fmtImpressorasREGISTRO.AsString := FormatDateTime('ddmmyyhhnnss', now);
  fmtImpressorasIP_LOCAL.AsString := GetLocalIP;
  fmtImpressorasNOME_TERMINAL.AsString := RetornaNomeTerminal;
end;

function TfmCadastroImpressoras.GetLocalIP: string;
begin
  TIdStack.IncUsage;
  try
    Result := GStack.LocalAddress;
  finally
    TIdStack.DecUsage;
  end;
end;

procedure TfmCadastroImpressoras.bbRemoverClick(Sender: TObject);
begin
  fmtImpressoras.Delete;
end;

procedure TfmCadastroImpressoras.bbSalvarClick(Sender: TObject);
begin
  case cbTipoImpressao.ItemIndex of
    0: fmtImpressorasTIPO_IMPRESSAO.AsString := 'PDF';
    1: fmtImpressorasTIPO_IMPRESSAO.AsString := 'TXT';
  end;
  fmtImpressoras.Post;
  cpCadastroImpressoras.ActiveCard := cListaImpressoras;
end;

procedure TfmCadastroImpressoras.CarregarImpressoras;
var
  vListaImpressoras: string;
  vArrayJson: TJSONArray;
  I: Integer;
begin
  vListaImpressoras := LerArrayJsonFromFile(FConfig);
  if not (vListaImpressoras.IsEmpty) then
  begin
    vArrayJson := TJSONObject.ParseJSONValue(vListaImpressoras) as TJSONArray;
    try
      for I := 0 to vArrayJson.Count - 1 do
      begin
        fmtImpressoras.Append;
        fmtImpressorasREGISTRO.AsString := (vArrayJson.Items[I] as TJSONObject).GetValue<string>('registro');
        fmtImpressorasDESCRICAO.AsString := (vArrayJson.Items[I] as TJSONObject).GetValue<string>('descricao');
        fmtImpressorasTIPO_IMPRESSAO.AsString := (vArrayJson.Items[I] as TJSONObject).GetValue<string>('tipoimpressora');
        fmtImpressorasCOMPARTILHAMENTO.AsString := (vArrayJson.Items[I] as TJSONObject).GetValue<string>('compartilhamento');
        fmtImpressorasIP_LOCAL.AsString := (vArrayJson.Items[I] as TJSONObject).GetValue<string>('iplocal');
        fmtImpressorasNOME_TERMINAL.AsString := (vArrayJson.Items[I] as TJSONObject).GetValue<string>('nometerminal');
        fmtImpressoras.Post;
      end;
    finally
      vArrayJson.Free;
    end;
  end;
end;

procedure TfmCadastroImpressoras.cbTipoImpressaoSelect(Sender: TObject);
begin
  sbPrintsSetup.Enabled := cbTipoImpressao.ItemIndex = 0;
end;

procedure TfmCadastroImpressoras.fmtImpressorasBeforePost(DataSet: TDataSet);
var
  I: Integer;
begin
  for I := 0 to fmtImpressoras.Fields.Count - 1 do
  begin
    if fmtImpressoras.Fields[I].AsString.IsEmpty then
      raise Exception.Create('Campo "'+fmtImpressoras.Fields[I].DisplayName+'" em branco');
  end;
end;

procedure TfmCadastroImpressoras.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
  vArrayJson: TJSONArray;
begin
  if not (fmtImpressoras.IsEmpty) then
  begin
    vArrayJson := TConverter.New.DataSet(fmtImpressoras).AsJSONArray;
    GravarArrayJsonToFile(vArrayJson.ToJSON, FConfig);
  end
  else
  if FileExists(FConfig) then
    DeleteFile(FConfig);
end;

procedure TfmCadastroImpressoras.FormCreate(Sender: TObject);
begin
  FConfig := ExtractFilePath(ParamStr(0))+'list.json';
  cpCadastroImpressoras.ActiveCard := cListaImpressoras;
  fmtImpressoras.Open;
  CarregarImpressoras;
end;

procedure TfmCadastroImpressoras.sbPrintsSetupClick(Sender: TObject);
begin
  if psdSetup.Execute then
  begin
    fmtImpressorasCOMPARTILHAMENTO.AsString := Printer.Printers[Printer.PrinterIndex];
  end;
end;

function TfmCadastroImpressoras.RetornaNomeTerminal: string;
var
  terminalName: string;

  function GetLocalPCName: String;
  var
      Buffer: array [0..63] of AnsiChar;
      i: Integer;
      GInitData: TWSADATA;
  begin
      Result := '';
      WSAStartup($101, GInitData);
      GetHostName(Buffer, SizeOf(Buffer));
      Result:=Buffer;
      WSACleanup;
  end;
begin
  terminalName := GetEnvironmentVariable('COMPUTERNAME');
  if terminalName.IsEmpty then
    terminalName := GetLocalPCName;
  Result := terminalName;
end;

end.

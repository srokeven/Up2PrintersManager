unit uRegistroImpressaoController;

interface

uses
  uRegistroImpressaoModel, System.Generics.Collections, System.SysUtils,
  System.Classes, System.JSON;

type
  TImpressaoController = class
    private
      FRegistrosImpressoes: TObjectList<TRegistroImpressao>;
      FError: string;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(ADescricao, ATipoArquivo, ARegistroImpressora, AJsonOriginal,
        ARelatorioEncoded, ACaminhoArquivo: string);
      function SalvarArquivos: boolean;
      function GetArquivos(ARegistro: string): string;
      function GetPrints(AListaArquivos: string): string;
      function Erro: string;
  end;

implementation

{ TImpressaoController }

uses uUtils;

procedure TImpressaoController.Add(ADescricao, ATipoArquivo,
  ARegistroImpressora, AJsonOriginal, ARelatorioEncoded, ACaminhoArquivo: string);
var
  vNovoRegistro: TRegistroImpressao;
begin
  vNovoRegistro := TRegistroImpressao.Create;
  vNovoRegistro.Descricao := ADescricao;
  vNovoRegistro.TipoArquivo := ATipoArquivo;
  vNovoRegistro.RegistroImpressora := ARegistroImpressora;
  vNovoRegistro.JsonOriginal := AJsonOriginal;
  vNovoRegistro.RelatorioEncoded := ARelatorioEncoded;
  vNovoRegistro.CaminhoArquivo := ACaminhoArquivo;
  FRegistrosImpressoes.Add(vNovoRegistro);
end;

constructor TImpressaoController.Create;
begin
  FRegistrosImpressoes := TObjectList<TRegistroImpressao>.Create;
end;

destructor TImpressaoController.Destroy;
begin
  FRegistrosImpressoes.DisposeOf;
  inherited;
end;

function TImpressaoController.Erro: string;
begin
  Result := FError;
end;

function TImpressaoController.GetArquivos(ARegistro: string): string;
var
  vDiretorio: string;
  listaArquivos: TStringList;
  busca: TSearchRec;
  resultado: Integer;
begin
  Result := '';
  vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))+'files')+ARegistro;
  if not (DirectoryExists(vDiretorio)) then
  begin
    ForceDirectories(vDiretorio);
    Exit;
  end;
  listaArquivos := TStringList.Create;
  try
    resultado := FindFirst(vDiretorio + '\*.*', faAnyFile, busca);
    try
      while resultado = 0 do
      begin
        // Verifica se o item encontrado é um arquivo e não um diretório
        if (busca.Attr and faDirectory) = 0 then
          listaArquivos.Add(vDiretorio + '\' + busca.Name);

        resultado := FindNext(busca);
      end;
    finally
      FindClose(busca);
    end;

    // Concatenar os caminhos dos arquivos separados por vírgula
    Result := listaArquivos.DelimitedText;
  finally
    listaArquivos.Free;
  end;
end;

function TImpressaoController.GetPrints(AListaArquivos: string): string;
var
  vJsonArray: TJSONArray;
  vJsonObject: TJSONObject;
  vStringJson: string;
  listaArquivos: TStringList;
  I: integer;
begin
  vJsonArray := TJSONArray.Create;
  listaArquivos := TStringList.Create;
  try
    listaArquivos.Delimiter := ',';
    listaArquivos.StrictDelimiter := True;
    listaArquivos.DelimitedText := AListaArquivos;

    for I := 0 to listaArquivos.Count -1 do
    begin
      vStringJson := LerJsonFromFile(listaArquivos[I]);
      vJsonObject := TJSONObject.ParseJSONValue(vStringJson) as TJSONObject;
      vJsonArray.AddElement(vJsonObject);
    end;
    Result := vJsonArray.ToJSON;
  finally
    listaArquivos.Free;
  end;
end;

function TImpressaoController.SalvarArquivos: boolean;
var
  I: Integer;
  vGeneric : TStringList;
  StreamFile: TBytesStream;
  vNomeArquivo, vDiretorio: string;
begin
  Result := True;
  for I := 0 to FRegistrosImpressoes.Count - 1 do
  begin
    if FRegistrosImpressoes[I].CaminhoArquivo = EmptyStr then
    begin
      vGeneric := TStringList.Create;
      try
        try
          vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))+'files')+FRegistrosImpressoes[I].RegistroImpressora;
          if not (DirectoryExists(vDiretorio)) then
            ForceDirectories(vDiretorio);
          vNomeArquivo := IncludeTrailingPathDelimiter(vDiretorio)+'arq_'+FormatDateTime('ddmmyyhhnnsszzz', now)+'.txt';
          vGeneric.Text := FRegistrosImpressoes[I].JsonOriginal;
          vGeneric.SaveToFile(vNomeArquivo);
          FRegistrosImpressoes[I].CaminhoArquivo := vNomeArquivo;
        except
          on E: exception do
          begin
            Result := False;
            FError := E.Message;
          end;
        end;
      finally
        vGeneric.Free;
      end;
    end;
  end;
end;

end.

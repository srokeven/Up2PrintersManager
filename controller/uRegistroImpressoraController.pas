unit uRegistroImpressoraController;

interface

uses
  uRegistroImpressoraModel, System.Generics.Collections, System.SysUtils,
  System.Classes, System.JSON;

type
  TImpressoraController = class
    private
      FRegistrosImpressoras: TObjectList<TRegistroImpressora>;
      FError: string;
      FArquivoConfig: string;
    public
      constructor Create;
      destructor Destroy; override;
      function Add(ARegistro, ADescricao, ATipoImpressora, ACompartilhamentoImpressora,
        AIpLocal, ANomeTerminal: string): integer;
      function GetPrinters(ARegistro: string): string;
      procedure LoadList(AArrayJson: string);
      function Erro: string;
      function SalvarRegistros: boolean;
  end;

implementation

{ TImpressaoController }

uses uUtils;

function TImpressoraController.Add(ARegistro, ADescricao, ATipoImpressora,
  ACompartilhamentoImpressora, AIpLocal, ANomeTerminal: string): integer;
var
  vNovoRegistro: TRegistroImpressora;
  I: integer;
begin
  for I := 0 to FRegistrosImpressoras.Count - 1 do
  begin
    if FRegistrosImpressoras[I].Registro = ARegistro then
    begin
      Result := 202;
      Exit;
    end;
  end;
  vNovoRegistro := TRegistroImpressora.Create;
  vNovoRegistro.Registro := ARegistro;
  vNovoRegistro.Descricao := ADescricao;
  vNovoRegistro.TipoImpressora := ATipoImpressora;
  vNovoRegistro.CompartilhamentoImpressora := ACompartilhamentoImpressora;
  vNovoRegistro.IpLocal := AIpLocal;
  vNovoRegistro.NomeTerminal := ANomeTerminal;
  FRegistrosImpressoras.Add(vNovoRegistro);
  Result := 201;
end;

constructor TImpressoraController.Create;
var
  vDiretorio: string;
begin
  FRegistrosImpressoras := TObjectList<TRegistroImpressora>.Create;
  vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))+'reg');
  if not (DirectoryExists(vDiretorio)) then
    ForceDirectories(vDiretorio);
  FArquivoConfig := IncludeTrailingPathDelimiter(vDiretorio)+'config.conf';
  LoadList(LerArrayJsonFromFile(FArquivoConfig));
end;

destructor TImpressoraController.Destroy;
begin
  FRegistrosImpressoras.DisposeOf;
  inherited;
end;

function TImpressoraController.Erro: string;
begin
  Result := FError;
end;

function TImpressoraController.GetPrinters(ARegistro: string): string;
var
  I: Integer;
  vObjectPrinter: TJSONObject;
  vJsonArray: TJSONArray;
begin
  Result := '[]';                    
  vJsonArray := TJSONArray.Create;
  try
    for I := 0 to FRegistrosImpressoras.Count - 1 do
    begin
      if not (ARegistro.IsEmpty) then
        if FRegistrosImpressoras[I].Registro <> ARegistro then
          continue;

      vObjectPrinter := TJSONObject.Create;
      vObjectPrinter.AddPair('registro', FRegistrosImpressoras[I].Registro);
      vObjectPrinter.AddPair('descricao', FRegistrosImpressoras[I].Descricao);
      vObjectPrinter.AddPair('tipoimpressora', FRegistrosImpressoras[I].TipoImpressora);
      vObjectPrinter.AddPair('compartilhamento', FRegistrosImpressoras[I].CompartilhamentoImpressora);
      vObjectPrinter.AddPair('iplocal', FRegistrosImpressoras[I].IpLocal);
      vObjectPrinter.AddPair('nometerminal', FRegistrosImpressoras[I].NomeTerminal);
      vJsonArray.AddElement(vObjectPrinter);
    end;
    Result := vJsonArray.ToJSON;
  finally
    vJsonArray.Free;
  end;
end;

procedure TImpressoraController.LoadList(AArrayJson: string);
var
  I: Integer;
  vJsonArray: TJSONArray;
  vJsonObjectString: string;
begin
  if AArrayJson = '[]' then
    Exit;
  vJsonArray := TJSONObject.ParseJSONValue(AArrayJson) as TJSONArray;
  try
    for I := 0 to vJsonArray.Count - 1 do
    begin
      vJsonObjectString := LerJsonFromArrayJson(vJsonArray.ToString, I);
      Add(LerJson(vJsonObjectString, 'registro'),
          LerJson(vJsonObjectString, 'descricao'),
          LerJson(vJsonObjectString, 'tipoimpressora'),
          LerJson(vJsonObjectString, 'compartilhamento'),
          LerJson(vJsonObjectString, 'iplocal'),
          LerJson(vJsonObjectString, 'nometerminal'));
    end;
  finally
    vJsonArray.Free;
  end;
end;

function TImpressoraController.SalvarRegistros: boolean;
begin
  Result := False;
  try
    GravarArrayJsonToFile(GetPrinters(''), FArquivoConfig);
    Result := True;
  except
     on e: exception do
       FError := 'Erro ao salvar o registro: '+e.Message;
  end;
end;

end.

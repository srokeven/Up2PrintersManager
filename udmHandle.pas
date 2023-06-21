unit udmHandle;

interface

uses
  System.SysUtils, System.Classes, uRegistroImpressaoController, System.JSON,
  uRegistroImpressoraController, System.StrUtils;

type
  TdmHandle = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FControllerImpressao: TImpressaoController;
    FControllerImpressora: TImpressoraController;
    FListaArquivosGarbageCollection: string;
  public
    function StoreFile(AJson: string): boolean;
    function RegisterPrinter(AJson: string): integer;
    function GetPrinters: string;
    function GetPrints(ARegistro: string):string;
    function GetErroImpressao: string;
    function GetErroImpressora: string;
    procedure LimparArquivos;
  end;

var
  dmHandle: TdmHandle;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

uses uUtils;

{$R *.dfm}

procedure TdmHandle.DataModuleCreate(Sender: TObject);
begin
  FControllerImpressao := TImpressaoController.Create;
  FControllerImpressora := TImpressoraController.Create;
end;

procedure TdmHandle.DataModuleDestroy(Sender: TObject);
begin
  FControllerImpressao.DisposeOf;
  FControllerImpressora.DisposeOf;
end;

function TdmHandle.GetErroImpressao: string;
begin
  result := FControllerImpressao.Erro;
end;

function TdmHandle.GetErroImpressora: string;
begin
  result := FControllerImpressora.Erro;
end;

function TdmHandle.GetPrinters: string;
var
  vJsonArray: TJSONArray;
begin
  vJsonArray := TJSONObject.ParseJSONValue(FControllerImpressora.GetPrinters('')) as TJSONArray;
  try
    Result := vJsonArray.ToString;
  finally
    vJsonArray.Free;
  end;
end;

function TdmHandle.GetPrints(ARegistro: string): string;
var
  vListaArquivos: string;
  listaArquivos: TStringList;
  I: Integer;
  vJsonArray: TJSONArray;
begin
  vListaArquivos := FControllerImpressao.GetArquivos(ARegistro);
  if vListaArquivos.IsEmpty then
    Exit('[]');
  FListaArquivosGarbageCollection := FListaArquivosGarbageCollection + IfThen(FListaArquivosGarbageCollection.IsEmpty, '', ',') + vListaArquivos;
  vJsonArray := TJSONObject.ParseJSONValue(FControllerImpressao.GetPrints(vListaArquivos)) as TJSONArray;
  try
    Result := vJsonArray.ToString;
  finally
    vJsonArray.Free;
  end;
end;

function TdmHandle.StoreFile(AJson: string): boolean;
begin
  if AJson.IsEmpty then
    Exit(False);
  FControllerImpressao.Add(LerJson(AJson, 'descricao'),
                           LerJson(AJson, 'tipoarquivo'),
                           LerJson(AJson, 'registroimpressora'),
                           AJson,
                           LerJson(AJson, 'relatorioencoded'),
                           '');
  Result := FControllerImpressao.SalvarArquivos;
end;

procedure TdmHandle.LimparArquivos;
var
  vListaArquivosApagar: TStringList;
  I: integer;
  vGarbageAux: string;
begin
  if FListaArquivosGarbageCollection.IsEmpty then
    Exit;
  vGarbageAux := FListaArquivosGarbageCollection;
  FListaArquivosGarbageCollection := '';
  vListaArquivosApagar := TStringList.Create;
  try
    try
      vListaArquivosApagar.Delimiter := ',';
      vListaArquivosApagar.StrictDelimiter := True;
      vListaArquivosApagar.DelimitedText := vGarbageAux;

      for I := 0 to vListaArquivosApagar.Count -1 do
      begin
        if FileExists(vListaArquivosApagar[I]) then
          DeleteFile(vListaArquivosApagar[I]);
      end;
    except
      on e: exception do
      begin
        FListaArquivosGarbageCollection := FListaArquivosGarbageCollection + IfThen(FListaArquivosGarbageCollection.IsEmpty, '', ',') + vGarbageAux;
        raise Exception.Create(e.Message);
      end;
    end;
  finally
    vListaArquivosApagar.Free;
  end;
end;

function TdmHandle.RegisterPrinter(AJson: string): integer;
var
  vResultadoAdd: integer;
  vJsonObjectString: string;
  vJsonArray: TJSONArray;
  I: Integer;
begin
  vResultadoAdd := 0;
  if AJson.IsEmpty then
    Result := 204
  else
  begin
    Result := 208;
    vJsonArray := TJSONObject.ParseJSONValue(LerJsonArray(AJson, 'impressoras')) as TJSONArray;
    try
      for I := 0 to vJsonArray.Count - 1 do
      begin
        vJsonObjectString := LerJsonFromArrayJson(vJsonArray.ToString, I);
        if LerJson(vJsonObjectString, 'registro') = '000000000000' then
        begin
          vResultadoAdd := 202;
          Result := 202;
          break;
        end;
        vResultadoAdd := FControllerImpressora.Add(LerJson(vJsonObjectString, 'registro'),
                                                   LerJson(vJsonObjectString, 'descricao'),
                                                   LerJson(vJsonObjectString, 'tipoimpressora'),
                                                   LerJson(vJsonObjectString, 'compartilhamento'),
                                                   LerJson(vJsonObjectString, 'iplocal'),
                                                   LerJson(vJsonObjectString, 'nometerminal'));
        if vResultadoAdd = 201 then
          Result := vResultadoAdd;
      end;
    finally
      vJsonArray.Free;
    end;
    if Result = 201 then
      if not (FControllerImpressora.SalvarRegistros) then
        Result := 500;
  end;
end;

end.

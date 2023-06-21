unit udmWebService;

interface

uses
  System.SysUtils, System.Classes, REST.Types, REST.Client, REST.Json,
  Data.Bind.Components, Data.Bind.ObjectScope, System.JSON, Vcl.Graphics,
  Vcl.Printers, Winapi.Windows, System.NetEncoding, IPPeerClient;

type
  TUltimoPost = record
    UltimoStatus: integer;
    UltimaMensagem: string;
    UltimaAcaoDataHora: TDateTime;
  end;

  TUltimoGet = record
    UltimoStatus: integer;
    UltimaMensagem: string;
    UltimaAcaoDataHora: TDateTime;
  end;

  TdmWebService = class(TDataModule)
  private
    FcUrl: string;
    FUltimoPost: TUltimoPost;
    FUltimoGet: TUltimoGet;
    FToken: string;
    function Get(AEndPoint, AToken: string): string;
    function Post(AEndPoint, AParam, AToken: string; const AUserBasic: string = ''; const APassBasic: string = ''): string;
    function SalvarPDFEncoded(aBase64, aNome: string): string;
  public
    //Testes operacionais
    function TesteWebservice: string;
    function TesteEnvioRegistrosImpressoras: string;
    function TesteRecebimentoRegistrosImpressoras: string;
    function TesteEnviarImpressao: string;
    function TesteRecebimentoImpressores: string;

    function ImprimirPDF(ADestino, AEncodedPDF: string): boolean;
    function ImprimirTXT(ADestino, AEncodedTXT: string): boolean;
    function CarregarRegistrosImpressoras: string;
    function EnviarRegistrosImpressoras: string;
    function GetImpressoras: string;
    function GetImpressoes(ARegistro: string): string;
    function GetTokenAPi: string;
    property cUrl: string read FcUrl write FcUrl;
  end;

var
  dmWebService: TdmWebService;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses uUtils, IdGlobal, IdHTTP, IdURI, REST.Authenticator.Basic;

{$R *.dfm}

{ TdmWebService }

function TdmWebService.CarregarRegistrosImpressoras: string;
var
  vArquivoLista: string;
begin
  vArquivoLista := ExtractFilePath(ParamStr(0))+'list.json';
  if FileExists(vArquivoLista) then
  begin
    Result := LerArrayJsonFromFile(vArquivoLista);
  end;
end;

function TdmWebService.TesteEnviarImpressao: string;
var
  vJsonTeste: string;
  vArquivoLocal: string;
  vJsonEnvio: TJSONObject;
  Cupom: TStringList;
  function EncodeBase64PDF(aFile: string): string;
  var
    StreamFile: TBytesStream;
  begin
    if aFile.IsEmpty then
    begin
      Result := '';
      Exit;
    end;
    if FileExists(aFile) then
    begin
      StreamFile := TBytesStream.Create;
      try
        try
          StreamFile.LoadFromFile(aFile);
          Result := TNetEncoding.Base64.EncodeBytesToString(StreamFile.Bytes);
        except
          Result := '';
        end;
      finally
        StreamFile.Free;
      end;
    end;
  end;
begin
  vArquivoLocal := ExtractFilePath(ParamStr(0))+'teste.pdf';
  if FileExists(vArquivoLocal) then
  begin
     {frxPDFExport1.FileName := ExtractFileName(vArquivoLocal);
    frxPDFExport1.DefaultPath := ExtractFilePath(vArquivoLocal);
    frxPDFExport1.ShowDialog := False;
    frxReport1.PrintOptions.ShowDialog := False;
    frxReport1.PrepareReport();
    frxReport1.Export(frxPDFExport1); }
    vJsonEnvio := TJSONObject.Create.AddPair('descricao', 'TESTE').
                                     AddPair('tipoarquivo','TST').
                                     AddPair('registroimpressora','000000000000').
                                     AddPair('relatorioencoded', EncodeBase64PDF(vArquivoLocal));

    vJsonTeste := vJsonEnvio.ToString;
    vJsonEnvio.Free;
  end else
  begin
    vArquivoLocal := ExtractFilePath(ParamStr(0))+'teste.txt';
    Cupom := TStringList.Create;
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    Cupom.Add('       PEDIDOS DE VENDAS       ');
    vJsonEnvio := TJSONObject.Create.AddPair('descricao', 'TESTE').
                                     AddPair('tipoarquivo','TST').
                                     AddPair('registroimpressora','000000000000').
                                     AddPair('relatorioencoded', TNetEncoding.Base64.Encode(Cupom.Text));

    vJsonTeste := vJsonEnvio.ToString;
    vJsonEnvio.Free;
    Cupom.Free;
  end;
  Result := LerJson(Post('print', vJsonTeste, FToken), 'mensagem');
end;

function TdmWebService.SalvarPDFEncoded(aBase64, aNome: string): string;
var
  StreamFile: TBytesStream;
  vCaminhoArquivo, vCaminhoDiretorio: string;
begin
  Result := '';
  vCaminhoDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'temp';
  if not (DirectoryExists(vCaminhoDiretorio)) then
    ForceDirectories(vCaminhoDiretorio);

  vCaminhoArquivo := IncludeTrailingPathDelimiter(vCaminhoDiretorio)+aNome+'.pdf';
  StreamFile := TBytesStream.Create(TNetEncoding.Base64.DecodeStringToBytes(aBase64));
  try
    try
      StreamFile.SaveToFile(vCaminhoArquivo);
      Result := vCaminhoArquivo;
    except
      Result := '';
    end;
  finally
    StreamFile.Free;
  end;
end;

function TdmWebService.EnviarRegistrosImpressoras: string;
var
  vArquivoLista, vListaImpressoras, vRetorno: string;
  vJsonEnvio: TJSONObject;
begin
  vArquivoLista := ExtractFilePath(ParamStr(0))+'list.json';
  if FileExists(vArquivoLista) then
  begin
    vListaImpressoras := LerArrayJsonFromFile(vArquivoLista);
    if vListaImpressoras.IsEmpty then
      Exit('Nenhuma impressora registrada');
    vJsonEnvio := TJSONObject.Create;
    try
      vJsonEnvio.AddPair('impressoras', TJSONObject.ParseJSONValue(vListaImpressoras) as TJSONArray);
      //vRetorno := PostEx('registerprint', vJsonEnvio);
      vRetorno := Post('registerprint', vJsonEnvio.ToJSON, FToken);
      if (FUltimoPost.UltimoStatus = 201) or
         (FUltimoPost.UltimoStatus = 208) then
        Result :=  'ok'
      else Result := LerJson(vRetorno, 'mensagem');
    finally
      vJsonEnvio.Free;
    end;
  end;
end;

function TdmWebService.GetImpressoes(ARegistro: string): string;
begin
  Result := Get('prints/'+ARegistro, FToken);
end;

function TdmWebService.GetImpressoras: string;
begin
  Result := Get('printers', FToken);
end;

function TdmWebService.GetTokenAPi: string;
begin
  FToken := LerJson(Post('gerartokendiario', '{}', '', USER_BASIC_AUTH, PASSWORD_BASIC_AUTH), 'mensagem');
  Result := FToken;
end;

function TdmWebService.ImprimirPDF(ADestino, AEncodedPDF: string): boolean;
var
  vDirArquivo, vNomeArquivo, vOutputDirectory: string;
begin
  Result := False;
  vDirArquivo := SalvarPDFEncoded(AEncodedPDF, 'pdf_'+ADestino+'_'+FormatDateTime('ddmmyyhhnnss', now));
  vNomeArquivo := ExtractFileName(vDirArquivo);
  vOutputDirectory := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'output';
  if not (DirectoryExists(vOutputDirectory)) then
    ForceDirectories(vOutputDirectory);
  MoveFile(PWideChar(vDirArquivo), PWideChar(IncludeTrailingPathDelimiter(vOutputDirectory)+vNomeArquivo));
  Result := True;
end;

function TdmWebService.ImprimirTXT(ADestino, AEncodedTXT: string): boolean;
var
  vImpressora: TStringList;
begin
  Result := False;
  vImpressora := TStringList.Create;
  try
    vImpressora.Text := TNetEncoding.Base64.Decode(AEncodedTXT);
    vImpressora.SaveToFile(ADestino);
    Result := True;
  finally
    vImpressora.Free;
  end;
end;

function TdmWebService.Get(AEndPoint, AToken: string): string;
var
  RestCliente: TRESTClient;
  RestRequisicao: TRESTRequest;
  RestResposta: TRESTResponse;
begin
  RestCliente := nil;
  RestRequisicao := nil;
  RestResposta := nil;
  try
    RestCliente := TRESTClient.Create(FcUrl);
    RestRequisicao := TRESTRequest.Create(nil);
    RestResposta := TRESTResponse.Create(nil);
    try
      try
        RestCliente.Accept := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
        RestCliente.AcceptCharset := 'utf-8, *;q=0.8';
        RestCliente.RaiseExceptionOn500 := False;
        RestRequisicao.Params.Clear;
        RestRequisicao.Client := RestCliente;
        RestRequisicao.Method := rmGET;
        RestRequisicao.Resource := AEndPoint;
        RestRequisicao.Response := RestResposta;
        RestRequisicao.SynchronizedEvents := False;
        if not (FToken.IsEmpty) then
        begin
          RestRequisicao.Params.AddHeader('Authorization', 'Bearer ' + FToken);
          RestRequisicao.Params.ParameterByName('Authorization').Options := [poDoNotEncode];
        end;
        RestResposta.ContentType := 'application/json';
        RestRequisicao.Execute;
        Result := RestResposta.Content;
        if not IsJSONValid(Result) then
          Result := '{"mensagem":"'+Result+'"}';
      except
        on e: exception do
        begin
          Result := '{"mensagem":"'+e.Message+'"}';
        end;
      end;
    finally
      FUltimoGet.UltimaAcaoDataHora := Now;
      FUltimoGet.UltimoStatus := RestResposta.StatusCode;
      FUltimoGet.UltimaMensagem := RestResposta.StatusText;
    end;
  finally
    RestCliente.Free;
    RestRequisicao.Free;
    RestResposta.Free;
  end;
end;

function TdmWebService.Post(AEndPoint, AParam, AToken: string; const AUserBasic: string = ''; const APassBasic: string = ''): string;
var
  JsonToSend: TJSONObject;
  vBasicAuth: THTTPBasicAuthenticator;
  RestCliente: TRESTClient;
  RestRequisicao: TRESTRequest;
  RestResposta: TRESTResponse;
begin
  JsonToSend := TJSONObject.ParseJSONValue(AParam) as TJSONObject;
  vBasicAuth := nil;
  RestCliente := nil;
  RestRequisicao := nil;
  RestResposta := nil;
  try
    RestCliente := TRESTClient.Create(FcUrl);
    RestRequisicao := TRESTRequest.Create(nil);
    RestResposta := TRESTResponse.Create(nil);
    try
      try
        RestCliente.BaseURL := FcUrl;
        RestCliente.Accept := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
        RestCliente.AcceptCharset := 'utf-8, *;q=0.8';
        RestCliente.RaiseExceptionOn500 := False;
        RestRequisicao.Params.Clear;
        RestRequisicao.Body.ClearBody;
        RestRequisicao.Client := RestCliente;
        RestRequisicao.Method := rmPOST;
        RestRequisicao.Resource := AEndPoint;
        RestRequisicao.Response := RestResposta;
        RestRequisicao.SynchronizedEvents := False;
        if not (AUserBasic.IsEmpty) then
        begin
          vBasicAuth := THTTPBasicAuthenticator.Create(AUserBasic, APassBasic);
          RestCliente.Authenticator := vBasicAuth;
        end;
        if not (FToken.IsEmpty) then
        begin
          RestRequisicao.Params.AddHeader('Authorization', 'Bearer ' + FToken);
          RestRequisicao.Params.ParameterByName('Authorization').Options := [poDoNotEncode];
        end;
        // Definir o corpo da requisição como o JSON
        RestRequisicao.AddBody(JsonToSend);
        RestResposta.ContentType := 'application/json';
        RestRequisicao.Execute;
        Result := RestResposta.Content;
        if not IsJSONValid(Result) then
          Result := '{"mensagem":"'+Result+'"}';
      except
        on e: exception do
        begin
          Result := '{"mensagem":"'+e.Message+'"}';
        end;
      end;
    finally
      JsonToSend.Free;
      if Assigned(vBasicAuth) then
      begin
        vBasicAuth.Free;
        RestCliente.Authenticator := nil;
      end;
      FUltimoPost.UltimaAcaoDataHora := Now;
      FUltimoPost.UltimoStatus := RestResposta.StatusCode;
      FUltimoPost.UltimaMensagem := RestResposta.StatusText;
    end;
  finally
    RestCliente.Free;
    RestRequisicao.Free;
    RestResposta.Free;
  end;
end;

function TdmWebService.TesteEnvioRegistrosImpressoras: string;
var
  vListaImpressoras, vRetorno: string;
  vJsonEnvio: TJSONObject;
begin
  vListaImpressoras := '['+
                          '{'+
                            '"registro": "000000000000",'+
                            '"descricao": "TESTE",'+
                            '"tipoimpressora": "TST",'+
                            '"compartilhamento": "TESTE",'+
                            '"iplocal": "127.0.0.1",'+
                            '"nometerminal": "TESTE-PC"'+
                          '}'+
                        ']';
  if vListaImpressoras.IsEmpty then
    Exit('Nenhuma impressora registrada');
  vJsonEnvio := TJSONObject.Create;
  try
    vJsonEnvio.AddPair('impressoras', TJSONObject.ParseJSONValue(vListaImpressoras) as TJSONArray);
    vRetorno := Post('registerprint', vJsonEnvio.ToJSON, FToken);
    if (FUltimoPost.UltimoStatus = 202) then
      Result :=  'ok'
    else Result := LerJson(vRetorno, 'mensagem');
  finally
    vJsonEnvio.Free;
  end;
end;

function TdmWebService.TesteRecebimentoImpressores: string;
begin
   Result := LerJson(GetImpressoes('000000000000'), 'mensagem');
end;

function TdmWebService.TesteRecebimentoRegistrosImpressoras: string;
begin
  Result := LerJson(Get('printers', FToken), 'mensagem');
end;

function TdmWebService.TesteWebservice: string;
var
  vRetorno: string;
begin
  vRetorno := Get('online', FToken);
  if FUltimoGet.UltimoStatus <> 200 then
    Result := LerJson(vRetorno, 'mensagem')
  else Result := 'online';
end;

end.

unit dmsrvGerenciamento;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, System.JSON, System.DateUtils;

type
  TsrvGerenciamento = class(TService)
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceBeforeInstall(Sender: TService);
  private
    FPortaWS: integer;
    FDescricao: string;
    procedure Start;
    procedure Stop;
    procedure RegistrarEndpoints;
    procedure CarregarConfiguracao;
    procedure SalvarConfiguracao;
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  srvGerenciamento: TsrvGerenciamento;

implementation

{$R *.dfm}

uses Horse, Horse.Jhonson, Horse.JWT, JOSE.Core.JWT, JOSE.Core.Builder, Horse.BasicAuthentication,
  udmHandle, uUtils;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  srvGerenciamento.Controller(CtrlCode);
end;

procedure TsrvGerenciamento.CarregarConfiguracao;
begin
  FDescricao := LerIni('GERAL', 'NOME_GERENCIAL', 'Serviço de gerenciamento', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  FPortaWS := StrToIntDef(LerIni('GERAL', 'PORTA_GERENCIAL', '9000', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini'), 9000);
  SalvarConfiguracao;
end;

function TsrvGerenciamento.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TsrvGerenciamento.RegistrarEndpoints;
begin
  THorse.Post('gerartokendiario',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LJWT: TJWT;
      LToken: String;
    begin
      LJWT := TJWT.Create();
      try
        // Enter the payload data
        LJWT.Claims.Expiration := EndOfTheDay(Now);

        // Generating the token
        LToken := TJOSE.SHA256CompactToken(TOKEN, LJWT);
      finally
        FreeAndNil(LJWT);
      end;

      // Sending the token
      Res.Send(LToken);
    end);

  THorse.AddCallback(HorseJWT(TOKEN)).Post('/registerprint',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      vResStatus: integer;
    begin
      GravaLog('Recebido registros de impressora', 'log');
      try
        try
          dmHandle := TdmHandle.Create(nil);
          vResStatus := dmHandle.RegisterPrinter(Req.Body<TJSONObject>.ToString);
          if (vResStatus = 201) or (vResStatus = 202) then
          begin
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', 'ok')).Status(vResStatus);
          end
          else
          if (vResStatus = 208) then
          begin
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', 'Impressoras já cadastradas')).Status(vResStatus);
          end
          else
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', dmHandle.GetErroImpressora)).Status(THTTPStatus.BadRequest);
        except
          on e: Exception do
            Res.Send(TJSONObject.Create.AddPair('mensagem', e.Message))
              .Status(THTTPStatus.InternalServerError);
        end;
      finally
        dmHandle.DisposeOf;
      end;
    end);

  THorse.AddCallback(HorseJWT(TOKEN)).Get('/printers',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      vJsonResposta: TJSONObject;
      vJsonArray: TJSONArray;
    begin
      GravaLog('Requisição de registros de impressoras', 'log');
      try
        try
          dmHandle := TdmHandle.Create(nil);
          vJsonArray := TJSONObject.ParseJSONValue(dmHandle.GetPrinters()) as TJSONArray;
          if (vJsonArray.Count > 0) then
          begin
            vJsonResposta := TJSONObject.Create;
            vJsonResposta.AddPair('mensagem', 'ok');
            vJsonResposta.AddPair('impressoras', vJsonArray);
            Res.Send(vJsonResposta).Status(THTTPStatus.OK)
          end
          else
            Res.Send(TJSONObject.Create.AddPair('mensagem',
              'Nenhuma impressora encontrada')).Status(THTTPStatus.NoContent);
        except
          on e: Exception do
            Res.Send(TJSONObject.Create.AddPair('mensagem', e.Message))
              .Status(THTTPStatus.InternalServerError);
        end;
      finally
        dmHandle.DisposeOf;
      end;
    end);

  THorse.Get('/online',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.Send(FormatDateTime('dd/mm/yyyy hh:nn:ss', now)).Status(THTTPStatus.OK);
    end);
end;

procedure TsrvGerenciamento.SalvarConfiguracao;
begin
  GravarIni('GERAL', 'NOME_GERENCIAL', FDescricao, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'PORTA_GERENCIAL', FPortaWS.ToString, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
end;

procedure TsrvGerenciamento.ServiceBeforeInstall(Sender: TService);
begin
  CarregarConfiguracao;
  Self.DisplayName := 'Serviço de impressão Up2 - '+FDescricao;
end;

procedure TsrvGerenciamento.ServiceContinue(Sender: TService;
  var Continued: Boolean);
begin
  Start;
  Continued := True;
end;

procedure TsrvGerenciamento.ServiceCreate(Sender: TObject);
begin
  THorse.Use(Jhonson());
  THorse.Use(HorseBasicAuthentication(
    function(const AUsername, APassword: string): Boolean
    begin
      Result := AUsername.Equals(USER_BASIC_AUTH) and APassword.Equals(PASSWORD_BASIC_AUTH);
    end, THorseBasicAuthenticationConfig.New.SkipRoutes(['/registerprint', '/printers', '/online'])));
  RegistrarEndpoints;
end;

procedure TsrvGerenciamento.ServiceDestroy(Sender: TObject);
begin
  Stop;
end;

procedure TsrvGerenciamento.ServicePause(Sender: TService;
  var Paused: Boolean);
begin
  Stop;
  Paused := True;
end;

procedure TsrvGerenciamento.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
  CarregarConfiguracao;
  Start;
  Started := True;
end;

procedure TsrvGerenciamento.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  Stop;
  Stopped := True;
end;

procedure TsrvGerenciamento.Start;
begin
  Self.DisplayName := FDescricao;
  THorse.Listen(FPortaWS);
  GravaLog('Serviço iniciado, ouvindo na porta: '+FPortaWS.ToString, 'log');
end;

procedure TsrvGerenciamento.Stop;
begin
  if THorse.IsRunning then
    THorse.StopListen;
  GravaLog('Serviço parado', 'log');
end;

end.

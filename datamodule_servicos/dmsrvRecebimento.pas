unit dmsrvRecebimento;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, System.JSON;

type
  TsrvRecebimento = class(TService)
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceBeforeInstall(Sender: TService);
  private
    FDescricao: string;
    FPortaWS: integer;
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
  srvRecebimento: TsrvRecebimento;

implementation

{$R *.dfm}

uses Horse, Horse.Jhonson, Horse.JWT, udmHandle, uUtils;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  srvRecebimento.Controller(CtrlCode);
end;

procedure TsrvRecebimento.CarregarConfiguracao;
begin
  FDescricao := LerIni('GERAL', 'NOME_RECEBIMENTO', 'Serviço de Recebimento', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  FPortaWS := StrToIntDef(LerIni('GERAL', 'PORTA_RECEBIMENTO', '9200', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini'), 9200);
  SalvarConfiguracao;
end;

function TsrvRecebimento.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TsrvRecebimento.RegistrarEndpoints;
begin
  THorse.AddCallback(HorseJWT(TOKEN)).Get('/prints/:registro',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      vJsonArray: TJSONArray;
      vRegistro: string;
      vJsonResposta: TJSONObject;
    begin
      vRegistro := Req.Params['registro'].Replace('*', '');
      if vRegistro.IsEmpty then
      begin
        GravaLog('Requisição de impressões sem codigo de registro informado', 'log_recebimento_');
        Res.Send(TJSONObject.Create.AddPair('mensagem',
          'Código de registro da impressora não informado'))
          .Status(THTTPStatus.BadRequest);
        Exit;
      end;

      try
        try
          dmHandle := TdmHandle.Create(nil);

          vJsonArray := TJSONObject.ParseJSONValue(dmHandle.GetPrints(vRegistro)) as TJSONArray;
          if not(vJsonArray = nil) and (vJsonArray.Count > 0) then
          begin
            vJsonResposta := TJSONObject.Create;
            vJsonResposta.AddPair('mensagem', 'ok');
            vJsonResposta.AddPair('impressoes', vJsonArray);
            if vJsonArray.Count > 0 then
              GravaLog('Requisição de impressões - '+vRegistro, 'log_recebimento_');
            Res.Send<TJSONObject>(vJsonResposta).Status(THTTPStatus.OK);
            dmHandle.LimparArquivos;
          end
          else if vRegistro = '000000000000' then
          begin
            Res.Send(TJSONObject.Create.AddPair('mensagem',
              'ok'))
              .Status(THTTPStatus.Accepted);
            Exit;
          end else
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem',
              'Nenhum arquivo de impressão encontrado')).Status(THTTPStatus.NoContent);

        except
          on e: Exception do
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', e.Message))
              .Status(THTTPStatus.InternalServerError);
        end;
      finally
        dmHandle.DisposeOf;
      end;
    end);
end;

procedure TsrvRecebimento.SalvarConfiguracao;
begin
  GravarIni('GERAL', 'NOME_RECEBIMENTO', FDescricao, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'PORTA_RECEBIMENTO', FPortaWS.ToString, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
end;

procedure TsrvRecebimento.ServiceBeforeInstall(Sender: TService);
begin
  CarregarConfiguracao;
  Self.DisplayName := 'Serviço de impressão Up2 - '+FDescricao;
end;

procedure TsrvRecebimento.ServiceContinue(Sender: TService;
  var Continued: Boolean);
begin
  Start;
  Continued := True;
end;

procedure TsrvRecebimento.ServiceCreate(Sender: TObject);
begin
  CarregarConfiguracao;
  THorse.Use(Jhonson());
  THorse.KeepConnectionAlive := True;
  RegistrarEndpoints;
end;

procedure TsrvRecebimento.ServiceDestroy(Sender: TObject);
begin
  Stop;
end;

procedure TsrvRecebimento.ServicePause(Sender: TService; var Paused: Boolean);
begin
  Stop;
  Paused := True;
end;

procedure TsrvRecebimento.ServiceStart(Sender: TService; var Started: Boolean);
begin
  CarregarConfiguracao;
  Start;
  Started := True;
end;

procedure TsrvRecebimento.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Stop;
  Stopped := True;
end;

procedure TsrvRecebimento.Start;
begin
  Self.DisplayName := FDescricao;
  THorse.Listen(FPortaWS);
  GravaLog('Serviço iniciado, ouvindo na porta: '+FPortaWS.ToString, 'log_recebimento_');
end;

procedure TsrvRecebimento.Stop;
begin
  if THorse.IsRunning then
    THorse.StopListen;
  GravaLog('Serviço parado', 'log_recebimento_');
end;

end.

unit dmsrvEnvio;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, System.JSON;

type
  TsrvEnvio = class(TService)
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceBeforeInstall(Sender: TService);
  private
    { Private declarations }
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
  srvEnvio: TsrvEnvio;

implementation

{$R *.dfm}

uses Horse, Horse.Jhonson, udmHandle, uUtils, Horse.JWT;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  srvEnvio.Controller(CtrlCode);
end;

procedure TsrvEnvio.CarregarConfiguracao;
begin
  FDescricao := LerIni('GERAL', 'NOME_ENVIO', 'Serviço de envio', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  FPortaWS := StrToIntDef(LerIni('GERAL', 'PORTA_ENVIO', '9100', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini'), 9100);
  SalvarConfiguracao;
end;

function TsrvEnvio.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TsrvEnvio.RegistrarEndpoints;
begin
  THorse.AddCallback(HorseJWT(TOKEN)).Post('/print',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      GravaLog('Recebido pedido de impressão', 'log_envio_');
      try
        try
          dmHandle := TdmHandle.Create(nil);
          if dmHandle.StoreFile(Req.Body<TJSONObject>.ToString) then
            Res.Send(TJSONObject.Create.AddPair('mensagem', 'ok'))
              .Status(THTTPStatus.Created)
          else
            Res.Send(TJSONObject.Create.AddPair('mensagem',
              dmHandle.GetErroImpressao)).Status(THTTPStatus.BadRequest);
        except
          on e: Exception do
            Res.Send(TJSONObject.Create.AddPair('mensagem', e.Message))
              .Status(THTTPStatus.InternalServerError);
        end;
      finally
        dmHandle.DisposeOf;
      end;
    end);
end;

procedure TsrvEnvio.SalvarConfiguracao;
begin
  GravarIni('GERAL', 'NOME_ENVIO', FDescricao, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'PORTA_ENVIO', FPortaWS.ToString, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
end;

procedure TsrvEnvio.ServiceBeforeInstall(Sender: TService);
begin
  CarregarConfiguracao;
  Self.DisplayName := 'Serviço de impressão Up2 - '+FDescricao;
end;

procedure TsrvEnvio.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  Start;
  Continued := True;
end;

procedure TsrvEnvio.ServiceCreate(Sender: TObject);
begin
  CarregarConfiguracao;
  THorse.Use(Jhonson());
  THorse.KeepConnectionAlive := True;
  RegistrarEndpoints;
end;

procedure TsrvEnvio.ServiceDestroy(Sender: TObject);
begin
  Stop;
end;

procedure TsrvEnvio.ServicePause(Sender: TService; var Paused: Boolean);
begin
  Stop;
  Paused := True;
end;

procedure TsrvEnvio.ServiceStart(Sender: TService; var Started: Boolean);
begin
  CarregarConfiguracao;
  Start;
  Started := True;
end;

procedure TsrvEnvio.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Stop;
  Stopped := True;
end;

procedure TsrvEnvio.Start;
begin
  Self.DisplayName := FDescricao;
  THorse.Listen(FPortaWS);
  GravaLog('Serviço iniciado, ouvindo na porta: '+FPortaWS.ToString, 'log_envio_');
end;

procedure TsrvEnvio.Stop;
begin
  if THorse.IsRunning then
    THorse.StopListen;
  GravaLog('Serviço parado', 'log_envio_');
end;

end.

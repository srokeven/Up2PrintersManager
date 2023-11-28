object srvEnvio: TsrvEnvio
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  DisplayName = 'Servi'#231'o de impress'#227'o Up2 - Envio'
  BeforeInstall = ServiceBeforeInstall
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 262
  Width = 500
end

object srvRecebimento: TsrvRecebimento
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  DisplayName = 'Servi'#231'o de impress'#227'o Up2 - Recebimento'
  BeforeInstall = ServiceBeforeInstall
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 269
  Width = 600
end

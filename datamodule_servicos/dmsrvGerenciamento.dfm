object srvGerenciamento: TsrvGerenciamento
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  DisplayName = 'Servi'#231'o de impress'#227'o Up2 - Gerenciamento'
  BeforeInstall = ServiceBeforeInstall
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 341
  Width = 618
end

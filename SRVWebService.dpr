program SRVWebService;

uses
  Vcl.SvcMgr,
  dmsrvGerenciamento in 'datamodule_servicos\dmsrvGerenciamento.pas' {srvGerenciamento: TService},
  udmHandle in 'udmHandle.pas' {dmHandle: TDataModule},
  uRegistroImpressaoController in 'controller\uRegistroImpressaoController.pas',
  uRegistroImpressoraController in 'controller\uRegistroImpressoraController.pas',
  uRegistroImpressaoModel in 'model\uRegistroImpressaoModel.pas',
  uRegistroImpressoraModel in 'model\uRegistroImpressoraModel.pas',
  uUtils in 'utils\uUtils.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TsrvGerenciamento, srvGerenciamento);
  Application.Run;
end.

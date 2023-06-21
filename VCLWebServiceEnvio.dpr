program VCLWebServiceEnvio;

uses
  Vcl.Forms,
  uVCLWebserviceEnvio in 'uVCLWebserviceEnvio.pas' {fmVCLWebServiceEnvio},
  uRegistroImpressaoModel in 'model\uRegistroImpressaoModel.pas',
  uRegistroImpressoraModel in 'model\uRegistroImpressoraModel.pas',
  uRegistroImpressaoController in 'controller\uRegistroImpressaoController.pas',
  uRegistroImpressoraController in 'controller\uRegistroImpressoraController.pas',
  Vcl.Themes,
  Vcl.Styles,
  uUtils in 'utils\uUtils.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
    ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Blue');
  Application.CreateForm(TfmVCLWebServiceEnvio, fmVCLWebServiceEnvio);
  Application.Run;
end.

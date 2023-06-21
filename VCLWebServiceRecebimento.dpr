program VCLWebServiceRecebimento;

uses
  Vcl.Forms,
  uVCLWebserviceRecebimento in 'uVCLWebserviceRecebimento.pas' {fmVCLWebServiceRecebimento},
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
  TStyleManager.TrySetStyle('Windows10 Green');
  Application.CreateForm(TfmVCLWebServiceRecebimento, fmVCLWebServiceRecebimento);
  Application.Run;
end.

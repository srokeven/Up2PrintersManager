program VCLWebService;

uses
  Vcl.Forms,
  uVCLWebserviceGerenciamento in 'uVCLWebserviceGerenciamento.pas' {fmVCLWebServiceGerenciamento},
  udmHandle in 'udmHandle.pas' {dmHandle: TDataModule},
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
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TfmVCLWebServiceGerenciamento, fmVCLWebServiceGerenciamento);
  Application.Run;
end.

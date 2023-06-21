program PrintersSuport;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {fmPrintersSuportMain},
  uCadastroImpressora in 'uCadastroImpressora.pas' {fmCadastroImpressoras},
  Vcl.Themes,
  Vcl.Styles,
  udmWebService in 'udmWebService.pas' {dmWebService: TDataModule},
  uRegistroImpressoraModel in 'model\uRegistroImpressoraModel.pas',
  uUtils in 'utils\uUtils.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
    ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Onyx Blue');
  Application.CreateForm(TfmPrintersSuportMain, fmPrintersSuportMain);
  Application.Run;
end.

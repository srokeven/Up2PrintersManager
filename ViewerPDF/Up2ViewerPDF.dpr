program Up2ViewerPDF;

uses
  Vcl.Forms,
  uViewerPDF in 'uViewerPDF.pas' {fmViewerPDF},
  uRegistroImpressoraModel in '..\model\uRegistroImpressoraModel.pas',
  udmWebService in '..\udmWebService.pas' {dmWebService: TDataModule},
  uUtils in '..\utils\uUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmViewerPDF, fmViewerPDF);
  Application.Run;
end.

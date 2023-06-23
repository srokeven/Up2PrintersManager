unit uViewerPDF;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, dxPDFDocument, dxBarBuiltInMenu, dxCustomPreview,
  dxPDFViewer, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, IniFiles, System.StrUtils,
  FileCtrl, dxPSdxPDFViewerLnk, dxPSGlbl, dxPSUtl, dxPSEngn, dxPrnPg, dxBkgnd,
  dxWrap, dxPrnDev, dxPSCompsProvider, dxPSFillPatterns, dxPSEdgePatterns,
  dxPSPDFExportCore, dxPSPDFExport, cxDrawTextUtils, dxPSPrVwStd, dxPSPrVwAdv,
  dxPSPrVwRibbon, dxPScxPageControlProducer, dxPScxEditorProducers,
  dxPScxExtEditorProducers, cxClasses, dxPSCore, System.JSON, uRegistroImpressoraModel,
  System.Generics.Collections;

type
  TfmViewerPDF = class(TForm)
    ViewerPDF: TdxPDFViewer;
    tmLooping: TTimer;
    tiIconeBandeja: TTrayIcon;
    popupOpcoes: TPopupMenu;
    popupExibir: TMenuItem;
    Panel1: TPanel;
    edDiretorio: TEdit;
    Label1: TLabel;
    tmInicializar: TTimer;
    procedure tmLoopingTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure popupExibirClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edDiretorioDblClick(Sender: TObject);
    procedure tmInicializarTimer(Sender: TObject);
  private
    FWatcherHandle: THandle;
    FComponentPrinter: TdxComponentPrinter;
    FReportLink: TdxPDFViewerReportLink;
    FRegistrosImpressoras: TObjectList<TRegistroImpressora>;
    FImpressaoComErro: boolean;
    procedure HandlePrintDeviceError(Sender: TObject; var ADone: boolean);
    procedure HideApplication;
    procedure ShowApplication;
    procedure HandleFileChange(const FileName: string);
    procedure ProcessFilesInFolder(const Folder: string);
    function SelecionaDiretorio(aDiretorioInicial, aDescricao: string): string;
    procedure CarregaImpressoras;
    function GetCompartilhamentoImpressora(ARegistro: string): string;
    function ExtrairRegistro(AFileName: string): string;
  public
    { Public declarations }
  end;

var
  fmViewerPDF: TfmViewerPDF;

implementation

{$R *.dfm}

uses udmWebService, uUtils;

function TfmViewerPDF.SelecionaDiretorio(aDiretorioInicial, aDescricao: string): string;
var
  fDir: string;
begin
  fDir := aDiretorioInicial;
  if Win32MajorVersion >= 6 then
  begin
    with TFileOpenDialog.Create(nil) do
    try
      Title := IfThen(aDescricao.IsEmpty, 'Selecione o diretório', aDescricao);
      Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem]; // YMMV
      OkButtonLabel := 'Selecionar';
      DefaultFolder := IfThen(aDiretorioInicial = EmptyStr, ExtractFileDir(ParamStr(0)), aDiretorioInicial);;
      FileName := IfThen(aDiretorioInicial = EmptyStr, ExtractFileDir(ParamStr(0)), aDiretorioInicial);;
      if Execute then
        Result := FileName;
    finally
      Free;
    end;
  end else
  if SelectDirectory('Selecione o diretório', ExtractFileDrive(FDir), FDir, [sdNewUI, sdNewFolder]) then
    Result := FDir;
end;

procedure TfmViewerPDF.edDiretorioDblClick(Sender: TObject);
begin
  edDiretorio.Text := SelecionaDiretorio('C:\', 'Selecione o diretorio de saídas dos arquivos PDF');
  GravarIni('PDF', 'DIRETORIO', edDiretorio.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
end;

function TfmViewerPDF.ExtrairRegistro(AFileName: string): string;
var
  PosInicio, PosFim: Integer;
begin
  Result := '';
  if not (AFileName.IsEmpty) then
  begin
    PosInicio := Pos('_', AFileName) + 1; // Encontra a posição do primeiro "_"
    PosFim := PosEx('_', AFileName, PosInicio); // Encontra a posição do segundo "_", a partir da posição inicial

    if (PosInicio > 0) and (PosFim > 0) then
      Result := Copy(AFileName, PosInicio, PosFim - PosInicio)
    else
      Result := '';
  end;
end;

procedure TfmViewerPDF.FormCreate(Sender: TObject);
begin
  edDiretorio.Text := LerIni('PDF', 'DIRETORIO', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  FComponentPrinter := TdxComponentPrinter.Create(Self);
  FComponentPrinter.OnPrintDeviceError := HandlePrintDeviceError;
  FReportLink := TdxPDFViewerReportLink.Create(Self);
  FRegistrosImpressoras := TObjectList<TRegistroImpressora>.Create;
  CarregaImpressoras;
  FReportLink.ComponentPrinter := FComponentPrinter;
  FReportLink.Component := ViewerPDF;
  if edDiretorio.Text = '' then
    if not DirectoryExists(IncludeTrailingPathDelimiter(GetCurrentDir) + 'output') then
      if ForceDirectories(IncludeTrailingPathDelimiter(GetCurrentDir) + 'output') then
      begin
        edDiretorio.Text := IncludeTrailingPathDelimiter(GetCurrentDir) + 'output';
        GravarIni('PDF', 'DIRETORIO', edDiretorio.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
      end;
  if edDiretorio.Text <> '' then
  begin
    FWatcherHandle := FindFirstChangeNotification(
      PChar(edDiretorio.Text),
      False,
      FILE_NOTIFY_CHANGE_FILE_NAME
    );

    if FWatcherHandle = INVALID_HANDLE_VALUE then
      RaiseLastOSError;
    tmInicializar.Enabled := True;
  end;
end;

procedure TfmViewerPDF.FormDestroy(Sender: TObject);
begin
  if FWatcherHandle <> INVALID_HANDLE_VALUE then
    FindCloseChangeNotification(FWatcherHandle);
  FReportLink.Free;
  FComponentPrinter.Free;
  FRegistrosImpressoras.Free;
end;

function TfmViewerPDF.GetCompartilhamentoImpressora(ARegistro: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FRegistrosImpressoras.Count - 1 do
  begin
    if SameText(FRegistrosImpressoras[I].Registro, ARegistro) then
      Result := FRegistrosImpressoras[I].CompartilhamentoImpressora;
  end;
end;

procedure TfmViewerPDF.HandleFileChange(const FileName: string);
var
  I, vIndexImpressora: Integer;
  vRegistro, vCompartilhamento: string;
  vImpressoraEncontrada: boolean;
begin
  vImpressoraEncontrada := False;
  vRegistro := ExtrairRegistro(ExtractFileName(FileName));
  vCompartilhamento := GetCompartilhamentoImpressora(vRegistro);
  vIndexImpressora := dxPrintDevice.Printers.IndexOf(vCompartilhamento);
  if vIndexImpressora > 0 then
  begin
    dxPrintDevice.PrinterIndex := vIndexImpressora;
    vImpressoraEncontrada := True;
  end
  else
  begin
    for I := 0 to dxPrintDevice.Printers.Count - 1 do
    begin
      if SameText(dxPrintDevice.Printers[I], vCompartilhamento) then
      begin
        vImpressoraEncontrada := True;
        dxPrintDevice.PrinterIndex := I;
      end;
    end;
  end;
  if vImpressoraEncontrada then
  begin
    FImpressaoComErro := False;
    ViewerPDF.LoadFromFile(FileName);
    try
      FReportLink.Print(False);
      ViewerPDF.Clear;
      if not (FImpressaoComErro) then
        DeleteFile(FileName);
      FImpressaoComErro := False;
    except
      on e: exception do
      begin
        GravaLog('Erro ao imprimir pdf -- '+e.Message, 'log_suporte_pdf_viewer_');
      end;
    end;
  end;
end;

procedure TfmViewerPDF.HandlePrintDeviceError(Sender: TObject; var ADone: boolean);
begin
  ADone := True;
  FImpressaoComErro := True;
  GravaLog('Não foi possivel imprimir o arquivo', 'log_suporte_pdf_viewer_');
end;

procedure TfmViewerPDF.HideApplication;
  function GetHandleOnTaskBar: THandle;
  begin
    {$IFDEF COMPILER11_UP}
    if Application.MainFormOnTaskBar and Assigned(Application.MainForm) then
      Result := Application.MainForm.Handle
    else
      {$ENDIF COMPILER11_UP}
      Result := Application.Handle;
  end;
begin
  tiIconeBandeja.Visible := True;
  Application.ShowMainForm := False;
  if Self <> nil then
    Self.Visible := False;
  Application.Minimize;
  ShowWindow(GetHandleOnTaskBar, SW_HIDE);
  Application.ProcessMessages;
  tiIconeBandeja.Hint := Self.Caption;
end;

procedure TfmViewerPDF.popupExibirClick(Sender: TObject);
begin
  ShowApplication;
end;

procedure TfmViewerPDF.ShowApplication;
  function GetHandleOnTaskBar: THandle;
  begin
    {$IFDEF COMPILER11_UP}
    if Application.MainFormOnTaskBar and Assigned(Application.MainForm) then
      Result := Application.MainForm.Handle
    else
      {$ENDIF COMPILER11_UP}
      Result := Application.Handle;
  end;
begin
  tiIconeBandeja.Visible := False;
  Application.ShowMainForm := True;
  if Self <> nil then
  begin
    Self.Visible     := True;
    Self.WindowState := WsNormal;
  end;
  ShowWindow(GetHandleOnTaskBar, SW_SHOW);
  Application.ProcessMessages;
end;

procedure TfmViewerPDF.tmInicializarTimer(Sender: TObject);
begin
  tmInicializar.Enabled := False;
  HideApplication;
  ViewerPDF.Clear;
  ProcessFilesInFolder(edDiretorio.Text);
  tmLooping.Enabled := True;
end;

procedure TfmViewerPDF.tmLoopingTimer(Sender: TObject);
begin
  try
    tmLooping.Enabled := False;
    if edDiretorio.Text <> '' then
      if DirectoryExists(edDiretorio.Text) then
      begin
        try
          if WaitForSingleObject(FWatcherHandle, 0) = WAIT_OBJECT_0 then
          begin
            ProcessFilesInFolder(edDiretorio.Text);
            // Chamada da função para manipular o arquivo encontrado
            // Você pode substituir 'C:\PastaMonitorada\arquivo.pdf' pelo caminho do arquivo encontrado
            // ou percorrer todos os arquivos da pasta usando um laço e chamar a função para cada arquivo
            // encontrado.

            if not FindNextChangeNotification(FWatcherHandle) then
              RaiseLastOSError;
          end;
        except
          on e : exception do
            ShowMessage(e.message);
        end;
      end;
  finally
    tmLooping.Enabled := True;
  end;
end;

procedure TfmViewerPDF.ProcessFilesInFolder(const Folder: string);
var
  SearchRec: TSearchRec;
  FilePath: string;
begin
  FilePath := IncludeTrailingPathDelimiter(Folder);
  if FindFirst(FilePath + '*.*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          if (SearchRec.Attr and faDirectory) = faDirectory then
          begin
            // Ignorar pastas
          end
          else
          begin
            if SameText(ExtractFileExt(SearchRec.Name), '.pdf') then
            begin
              HandleFileChange(FilePath + SearchRec.Name);
            end;
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

procedure TfmViewerPDF.CarregaImpressoras;
var
  vNovoRegistro: TRegistroImpressora;
  vListaImpressoras: string;
  vJsonArray: TJSONArray;
  I: Integer;
begin
  FRegistrosImpressoras.Clear;
  vListaImpressoras := dmWebService.CarregarRegistrosImpressoras;
  if not (vListaImpressoras.Isempty) then
  begin
    vJsonArray := TJSONObject.ParseJSONValue(vListaImpressoras) as TJSONArray;
    try
      for I := 0 to vJsonArray.Count - 1 do
      begin
        vNovoRegistro := TRegistroImpressora.Create;
        vNovoRegistro.Registro := LerJson(vJsonArray.Items[I].ToJSON, 'registro');
        vNovoRegistro.Descricao := LerJson(vJsonArray.Items[I].ToJSON, 'descricao');
        vNovoRegistro.TipoImpressora := LerJson(vJsonArray.Items[I].ToJSON, 'tipoimpressora');
        vNovoRegistro.CompartilhamentoImpressora := LerJson(vJsonArray.Items[I].ToJSON, 'compartilhamento');
        vNovoRegistro.IpLocal := LerJson(vJsonArray.Items[I].ToJSON, 'iplocal');
        vNovoRegistro.NomeTerminal := LerJson(vJsonArray.Items[I].ToJSON, 'nometerminal');
        FRegistrosImpressoras.Add(vNovoRegistro);
      end;
    finally
      vJsonArray.Free;
    end;
  end;
end;

end.

unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, uRegistroImpressoraModel,
  System.Generics.Collections, System.JSON, Vcl.ExtCtrls, Vcl.Menus, ShellApi,
  IniFiles, System.Win.Registry, Tlhelp32, System.Threading, System.DateUtils;

type
  TStatus = (stsOnline, stsOffline);
  TfmPrintersSuportMain = class(TForm)
    bbStart: TButton;
    bbStop: TButton;
    grFilaImpressao: TDBGrid;
    bbAddImpressora: TButton;
    bbRemoverImpressao: TButton;
    gbDadosServico: TGroupBox;
    edIpServidor: TEdit;
    Label1: TLabel;
    edPortaServicoGerenciamento: TEdit;
    Label2: TLabel;
    Label5: TLabel;
    fmtFilaImpressao: TFDMemTable;
    dsFilaImpressao: TDataSource;
    fmtFilaImpressaoORDEM: TIntegerField;
    fmtFilaImpressaoDESCRICAO: TStringField;
    fmtFilaImpressaoTIPO_ARQUIVO: TStringField;
    fmtFilaImpressaoRELATORIO_ENCODED: TMemoField;
    Label6: TLabel;
    lbStatus: TLabel;
    Label8: TLabel;
    lbQuantidade: TLabel;
    fmtFilaImpressaoREGISTRO: TStringField;
    edPortaServicoRecebimento: TEdit;
    Label4: TLabel;
    edPortaServicoEnvio: TEdit;
    Label3: TLabel;
    tiIconeBandeja: TTrayIcon;
    PopupApp: TPopupMenu;
    popupIniciar: TMenuItem;
    popupParar: TMenuItem;
    popupRestaurar: TMenuItem;
    lbLog: TLabel;
    pnlBackground: TPanel;
    cbTestes: TComboBox;
    bbExecutarTeste: TButton;
    tmLooping: TTimer;
    tmInicializar: TTimer;
    procedure bbAddImpressoraClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bbStartClick(Sender: TObject);
    procedure bbStopClick(Sender: TObject);
    procedure popupIniciarClick(Sender: TObject);
    procedure popupPararClick(Sender: TObject);
    procedure popupRestaurarClick(Sender: TObject);
    procedure lbLogClick(Sender: TObject);
    procedure dsFilaImpressaoDataChange(Sender: TObject; Field: TField);
    procedure bbExecutarTesteClick(Sender: TObject);
    procedure bbRemoverImpressaoClick(Sender: TObject);
    procedure tmLoopingTimer(Sender: TObject);
    procedure tmInicializarTimer(Sender: TObject);
  private
    FRegistrosImpressoras: TObjectList<TRegistroImpressora>;
    FTarefa: ITask;
    FDataExpiracaoToken: TDateTime;
    procedure CarregaImpressoras;
    procedure SetStatus(AStatus: TStatus);
    procedure GerarFilaImpressao;
    procedure ExecutaFila;
    function GetCaminhoImpressoraTXT(ARegistro: string): string;
    procedure HideApplication;
    procedure ShowApplication;
    procedure VerificarImpressaoPDF;
    function processExists(exeFileName: string): Boolean;
    function GetToken: string;
  public
    { Public declarations }
  end;

var
  fmPrintersSuportMain: TfmPrintersSuportMain;

implementation

{$R *.dfm}

uses uCadastroImpressora, udmWebService, uUtils;

procedure TfmPrintersSuportMain.bbAddImpressoraClick(Sender: TObject);
begin
  fmCadastroImpressoras := TfmCadastroImpressoras.Create(Self);
  try
    fmCadastroImpressoras.ShowModal;
  finally
    fmCadastroImpressoras.Free;
  end;
end;

procedure TfmPrintersSuportMain.bbExecutarTesteClick(Sender: TObject);
begin
  case cbTestes.ItemIndex of
    0: begin
      dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoGerenciamento.Text;
      ShowMessage(dmWebService.TesteWebservice);
    end;
    1: begin
      dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoGerenciamento.Text;
      ShowMessage(dmWebService.TesteEnvioRegistrosImpressoras);
    end;
    2: begin
      dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoGerenciamento.Text;
      ShowMessage(dmWebService.TesteRecebimentoRegistrosImpressoras);
    end;
    3: begin
      dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoEnvio.Text;
      ShowMessage(dmWebService.TesteEnviarImpressao);
    end;
    4: begin
      dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoRecebimento.Text;
      ShowMessage(dmWebService.TesteRecebimentoImpressores);
    end;
    5: begin
      GerarFilaImpressao;
    end;
    6: begin
      ExecutaFila;
    end;
    7: begin
      if not (GetToken.IsEmpty) then
        ShowMessage('Token gerado');
    end;
  end;
end;

procedure TfmPrintersSuportMain.bbRemoverImpressaoClick(Sender: TObject);
begin
  fmtFilaImpressao.EmptyDataSet;
end;

procedure TfmPrintersSuportMain.bbStartClick(Sender: TObject);
var
  vTesteInicial, vEnvioImpressoras: string;
begin
  if edIpServidor.Text = EmptyStr then
  begin
    ShowMessage('Informe o ip do servidor');
    edIpServidor.SetFocus;
    exit;
  end;
  if edPortaServicoGerenciamento.Text = EmptyStr then
  begin
    ShowMessage('Informe a porta de serviço "Gerenciamento"');
    edPortaServicoGerenciamento.SetFocus;
    exit;
  end;
  if edPortaServicoRecebimento.Text = EmptyStr then
  begin
    ShowMessage('Informe a porta de serviço "Recebimento"');
    edPortaServicoRecebimento.SetFocus;
    exit;
  end;
  if edPortaServicoEnvio.Text = EmptyStr then
  begin
    ShowMessage('Informe a porta de serviço "Envio"');
    edPortaServicoEnvio.SetFocus;
    exit;
  end;
  dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoGerenciamento.Text;
  vTesteInicial := dmWebService.TesteWebservice;
  if not (vTesteInicial = 'online') then
  begin
    ShowMessage('O servidor de gerenciamento não está acessivel'+sLineBreak+'Mensagem original: '+vTesteInicial);
    exit;
  end;
  if GetToken.IsEmpty then
  begin
    ShowMessage('Nenhum token encontrado');
    Exit;
  end;
  CarregaImpressoras;
  vEnvioImpressoras := dmWebService.EnviarRegistrosImpressoras;
  if vEnvioImpressoras <> 'ok' then
  begin
    ShowMessage('O servidor de gerenciamento não está acessivel'+sLineBreak+'Mensagem original: '+vEnvioImpressoras);
    exit;
  end;
  SetStatus(stsOnline);
  GravarIni('GERAL', 'SERVIDOR', edIpServidor.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'SERVIDOR_PORTA_GERENCIAL', edPortaServicoGerenciamento.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'SERVIDOR_PORTA_ENVIO', edPortaServicoEnvio.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'SERVIDOR_PORTA_RECEBIMENTO', edPortaServicoRecebimento.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  {$IFDEF DEBUG}
  {$ELSE}
    HideApplication;
  {$ENDIF}
  tmLooping.Enabled := True;
end;

procedure TfmPrintersSuportMain.bbStopClick(Sender: TObject);
begin
  tmLooping.Enabled := False;
  case FTarefa.Status of
    TTaskStatus.Running: begin
      FTarefa.Cancel;
      tmLooping.Enabled := False;
      Sleep(1000);
    end;
    else begin
      tmLooping.Enabled := False;
      Sleep(1000);
    end;
  end;
  SetStatus(stsOffline);
end;

procedure TfmPrintersSuportMain.CarregaImpressoras;
var
  vNovoRegistro: TRegistroImpressora;
  vListaImpressoras: string;
  vJsonArray: TJSONArray;
  I: Integer;
  vExisteImpressoraDriver: boolean;
begin
  vExisteImpressoraDriver := False;
  FRegistrosImpressoras.Clear;
  vListaImpressoras := dmWebService.CarregarRegistrosImpressoras;
  vJsonArray := TJSONObject.ParseJSONValue(vListaImpressoras) as TJSONArray;
  if not (vJsonArray = nil) then
  begin
    try
      for I := 0 to vJsonArray.Count - 1 do
      begin
        vNovoRegistro := TRegistroImpressora.Create;
        vNovoRegistro.Registro := LerJson(vJsonArray.Items[I].ToJSON, 'registro');
        vNovoRegistro.Descricao :=  LerJson(vJsonArray.Items[I].ToJSON, 'descricao');
        vNovoRegistro.TipoImpressora := LerJson(vJsonArray.Items[I].ToJSON, 'tipoimpressora');
        if vNovoRegistro.TipoImpressora = 'PDF' then
          vExisteImpressoraDriver := True;
        vNovoRegistro.CompartilhamentoImpressora := LerJson(vJsonArray.Items[I].ToJSON, 'compartilhamento');
        vNovoRegistro.IpLocal := LerJson(vJsonArray.Items[I].ToJSON, 'iplocal');
        vNovoRegistro.NomeTerminal := LerJson(vJsonArray.Items[I].ToJSON, 'nometerminal');
        FRegistrosImpressoras.Add(vNovoRegistro);
      end;
    finally
      vJsonArray.Free;
    end;
  end;
  lbQuantidade.Caption := FRegistrosImpressoras.Count.ToString;
  if vExisteImpressoraDriver then
    VerificarImpressaoPDF;
end;

procedure TfmPrintersSuportMain.dsFilaImpressaoDataChange(Sender: TObject;
  Field: TField);
begin
  ShowScrollBar(grFilaImpressao.handle, SB_VERT, False);
end;

procedure TfmPrintersSuportMain.ExecutaFila;
begin
  if fmtFilaImpressao.IsEmpty then
    Exit;
  fmtFilaImpressao.First;
  if fmtFilaImpressaoTIPO_ARQUIVO.AsString.ToUpper = 'TXT' then
  begin
    if dmWebService.ImprimirTXT(GetCaminhoImpressoraTXT(fmtFilaImpressaoREGISTRO.AsString), fmtFilaImpressaoRELATORIO_ENCODED.AsWideString) then
      fmtFilaImpressao.Delete;
  end
  else if fmtFilaImpressaoTIPO_ARQUIVO.AsString.ToUpper = 'PDF' then
    if dmWebService.ImprimirPDF(fmtFilaImpressaoREGISTRO.AsString, fmtFilaImpressaoRELATORIO_ENCODED.AsWideString) then
      fmtFilaImpressao.Delete;
end;

procedure TfmPrintersSuportMain.FormCreate(Sender: TObject);
begin
  FDataExpiracaoToken := 0;
  dmWebService := TdmWebService.Create(nil);
  FRegistrosImpressoras := TObjectList<TRegistroImpressora>.Create;
  SetStatus(stsOffline);
  edIpServidor.Text := LerIni('GERAL', 'SERVIDOR', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  edPortaServicoGerenciamento.Text := LerIni('GERAL', 'SERVIDOR_PORTA_GERENCIAL', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  edPortaServicoEnvio.Text := LerIni('GERAL', 'SERVIDOR_PORTA_ENVIO', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  edPortaServicoRecebimento.Text := LerIni('GERAL', 'SERVIDOR_PORTA_RECEBIMENTO', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  FTarefa := TTask.Create(
      procedure
      begin
        GerarFilaImpressao;
        FTarefa.CheckCanceled;
        ExecutaFila;
      end);
  {$IFDEF DEBUG}
  {$ELSE}
    tmInicializar.Enabled := True;
  {$ENDIF}
end;

procedure TfmPrintersSuportMain.FormDestroy(Sender: TObject);
begin
  dmWebService.Free;
  FRegistrosImpressoras.Free;
end;

procedure TfmPrintersSuportMain.GerarFilaImpressao;
var
  I, O: Integer;
  vJson: string;
  vArrayImpressoes: TJSONArray;
  vArrayImpressoesString: string;
begin
  if FRegistrosImpressoras.Count > 0 then
  begin
    if FDataExpiracaoToken < Now then
      if GetToken.IsEmpty then
      begin
        GravaLog('Nenhum token encontrado', 'terminal');
        Exit;
      end;
    for I := 0 to FRegistrosImpressoras.Count -1 do
    begin
      FTarefa.CheckCanceled;
      vJson := '';
      dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoRecebimento.Text;
      vJson := dmWebService.GetImpressoes(FRegistrosImpressoras[I].Registro);
      if not (vJson.IsEmpty) then
      begin
        if LerJson(vJson, 'mensagem') = 'ok' then
        begin
          vArrayImpressoes := TJSONObject.ParseJSONValue(LerJsonArray(vJson, 'impressoes')) as TJSONArray;
          try
            for O := 0 to vArrayImpressoes.Count - 1 do
            begin
              FTarefa.CheckCanceled;
              fmtFilaImpressao.Append;
              fmtFilaImpressaoORDEM.AsInteger := O;
              fmtFilaImpressaoDESCRICAO.AsString := LerJson(vArrayImpressoes.Items[O].ToJSON, 'descricao');
              fmtFilaImpressaoREGISTRO.AsString := LerJson(vArrayImpressoes.Items[O].ToJSON, 'registroimpressora');
              fmtFilaImpressaoTIPO_ARQUIVO.AsString := LerJson(vArrayImpressoes.Items[O].ToJSON, 'tipoarquivo');
              fmtFilaImpressaoRELATORIO_ENCODED.AsString := LerJson(vArrayImpressoes.Items[O].ToJSON, 'relatorioencoded');
              fmtFilaImpressao.Post;
            end;
          finally
            vArrayImpressoes.Free;
          end;
        end;
      end;
    end;
  end;
end;

function TfmPrintersSuportMain.GetCaminhoImpressoraTXT(
  ARegistro: string): string;
var
  I: integer;
begin
  for I := 0 to FRegistrosImpressoras.Count -1 do
  begin
    if FRegistrosImpressoras[I].Registro = ARegistro then
      Result := FRegistrosImpressoras[I].CompartilhamentoImpressora;
  end;
end;

function TfmPrintersSuportMain.GetToken: string;
begin
  dmWebService.cUrl := 'http://'+edIpServidor.Text + ':' +edPortaServicoGerenciamento.Text;
  Result := dmWebService.GetTokenAPi;
  if not (Result.IsEmpty) then
    FDataExpiracaoToken := EndOfTheDay(Now);
end;

procedure TfmPrintersSuportMain.SetStatus(AStatus: TStatus);
begin
  bbStart.Enabled := AStatus = stsOffline;
  bbStop.Enabled := AStatus = stsOnline;
  popupIniciar.Enabled := AStatus = stsOffline;
  popupParar.Enabled := AStatus = stsOnline;

  edIpServidor.Enabled := AStatus = stsOffline;
  edPortaServicoGerenciamento.Enabled := AStatus = stsOffline;
  edPortaServicoEnvio.Enabled := AStatus = stsOffline;
  edPortaServicoRecebimento.Enabled := AStatus = stsOffline;

  bbAddImpressora.Enabled := AStatus = stsOffline;
  bbExecutarTeste.Enabled := AStatus = stsOffline;

  case AStatus of
    stsOnline: lbStatus.Caption := 'Em execução';
    stsOffline: lbStatus.Caption := 'Parado';
  end;
end;

procedure TfmPrintersSuportMain.popupIniciarClick(Sender: TObject);
begin
  if bbStart.Enabled then
    bbStart.Click;
end;

procedure TfmPrintersSuportMain.popupPararClick(Sender: TObject);
begin
  if bbStop.Enabled then
    bbStop.Click;
end;

procedure TfmPrintersSuportMain.popupRestaurarClick(Sender: TObject);
begin
  ShowApplication;
end;

procedure TfmPrintersSuportMain.HideApplication;
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

procedure TfmPrintersSuportMain.lbLogClick(Sender: TObject);
begin
  var vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'logs';
  if FileExists(IncludeTrailingPathDelimiter(vDiretorio)+'log_suporte_'+FormatDateTime('ddMMyyyy',Date)+'.txt') then
       ShellExecute(0,
          'open',
          PChar('explorer.exe'),
          PChar('/n, /select,'+IncludeTrailingPathDelimiter(vDiretorio)+'log_suporte_'+FormatDateTime('ddMMyyyy',Date)+'.txt'),
          nil,  // Se nao funcionar, precisa por o caminho do Windows no parâmetro Directory >> PChar('C:\WINDOWS\'),
          SW_SHOWMAXIMIZED);
end;

procedure TfmPrintersSuportMain.ShowApplication;
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

procedure TfmPrintersSuportMain.tmInicializarTimer(Sender: TObject);
begin
  tmInicializar.Enabled := false;
  if not (edIpServidor.Text = EmptyStr) then
    bbStart.Click;
end;

procedure TfmPrintersSuportMain.tmLoopingTimer(Sender: TObject);
begin
  tmLooping.Enabled := False;
  if FTarefa.Status = TTaskStatus.Completed then
  begin
    FTarefa := TTask.Create(
      procedure
      begin
        TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          GerarFilaImpressao;
        end);
        TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          ExecutaFila;
        end);
      end);
  end;
  if (FTarefa.Status = TTaskStatus.WaitingToRun) or (FTarefa.Status = TTaskStatus.Created) then
    FTarefa.Start;
  tmLooping.Enabled := True;
end;

procedure TfmPrintersSuportMain.VerificarImpressaoPDF;
var
  vDirExeAssistente, vDirRaiz, vOutputDirectory: string;
begin
  vDirRaiz := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  vDirExeAssistente := vDirRaiz + 'Up2ViewerPDF.exe';
  if not (FileExists(vDirExeAssistente)) then
  begin
    ShowMessage('Assistente de impressão PDF não se encontra na pasta raiz do executável'+sLineBreak+
    'Diretório: "'+vDirRaiz+'"');
  end
  else
  begin
    vOutputDirectory := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'output';
    if not (DirectoryExists(vOutputDirectory)) then
      ForceDirectories(vOutputDirectory);
  end;
  if not (processExists('Up2ViewerPDF.exe')) then
    ShellExecute(handle,'open',PChar(vDirExeAssistente), '','',SW_SHOWNORMAL);
end;

function TfmPrintersSuportMain.processExists(exeFileName: string): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  vCount: integer;
begin
  vCount := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      Inc(vCount);
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
  if vCount > 0 then
    Result := True;
end;

end.

unit uVCLWebserviceRecebimento;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON, IniFiles, ShellApi,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.Menus;

type
  TfmVCLWebServiceRecebimento = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    edDescricao: TEdit;
    edPorta: TEdit;
    bbIniciar: TButton;
    bbParar: TButton;
    Label3: TLabel;
    imgIcon: TImage;
    tiIconeBandeja: TTrayIcon;
    PopupApp: TPopupMenu;
    popupIniciar: TMenuItem;
    popupParar: TMenuItem;
    popupRestaurar: TMenuItem;
    tmInicializar: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure bbIniciarClick(Sender: TObject);
    procedure bbPararClick(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure popupIniciarClick(Sender: TObject);
    procedure popupPararClick(Sender: TObject);
    procedure popupRestaurarClick(Sender: TObject);
    procedure tmInicializarTimer(Sender: TObject);
  private
    procedure Status;
    procedure Start;
    procedure Stop;
    procedure HideApplication;
    procedure ShowApplication;
  public
    { Public declarations }
  end;

var
  fmVCLWebServiceRecebimento: TfmVCLWebServiceRecebimento;

implementation

uses Horse, Horse.Jhonson, udmHandle, uUtils, Horse.JWT;

{$R *.dfm}

{ TfmVCLWebServiceRecebimento }

procedure TfmVCLWebServiceRecebimento.bbIniciarClick(Sender: TObject);
begin
  GravarIni('GERAL', 'NOME_RECEBIMENTO', edDescricao.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'PORTA_RECEBIMENTO', edPorta.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  Start;
  Status;
  {$IFDEF DEBUG}
  {$ELSE}
    HideApplication;
  {$ENDIF}
end;

procedure TfmVCLWebServiceRecebimento.bbPararClick(Sender: TObject);
begin
  Stop;
  Status;
end;

procedure TfmVCLWebServiceRecebimento.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if THorse.IsRunning then
    Stop;
end;

procedure TfmVCLWebServiceRecebimento.FormCreate(Sender: TObject);
begin
  edDescricao.Text := LerIni('GERAL', 'NOME_RECEBIMENTO', 'Serviço de envio', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  edPorta.Text := LerIni('GERAL', 'PORTA_RECEBIMENTO', '9200', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  try
    THorse.Use(Jhonson());
    THorse.KeepConnectionAlive := True;

    THorse.AddCallback(HorseJWT(TOKEN)).Get('/prints/:registro',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      vJsonArray: TJSONArray;
      vRegistro: string;
      vJsonResposta: TJSONObject;
    begin
      vRegistro := Req.Params['registro'].Replace('*', '');
      if vRegistro.IsEmpty then
      begin
        GravaLog('Requisição de impressões sem codigo de registro informado', 'log_recebimento_');
        Res.Send(TJSONObject.Create.AddPair('mensagem',
          'Código de registro da impressora não informado'))
          .Status(THTTPStatus.BadRequest);
        Exit;
      end;

      try
        try
          dmHandle := TdmHandle.Create(nil);

          vJsonArray := TJSONObject.ParseJSONValue(dmHandle.GetPrints(vRegistro)) as TJSONArray;
          if not(vJsonArray = nil) then
          begin
            vJsonResposta := TJSONObject.Create;
            vJsonResposta.AddPair('mensagem', 'ok');
            vJsonResposta.AddPair('impressoes', vJsonArray);
            if vJsonArray.Count > 0 then
              GravaLog('Requisição de impressões - '+vRegistro, 'log_recebimento_');
            Res.Send<TJSONObject>(vJsonResposta).Status(THTTPStatus.OK);
            dmHandle.LimparArquivos;
          end
          else if vRegistro = '000000000000' then
          begin
            Res.Send(TJSONObject.Create.AddPair('mensagem',
              'ok'))
              .Status(THTTPStatus.Accepted);
            Exit;
          end else
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem',
              'Nenhum arquivo de impressão encontrado')).Status(THTTPStatus.NotFound);

        except
          on e: Exception do
            Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', e.Message))
              .Status(THTTPStatus.InternalServerError);
        end;
      finally
        dmHandle.DisposeOf;
      end;
    end);
    tmInicializar.Enabled := True;
  except
    on e: Exception do
      GravaLog(e.ClassName+ ': '+ e.Message, 'log_recebimento_');
  end;
end;

procedure TfmVCLWebServiceRecebimento.HideApplication;
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

procedure TfmVCLWebServiceRecebimento.Label3Click(Sender: TObject);
begin
  var vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'logs';
  if FileExists(IncludeTrailingPathDelimiter(vDiretorio)+'log_recebimento_'+FormatDateTime('ddMMyyyy',Date)+'.txt') then
       ShellExecute(0,
          'open',
          PChar('explorer.exe'),
          PChar('/n, /select,'+IncludeTrailingPathDelimiter(vDiretorio)+'log_recebimento_'+FormatDateTime('ddMMyyyy',Date)+'.txt'),
          nil,  // Se nao funcionar, precisa por o caminho do Windows no parâmetro Directory >> PChar('C:\WINDOWS\'),
          SW_SHOWMAXIMIZED);
end;

procedure TfmVCLWebServiceRecebimento.popupIniciarClick(Sender: TObject);
begin
  if bbIniciar.Enabled then
  begin
    Start;
    Status;
  end;
end;

procedure TfmVCLWebServiceRecebimento.popupPararClick(Sender: TObject);
begin
  if bbParar.Enabled then
    bbParar.Click;
end;

procedure TfmVCLWebServiceRecebimento.popupRestaurarClick(Sender: TObject);
begin
  ShowApplication;
end;

procedure TfmVCLWebServiceRecebimento.ShowApplication;
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

procedure TfmVCLWebServiceRecebimento.Start;
begin
  // Need to set "HORSE_VCL" compilation directive
  THorse.Listen(StrToInt(edPorta.Text));
  GravaLog('Serviço iniciado', 'log_recebimento_');
end;

procedure TfmVCLWebServiceRecebimento.Status;
begin
  bbParar.Enabled := THorse.IsRunning;
  bbIniciar.Enabled := not THorse.IsRunning;
  edPorta.Enabled := not THorse.IsRunning;
  edDescricao.Enabled := not THorse.IsRunning;
  popupIniciar.Enabled := not THorse.IsRunning;
  popupParar.Enabled := THorse.IsRunning;
end;

procedure TfmVCLWebServiceRecebimento.Stop;
begin
  THorse.StopListen;
  GravaLog('Serviço parado', 'log_recebimento_');
end;

procedure TfmVCLWebServiceRecebimento.tmInicializarTimer(Sender: TObject);
begin
  tmInicializar.Enabled := false;
  bbIniciar.Click;
end;

end.

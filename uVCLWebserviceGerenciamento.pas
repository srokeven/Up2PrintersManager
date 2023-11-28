unit uVCLWebserviceGerenciamento;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON, IniFiles, ShellApi,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.Menus, System.DateUtils;

type
  TfmVCLWebServiceGerenciamento = class(TForm)
    Label1: TLabel;
    edDescricao: TEdit;
    Label2: TLabel;
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
  fmVCLWebServiceGerenciamento: TfmVCLWebServiceGerenciamento;

implementation

uses Horse, Horse.Jhonson, Horse.JWT, JOSE.Core.JWT, JOSE.Core.Builder, Horse.BasicAuthentication,
  udmHandle, uUtils;

{$R *.dfm}

procedure TfmVCLWebServiceGerenciamento.bbIniciarClick(Sender: TObject);
begin
  GravarIni('GERAL', 'NOME_GERENCIAL', edDescricao.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'PORTA_GERENCIAL', edPorta.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  Start;
  Status;
  {$IFDEF DEBUG}
  {$ELSE}
    HideApplication;
  {$ENDIF}
end;

procedure TfmVCLWebServiceGerenciamento.bbPararClick(Sender: TObject);
begin
  Stop;
  Status;
end;

procedure TfmVCLWebServiceGerenciamento.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if THorse.IsRunning then
    Stop;
end;

procedure TfmVCLWebServiceGerenciamento.FormCreate(Sender: TObject);
begin
  edDescricao.Text := LerIni('GERAL', 'NOME_GERENCIAL', 'Serviço de gerenciamento', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  edPorta.Text := LerIni('GERAL', 'PORTA_GERENCIAL', '9000', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  try
    THorse.Use(Jhonson());
    THorse.Use(HorseBasicAuthentication(
    function(const AUsername, APassword: string): Boolean
    begin
      Result := AUsername.Equals(USER_BASIC_AUTH) and APassword.Equals(PASSWORD_BASIC_AUTH);
    end, THorseBasicAuthenticationConfig.New.SkipRoutes(['/registerprint', '/printers', '/online'])));

    THorse.KeepConnectionAlive := True;

    THorse.Post('gerartokendiario',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      var
        LJWT: TJWT;
        LToken: String;
      begin
        LJWT := TJWT.Create();
        try
          // Enter the payload data
          LJWT.Claims.Expiration := EndOfTheDay(Now);

          // Generating the token
          LToken := TJOSE.SHA256CompactToken(TOKEN, LJWT);
        finally
          FreeAndNil(LJWT);
        end;

        // Sending the token
        Res.Send(LToken);
      end);

    THorse.AddCallback(HorseJWT(TOKEN)).Post('/registerprint',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        vResStatus: integer;
      begin
        GravaLog('Recebido registros de impressora', 'log');
        try
          try
            dmHandle := TdmHandle.Create(nil);
            vResStatus := dmHandle.RegisterPrinter(Req.Body<TJSONObject>.ToString);
            if (vResStatus = 201) or (vResStatus = 202) then
            begin
              Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', 'ok')).Status(vResStatus);
            end
            else
            if (vResStatus = 208) then
            begin
              Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', 'Impressoras já cadastradas')).Status(vResStatus);
            end
            else
              Res.Send<TJSONObject>(TJSONObject.Create.AddPair('mensagem', dmHandle.GetErroImpressora)).Status(THTTPStatus.BadRequest);
          except
            on e: Exception do
              Res.Send(TJSONObject.Create.AddPair('mensagem', e.Message))
                .Status(THTTPStatus.InternalServerError);
          end;
        finally
          dmHandle.DisposeOf;
        end;
      end);

    THorse.AddCallback(HorseJWT(TOKEN)).Get('/printers',
      procedure(Req: THorseRequest; Res: THorseResponse)
      var
        vJsonResposta: TJSONObject;
        vJsonArray: TJSONArray;
      begin
        GravaLog('Requisição de registros de impressoras', 'log');
        try
          try
            dmHandle := TdmHandle.Create(nil);
            vJsonArray := TJSONObject.ParseJSONValue(dmHandle.GetPrinters()) as TJSONArray;
            if (vJsonArray.Count > 0) then
            begin
              vJsonResposta := TJSONObject.Create;
              vJsonResposta.AddPair('mensagem', 'ok');
              vJsonResposta.AddPair('impressoras', vJsonArray);
              Res.Send(vJsonResposta).Status(THTTPStatus.OK)
            end
            else
              Res.Send(TJSONObject.Create.AddPair('mensagem',
                'Nenhuma impressora encontrada')).Status(THTTPStatus.NoContent);
          except
            on e: Exception do
              Res.Send(TJSONObject.Create.AddPair('mensagem', e.Message))
                .Status(THTTPStatus.InternalServerError);
          end;
        finally
          dmHandle.DisposeOf;
        end;
      end);

    THorse.Get('/online',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        Res.Send(FormatDateTime('dd/mm/yyyy hh:nn:ss', now)).Status(THTTPStatus.OK);
      end);
    tmInicializar.Enabled := True;
  except
    on e: Exception do
      GravaLog(e.ClassName+ ': '+ e.Message, 'log');
  end;
end;

procedure TfmVCLWebServiceGerenciamento.HideApplication;
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

procedure TfmVCLWebServiceGerenciamento.Label3Click(Sender: TObject);
begin
  var vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'logs';
  if FileExists(IncludeTrailingPathDelimiter(vDiretorio)+'log'+FormatDateTime('ddMMyyyy',Date)+'.txt') then
       ShellExecute(0,
          'open',
          PChar('explorer.exe'),
          PChar('/n, /select,'+IncludeTrailingPathDelimiter(vDiretorio)+'log'+FormatDateTime('ddMMyyyy',Date)+'.txt'),
          nil,  // Se nao funcionar, precisa por o caminho do Windows no parâmetro Directory >> PChar('C:\WINDOWS\'),
          SW_SHOWMAXIMIZED);
end;

procedure TfmVCLWebServiceGerenciamento.popupIniciarClick(Sender: TObject);
begin
  if bbIniciar.Enabled then
  begin
    Start;
    Status;
  end;
end;

procedure TfmVCLWebServiceGerenciamento.popupPararClick(Sender: TObject);
begin
  if bbParar.Enabled then
    bbParar.Click;
end;

procedure TfmVCLWebServiceGerenciamento.popupRestaurarClick(Sender: TObject);
begin
  ShowApplication;
end;

procedure TfmVCLWebServiceGerenciamento.ShowApplication;
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

procedure TfmVCLWebServiceGerenciamento.Start;
begin
  // Need to set "HORSE_VCL" compilation directive
  THorse.Listen(StrToInt(edPorta.Text));
  GravaLog('Serviço iniciado', 'log');
end;

procedure TfmVCLWebServiceGerenciamento.Status;
begin
  bbParar.Enabled := THorse.IsRunning;
  bbIniciar.Enabled := not THorse.IsRunning;
  edPorta.Enabled := not THorse.IsRunning;
  edDescricao.Enabled := not THorse.IsRunning;
  popupIniciar.Enabled := not THorse.IsRunning;
  popupParar.Enabled := THorse.IsRunning;
end;

procedure TfmVCLWebServiceGerenciamento.Stop;
begin
  THorse.StopListen;
  GravaLog('Serviço parado', 'log');
end;

procedure TfmVCLWebServiceGerenciamento.tmInicializarTimer(Sender: TObject);
begin
  tmInicializar.Enabled := false;
  bbIniciar.Click;
end;

end.

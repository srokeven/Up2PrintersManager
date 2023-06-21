unit uVCLWebserviceEnvio;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON, IniFiles, ShellApi,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.Menus;

type
  TfmVCLWebServiceEnvio = class(TForm)
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
    procedure bbIniciarClick(Sender: TObject);
    procedure bbPararClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
  fmVCLWebServiceEnvio: TfmVCLWebServiceEnvio;

implementation

uses Horse, Horse.Jhonson, udmHandle, uUtils, Horse.JWT;

{$R *.dfm}

{ TfmVCLWebServiceEnvio }

procedure TfmVCLWebServiceEnvio.bbIniciarClick(Sender: TObject);
begin
  GravarIni('GERAL', 'NOME_ENVIO', edDescricao.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  GravarIni('GERAL', 'PORTA_ENVIO', edPorta.Text, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  Start;
  Status;
  {$IFDEF DEBUG}
  {$ELSE}
    HideApplication;
  {$ENDIF}
end;

procedure TfmVCLWebServiceEnvio.bbPararClick(Sender: TObject);
begin
  Stop;
  Status;
end;

procedure TfmVCLWebServiceEnvio.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if THorse.IsRunning then
    Stop;
end;

procedure TfmVCLWebServiceEnvio.FormCreate(Sender: TObject);
begin
  edDescricao.Text := LerIni('GERAL', 'NOME_ENVIO', 'Serviço de envio', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  edPorta.Text := LerIni('GERAL', 'PORTA_ENVIO', '9100', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'configuracao.ini');
  try
    THorse.Use(Jhonson());
    THorse.KeepConnectionAlive := True;

    THorse.AddCallback(HorseJWT(TOKEN)).Post('/print',
      procedure(Req: THorseRequest; Res: THorseResponse)
      begin
        GravaLog('Recebido pedido de impressão', 'log_envio_');
        try
          try
            dmHandle := TdmHandle.Create(nil);
            if dmHandle.StoreFile(Req.Body<TJSONObject>.ToString) then
              Res.Send(TJSONObject.Create.AddPair('mensagem', 'ok'))
                .Status(THTTPStatus.Created)
            else
              Res.Send(TJSONObject.Create.AddPair('mensagem',
                dmHandle.GetErroImpressao)).Status(THTTPStatus.BadRequest);
          except
            on e: Exception do
              Res.Send(TJSONObject.Create.AddPair('mensagem', e.Message))
                .Status(THTTPStatus.InternalServerError);
          end;
        finally
          dmHandle.DisposeOf;
        end;
      end);
    tmInicializar.Enabled := True;
  except
    on e: Exception do
      GravaLog(e.ClassName+ ': '+ e.Message, 'log_envio_');
  end;
end;

procedure TfmVCLWebServiceEnvio.HideApplication;
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

procedure TfmVCLWebServiceEnvio.Label3Click(Sender: TObject);
begin
  var vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'logs';
  if FileExists(IncludeTrailingPathDelimiter(vDiretorio)+'log_envio_'+FormatDateTime('ddMMyyyy',Date)+'.txt') then
       ShellExecute(0,
          'open',
          PChar('explorer.exe'),
          PChar('/n, /select,'+IncludeTrailingPathDelimiter(vDiretorio)+'log_envio_'+FormatDateTime('ddMMyyyy',Date)+'.txt'),
          nil,  // Se nao funcionar, precisa por o caminho do Windows no parâmetro Directory >> PChar('C:\WINDOWS\'),
          SW_SHOWMAXIMIZED);
end;

procedure TfmVCLWebServiceEnvio.popupIniciarClick(Sender: TObject);
begin
  if bbIniciar.Enabled then
  begin
    Start;
    Status;
  end;
end;

procedure TfmVCLWebServiceEnvio.popupPararClick(Sender: TObject);
begin
  if bbParar.Enabled then
    bbParar.Click;
end;

procedure TfmVCLWebServiceEnvio.popupRestaurarClick(Sender: TObject);
begin
  ShowApplication;
end;

procedure TfmVCLWebServiceEnvio.ShowApplication;
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

procedure TfmVCLWebServiceEnvio.Start;
begin
  // Need to set "HORSE_VCL" compilation directive
  THorse.Listen(StrToInt(edPorta.Text));
  GravaLog('Serviço iniciado', 'log_envio_');
end;

procedure TfmVCLWebServiceEnvio.Status;
begin
  bbParar.Enabled := THorse.IsRunning;
  bbIniciar.Enabled := not THorse.IsRunning;
  edPorta.Enabled := not THorse.IsRunning;
  edDescricao.Enabled := not THorse.IsRunning;
  popupIniciar.Enabled := not THorse.IsRunning;
  popupParar.Enabled := THorse.IsRunning;
end;

procedure TfmVCLWebServiceEnvio.Stop;
begin
  THorse.StopListen;
  GravaLog('Serviço parado', 'log_envio_');
end;

procedure TfmVCLWebServiceEnvio.tmInicializarTimer(Sender: TObject);
begin
  tmInicializar.Enabled := false;
  bbIniciar.Click;
end;

end.

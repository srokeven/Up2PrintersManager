unit uRegistroImpressaoModel;

interface

type
  TRegistroImpressao = class
    private
      FDescricao: string;
      FTipoArquivo: string;
      FRegistroImpressora: string;
      FJsonOriginal: string;
      FRelatorioEncoded: string;
      FCaminhoArquivo: string;
    public
      property Descricao: string read FDescricao write FDescricao;
      property TipoArquivo: string read FTipoArquivo write FTipoArquivo;
      property RegistroImpressora: string read FRegistroImpressora write FRegistroImpressora;
      property JsonOriginal: string read FJsonOriginal write FJsonOriginal;
      property RelatorioEncoded: string read FRelatorioEncoded write FRelatorioEncoded;
      property CaminhoArquivo: string read FCaminhoArquivo write FCaminhoArquivo;
  end;

implementation

end.

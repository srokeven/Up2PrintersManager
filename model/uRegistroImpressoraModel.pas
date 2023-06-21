unit uRegistroImpressoraModel;

interface

type
  TRegistroImpressora = class
    private
      FRegistro: string;
      FDescricao: string;
      FTipoImpressora: string;
      FCompartilhamentoImpressora: string;
      FIpLocal: string;
      FNomeTerminal: string;
    public
      property Registro: string read FRegistro write FRegistro;
      property Descricao: string read FDescricao write FDescricao;
      property TipoImpressora: string read FTipoImpressora write FTipoImpressora;
      property CompartilhamentoImpressora: string read FCompartilhamentoImpressora write FCompartilhamentoImpressora;
      property IpLocal: string read FIpLocal write FIpLocal;
      property NomeTerminal: string read FNomeTerminal write FNomeTerminal;
  end;

implementation

end.

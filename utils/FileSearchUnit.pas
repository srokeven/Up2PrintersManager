unit FileSearchUnit;

interface

uses
  SysUtils, Classes, IOUtils;

type
  TFileSearch = class
  private
    FFolder: string;
    FExtension: string;
    FFileList: TStringList;
    procedure SearchFiles(const APath: string); overload;
    procedure SearchFiles; overload;
  public
    constructor Create(const AFolder, AExtension: string);
    destructor Destroy; override;
    procedure Execute;
    procedure Extension(const AExtension: string);
    procedure Directory(const AFolder: string);
    function GetFileList: TStringList;
  end;

implementation

constructor TFileSearch.Create(const AFolder, AExtension: string);
begin
  FFolder := IncludeTrailingPathDelimiter(AFolder);
  FExtension := AExtension;
  FFileList := TStringList.Create;
end;

destructor TFileSearch.Destroy;
begin
  FFileList.Free;
  inherited;
end;

procedure TFileSearch.Directory(const AFolder: string);
begin
  FFolder := AFolder;
end;

procedure TFileSearch.SearchFiles(const APath: string);
var
  SearchRec: TSearchRec;
  ResultCode: Integer;
begin
  ResultCode := FindFirst(APath + '*.*', faAnyFile, SearchRec);
  try
    while ResultCode = 0 do
    begin
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        if (SearchRec.Attr and faDirectory) = faDirectory then
          SearchFiles(APath + SearchRec.Name + '\')
        else if SameText(ExtractFileExt(SearchRec.Name), FExtension) then
          FFileList.Add(APath + SearchRec.Name);
      end;
      ResultCode := FindNext(SearchRec);
    end;
  finally
    FindClose(SearchRec);
  end;
end;

procedure TFileSearch.Execute;
begin
  FFileList.Clear;
  SearchFiles;
end;

procedure TFileSearch.Extension(const AExtension: string);
begin
  FExtension := AExtension;
end;

function TFileSearch.GetFileList: TStringList;
begin
  Result := FFileList;
end;

procedure TFileSearch.SearchFiles;
var
  path : string;
begin
  for Path in TDirectory.GetFiles(FFolder)  do
    if ExtractFileExt(Path) = FExtension then
      FFileList.Add(Path);
end;

end.


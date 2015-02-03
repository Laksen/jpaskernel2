unit filesystem;

interface

uses storagedev, partition, cclasses, handles, fsutils;

type
 TFileAttribute = (faReadOnly);
 TFileAttributes = set of TFileAttribute;
 
 TFileDescription = record
  Name: PChar;
  FileAttributes: TFileAttributes;
  FileSize: int64;
 end;
 
 TDirectoryContents = class
  function HasFiles: boolean; virtual; abstract;
  function Next: TFileDescription; virtual; abstract;
  
  function Count: PtrInt; virtual; abstract;
 end;
 
 TFile = class(TOwnedObject)
  function ReadFile(Data: Pointer; DataLen: PtrInt): PtrInt; virtual;
  function WriteFile(Data: Pointer; DataLen: PtrInt): PtrInt; virtual;
  function GetFileSize: int64; virtual;
  function Seek(Offset: int64; From: PtrUInt): ptrint; virtual;
  function FilePosition: int64; virtual;
 end;
 
 TFileSystem = class
  function OpenFile(filename: TFilenameInfo; FileMode: PtrUInt): TFile; virtual; abstract;
  function GetDirectoryContents(path: pchar): TDirectoryContents; virtual; abstract;
 end;
 
 TFileSystemProbe = class
 private
  fParts: TList;
  function GetCount: PtrInt;
  function GetPartition(const index: PtrInt): TPartition;
 public
  procedure UnownPartition(part: TPartition);
  
  constructor Create(D: TStorageDevice);
  destructor Destroy; override;
  
  property PartitionCount: PtrInt read GetCount;
  property Partitions[index: PtrInt]: TPartition read GetPartition;
 end;

implementation

uses fat;

var fsList: TList;

function TFileSystemProbe.GetCount: PtrInt;
begin
	result := fParts.Count;
end;

function TFileSystemProbe.GetPartition(const index: PtrInt): TPartition;
begin
	result := TPartition(fParts[index]);
end;

procedure TFileSystemProbe.UnownPartition(part: TPartition);
begin
	fParts.Remove(part);
end;

constructor TFileSystemProbe.Create(D: TStorageDevice);
begin
	inherited Create;
	fParts := TList.Create(nil);
end;

destructor TFileSystemProbe.Destroy;
var i: PtrInt;
begin
	for i := 0 to fParts.Count-1 do TPartition(fParts[i]).Free;
	fParts.Free;
	inherited Destroy;
end;

function TFile.ReadFile(Data: Pointer; DataLen: PtrInt): PtrInt;
begin
	result := -1;
end;

function TFile.WriteFile(Data: Pointer; DataLen: PtrInt): PtrInt;
begin
	result := -1;
end;

function TFile.GetFileSize: int64;
begin
	result := 0;
end;

function TFile.Seek(Offset: int64; From: PtrUInt): ptrint;
begin
	result := 0;
end;

function TFile.FilePosition: int64;
begin
	result := 0;
end;

initialization
	fsList := TList.Create(nil);

end.

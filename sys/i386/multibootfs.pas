unit multibootfs;

interface

uses vfs, cclasses, filesystem, fsutils;

type
 TMBFileInfo = class
 private
  fAddr: Pointer;
  fSize: PtrUInt;
 public
  constructor Create(Addr: Pointer; Size: PtrUInt);
  
  property Address: Pointer read fAddr;
  property Size: PtrUInt read fSize;
 end;
 
 TMBFile = class(TFile)
 private
  fAddr: Pointer;
  fOffset,
  fSize: PtrUInt;
 public
  function ReadFile(Data: Pointer; DataLen: PtrInt): PtrInt; override;
  function WriteFile(Data: Pointer; DataLen: PtrInt): PtrInt; override;
  function GetFileSize: int64; override;
  function Seek(Offset: int64; From: PtrUInt): ptrint; override;
  function FilePosition: int64; override;
  
  constructor Create(FI: TMBFileInfo);
 end;
 
 TMBFS = class(TFileSystem)
 private
  fFiles: TStringList;
 public
  procedure AddFile(name: PChar; Addr: Pointer; Size: PtrUInt);
  
  function OpenFile(filename: TFilenameInfo; FileMode: PtrUInt): TFile; override;
  function GetDirectoryContents(path: pchar): TDirectoryContents; override;
  
  constructor Create;
  destructor Destroy; override;
 end;

implementation

function TMBFile.ReadFile(Data: Pointer; DataLen: PtrInt): PtrInt;
begin
	result := DataLen;
	move(pbyte(Pointer(PtrUInt(fAddr)+fOffset))^, pbyte(data)^, datalen);
	inc(fOffset, Datalen);
end;

function TMBFile.WriteFile(Data: Pointer; DataLen: PtrInt): PtrInt;
begin
	result := -1;
end;

function TMBFile.GetFileSize: int64;
begin
	result := fSize;
end;

function TMBFile.Seek(Offset: int64; From: PtrUInt): ptrint;
begin
	case from of 
		soFromBeginning: fOffset := Offset;
		soFromCurrent: fOffset := fOffset + Offset;
		soFromEnd: fOffset := fSize-Offset;
	end;
	result := fOffset;
end;

function TMBFile.FilePosition: int64;
begin
	result := FOffset;
end;

constructor TMBFile.Create(FI: TMBFileInfo);
begin
	inherited Create;
	fAddr := Fi.Address;
	fSize := FI.Size;
	fOffset := 0;
end;

procedure TMBFS.AddFile(name: PChar; Addr: Pointer; Size: PtrUInt);
begin
	fFiles.Add(@name[1], TMBFileInfo.Create(Addr, Size));
end;

function TMBFS.OpenFile(filename: TFilenameInfo; FileMode: PtrUInt): TFile;
begin
	result := nil;
	
	if (filemode and fmOpenWrite) = fmOpenWrite then exit;
	
	result := TMBFile.Create(TMBFileInfo(fFiles[filename.filename]));
end;

function TMBFS.GetDirectoryContents(path: pchar): TDirectoryContents;
begin
	
end;

constructor TMBFS.Create;
begin
	inherited Create;
	fFiles := TStringList.Create(nil);
end;

destructor TMBFS.Destroy;
begin
	fFiles.Free;
	inherited Destroy;
end;

constructor TMBFileInfo.Create(Addr: Pointer; Size: PtrUInt);
begin
	inherited Create;
	fAddr := Addr;
	fSize := Size;
end;

end.

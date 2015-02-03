unit vfs;

interface

uses handles, services, cclasses, sysutils, filesystem, storagedev;

const
 fmOpenRead = 1;
 fmOpenWrite = 2;
 fmCreate = 4;
 
 soFromBeginning = 1;
 soFromCurrent = 2;
 soFromEnd = 4;

type
 TVFS = class(TServiceObject)
 private
  fPartitions: TStringList;
  function FindFile(handle: THandle): TFile;
 protected
  procedure RegisterFunctions; override;
 public
  procedure RegisterStorage(D: TStorageDevice);
  
  procedure AddFilesystem(FsLabel: pchar; fs: TFilesystem);
  procedure RemoveFilesystem(FsLabel: pchar);
  
  function OpenFile(Filename: pchar; FileFlags: PtrUInt): THandle;
  procedure CloseFile(Handle: THandle);
  
  function ReadFile(Handle: THandle; Data: Pointer; DataLen: PtrInt): PtrInt;
  function WriteFile(Handle: THandle; Data: Pointer; DataLen: PtrInt): PtrInt;
  function SeekFile(Handle: THandle; Position, PositionHigh, Offset: PtrUInt): PtrInt;
  function FileSize(Handle: THandle; FsLow, FsHigh: PPtrUInt): PtrInt;
  function FilePosition(Handle: THandle; FPLow, FPHigh: PPtrUInt): PtrInt;
  
  constructor Create;
 end;

var VFSManager: TVFS = nil;

implementation

uses fsutils;

constructor TVFS.Create;
begin
	inherited Create('VFS');
  fPartitions := TStringList.Create(nil);
end;

function TVFS.FindFile(handle: THandle): TFile;
begin
	result := TFile(FindObject(handle));
	if not assigned(result) then
		raise exception.Create('Object not found');
	if not result.InheritsFrom(TFile) then
		raise exception.Create('Object is not a file');
end;

procedure TVFS.AddFilesystem(FsLabel: pchar; fs: TFilesystem);
begin
	fPartitions.Add(FsLabel, fs);
end;

procedure TVFS.RemoveFilesystem(FsLabel: pchar);
begin
	fPartitions.remove(fslabel);
end;

function TVFS.OpenFile(Filename: pchar; FileFlags: PtrUInt): THandle;
var fn: TFilenameInfo;
	 part: TFileSystem;
begin
	result := InvalidHandle;
	
	fn := ExplodeFilename(filename);
	
	try
		part := TFileSystem(fPartitions[fn.Drive]);
		if assigned(part) then
			result := part.openfile(fn, fileflags).Handle;
	except
	end;
	
	FreeFilenameInfo(fn);
end;

function TVFS.ReadFile(Handle: THandle; Data: Pointer; DataLen: PtrInt): PtrInt;
var x: TFile;
begin
	try
		x := FindFile(Handle);
		result := x.ReadFile(Data, DataLen);
	except
		result := -1;
	end;
end;

function TVFS.WriteFile(Handle: THandle; Data: Pointer; DataLen: PtrInt): PtrInt;
var x: TFile;
begin
	try
		x := FindFile(Handle);
		result := x.WriteFile(Data, DataLen);
	except
		result := -1;
	end;
end;

function TVFS.SeekFile(Handle: THandle; Position, PositionHigh, Offset: PtrUInt): PtrInt;
var x: TFile;
begin
	try
		x := FindFile(Handle);
		result := x.Seek(Position, Offset);
	except
		result := -1;
	end;
end;

function TVFS.FileSize(Handle: THandle; FsLow, FsHigh: PPtrUInt): PtrInt;
var x: TFile;
	 t: int64;
begin
	try
		x := FindFile(Handle);
		t := x.GetFileSize;
		
		if assigned(fslow) then fslow^ := t and $FFFFFFFF;
		if assigned(FsHigh) then FsHigh^ := (t shr 32) and $FFFFFFFF;
		
		result := 0;
	except
		result := -1;
	end;
end;

function TVFS.FilePosition(Handle: THandle; FPLow, FPHigh: PPtrUInt): PtrInt;
var x: TFile;
	 t: int64;
begin
	try
		x := FindFile(Handle);
		t := x.FilePosition;
		
		if assigned(FPLow) then FPLow^ := t and $FFFFFFFF;
		if assigned(FPHigh) then FPHigh^ := (t shr 32) and $FFFFFFFF;
		
		result := 0;
	except
		result := -1;
	end;
end;

procedure TVFS.CloseFile(Handle: THandle);
begin
	CloseHandle(Handle);
end;

procedure TVFS.RegisterStorage(D: TStorageDevice);
begin
	
end;

procedure TVFS.RegisterFunctions;
begin
	RegisterFunction('OpenFile',  GetMethod(@TVFS.OpenFile, self),  2);
	RegisterFunction('CloseFile', GetMethod(@TVFS.WriteFile, self), 1);
	RegisterFunction('ReadFile',  GetMethod(@TVFS.ReadFile, self),  3);
	RegisterFunction('WriteFile', GetMethod(@TVFS.WriteFile, self), 3);
	RegisterFunction('SeekFile',  GetMethod(@TVFS.SeekFile, self),  4);
	RegisterFunction('FileSize',  GetMethod(@TVFS.FileSize, self),  3);
end;

initialization
	if not assigned(VFSManager) then
		VFSManager := TVFS.Create;

end.

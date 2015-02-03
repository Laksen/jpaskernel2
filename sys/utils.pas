unit utils;

interface

// VFS utils
function LoadFile(const FileName: pchar; out FileSize: PtrInt): Pointer;

implementation

uses vfs, handles;

function LoadFile(const FileName: pchar; out FileSize: PtrInt): Pointer;
var h: THandle;
	 fs: ptruint;
begin
	result := nil;
  FileSize := 0;

	if not assigned(VFSManager) then
    exit;

	h := VFSManager.OpenFile(filename, fmOpenRead);

	if h <> invalidhandle then
	  begin
		  VFSManager.FileSize(h, @fs, nil);
		  filesize := fs;
		  result := GetMem(fs);
		  VFSManager.ReadFile(h, result, fs);
		  VFSManager.CloseFile(h);
	  end;
end;

end.

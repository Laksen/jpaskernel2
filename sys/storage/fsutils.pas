unit fsutils;

interface

type
 TFilenameInfo = record
  Drive: PChar;
  Directories: PPChar;
  Filename: PChar;
 end;

function ExplodeFilename(filename: pchar): TFilenameInfo;
procedure FreeFilenameInfo(const fnInfo: TFilenameInfo);

implementation

uses cclasses;

function StrCount(sep: char; str: pchar): PtrInt;
var i, len: ptrint;
begin
	result := 0;
	len := strlen(str);
	for i := 0 to len-1 do
		if str[i] = sep then
			inc(result);
end;

function ExplodeFilename(filename: pchar): TFilenameInfo;
var t,cnt,i: ptrint;
begin
	result.drive := nil;
	result.directories := nil;
	result.filename := nil;
	
	//Drive
	t := StrPosChar(':', filename);
	if t >= 0 then
	begin
		result.Drive := StrCopy(filename, 0, t);
		filename := @filename[t+1];
	end
	else
	begin
		//Get the current drive(of the current thread)
	end;
	
	//Dir
	t := strrpos('/', filename);
	if t >= 0 then
	begin
		cnt := strcount('/', filename);
		
		result.directories := GetMem((cnt+2)*sizeof(Pointer));
		fillchar(result.directories, (cnt+2)*sizeof(Pointer), 0);
		
		for i := 0 to cnt-1 do
		begin
			t := strposchar('/', filename);
			result.directories[i] := StrCopy(filename, 0, t);
			filename := @filename[t+1];
		end;
	end;
	
	result.filename := strdup(filename);
end;

procedure FreeFilenameInfo(const fnInfo: TFilenameInfo);
var p: ppchar;
begin
	if assigned(fnInfo.Drive) then StrDispose(fnInfo.Drive);
	if assigned(fnInfo.Filename) then StrDispose(fnInfo.Filename);
	
	if assigned(fnInfo.Directories) then
	begin
		p := fnInfo.Directories;
		while p^ <> nil do
		begin
			StrDispose(p^);
			inc(p);
		end;
		
		FreeMem(fnInfo.Directories);
	end;
end;

end.

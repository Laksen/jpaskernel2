unit fat;

interface

uses filesystem, partition, fsutils;

type
 TFATFS = class(TFileSystem)
 private
  //Root
  //Directory
 public
  function OpenFile(filename: TFilenameInfo; FileMode: PtrUInt): TFile; override;
  function GetDirectoryContents(path: pchar): TDirectoryContents; override;
 end;
 
 TFAT16 = class(TFATFS)
 private
  
 public
  constructor Create(Part: TPartition);
 end;
 
 TFAT32 = class(TFATFS)
 private
  
 public
  constructor Create(Part: TPartition);
 end;
 
function CreateFAT(part: TPartition): TFileSystem;

implementation

function TFATFS.OpenFile(filename: TFilenameInfo; FileMode: PtrUInt): TFile;
begin
	
end;

function TFATFS.GetDirectoryContents(path: pchar): TDirectoryContents;
begin
	result := nil;
end;

constructor TFAT16.Create(Part: TPartition);
begin
	inherited Create;
	
end;

constructor TFAT32.Create(Part: TPartition);
begin
	inherited Create;
	
end;

function CreateFAT(part: TPartition): TFileSystem;
begin
	//Read BPB
	//Determine cluster count
	//Instantiate the correct implementation
	result := TFat32.Create(part);
end;

end.

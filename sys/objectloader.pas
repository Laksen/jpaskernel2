unit objectloader;

interface

uses cclasses, sysutils, AddressSpace, paso, memoryutils, heapmgr;

type
 TObjSection = class
 protected
  fData,
  fVirt: Pointer;
  fDataSize: PtrUInt;
  fSec: TPasoSection;
 public
  function Map(AddrSpace: TAddressSpace): boolean; virtual; abstract;
  
  function Read(Offset: TPasoDWord; var val: TPasoDWord): boolean; virtual; abstract;
  function Write(Offset: TPasoDWord; val: TPasoDWord): boolean; virtual; abstract;
  
  constructor Create(Data: Pointer; const Sec: TPasoSection);
  destructor Destroy; override;
  
  property PhysicalAddress: Pointer read fData;
  property VirtualAddress: Pointer read fVirt;
 end;
 
 TKernelObjSection = class(TObjSection)
  function Map(AddrSpace: TAddressSpace): boolean; override;
  
  function Read(Offset: TPasoDWord; var val: TPasoDWord): boolean; override;
  function Write(Offset: TPasoDWord; val: TPasoDWord): boolean; override;
 end;
 
 TUserObjSection = class(TObjSection)
  function Map(AddrSpace: TAddressSpace): boolean; override;
  
  function Read(Offset: TPasoDWord; var val: TPasoDWord): boolean; override;
  function Write(Offset: TPasoDWord; val: TPasoDWord): boolean; override;
 end;
 
 TObjSectionClass = class of TObjSection;
 
 TObj = class
 private
  fSections: TDictionary;
  fEntry: Pointer;
  procedure FreeSection(Sec, Data: Pointer);
  
  procedure DoMap(Val, data: pointer);
  procedure Relocate(const rel: TPasoRelocation; Sym: PPasoSymbol);
 public
  function Map(AddrSpace: TAddressSpace): boolean;
  
  constructor Create(const FileName: pchar; SectionType: TObjSectionClass);
  destructor Destroy; override;
  
  property Entrypoint: Pointer read fEntry;
 end;
 
 TKernelObj = class(TObj)
  constructor Create(const FileName: pchar);
 end;
 
 TUserObj = class(TObj)
  constructor Create(const FileName: pchar);
 end;

implementation

uses architecture, utils;

procedure TObj.DoMap(Val, data: pointer);
begin
	TObjSection(Val).Map(TAddressSpace(data));
end;

function TObj.Map(AddrSpace: TAddressSpace): boolean;
begin
	result := false;
	
	fSections.ForeachCall(@DoMap, AddrSpace);
	
	result := true;
end;

procedure TObj.Relocate(const rel: TPasoRelocation; Sym: PPasoSymbol);
var target, tmp: TPasoDWord;
	 sec: TObjSection;
begin
	sec := TObjSection(fSections[rel.Section]);
	
	if not assigned(sec) then
		exit;
	
	//Get target address
	case rel.IndexType of
		PASO_RELIDX_SYMBOL:
			target := PtrUInt(TObjSection(fSections[Sym^.Section]).VirtualAddress)+sym^.Offset;
		PASO_RELIDX_SECTION:
			target := PtrUInt(TObjSection(fSections[rel.Index]).VirtualAddress);
	end;
	
	case rel.RelocType of
		PASO_REL_RELATIVE:
			begin
				sec.Read(rel.offset, tmp);
				sec.Write(rel.Offset, target-(PtrUInt(sec.VirtualAddress)+rel.offset)+tmp);
			end;
		PASO_REL_ABSOLUTE:
			sec.Write(rel.Offset, target);
	end;
end;

constructor TObj.Create(const FileName: pchar; SectionType: TObjSectionClass);
var Buf: Pointer;
	 hdr: PPasoHeader;
	 fs, i: PtrInt;
	 Sec: TPasoSection;
	 rel: PPasoRelocation;
	 sym: PPasoSymbol;
begin
	inherited Create;
	fSections := TDictionary.Create(nil);
	
	Buf := LoadFile(FileName, FS);
	hdr := buf;

  if buf = nil then
    raise exception.Create('File not found');
	
	try
		if fs < sizeof(TPasoHeader) then Raise Exception.Create('Invalid file size');
		
		if hdr^.Identity <> PASO_IDENTIFIER then raise Exception.Create('Wrong identity');
		if hdr^.MachineType <> PASO_CURRENT then raise Exception.Create('Wrong machine type');
		
		//Create sections
		for i := 0 to hdr^.SecCount-1 do
		begin
			sec := PPasoSection(Buf+hdr^.SecOffset+i*SizeOf(TPasoSection))^;
			
			fSections.Add(i, SectionType.Create(pointer(buf+sec.Offset), sec));
		end;
		
		if afNoProtection in ArchInfo.Flags then
		begin
			//Use relocations
			rel := Pointer(PtrUint(buf)+PtrUInt(hdr^.RelOffset));
			
			for i := 0 to hdr^.RelCount-1 do
			begin
				if rel^.IndexType = PASO_RELIDX_SYMBOL then
					sym := Pointer(PtrUint(buf)+PtrUInt(hdr^.SymOffset)+PtrUInt(rel^.Index*SizeOf(TPasoSymbol)))
				else
					sym := nil;
				
				Relocate(rel^, sym);
				inc(rel);
			end;
		end;
		
		//Calculate entrypoint
		fEntry := Pointer(PtrUInt(TObjSection(fSections[hdr^.EntrySec]).VirtualAddress)+hdr^.EntryOffset);
		writeln('Entry: ', ptruint(fEntry));
	finally
		FreeMem(Buf);
	end;
end;

procedure TObj.FreeSection(Sec, Data: Pointer);
begin
	TObjSection(sec).Free;
end;

destructor TObj.Destroy;
begin
	fSections.ForEachCall(@FreeSection, nil);
	
	fSections.Free;
	inherited Destroy;
end;

constructor TKernelObj.Create(const FileName: pchar);
begin
	inherited Create(filename, TKernelObjSection);
end;

constructor TUserObj.Create(const FileName: pchar);
begin
	inherited Create(filename, TUserObjSection);
end;

function TKernelObjSection.Map(AddrSpace: TAddressSpace): boolean;
begin
	result := false;
	try
		AddrSpace.MapDirect(fData, fVirt, fsec.Size, [mfWrite, mfRead, mfExecute]);
		result := true;
	except
	end;
end;

function TUserObjSection.Map(AddrSpace: TAddressSpace): boolean;
begin
	result := false;
	try
		AddrSpace.MapDirect(fData, fVirt, fsec.Size, [mfWrite, mfRead, mfExecute]);
		result := true;
	except
	end;
end;

function TUserObjSection.Read(Offset: TPasoDWord; var val: TPasoDWord): boolean;
begin
	val := PPasoDWord(fData+Offset)^;
	result := true;
end;

function TUserObjSection.Write(Offset: TPasoDWord; val: TPasoDWord): boolean;
begin
	PPasoDWord(fData+Offset)^ := val;
	result := true;
end;

function TKernelObjSection.Read(Offset: TPasoDWord; var val: TPasoDWord): boolean;
begin
	val := PPasoDWord(fData+Offset)^;
	result := true;
end;

function TKernelObjSection.Write(Offset: TPasoDWord; val: TPasoDWord): boolean;
begin
	PPasoDWord(fData+Offset)^ := val;
	result := true;
end;

constructor TObjSection.Create(Data: Pointer; const Sec: TPasoSection);
begin
	inherited Create;
	fSec := Sec;
	fDataSize := Sec.Size;
	fData := GetAlignedMem(fDataSize, Sec.Alignment);
	
	if afNoProtection in ArchInfo.Flags then
		fVirt := fData
	else
		fVirt := Pointer(Sec.VAddr);
	
	if (sec.Flags and PASO_SECFLAGS_DATA) = PASO_SECFLAGS_DATA then
		Move(PByte(Data)^, PByte(fData)^, fDataSize)
	else
		FillChar(PByte(fData)^, fDataSize, 0);
end;

destructor TObjSection.Destroy;
begin
	FreeMem(fData);
	inherited Destroy;
end;

end.

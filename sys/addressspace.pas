unit addressspace;

interface

type
 TMemoryFlag = (mfRead, mfWrite, mfExecute);
 TMemoryFlags = set of TMemoryFlag;
 
 TAddressSpaceType = class of TAddressSpace;
 
 TAddressSpace = class
  function Map(Phys: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer; virtual;
  function MapDirect(Phys, Virt: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer; virtual;
  function Unmap(Virt: Pointer; Size: PtrUInt): Pointer; virtual;
 end;

implementation

uses sysutils;

function TAddressSpace.Map(Phys: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer;
begin
	result := Phys;
end;

function TAddressSpace.MapDirect(Phys, Virt: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer;
begin
	if Phys <> Virt then
		raise exception.Create('Cannot map area');
	
	result := Phys;
end;

function TAddressSpace.Unmap(Virt: Pointer; Size: PtrUInt): Pointer;
begin
	result := Virt;
end;

end.

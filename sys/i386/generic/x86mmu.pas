unit x86mmu;

interface

uses addressspace;

type
 TX86AddressSpace = class(TAddressSpace)
  function Map(Phys: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer; override;
  function MapDirect(Phys, Virt: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer; override;
  function Unmap(Virt: Pointer; Size: PtrUInt): Pointer; override;
 end;

implementation

function TX86AddressSpace.Map(Phys: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer;
begin
	result := Phys;
end;

function TX86AddressSpace.MapDirect(Phys, Virt: Pointer; Size: PtrUInt; Flags: TMemoryFlags): Pointer;
begin
	result := Inherited MapDirect(Phys, virt, size, flags);
end;

function TX86AddressSpace.Unmap(Virt: Pointer; Size: PtrUInt): Pointer;
begin
	result := inherited Unmap(virt,size);
end;

end.

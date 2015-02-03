unit memoryutils;

interface

const
 MaxMemBlocks = 16;

type
 TMemoryBlock = record
  Address: Pointer;
  Size: PtrUInt;
 end;
 
 TMemoryChain = record
  BlockCount: PtrInt;
  Free: array[0..MaxMemBlocks-1] of TMemoryBlock;
 end;

procedure InitializeChain(var Chain: TMemoryChain);

procedure AddBlock(var Chain: TMemoryChain; Addr: Pointer; Size: PtrUInt);
procedure RemoveBlock(var Chain: TMemoryChain; Addr: Pointer; Size: PtrUInt);

implementation

procedure InitializeChain(var Chain: TMemoryChain);
begin
	fillchar(chain, sizeof(chain), 0);
end;

procedure DeleteBlock(var chain: TMemoryChain; Index: PtrInt);
begin
	move(Chain.Free[Index+1], Chain.Free[Index], (chain.BlockCount-index+1)*SizeOf(TMemoryBlock));
	dec(chain.BlockCount);
end;

procedure AddBlock(var Chain: TMemoryChain; Addr: Pointer; Size: PtrUInt);
begin
	if size = 0 then exit;
	
	Chain.Free[Chain.BlockCount].Address := Addr;
	Chain.Free[Chain.BlockCount].Size := Size;
	inc(Chain.BlockCount);
end;

procedure RemoveBlock(var Chain: TMemoryChain; Addr: Pointer; Size: PtrUInt);
var r,l: boolean;
	 i: PtrInt;
	 b: TMemoryBlock;
begin
	if size = 0 then exit;
	
	for i := Chain.BlockCount-1 downto 0 do
	begin
		l := ((PtrUInt(Addr)) >= PtrUInt(Chain.Free[i].Address)) and ((PtrUInt(Addr)) <= (PtrUInt(Chain.Free[i].Address)+Chain.Free[i].Size));
		r := ((PtrUInt(Addr)+Size) >= PtrUInt(Chain.Free[i].Address)) and ((PtrUInt(Addr)+Size) <= (PtrUInt(Chain.Free[i].Address)+Chain.Free[i].Size));
		
		if r and l then
		begin
			b := Chain.Free[i];
			DeleteBlock(chain, i);
			
			AddBlock(chain, b.Address, PtrUInt(Addr)-PtrUInt(b.Address));
			AddBlock(chain, Pointer(PtrUInt(Addr)+Size), (PtrUInt(b.Address)+b.Size)-(PtrUInt(Addr)+Size));
		end
		else if r then
		begin
			b := Chain.Free[i];
			
			Chain.Free[i].Address := Pointer(PtrUInt(Addr)+Size);
			Chain.Free[i].Size := (PtrUInt(b.Address)+b.Size)-(PtrUInt(Addr)+Size);
		end
		else if l then
		begin
			Chain.Free[i].Size := PtrUInt(Addr)-PtrUInt(Chain.Free[i].Address);
			if Chain.Free[i].Size = 0 then
				DeleteBlock(Chain, i);
		end
		else if ((PtrUInt(Chain.Free[i].Address) >= PtrUInt(Addr)) and (PtrUInt(Chain.Free[i].Address) < (PtrUInt(Addr)+Size))) then
		begin
			DeleteBlock(chain, i);
		end;
	end;
end;

end.

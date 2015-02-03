unit multibootentry;

interface

uses heapmgr, vgaoutput;
{uses multibootfs, vfs;}

implementation

uses memoryutils;

{$asmmode att}

var text_start: record end; external name '_text';
var data_end: record end; external name '_edata';
var bss_end: record end; external name '_bss_end';
var Entry2: record end; external name '_START';

procedure Signature; assembler; nostackframe;
const
 MULTIBOOT_PAGE_ALIGN = 1;
 MULTIBOOT_MEMORY_INFO = 2;
 MULTIBOOT_AOUT_KLUDGE = 1 shl 16;
 
 MultibootSig = $1BADB002;
 MultibootFlags = {MULTIBOOT_PAGE_ALIGN or }MULTIBOOT_MEMORY_INFO or MULTIBOOT_AOUT_KLUDGE;
 MultibootChksum = -(MultibootSig + MultibootFlags);
label abc;
asm
  .init
abc:
  .long MultibootSig
  .long MultibootFlags
  .long MultibootChksum
  //AOUT kludge
  .long abc
  .long text_start
  .long data_end
  .long bss_end
  .long Entry2

  .text
end;

{$asmmode intel}

type
 PMBModule = ^TMBModule;
 TMBModule = packed record
  mod_start,
  mod_end: PtrUInt;
  name: pchar;
  reserved: DWord;
 end;
 
 PMemoryMap = ^TMemoryMap;
 TMemoryMap = packed record
  size,
  base_lower,
  base_upper,
  length_lower,
  length_upper,
  mtype: DWord;
 end;

 PElfSectionHeaderTable = ^TElfSectionHeaderTable;
 TElfSectionHeaderTable = packed record
  num,
  size,
  addr,
  shndx: DWord;
 end; 

 PMultibootinfo = ^TMultibootinfo;
 TMultiBootInfo = packed record
  Flags,
  MemLower, MemUpper,
  BootDevice,
  CmdLine,
  ModuleCount: DWord;
  ModuleAddress: PMBModule;
  ElfSection: TElfSectionHeaderTable;
  MMapLength: longint;
  MMapAddress: PMemoryMap;
 end;

const
 KernelStackSize = 1024;
var
 KernelStack: array[0..KernelStackSize-1] of byte;
 mbinfo: TMultibootinfo;
 
 memchain: TMemoryChain;

procedure HandleMultiboot;
var i, l: longint;
	 c: pmemorymap;
begin
	InitializeChain(MemChain);
	
	//Register memory blocks
	c := pmemorymap(ptruint(mbinfo.mmapaddress) and $FFFFFFFF);
  l := (mbinfo.mmaplength div sizeof(Tmemorymap));

  for i := 0 to l-1 do
    if c[i].mtype = 1 then
      AddBlock(memchain, pointer(ptruint(c[i].base_lower) and $FFFFFFFF), c[i].length_lower);

	//Reserve 1MB + kernel
	RemoveBlock(memchain, nil, ptruint(@bss_end));
	
	//Multiboot module table
	RemoveBlock(memchain, MBInfo.ModuleAddress, MBinfo.ModuleCount*sizeof(TMBModule));
	
	//Reserve modules
	for i := 0 to MBinfo.ModuleCount-1 do
	  begin
		  RemoveBlock(memchain, MBInfo.ModuleAddress[i].name, strlen(MBInfo.ModuleAddress[i].name)+1);
		  RemoveBlock(memchain, pointer(ptruint(MBInfo.ModuleAddress[i].Mod_start)), MBInfo.ModuleAddress[i].Mod_end-MBInfo.ModuleAddress[i].Mod_start);
	  end;

	for i := 0 to MemChain.BlockCount-1 do
  	RegisterHeapBlock(MemChain.Free[i].Address, MemChain.Free[i].Size);
end;

{procedure AddModules;
var i: PtrInt;
	 fs: TMBFS;
begin
	fs := TMBFS.Create;
	for i := 0 to MBinfo.ModuleCount-1 do 
		fs.AddFile(mbinfo.Moduleaddress[i].name, Pointer(MBInfo.ModuleAddress[i].Mod_start), MBInfo.ModuleAddress[i].Mod_end-MBInfo.ModuleAddress[i].Mod_start);
	
	if not assigned(VFSManager) then VFSManager := TVFS.Create;
	
	VFSManager.AddFilesystem('boot', fs);
end;}

procedure EnterKernel; external name 'PASCALMAIN';

procedure EntryPas(mbptr: pointer);
var
  i: longint;
begin
  for i := 0 to 80*25-1 do
    pword($b8000)[i]:=$720;

  if ptruint(@bss_end)>ptruint(@data_end) then
    for i := 0 to ptruint(@bss_end)-ptruint(@data_end)-1 do
      pbyte(@data_end)[i] := 0;

  for i := 0 to sizeof(mbinfo)-1 do
    pbyte(@mbinfo)[i] := pbyte(mbptr)[i];

	EnterKernel;
end;

procedure HaltProc; [public, alias: '_haltproc'];
begin
  while true do;
end;

procedure Entry; assembler; nostackframe; [public, alias: '_START'];
asm
  cli
  cld

  finit

	mov esp, offset KernelStack+KernelStackSize
	mov ebp, esp

	mov eax, ebx
  jmp EntryPas
end;

initialization
	HandleMultiboot;
	//AddModules;

end.

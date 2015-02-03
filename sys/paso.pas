unit paso;

interface

const
 PASO_IDENTIFIER = $4F534150; // 'PASO'
 
 PASO_I386    = 1;
 PASO_X86_64  = 2;
 PASO_ARM     = 3;
 PASO_SPARC   = 4;
 PASO_SPARC64 = 5;
 PASO_PPC     = 6;
 PASO_PPC64   = 7;
 PASO_M68K    = 8;
 
 PASO_EXEC = 1;
 PASO_KERNEL = 2;
 PASO_DRIVER = 3;
 PASO_MODULE = 4;
 PASO_RELOCATABLE = 5;
 
 PASO_SEC_DATA = 1;
 
 PASO_SECFLAGS_WRITE = 1;
 PASO_SECFLAGS_EXEC = 2;
 PASO_SECFLAGS_LOAD = 4;
 PASO_SECFLAGS_DEBUG = 8;
 PASO_SECFLAGS_DATA = $10;
 
 PASO_SYM_FUNC = 1;
 PASO_SYM_DATA = 2;
 PASO_SYM_UNDEFINED = 3;
 
 PASO_SYMBIND_EXTERNAL = 1;
 PASO_SYMBIND_COMMON = 2;
 PASO_SYMBIND_LOCAL = 3;
 PASO_SYMBIND_GLOBAL = 4;
 
 PASO_REL_RELATIVE = 1;
 PASO_REL_ABSOLUTE = 2;
 
 PASO_RELIDX_SECTION = 1;
 PASO_RELIDX_SYMBOL = 2;

{$ifdef cpusparc}
 PASO_CURRENT = PASO_SPARC;
{$endif}
{$ifdef cpui386}
 PASO_CURRENT = PASO_I386;
{$endif}
{$ifdef cpum68k}
 PASO_CURRENT = PASO_M68K;
{$endif}
{$ifdef cpupowerpc}
 PASO_CURRENT = PASO_PPC;
{$endif}
{$ifdef cpuarm}
 PASO_CURRENT = PASO_ARM
{$endif}
{$ifdef cpux86_64}
 PASO_CURRENT = PASO_X86_64;
{$endif}

type
 TPasoWord = word;
 TPasoDWord = PtrUInt;
 TPasoInt = longint;
 
 PPasoDWord = ^TPasoDWord;
 
 PPasoHeader = ^TPasoHeader;
 TPasoHeader = packed record
  Identity, MachineType,
  ObjType,
  EntryOffset, EntrySec: TPasoDWord;
  
  SecCount, SecOffset,
  ImpCount, ImpOffset,
  ExpCount, ExpOffset,
  RelCount, RelOffset,
  SymCount, SymOffset,
  StrOffset: TPasoInt;
 end;
 
 PPasoSection = ^TPasoSection;
 TPasoSection = packed record
  SecType,
  Flags,
  SecName, //String table offset
  Alignment,
  VAddr,
  Offset, Size: TPasoDWord;
 end;
 
 PPasoImport = ^TPasoImport;
 TPasoImport = packed record
  ImportName: TPasoDWord;
 end;

 PPasoRelocation = ^TPasoRelocation;
 TPasoRelocation = packed record
  RelocType, IndexType: TPasoWord;
  Index, //Symbol or section table offset
  Section,
  Offset: TPasoDWord;
 end;

 PPasoSymbol = ^TPasoSymbol;
 TPasoSymbol = packed record
  SymbolType, SymbolBind: TPasoWord;
  
  SymbolName, //String table offset
  Section,
  Offset,
  Size: TPasoDWord;
 end;

implementation

end.

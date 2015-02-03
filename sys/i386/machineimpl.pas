unit machineimpl;

interface

uses vgaoutput, machine, debugger, smp, x86exceptions,
     pc;

type
 PContext = ^TContext;
 TContext = packed record
  gs,fs,es,ds: DWord;//4
  edi,esi,ebp,esp,ebx,edx,ecx,eax: DWord;//8
  HandlerTable: pointer;//1
  int, errorcode: DWord;//2
  eip,cs,eflags,useresp,//4
  ss: DWord;
 end;

const
 ApicInterruptVector = $A0;

procedure InitializeSpecifics;

implementation

uses heapmgr, apic, gdt, idt, tss, io, schedulers, x86scheduling, addressspace, x86mmu;

type

 { TX86Machine }

 TX86Machine = class(TMachine)
 protected
  function GetProcIndex: PtrInt; override;
 public
  procedure EnableInterrupts; override;
  procedure DisableInterrupts; override;

  function CreateContext(Entry, Data, Stack: Pointer; StackSize: PtrInt; var CtxSize: PtrInt): Pointer; override;
  function CreateAddressSpace: TAddressSpace; override;
 end;
 
 Tx86Processor = class(TProcessor)
 private
  fPID: PtrInt;
  fIDt: TIDT;
  
  fTSS: TTSS;
  fTSSStack: Pointer;
  fTSSSel: word;
 protected
  procedure Load;
  procedure IntHandler(Vector: Byte; var Ctx; CtxSize: PtrInt);
 public
  constructor Create(ID: PtrInt);
  destructor Destroy; override;
 end;
 
 TAP = class(Tx86Processor)
 private
 public
  procedure Boot;
  
  constructor Create(ID: PtrInt);
 end;
 
 TBSP = class(Tx86Processor)
  constructor Create;
 end;

const
 TSSStackSize = 1024*4;

{$asmmode intel}

procedure Tx86Processor.IntHandler(Vector: Byte; var Ctx; CtxSize: PtrInt);
begin
	Mach.ServiceInterrupt(Vector, Ctx, CtxSize);
end;

procedure Tx86Processor.Load;
begin
	LogDebug('Loading GDT', ssMachine);
	GDTLoad(SystemGDT);
	LogDebug('Loading TSS selector', ssMachine);
	LoadTSS(fTSSSel);
	LogDebug('Loading IDT', ssMachine);
	IDTLoad(fIDT);
	
	WriteCR0((ReadCR0 or $22) and not(12)); 
	WriteCR4(ReadCR4 or $600);
	
	LAPICEnable;
	LAPICSetCurrentCPU(fPID);
	LAPICSetupPeriodicTimer(5, ApicInterruptVector, 30000);
end;

constructor Tx86Processor.Create(ID: PtrInt);
begin
	inherited Create;
	fPID := ID;
	LogDebug('Initializing IDT', ssMachine);
	IDTInit(fIDT);
	IDTSetHandler(fIDT, @IntHandler);
	
	LogDebug('Initializing TSS', ssMachine);
	fTSSStack := GetMem(TSSStackSize);
	InitTSS(fTSS, PtrUInt(fTSSStack)+TSSStackSize-8);
	fTSSSel := GDTGetTSSDesc(SystemGDT, fTSS) or 3;
end;

destructor Tx86Processor.Destroy;
begin
	FreeMem(fTSSStack);
	inherited Destroy;
end;

procedure TAP.Boot;
begin
	
end;

constructor TAP.Create(ID: PtrInt);
begin
	inherited Create(id);
	Boot;
end;

constructor TBSP.Create;
begin
	inherited Create(0);
	Load;
end;

function TX86Machine.GetProcIndex: PtrInt;
begin
	result := LAPICGetCurrentCPU;
end;

procedure TX86Machine.EnableInterrupts; assembler; nostackframe;
asm
  sti
end;

procedure TX86Machine.DisableInterrupts; assembler; nostackframe;
asm
  cli
end;

function TX86Machine.CreateContext(Entry, Data, Stack: Pointer; StackSize: PtrInt; var CtxSize: PtrInt): Pointer;
begin
	result := GetMem(sizeof(TContext));
	FillChar(pbyte(result)^, sizeof(TContext), 0);
	
	ctxsize := sizeof(TContext);
	
	PContext(result)^.cs := $1B;
	PContext(result)^.ds := $23;
	PContext(result)^.es := $23;
	PContext(result)^.fs := $23;
	PContext(result)^.gs := $23;
	PContext(result)^.ss := $23;
	
	PContext(result)^.ESP := PtrUInt(Stack)+ptruint(StackSize);
	//TODO: Push thread exit address
	PContext(result)^.EBP := PContext(result)^.ESP;
	PContext(result)^.UserESP := PContext(result)^.ESP;
	
	PContext(result)^.EIP := PtrUInt(Entry);
	
	PContext(result)^.EFLAGS := $3202;
end;

function TX86Machine.CreateAddressSpace: TAddressSpace;
begin
	result := TX86AddressSpace.Create;
end;

procedure InitializeSpecifics;
var i: longint;
begin
	InitializeMachine(TX86Machine);
	
	LogInfo('Registering BSP', ssMachine);
	Mach.RegisterProcessor(TBSP.Create);
	
	if SMPConfig.HasSMP then
	begin
		LogInfo('Registering SMP processors', ssMachine);
		for i := 1 to SMPConfig.CPUCount-1 do
		begin
			LogInfo(' Registering APs', ssMachine);
			Mach.RegisterProcessor(TAP.Create(i));
		end;
	end;
	
	InitializePC;
	InitializeX86Exceptions;
	
	LogInfo('Initializing scheduler manager', ssScheduler);
	Scheduler := Tx86SchedulerManager.Create;
end;

end.

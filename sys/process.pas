unit process;

interface

uses machine, cclasses, handles, threadstorage, threads;

const
 DefaultStacksize = 1024;

type
 TObjectMode = (omUser, omKernel);
 
 TProcess = class(TKernelObject)
 private
  fThreads: TDictionary;
  fTlsMan: TTLSManager;
 public
  function HasThread(ThreadID: THandle): boolean;
  
  function BeginThread(EntryPoint, Data: Pointer; Stacksize: Ptrint = DefaultStacksize): THandle;
  procedure EndThread(H: THandle);
  
  constructor Create;
  destructor Destroy; override;
  
  property TLS: TTLSManager read fTlsMan;
 end;

function GetProcess: TProcess;
function GetProcessID: THandle;

implementation

uses schedulers;

function GetProcess: TProcess;
var t: TThread;
begin
	t := GetThread;
	
	if assigned(t) then
		result := TProcess(t.Owner)
	else
		result := nil;
end;

function GetProcessID: THandle;
var t: TProcess;
begin
	t := GetProcess;
	if assigned(t) then
		result := t.Handle
	else
		result := InvalidHandle;
end;

function TProcess.HasThread(ThreadID: THandle): boolean;
begin
	result := Assigned(fThreads[ThreadID]);
end;

function TProcess.BeginThread(EntryPoint, Data: Pointer; Stacksize: Ptrint = DefaultStacksize): THandle;
var t: TThread;
	 ctx: Pointer;
	 ctxSize,i : PtrInt;
begin
	t := TThread.Create(self, StackSize);
	ctx := Mach.CreateContext(Entrypoint, Data, t.stack, StackSize, ctxsize);
	t.SetContext(pbyte(ctx)^, ctxsize);
	FreeMem(ctx);
	
	result := t.Handle;
	fThreads.Add(result, t);
	
	Scheduler.AddThread(t);
end;

procedure TProcess.EndThread(H: THandle);
begin
	fTHreads.Delete(H);
end;

constructor TProcess.Create;
begin
	inherited Create;
	fTlsMan := TTLSManager.Create;
	fThreads := TDictionary.Create(nil);
end;

destructor TProcess.Destroy;
begin
	fTlsMan.Free;
	inherited Destroy;
end;

end.

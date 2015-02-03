program kernel;

uses
  sysutils,
  applications, modules, debugger, hal, machine, exceptions, services,
  machineimpl,
  handles, vfs,
  schedulers, schedulerRR, threads, process,
  bochsgfx;

procedure test;
begin
  writeln('test');
  while true do;
end;

procedure test2;
begin
  writeln('test2');
  while true do;
end;

var
  t: TThread;
  ctxsize: PtrInt;
  ctx: Pointer;
  p: TProcess;
begin
  LogInfo('Initializing machine', ssKernel);
	MachineImpl.InitializeSpecifics;

	LogInfo('Initializing schedulers', ssKernel);
	Scheduler.RegisterSchedulers(TSchedulerRoundRobin);

	LogInfo('Kernel booted', ssKernel);

	//LogInfo('Installing bochs gfx adapter', ssKernel);
	//DevManager.AddDevice(TBochsGFX.Create.DeviceDescriptor);

	{try
		TApplication.Create('boot:test');
	except
		on e: exception do
			LogError(pchar(e.message), ssKernel);
  end;}

  p:=TProcess.Create;
  p.BeginThread(@test,nil);
  p.BeginThread(@test2,nil);

	LogDebug('Enabling interrupts', ssKernel);
	Mach.EnableInterrupts;
	LogInfo('Done', ssKernel);

  while true do;
end.

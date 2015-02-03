program kernel;

uses
  sysutils,
  applications, modules, debugger, hal, machine, exceptions, services,
  machineimpl,
  devicetypes,videodev,
  handles, vfs,
  schedulers, schedulerRR, threads, process,
  bochsgfx;

var
  p: TProcess;
  b: TBochsGFX;
  dev: TVideoDevice;

procedure test;
begin
  while true do
    dev.AccelIntf.DrawLine(dev.AccelIntf.GetScreenSurface, random(400-20)+10, random(280)+10, random(400-20)+10, random(280)+10, random(255), random(255), 0);
end;

procedure test2;
begin
  while true do
    dev.AccelIntf.DrawLine(dev.AccelIntf.GetScreenSurface, random(400-20)+410, random(280)+310, random(400-20)+410, random(280)+310, random(255), 0, random(255));
end;

procedure test3;
begin
  while true do
    dev.AccelIntf.DrawLine(dev.AccelIntf.GetScreenSurface, random(400-20)+10, random(280)+310, random(400-20)+10, random(280)+310, 0, random(255), random(255));
end;

procedure test4;
begin
  while true do
    dev.AccelIntf.DrawLine(dev.AccelIntf.GetScreenSurface, random(400-20)+410, random(280)+10, random(400-20)+410, random(280)+10, random(128), random(255), random(128));
end;

begin
  LogInfo('Initializing machine', ssKernel);
	MachineImpl.InitializeSpecifics;

	LogInfo('Initializing schedulers', ssKernel);
	Scheduler.RegisterSchedulers(TSchedulerRoundRobin);

	LogInfo('Kernel booted', ssKernel);

  b:=TBochsGFX.Create;
  dev:=TVideoDevice(GetDeviceImplementation(b.DeviceDescriptor));
  dev.SetMode(0);

  p:=TProcess.Create;
  p.BeginThread(@test,nil);
  p.BeginThread(@test2,nil);
  p.BeginThread(@test3,nil);
  p.BeginThread(@test4,nil);

	Mach.EnableInterrupts;

  while true do;
end.

unit x86scheduling;

interface

uses debugger, machine, machineimpl, threads, schedulers, heapmgr;

type
  Tx86SchedulerManager = class(TSchedulerManager)
  private
    fISR, fFPU: TInterruptEvent;
    fCurrentFPUThread: TThread;
    procedure OnScheduling(var Ctx; CtxSize: PtrInt; var done: boolean);
    procedure OnNumError(var Ctx; CtxSize: PtrInt; var done: boolean);
  public
    procedure RemoveThread(T: TThread); override;

    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses io, apic;

procedure Tx86SchedulerManager.OnNumError(var Ctx; CtxSize: PtrInt; var done: boolean);
  begin
    done := True;

    ClearTS;

    if Assigned(fCurrentFPUThread) then
      begin
        if not Assigned(fCurrentFPUThread.ThreadData) then
          fCurrentFPUThread.ThreadData := GetAlignedMem(512, 16);
        SaveFPU(fCurrentFPUThread.ThreadData);
      end;

    fCurrentFPUThread := Scheduler.GetCurrentScheduler.GetCurrentThread;

    if not Assigned(fCurrentFPUThread) then
      exit;

    if not Assigned(fCurrentFPUThread.ThreadData) then
      begin
        fCurrentFPUThread.ThreadData := GetAlignedMem(512, 16);
        ResetFPU;
      end
    else
      RestoreFPU(fCurrentFPUThread.ThreadData);

    done := True;
  end;

procedure Tx86SchedulerManager.OnScheduling(var Ctx; CtxSize: PtrInt; var done: boolean);
  var
    ts: boolean;
  begin
    if GetCurrentScheduler.Schedule(ctx, ctxsize, ts) then
      begin
        //writeln(TContext(ctx).gs, ' - ', TContext(ctx).fs, ' - ', TContext(ctx).es, ' - ', TContext(ctx).ds);
        if ts then
          SetTS();
      end;

    done := True;
    LAPICSignalEOI;
  end;

procedure Tx86SchedulerManager.RemoveThread(T: TThread);
  begin
    inherited RemoveThread(t);
    if t = fCurrentFPUThread then
      fCurrentFPUThread := nil;
  end;

constructor Tx86SchedulerManager.Create;
  begin
    inherited Create;
    fCurrentFPUThread := nil;

    fISR := TInterruptEvent.Create(ApicInterruptVector, vhAllProcessors);
    fISR.OnEvent := @OnScheduling;

    fFPU := TInterruptEvent.Create(7, vhAllProcessors);
    fFPU.OnEvent := @OnNumError;
  end;

destructor Tx86SchedulerManager.Destroy;
  begin
    fISR.Free;
    inherited Destroy;
  end;

end.

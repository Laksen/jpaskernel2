unit debugger;

interface

type
  TSubsystem = (ssApplications, ssVFS, ssNetwork, ssUI, ssHal, ssKernel, ssScheduler, ssDebugger, ssMachine);
  TEventLevel = (evDebug, evInfo, evWarning, evError, evFatal);

  TKernelEvent = class
  private
    fEvent: ansistring;
    fLevel: TEventLevel;
    fSubsystem: TSubsystem;
  public
    constructor Create(const AEvent: ansistring; SubSystem: TSubSystem; Level: TEventLevel);

    property Event: ansistring read fEvent;
    property Subsystem: TSubsystem read fSubsystem;
    property Level: TEventLevel read fLevel;
  end;

  TKernelEventManager = class
  protected
    procedure RaiseEvent(Event: TKernelEvent); virtual; abstract;
  public
    procedure Log(Event: TKernelEvent);
  end;

  TKernelLog = class(TKernelEventManager)
  protected
    procedure RaiseEvent(Event: TKernelEvent); override;
  end;

  TKernelOutput = class(TKernelEventManager)
  protected
    procedure RaiseEvent(Event: TKernelEvent); override;
  end;

procedure LogDebug(const Event: ansistring; Subsystem: TSubsystem);
procedure LogInfo(const Event: ansistring; Subsystem: TSubsystem);
procedure LogWarning(const Event: ansistring; Subsystem: TSubsystem);
procedure LogError(const Event: ansistring; Subsystem: TSubsystem);
procedure LogFatal(const Event: ansistring; Subsystem: TSubsystem);

var
  KernelEvents: TKernelEventManager;

implementation

uses cclasses, heapmgr;

procedure Log(Event: TKernelEvent); inline;
  begin
    if assigned(KernelEvents) then
      KernelEvents.Log(Event);
  end;

procedure LogDebug(const Event: ansistring; Subsystem: TSubsystem);
  begin
    Log(TKernelEvent.Create(Event, subsystem, evDebug));
  end;

procedure LogInfo(const Event: ansistring; Subsystem: TSubsystem);
  begin
    Log(TKernelEvent.Create(Event, subsystem, evInfo));
  end;

procedure LogWarning(const Event: ansistring; Subsystem: TSubsystem);
  begin
    Log(TKernelEvent.Create(Event, subsystem, evWarning));
  end;

procedure LogError(const Event: ansistring; Subsystem: TSubsystem);
  begin
    Log(TKernelEvent.Create(Event, subsystem, evError));
  end;

procedure LogFatal(const Event: ansistring; Subsystem: TSubsystem);
  begin
    Log(TKernelEvent.Create(Event, subsystem, evFatal));
  end;

procedure TKernelEventManager.Log(Event: TKernelEvent);
  begin
    RaiseEvent(Event);
    Event.Free;
  end;

procedure TKernelLog.RaiseEvent(Event: TKernelEvent);
  begin

  end;

procedure TKernelOutput.RaiseEvent(Event: TKernelEvent);
  const
    EventStr: array[TEventLevel] of PChar = ('Debug:   ',
      'Info:    ',
      'Warning: ',
      'Error:   ',
      'Fatal:   ');
  begin
    writeln(EventStr[Event.Level], Event.Event);
  end;

constructor TKernelEvent.Create(const AEvent: ansistring; SubSystem: TSubSystem; Level: TEventLevel);
  begin
    inherited Create;
    fEvent := AEvent;
    fSubSystem := SubSystem;
    fLevel := Level;
  end;

initialization
  KernelEvents := TKernelOutput.Create;

end.

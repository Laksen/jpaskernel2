unit debugger;

interface

type
  TSubsystem = (ssApplications, ssVFS, ssNetwork, ssUI, ssHal, ssKernel, ssScheduler, ssDebugger, ssMachine);
  TEventLevel = (evDebug, evInfo, evWarning, evError, evFatal);

  TKernelEvent = class
  private
    fEvent: PChar;
    fLevel: TEventLevel;
    fSubsystem: TSubsystem;
  public
    constructor Create(AEvent: PChar; SubSystem: TSubSystem; Level: TEventLevel);
    destructor Destroy; override;

    property Event: PChar read fEvent;
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

procedure LogDebug(Event: PChar; Subsystem: TSubsystem);
procedure LogInfo(Event: PChar; Subsystem: TSubsystem);
procedure LogWarning(Event: PChar; Subsystem: TSubsystem);
procedure LogError(Event: PChar; Subsystem: TSubsystem);
procedure LogFatal(Event: PChar; Subsystem: TSubsystem);

var
  KernelEvents: TKernelEventManager;

implementation

uses cclasses, heapmgr;

procedure LogDebug(Event: PChar; Subsystem: TSubsystem);
  begin
    KernelEvents.Log(TKernelEvent.Create(Event, subsystem, evDebug));
  end;

procedure LogInfo(Event: PChar; Subsystem: TSubsystem);
  begin
    KernelEvents.Log(TKernelEvent.Create(Event, subsystem, evInfo));
  end;

procedure LogWarning(Event: PChar; Subsystem: TSubsystem);
  begin
    KernelEvents.Log(TKernelEvent.Create(Event, subsystem, evWarning));
  end;

procedure LogError(Event: PChar; Subsystem: TSubsystem);
  begin
    KernelEvents.Log(TKernelEvent.Create(Event, subsystem, evError));
  end;

procedure LogFatal(Event: PChar; Subsystem: TSubsystem);
  begin
    KernelEvents.Log(TKernelEvent.Create(Event, subsystem, evFatal));
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

constructor TKernelEvent.Create(AEvent: PChar; SubSystem: TSubSystem; Level: TEventLevel);
  begin
    inherited Create;
    fEvent := StrDup(AEvent);
    fSubSystem := SubSystem;
    fLevel := Level;
  end;

destructor TKernelEvent.Destroy;
  begin
    StrDispose(fEvent);
    inherited Destroy;
  end;

initialization
  KernelEvents := TKernelOutput.Create;

end.

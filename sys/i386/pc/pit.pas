unit pit;

interface

procedure InitializePIT;

implementation

uses debugger, machine, machineimpl;

type
  TPit = class(TTimer)
  private
    fIntVector: TInterruptEvent;
    fCtr: int64;

    fNextActivation, fInterval: int64;

    fIntervalCallback: TInterruptNotification;
    procedure Handle(var Ctx; CtxSize: PtrInt; var done: boolean);
  public
    function GetMsTick: PtrInt; override;
    function GetNsTick: PtrInt; override;

    procedure SetCallback(IntervalMS: PtrInt; Callback: TInterruptNotification); override;

    constructor Create;
    destructor Destroy; override;
  end;

procedure TPit.Handle(var Ctx; CtxSize: PtrInt; var done: boolean);
  begin
    done := True;
    Inc(fCtr);

    if (fCtr >= fNextActivation) and assigned(fIntervalCallback) then
      begin
        fNextActivation := fCtr + fInterval;
        fIntervalCallback(ctx, ctxsize, done);
      end;
  end;

procedure TPit.SetCallback(IntervalMS: PtrInt; Callback: TInterruptNotification);
  begin
    fInterval := IntervalMS;
    fNextActivation := fCtr + fInterval;

    fIntervalCallback := Callback;
  end;

function TPit.GetMsTick: PtrInt;
  begin
    Result := fCtr;
  end;

function TPit.GetNsTick: PtrInt;
  begin
    Result := fCtr * 1000;
  end;

constructor TPit.Create;
  begin
    inherited Create;
    fCtr := 0;
    fIntervalCallback := nil;
    fIntVector := TInterruptEvent.Create(32);
    fIntVector.OnEvent := @Handle;
  end;

destructor TPit.Destroy;
  begin
    fIntVector.Free;
    inherited Destroy;
  end;

procedure InitializePIT;
  begin
    LogInfo('Registering PIT', ssMachine);
    Mach.RegisterTimer(TPit.Create);
  end;


end.

unit schedulers;

interface

uses cclasses, machine, threads, debugger;

type
  TSchedulerClass = class of TScheduler;

  TScheduler = class
  private
    fPID: PtrInt;
    fThreads: TList;
  protected
    function GetThreadCount: PtrInt;
    function GetThread(Index: PtrInt): TThread;

    function FindNewThread(out old, New: TThread): boolean; virtual; abstract;
  public
    function GetCurrentThread: TThread; virtual; abstract;

    function Schedule(var ctx; CtxSize: PtrInt; var TaskSwitched: boolean): boolean;

    procedure AddThread(T: TThread); virtual;
    procedure RemoveThread(T: TThread); virtual;

    constructor Create(ProcID: PtrInt); virtual;
    destructor Destroy; override;
  end;

  TSchedulerManagerClass = class of TSchedulerManager;

  TSchedulerManager = class
  private
    fProcCount: PtrInt;
    fSchedulers: TDictionary;
  protected
    function GetScheduler(Index: PtrInt): TScheduler;
  public
    function GetCurrentScheduler: TScheduler;

    procedure RegisterSchedulers(Typ: TSchedulerClass);

    procedure AddThread(T: TThread);
    procedure RemoveThread(T: TThread); virtual;

    constructor Create; virtual;
    destructor Destroy; override;
  end;

var
  Scheduler: TSchedulerManager;

implementation

uses machineimpl;

function TScheduler.Schedule(var ctx; CtxSize: PtrInt; var TaskSwitched: boolean): boolean;
  var
    new, cur: TThread;
  begin
    Result := FindNewThread(cur, new);

    taskswitched := new <> cur;

    if taskswitched then
      begin
        if assigned(cur) then
          cur.SetContext(ctx, ctxsize);

        if Result and assigned(new) then
          new.GetContext(ctx, ctxsize);
      end;
  end;

function TScheduler.GetThread(Index: PtrInt): TThread;
  begin
    Result := TThread(fThreads[Index]);
  end;

function TScheduler.GetThreadCount: PtrInt;
  begin
    Result := fThreads.Count;
  end;

procedure TScheduler.AddThread(T: TThread);
  begin
    fThreads.Add(T);
  end;

procedure TScheduler.RemoveThread(T: TThread);
  begin
    fThreads.Remove(T);
  end;

constructor TScheduler.Create(ProcID: PtrInt);
  begin
    inherited Create;
    fThreads := TList.Create(nil);
    fPID := ProcID;
  end;

destructor TScheduler.Destroy;
  begin
    fThreads.Free;
    inherited Destroy;
  end;

function TSchedulerManager.GetCurrentScheduler: TScheduler;
  begin
    Result := GetScheduler(mach.CurrentProcessorIndex);
  end;

procedure TSchedulerManager.AddThread(T: TThread);
  begin
    TScheduler(fSchedulers[0]).AddThread(t);
  end;

procedure TSchedulerManager.RemoveThread(T: TThread);
  begin
    TScheduler(fSchedulers[0]).RemoveThread(t);
  end;

procedure TSchedulerManager.RegisterSchedulers(Typ: TSchedulerClass);
  var
    i: PtrInt;
  begin
    fProcCount := Mach.ProcessorCount;

    for i := 0 to fProcCount - 1 do
      fSchedulers.Add(i, Typ.Create(i));
  end;

function TSchedulerManager.GetScheduler(Index: PtrInt): TScheduler;
  begin
    Result := TScheduler(fSchedulers[index]);
  end;

constructor TSchedulerManager.Create;
  begin
    inherited Create;
    fProcCount := 0;
    fSchedulers := TDictionary.Create(nil);
  end;

destructor TSchedulerManager.Destroy;
  begin
    fSchedulers.Free;
    inherited Destroy;
  end;

end.

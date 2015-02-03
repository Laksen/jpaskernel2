unit threads;

interface

uses handles, threadstorage;

type
  TThread = class(TKernelObject)
  private
    fStacksize: Ptrint;
    fStack, fContext, fThreadData: Pointer;
    fOwner: TObject;
    fTLS: TTLS;
  public
    procedure SetContext(const Ctx; CtxSize: PtrInt);
    procedure GetContext(var Ctx; CtxSize: PtrInt);

    constructor Create(Owner: TObject; StackSize: PtrInt);
    destructor Destroy; override;

    property TLS: TTLS read fTLS;
    property Owner: TObject read fOwner;
    property Stack: Pointer read fStack;
    property StackSize: PtrInt read fStacksize;
    property ThreadData: pointer read fThreadData write fThreadData;
  end;

function GetThread: TThread;
function GetThreadID: PtrInt;

implementation

uses schedulers, process, heapmgr;

function GetThread: TThread;
  begin
    Result := Scheduler.GetCurrentScheduler.GetCurrentThread();
  end;

function GetThreadID: PtrInt;
  var
    t: TThread;
  begin
    t := GetThread;

    if assigned(t) then
      Result := t.Handle
    else
      Result := InvalidHandle;
  end;

procedure TThread.SetContext(const Ctx; CtxSize: PtrInt);
  begin
    if not assigned(fContext) then
      fContext := GetMem(CtxSize);
    move(Ctx, pbyte(fContext)^, CtxSize);
  end;

procedure TThread.GetContext(var Ctx; CtxSize: PtrInt);
  begin
    if assigned(fContext) then
      move(pbyte(fContext)^, Ctx, CtxSize);
  end;

constructor TThread.Create(Owner: TObject; StackSize: PtrInt);
  begin
    inherited Create;
    fOwner := Owner;
    fContext := nil;
    fTLS := TTLS.Create(TProcess(Owner).TLS);
    fThreadData := nil;
    fStacksize := StackSize;
    fStack := GetMem(StackSize);
  end;

destructor TThread.Destroy;
  begin
    if assigned(fStack) then
      freemem(fStack);
    if assigned(fThreadData) then
      freemem(fThreadData);
    if Assigned(fContext) then
      FreeMem(fContext);
    fTLS.Free;
    inherited Destroy;
  end;

end.

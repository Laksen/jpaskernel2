unit machine;

interface

uses addressspace, cclasses, debugger;

type
  TCurrentProcIndexFunc = function: PtrInt;

  TCreateContextFunc = function(Entry, Data, Stack: Pointer; StackSize: PtrInt; var CtxSize: PtrInt): Pointer;

  TInterruptRequest = procedure(Vector: byte; var Ctx; CtxSize: PtrInt) of object;
  TInterruptNotification = procedure(var Ctx; CtxSize: PtrInt; var done: boolean) of object;

  TTimer = class
    function GetMsTick: PtrInt; virtual;
    function GetNsTick: PtrInt; virtual;

    procedure SetCallback(IntervalMS: PtrInt; Callback: TInterruptNotification); virtual;
  end;

  TProcessor = class

  end;

  TVectorHandling = (vhAllProcessors, vhOneProcessor);

  TInterruptHandler = class
  private
    fVect: byte;
    fNext: TInterruptHandler;
  protected
    procedure HandleVector(var Ctx; CtxSize: PtrInt; var done: boolean); virtual;
  public
    constructor Create(Vect: byte; Handling: TVectorHandling = vhOneProcessor); virtual;
    destructor Destroy; override;

    property Vector: byte read fVect;
    property Next: TInterruptHandler read fNext write fNext;
  end;

  TInterruptEvent = class(TInterruptHandler)
  private
    fOnEvent: TInterruptNotification;
  protected
    procedure HandleVector(var Ctx; CtxSize: PtrInt; var done: boolean); override;
  public
    constructor Create(Vect: byte; Handling: TVectorHandling = vhOneProcessor); override;

    property OnEvent: TInterruptNotification read fOnEvent write fOnEvent;
  end;

  TInterruptTable = class
  private
    fItems: array[0..255] of TInterruptHandler;
    fLock: longint;
    procedure GetLock;
    procedure UnLock;
  protected
    procedure AddHandler(Handler: TInterruptHandler);
    procedure RemoveHandler(Handler: TInterruptHandler);
  public
    procedure ServiceInterrupt(vector: byte; var Ctx; CtxSize: PtrInt);

    constructor Create;
    destructor Destroy; override;
  end;

  TMachinClass = class of TMachine;

  { TMachine }

  TMachine = class
  private
    fProcessors: TList;
    fTimer: TTimer;
    fInterrupts: TInterruptTable;

    function GetProcCount: PtrInt;
    function GetProcessor(index: PtrInt): TProcessor;
    function GetCurrentProcessor: TProcessor;
  protected
    function GetProcIndex: PtrInt; virtual;

    property InterruptTable: TInterruptTable read fInterrupts;
  public
    procedure ServiceInterrupt(vector: byte; var Ctx; CtxSize: PtrInt);

    procedure RegisterTimer(Timer: TTimer);
    procedure RegisterProcessor(Proc: TProcessor);

    procedure EnableInterrupts; virtual; abstract;
    procedure DisableInterrupts; virtual; abstract;

    function GetMsTick: PtrInt;
    function GetNsTick: PtrInt;

    function CreateContext(Entry, Data, Stack: Pointer; StackSize: PtrInt; var CtxSize: PtrInt): Pointer; virtual;
    function CreateAddressSpace: TAddressSpace; virtual;

    constructor Create;
    destructor Destroy; override;

    property ProcessorCount: PtrInt read GetProcCount;
    property Processors[index: PtrInt]: TProcessor read GetProcessor;
    property CurrentProcessorIndex: PtrInt read GetProcIndex;
    property CurrentProcessor: TProcessor read GetCurrentProcessor;
  end;

var
  Mach: TMachine;

procedure InitializeMachine(Cls: TMachinClass);

implementation

uses exceptions;

function TTimer.GetMsTick: PtrInt;
  begin
    Result := 0;
  end;

function TTimer.GetNsTick: PtrInt;
  begin
    Result := 0;
  end;

procedure TTimer.SetCallback(IntervalMS: PtrInt; Callback: TInterruptNotification);
  begin

  end;

// TMachine

function TMachine.GetProcCount: PtrInt;
  begin
    Result := fProcessors.Count;
  end;

function TMachine.GetProcIndex: PtrInt;
  begin
    Result := 0;
  end;

function TMachine.GetProcessor(index: PtrInt): TProcessor;
  begin
    Result := TProcessor(fProcessors[index]);
  end;

function TMachine.GetCurrentProcessor: TProcessor;
  begin
    Result := TProcessor(fProcessors[GetProcIndex]);
  end;

procedure TMachine.RegisterProcessor(Proc: TProcessor);
  begin
    LogDebug('Registering processor', ssMachine);
    fProcessors.Add(Proc);
    LogInfo('Registered processor', ssMachine);
  end;

procedure TMachine.RegisterTimer(Timer: TTimer);
  begin
    fTimer := Timer;
    LogInfo('Registered timer', ssMachine);
  end;

function TMachine.GetMsTick: PtrInt;
  begin
    if assigned(fTimer) then
      Result := fTimer.GetMsTick
    else
      Result := 0;
  end;

function TMachine.GetNsTick: PtrInt;
  begin
    if assigned(fTimer) then
      Result := fTimer.GetNsTick
    else
      Result := 0;
  end;

function TMachine.CreateContext(Entry, Data, Stack: Pointer; StackSize: PtrInt; var CtxSize: PtrInt): Pointer;
  begin
    Result := nil;
  end;

function TMachine.CreateAddressSpace: TAddressSpace;
  begin
    Result := TAddressSpace.Create;
  end;

procedure TMachine.ServiceInterrupt(vector: byte; var Ctx; CtxSize: PtrInt);
  begin
    InterruptTable.ServiceInterrupt(vector, ctx, ctxsize);
  end;

constructor TMachine.Create;
  begin
    inherited Create;
    fTimer := nil;
    fProcessors := TList.Create(nil);
    fInterrupts := TInterruptTable.Create;
  end;

destructor TMachine.Destroy;
  begin
    fInterrupts.Free;
    fProcessors.Free;
    inherited Destroy;
  end;

procedure TInterruptEvent.HandleVector(var Ctx; CtxSize: PtrInt; var done: boolean);
  begin
    if assigned(OnEvent) then
      OnEvent(Ctx, CtxSize, Done)
    else
      done := False;
  end;

constructor TInterruptEvent.Create(Vect: byte; Handling: TVectorHandling = vhOneProcessor);
  begin
    inherited Create(Vect, Handling);
    fOnEvent := nil;
  end;

procedure TInterruptHandler.HandleVector(var Ctx; CtxSize: PtrInt; var done: boolean);
  begin
    done := False;
  end;

constructor TInterruptHandler.Create(Vect: byte; Handling: TVectorHandling = vhOneProcessor);
  begin
    inherited Create;
    fVect := vect;
    fNext := nil;

    Mach.InterruptTable.AddHandler(Self);
  end;

destructor TInterruptHandler.Destroy;
  begin
    Mach.InterruptTable.RemoveHandler(Self);
    inherited Destroy;
  end;

procedure TInterruptTable.GetLock;
  begin
    while InterlockedCompareExchange(fLock, 0, 1) <> 1 do ;
  end;

procedure TInterruptTable.UnLock;
  begin
    fLock := 1;
  end;

procedure TInterruptTable.ServiceInterrupt(vector: byte; var Ctx; CtxSize: PtrInt);
  var
    done: boolean;
    p: TInterruptHandler;
  begin
    p := fItems[vector];

    done := False;
    while (not done) and assigned(p) do
      begin
        p.HandleVector(ctx, ctxsize, done);
        p := p.Next;
      end;
  end;

procedure TInterruptTable.AddHandler(Handler: TInterruptHandler);
  var
    v: byte;
  begin
    if not assigned(handler) then
      exit;

    v := handler.Vector;

    GetLock;
    Handler.Next := fItems[v];
    fItems[v] := Handler;
    UnLock;
  end;

procedure TInterruptTable.RemoveHandler(Handler: TInterruptHandler);
  var
    p: TInterruptHandler;
    v: byte;
  begin
    if not assigned(handler) then
      exit;

    v := handler.Vector;

    p := fItems[v];

    GetLock;
    if p = Handler then
      fItems[v] := p.Next
    else
      begin
        while assigned(p.Next) do
          begin
            if p.Next = handler then
              begin
              p.Next := handler.Next;
              break;
              end;
            p := p.Next;
          end;
      end;
    UnLock;
  end;

constructor TInterruptTable.Create;
  var
    i: longint;
  begin
    inherited Create;
    fLock := 1;
    for i := 0 to 255 do
      fItems[i] := nil;
  end;

destructor TInterruptTable.Destroy;
  begin
    inherited Destroy;
  end;

procedure InitializeMachine(Cls: TMachinClass);
  begin
    LogInfo('Creating machine', ssMachine);
    Mach := Cls.Create;

    LogInfo('Creating exception manager', ssMachine);
    InitializeExceptions;
  end;

end.

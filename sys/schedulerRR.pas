unit schedulerRR;

interface

uses threads, schedulers;

type

  { TSchedulerRoundRobin }

  TSchedulerRoundRobin = class(TScheduler)
  private
    fCurrent: TThread;
    fCurrentID: PtrInt;
  protected
    function FindNewThread(out old, New: TThread): boolean; override;
  public
    function GetCurrentThread: TThread; override;

    procedure RemoveThread(T: TThread); override;

    constructor Create(ProcID: PtrInt); override;
  end;

implementation

function TSchedulerRoundRobin.GetCurrentThread: TThread;
  begin
    Result := fCurrent;
  end;

function TSchedulerRoundRobin.FindNewThread(out old, New: TThread): boolean;
  var
    t: PtrInt;
  begin
    Result := False;

    old := fCurrent;
    new := nil;

    t := GetThreadCount;
    if t <= 0 then
      exit;

    if not Assigned(fCurrent) then
      begin
        fCurrentID := 0;
        fCurrent := GetThread(fCurrentID);
        new := fCurrent;
      end
    else
      begin
        Inc(fCurrentID);
        if fCurrentID >= t then
          fCurrentID := 0;

        fCurrent := GetThread(fCurrentID);
        new := fCurrent;
      end;

    Result := True;
  end;

procedure TSchedulerRoundRobin.RemoveThread(T: TThread);
  begin
    inherited RemoveThread(t);

    if fCurrent = t then
      begin
        fCurrent := nil;
        fCurrentID := 0;
      end;
  end;

constructor TSchedulerRoundRobin.Create(ProcID: PtrInt);
  begin
    inherited Create(ProcID);
    fCurrent := nil;
    fCurrentID := 0;
  end;

end.

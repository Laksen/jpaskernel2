unit pc;

interface

procedure InitializePC;

implementation

uses pit;

procedure InitializePC;
begin
	InitializePIT;
end;

end.

unit exceptions;

interface

uses machine, debugger;

type
 TExceptionType = (etNone, etUndefined, etDivisionByZero, etGeneralError, etPageFault);
 
 TExceptionHandler = class(TInterruptHandler)
 protected
  function GetExceptionType: TExceptionType; virtual;
  function GetExceptionDescription: pchar; virtual;
 end;
 
 TExceptionManager = class
  procedure HandleException(Exception: TExceptionHandler; var Ctx; CtxSize: PtrInt; var done: boolean);
 end;

var ExceptionManager: TExceptionManager;

procedure InitializeExceptions;

implementation

function TExceptionHandler.GetExceptionType: TExceptionType;
begin
	result := etUndefined;
end;

function TExceptionHandler.GetExceptionDescription: pchar; 
begin
	result := 'Undefined';
end;

procedure TExceptionManager.HandleException(Exception: TExceptionHandler; var Ctx; CtxSize: PtrInt; var done: boolean);
begin
	LogFatal(Exception.GetExceptionDescription, ssKernel);
	while true do;
end;

procedure InitializeExceptions;
begin
	ExceptionManager := TExceptionManager.Create;
end;

end.

unit x86exceptions;

interface

uses exceptions;

type
 TX86ExceptionHandler = class(TExceptionHandler)
 private
  fType: TExceptionType;
  fMessage: PChar;
 protected
  procedure HandleVector(var Ctx; CtxSize: PtrInt; var done: boolean); override;
  
  function GetExceptionType: TExceptionType; override;
  function GetExceptionDescription: pchar; override;
 public
  constructor CreateException(Vect: byte; Message: pchar; ExType: TExceptionType);
 end;

procedure InitializeX86Exceptions;

implementation

uses machineimpl, debugger, handles, threads;

const
 ErrorMessages: array[0..31] of pchar = 
  ('Division By Zero Exception',
   'Debug Exception',
   'Non Maskable Interrupt Exception',
   'Breakpoint Exception',
   'Into Detected Overflow Exception',
   'Out of Bounds Exception',
   'Invalid Opcode Exception',
   'No Coprocessor Exception',
   'Double Fault Exception',
   'Coprocessor Segment Overrun Exception',
   'Bad TSS Exception',
   'Segment Not Present Exception',
   'Stack Fault Exception',
   'General Protection Fault Exception',
   'Page Fault Exception',
   'Unknown Interrupt Exception',
   'Coprocessor Fault Exception',
   'Alignment Check Exception (486+)',
   'Machine Check Exception (Pentium/586+)','','','','','','','','','','','','','');

procedure TX86ExceptionHandler.HandleVector(var Ctx; CtxSize: PtrInt; var done: boolean);
var i: ptrint;
begin
	writeln('Error at ', hexStr(TContext(ctx).eip,8));
	
	for i := 0 to 7 do write(pbyte(TContext(ctx).eip)[i],' '); writeln;
	
	writeln('Code: ', TContext(ctx).errorcode);
	writeln('EFLAGS: ', TContext(ctx).eflags);
	writeln('ESP: ', TContext(ctx).ESP,'(',TContext(ctx).UserESP,')');
	writeln('CS: ', hexStr(TContext(ctx).CS,8));
	writeln('DS: ', hexStr(TContext(ctx).DS,8));
	writeln('ES: ', hexStr(TContext(ctx).ES,8));
	writeln('FS: ', hexStr(TContext(ctx).FS,8));
	writeln('GS: ', hexStr(TContext(ctx).GS,8));
	writeln('SS: ', hexStr(TContext(ctx).SS,8));

  ExceptionManager.HandleException(self, Ctx, CtxSize, done);
end;

function TX86ExceptionHandler.GetExceptionType: TExceptionType;
begin
	result := fType;
end;

function TX86ExceptionHandler.GetExceptionDescription: pchar;
begin
	result := fMessage;
end;

constructor TX86ExceptionHandler.CreateException(Vect: byte; Message: pchar; ExType: TExceptionType);
begin
	inherited Create(Vect);
	fMessage := Message;
	fType := ExType;
end;

procedure InitializeX86Exceptions;
var i: longint;
begin
	LogInfo('Registering X86 exception handlers', ssMachine);
	for i := 0 to 31 do
		if i <> 7 then
			TX86ExceptionHandler.CreateException(i, ErrorMessages[i], etPageFault);
end;

end.

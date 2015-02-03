unit handles;

interface

type
 THandle = PtrInt;

const
 InvalidHandle = THandle(-1);

type
 TKernelObject = class
 private
  fHandle: THandle;
 protected
  function CanAccess: boolean; virtual;
  function CanDestroy: boolean; virtual;
 public
  constructor Create;
  destructor Destroy; override;
  
  property Handle: THandle read fHandle;
 end;
 
 TOwnedObject = class(TKernelObject)
 private
  fOwnerProc,
  fOwner: THandle;
 protected
  function CanAccess: boolean; override;
  function CanDestroy: boolean; override;
 public
  constructor Create;
 end;
 
 TProcessObject = class(TKernelObject)
 private
  fOwner: THandle;
 protected
  function CanAccess: boolean; override;
  function CanDestroy: boolean; override;
 public
  constructor Create;
 end;

function FindObject(Handle: THandle): TKernelObject;
procedure CloseHandle(Handle: THandle);

implementation

uses threads, process, cclasses, sysutils;

type
 THandles = specialize TGDictionary<THandle, TKernelObject>;
 THandleStack = specialize TGStack<THandle>;

var HandleList: THandles;
    FreeHandles: THandleStack;
    
    HandleCounter: THandle = 1;

function TKernelObject.CanAccess: boolean;
begin
	result := true;
end;

function TKernelObject.CanDestroy: boolean;
begin
	result := true;
end;

constructor TKernelObject.Create;
begin
	inherited Create;
   fHandle := FreeHandles.Pop;
   if fHandle = InvalidHandle then
      fHandle := InterlockedIncrement(HandleCounter);
   HandleList.Add(fHandle, self);
end;

destructor TKernelObject.Destroy;
begin
   HandleList.Delete(fHandle);
   FreeHandles.Push(fHandle);
   inherited Destroy;
end;

function TOwnedObject.CanAccess: boolean;
begin
	try
		result := GetProcessID = fOwnerProc;
	except
		result := false;
	end;
end;

function TOwnedObject.CanDestroy: boolean;
begin
	result := (GetThreadID = fOwner);
end;

constructor TOwnedObject.Create;
begin
	inherited Create;
	fOwner := GetThreadID;
	fOwnerProc := GetProcessID;
end;

function TProcessObject.CanAccess: boolean;
begin
	try
		result := GetProcessID = fOwner;
	except
		result := false;
	end;
end;

function TProcessObject.CanDestroy: boolean;
begin
	result := (GetProcessID = fOwner);
end;

constructor TProcessObject.Create;
begin
	inherited Create;
	fOwner := GetProcessID;
end;

function FindObject(Handle: THandle): TKernelObject;
begin
	if handle = InvalidHandle then
		raise exception.Create('Invalid handle');
	
   result := HandleList[handle];
	
	if not assigned(result) then
		raise Exception.Create('No object found');
	
	if not result.CanAccess then
		raise Exception.Create('Insufficient access rights');
end;

procedure CloseHandle(Handle: THandle);
var p: TKernelObject;
begin
   p := HandleList[handle];
   if assigned(p) then
		if p.CanDestroy then
			p.Free;
end;

initialization
   HandleList := THandles.Create(nil);
   FreeHandles := THandleStack.Create(InvalidHandle);

end.

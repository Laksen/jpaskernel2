unit services;

interface

uses cclasses;

type
 TServiceCall = class
 private
  fName: PChar;
  fFunc: TMethod;
  fParams: PtrInt;
 public
  constructor Create(AName: PChar; const Func: TMethod; ParamCount: PtrInt);
  
  property Name: PChar read fName;
  property Func: TMethod read fFunc;
  property Parameters: PtrInt read fParams;
 end;
 
 TServiceObject = class
 private
  fFuncs: TStringList;
  function GetCallCount: PtrInt;
  function GetCall(const index: PtrInt): TServiceCall;
  function GetCallByName(const index: PChar): TServiceCall;
 protected
  procedure RegisterFunction(const Name: PChar; Method: TMethod; Params: PtrInt);
  procedure RegisterFunctions; virtual;
 public
  constructor Create(ObjName: PChar);
  destructor Destroy; override;
  
  property CallCount: PtrInt read GetCallCount;
  property Calls[index: PtrInt]: TServiceCall read GetCall;
  property CallByName[index: PChar]: TServiceCall read GetCallByName;
 end;
 
 TServiceManager = class
 private
  fObjs: TStringList;
 protected
  procedure RegisterObject(Base: PChar; Obj: TServiceObject);
 public
  constructor Create;
  destructor Destroy; override;
 end;

var ServiceManager: TServiceManager;

function GetMethod(const Code, Data: pointer): TMethod;

implementation

function GetMethod(const Code, Data: pointer): TMethod;
begin
	result.Code := Code;
	result.Data := Data;
end;

procedure TServiceManager.RegisterObject(Base: PChar; Obj: TServiceObject);
begin
	fObjs.Add(Base, Obj);
end;

constructor TServiceManager.Create;
begin
	inherited Create;
	fObjs := TStringList.Create(nil);
end;

destructor TServiceManager.Destroy;
begin
	fObjs.Free;
	inherited Destroy;
end;

function TServiceObject.GetCallCount: PtrInt;
begin
	result := fFuncs.Count;
end;

function TServiceObject.GetCall(const index: PtrInt): TServiceCall;
begin
	result := TServiceCall(fFuncs.ItemByIndex[index]);
end;

function TServiceObject.GetCallByName(const index: PChar): TServiceCall;
begin
	result := TServiceCall(fFuncs[index]);
end;

constructor TServiceObject.Create(ObjName: PChar);
begin
	inherited Create;
	fFuncs := TStringList.Create(nil);
	if not assigned(ServiceManager) then
		ServiceManager := TServiceManager.Create;
	RegisterFunctions;
	ServiceManager.RegisterObject(ObjName, self);
end;

destructor TServiceObject.Destroy;
begin
	fFuncs.Free;
	inherited Destroy;
end;

procedure TServiceObject.RegisterFunction(const Name: PChar; Method: TMethod; Params: PtrInt);
begin
	fFuncs.Add(Name, TServiceCall.Create(Name, Method, Params));
end;

procedure TServiceObject.RegisterFunctions;
begin
end;

constructor TServiceCall.Create(AName: PChar; const Func: TMethod; ParamCount: PtrInt);
begin
	inherited Create;
	fName := Aname;
	fFunc := Func;
	fParams := ParamCount;
end;

end.

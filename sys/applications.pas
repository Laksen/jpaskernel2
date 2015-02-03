unit applications;

interface

uses addressSpace, process, threads, modules, objectloader;

type
 TApplication = class(TProcess)
 private
  fObj: TObj;
  fAddrSpace: TAddressSpace;
 public
  constructor Create(const Filename: Pchar);
  destructor Destroy; override;
 end;

implementation

uses machine;

constructor TApplication.Create(const Filename: Pchar);
begin
	inherited Create;
	fObj := TUserObj.Create(filename);
	
	fAddrSpace := Mach.CreateAddressSpace;
	
	fObj.Map(fAddrSpace);
	
	//Create main thread
	BeginThread(fObj.EntryPoint, nil);
end;

destructor TApplication.Destroy;
begin
	fAddrSpace.Free;
	fObj.Free;
	inherited Destroy;
end;

end.

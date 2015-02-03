unit threadstorage;

interface

uses cclasses;

type
 TTlsManager = class;
 
 TTls = class
 private
  fManager: TTlsManager;
  fTLS: TDictionary;
  function GetValue(const id: longint): pointer;
  procedure SetValue(const id: longint; value: pointer);
 protected
  procedure RegisterSlot(const id: longint);
  procedure UnregisterSlot(const id: longint);
 public
  constructor Create(Manager: TTlsManager);
  destructor Destroy; override;
 end;
 
 TTlsManager = class
 private
  fTLSs: TDictionary;
  fSlotCounter: longint;
  fSlots: TList;
  function GetValue(const id: longint): pointer;
  procedure SetValue(const id: longint; value: pointer);
  
  procedure IntDealloc(tls, id: pointer);
 protected
  procedure RegisterTls(storage: TTLS);
  procedure UnregisterTls(storage: TTLS);
 public
  function AllocSlot: longint;
  procedure DeallocSlot(const id: longint);
  
  constructor Create;
  destructor Destroy; override;
  
  property Value[index: longint]: pointer read GetValue write SetValue; default;
 end;

implementation

uses threads;

function TTls.GetValue(const id: longint): pointer;
begin
	result := fTLS[id];
end;

procedure TTls.SetValue(const id: longint; value: pointer);
begin
	fTLS[id] := value;
end;

procedure TTls.RegisterSlot(const id: longint);
begin
	fTLS.Add(id, nil);
end;

procedure TTls.UnregisterSlot(const id: longint);
begin
	fTLS.Delete(id);
end;

constructor TTls.Create(Manager: TTlsManager);
begin
	inherited Create;
	fManager := Manager;
	fManager.RegisterTls(self);
	fTls := TDictionary.Create(nil);
end;

destructor TTls.Destroy;
begin
	fTls.Free;
	fManager.UnregisterTls(self);
	inherited Destroy;
end;

function TTlsManager.GetValue(const id: longint): pointer;
begin
	result := nil;
end;

procedure TTlsManager.SetValue(const id: longint; value: pointer);
begin
	
end;

procedure TTlsManager.RegisterTls(storage: TTLS);
var i: longint;
begin
	fTLSs.Add(GetThreadID, storage);
	for i := 0 to fSlots.Count-1 do
		Storage.RegisterSlot(longint(fSlots[i]));
end;

procedure TTlsManager.UnregisterTls(storage: TTLS);
begin
	//TODO
	//fTLSs.Remove(storage);
end;

function TTlsManager.AllocSlot: longint;
begin
	result := InterlockedIncrement(fSlotCounter);
	fSlots.Add(pointer(result));
end;

procedure TTlsManager.IntDealloc(tls, id: pointer);
begin
	TTLS(tls).UnregisterSlot(longint(id));
end;

procedure TTlsManager.DeallocSlot(const id: longint);
begin
	fTLSs.ForEachCall(@IntDealloc, pointer(id));
	fSlots.Remove(pointer(id));
end;

constructor TTlsManager.Create;
begin
	inherited Create;
	fTLSs := TDictionary.Create(nil);
	fSlots := TList.Create(nil);
	fSlotCounter := 0;
end;

destructor TTlsManager.Destroy;
begin
	fSlots.Free;
	fTLSs.Free;
	inherited Destroy;
end;

end.

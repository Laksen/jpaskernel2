unit partition;

interface

uses storagedev;

type
 TPartition = class
  constructor Create(St: TStorageDevice; Offset, Count: PtrUInt);
 end;

implementation

constructor TPartition.Create(St: TStorageDevice; Offset, Count: PtrUInt);
begin
	inherited Create;
end;

end.

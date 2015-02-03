unit storagedev;

interface

uses devicetypes, hal;

type
 TStorageDevice = class(TDevice)
 private
  fDev: TStorageDevDescriptor;
 public
  function Read(var Buffer; Len, Offset: int64): Int64;
  function Write(const Buffer; Len, Offset: int64): Int64;
  
  procedure GetMediaStatus(var MediaStatus: TMediaStatus);
  
  constructor Create(Desc: PStorageDevDescriptor);
 end;

implementation

function TStorageDevice.Read(var Buffer; Len, Offset: int64): Int64;
begin
	result := fDev.ReadData(@buffer, len, offset);
end;

function TStorageDevice.Write(const Buffer; Len, Offset: int64): Int64;
begin
	result := fDev.WriteData(@buffer, len, offset);
end;

procedure TStorageDevice.GetMediaStatus(var MediaStatus: TMediaStatus);
begin
	fDev.GetMediaStatus(@MediaStatus);
end;

constructor TStorageDevice.Create(Desc: PStorageDevDescriptor);
begin
	inherited Create(PDeviceDescriptor(Desc));
	fDev := Desc^;
end;

end.

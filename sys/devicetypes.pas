unit devicetypes;

interface

uses hal;

type
// Storage
 PMediaStatus = ^TMediaStatus;
 TMediaStatus = packed record
  Inserted: boolean;
  
  BlockCount,
  BlockSize: int64;
 end;
 
 PStorageDevDescriptor = ^TStorageDevDescriptor;
 TStorageDevDescriptor = packed record
  Info: TDeviceDescriptor;
  
  //Data
  ReadData: function(Buffer: Pointer; Count, Address: Int64): Int64 of object;
  WriteData: function(Buffer: Pointer; Count, Address: Int64): Int64 of object;
  
  GetMediaStatus: procedure(MediaStatus: PMediaStatus) of object;
 end;
 
// Network
 TNetworkDevDescriptor = packed record
  Info: TDeviceDescriptor;
  
  //Data
  Connected: function: boolean of object;
  SetLocalAddress: function(Addr: Pointer; AddrSize: PtrInt): boolean of object;
  
  SendPacket: function(Packet: Pointer; PacketSize: PtrInt): boolean of object;
 end;
 
// Video
 TSurfaceHandle = PtrInt;
 
 PSurfaceRect = ^TSurfaceRect;
 TSurfaceRect = packed record
  x,y,w,h: PtrInt;
 end;
 
 PVideoAccelerationInterface = ^TVideoAccelerationInterface;
 TVideoAccelerationInterface = packed record
  GetScreenSurface: function: TSurfaceHandle of object;
  
  AllocateSurface: function(Width, Height, Format, Flags: PtrInt): TSurfaceHandle of object;
  DeallocateSurface: function(Handle: TSurfaceHandle): PtrInt of object;
  
  LockSurface: function(Surf: TSurfaceHandle): Pointer of object;
  UnlockSurface: procedure(Surf: TSurfaceHandle) of object;
  
  BlitSurface: procedure(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect) of object;
 end;
 
 PModeInfo = ^TModeInfo;
 TModeInfo = packed record
  ModeDescriptor,
  Width, Height: PtrInt;
  ColorDepth,
  BytePerPixel: byte;
  RMask, RShift,
  GMask, GShift,
  BMask, BShift: longint;
 end;
 
 PVideoDevDescriptor = ^TVideoDevDescriptor;
 TVideoDevDescriptor = packed record
  Info: TDeviceDescriptor;
  
  //Data
  AccelerationIntf: PVideoAccelerationInterface;
  
  GetModeCount: function: PtrInt of object;
  GetModes: function(Buffer: PModeInfo; Count: PtrInt): PtrInt of object;
  GetCurrentMode: function(Buffer: PModeInfo): PtrInt of object;
  SetMode: function(ModeDesc: PtrInt): boolean of object;
  
  //Framebuffer
  GetFrameBuffer: function(Size: PPtrInt): Pointer of object;
 end;

function GetDeviceImplementation(Dev: PDeviceDescriptor): TDevice;

implementation

uses videodev;

function GetDeviceImplementation(Dev: PDeviceDescriptor): TDevice;
begin
	if Dev^.DeviceType = DT_Video then
		result := TVideoDevice.Create(PVideoDevDescriptor(Dev))
	else
		result := TDevice.Create(Dev);
end;

end.

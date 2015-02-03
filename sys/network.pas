unit network;

interface

uses handles, services;

type
 TLinkDevice = class
  function Connected: boolean; virtual; abstract;
  procedure SetLocalAddress(var Addr; AddrSize: PtrInt); virtual; abstract;
 end;
 
 TNetworkDeviceCallback = procedure(var Packet; PacketSize: PtrInt);
 
 TNetworkDevice = class(TLinkDevice)
  function SendPacket(var Packet; PacketSize: PtrInt): boolean; virtual; abstract;
  procedure RegisterPacketCallback(clb: TNetworkDeviceCallback); virtual; abstract;
 end;
 
 TNetwork = class(TServiceObject)
 protected
  procedure RegisterFunctions; override;
 public
  function Socket(Family, SockType, Protocol: PtrUInt): THandle;
  function Bind(Sock: THandle; Addr: Pointer; AddrLen: PtrInt): PtrInt;
  function Send(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt): PtrInt;
  function Recv(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt): PtrInt;
  function SendTo(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt; Addr: Pointer; AddrLen: PtrInt): PtrInt;
  function RecvFrom(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt; Addr: Pointer; AddrLen: PPtrInt): PtrInt;
  function Shutdown(Sock: THandle; howTo: PtrInt): PtrInt;
  function CloseSocket(Sock: THandle): PtrInt;
  
  constructor Create;
 end;

var net: TNetwork;

implementation

function TNetwork.Socket(Family, SockType, Protocol: PtrUInt): THandle;
begin
	result := InvalidHandle;
end;

function TNetwork.Bind(Sock: THandle; Addr: Pointer; AddrLen: PtrInt): PtrInt;
begin
	result := -1;
end;

function TNetwork.Send(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt): PtrInt;
begin
	result := -1;
end;

function TNetwork.Recv(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt): PtrInt;
begin
	result := -1;
end;

function TNetwork.SendTo(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt; Addr: Pointer; AddrLen: PtrInt): PtrInt;
begin
	result := -1;
end;

function TNetwork.RecvFrom(Sock: THandle; Data: Pointer; DataLen: PtrInt; Flags: PtrUInt; Addr: Pointer; AddrLen: PPtrInt): PtrInt;
begin
	result := -1;
end;

function TNetwork.Shutdown(Sock: THandle; howTo: PtrInt): PtrInt;
begin
	result := -1;
end;

function TNetwork.CloseSocket(Sock: THandle): PtrInt;
begin
	result := -1;
end;

procedure TNetwork.RegisterFunctions;
begin
	RegisterFunction('Socket',       GetMethod(@TNetwork.Socket, self),       3);
	RegisterFunction('Bind',         GetMethod(@TNetwork.Bind, self),         3);
	RegisterFunction('Send',         GetMethod(@TNetwork.Send, self),         4);
	RegisterFunction('Recv',         GetMethod(@TNetwork.Recv, self),         4);
	RegisterFunction('SendTo',       GetMethod(@TNetwork.SendTo, self),       6);
	RegisterFunction('RecvFrom',     GetMethod(@TNetwork.RecvFrom, self),     6);
	RegisterFunction('Shutdown',     GetMethod(@TNetwork.Shutdown, self),     2);
	RegisterFunction('CloseSocket',  GetMethod(@TNetwork.CloseSocket, self),  1);
end;

constructor TNetwork.Create;
begin
	inherited Create('NET');
end;

initialization
	net := TNetwork.Create;

end.

unit hal;

interface

uses cclasses, debugger;

type
  PDeviceDescriptor = ^TDeviceDescriptor;

  TDeviceDescriptor = packed record
    DeviceType,
    DeviceFlags: PtrInt;
    DeviceName: PChar;
  end;

const
  DT_Video   = 1;
  DT_NetworkDevice = 2;
  DT_Storage = 3;

  DF_Video_Acceleration = 1;

  DF_Storage_Removable = 1;

type
  TDevice = class
  private
    fName: PChar;
  public
    constructor Create(DevData: PDeviceDescriptor);
    destructor Destroy; override;

    property Name: PChar read fName;
  end;

  THal = class
  private
    fDevs: TList;
  public
    function AddDevice(Dev: PDeviceDescriptor): PtrInt;

    constructor Create;
    destructor Destroy; override;
  end;

var
  DevManager: THal;

implementation

uses devicetypes, vfs, network, ui, videodev, storagedev;

constructor TDevice.Create(DevData: PDeviceDescriptor);
  begin
    inherited Create;
    fName := StrDup(DevData^.DeviceName);
  end;

destructor TDevice.Destroy;
  begin
    StrDispose(fName);
    inherited Destroy;
  end;

const
  DeviceTypeStrs: array[1..3] of PChar = ('Video', 'Network', 'Storage');

function THal.AddDevice(Dev: PDeviceDescriptor): PtrInt;
  var
    d: TDevice;
  begin
    LogInfo('Adding device', ssHal);
    LogDebug(DeviceTypeStrs[Dev^.DeviceType], ssHal);
    LogDebug(Dev^.DeviceName, ssHal);

    d := GetDeviceImplementation(Dev);
    fDevs.Add(d);

    if Dev^.DeviceType = DT_Video then
      UIManager.RegisterOutput(TVideoDevice(d))
    else if Dev^.DeviceType = DT_Storage then
      VFSManager.RegisterStorage(TStorageDevice(d));

    Result := 0;
  end;

constructor THal.Create;
  begin
    inherited Create;
    fDevs := TList.Create(nil);
  end;

destructor THal.Destroy;
  begin
    fDevs.Free;
    inherited Destroy;
  end;

initialization
  DevManager := THal.Create;

end.

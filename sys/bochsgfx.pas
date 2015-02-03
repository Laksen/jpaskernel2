unit bochsgfx;

interface

uses hal, devicetypes;

type
  TBochsGFX = class
  private
    fFB: pointer;
    fCurrentMode: PtrInt;

    fModes: array[0..0] of TModeInfo;

    fDevDesc: TVideoDevDescriptor;
    function GetDevDesc: PDeviceDescriptor;
  public
    function GetModeCount: PtrInt;
    function GetModes(Buffer: PModeInfo; Count: PtrInt): PtrInt;
    function GetCurrentMode(Buffer: PModeInfo): PtrInt;
    function SetMode(ModeDesc: PtrInt): boolean;

    //Framebuffer
    function GetFrameBuffer(Size: PPtrInt): Pointer;

    constructor Create;
    destructor Destroy; override;

    property DeviceDescriptor: PDeviceDescriptor read GetDevDesc;
  end;

implementation

uses io;

const
  VBE_DISPI_IOPORT_INDEX = $1CE;
  VBE_DISPI_IOPORT_DATA  = $1CF;

  VBE_DISPI_DISABLED = 0;
  VBE_DISPI_ENABLED  = 1;

  VBE_DISPI_INDEX_ID     = 0;
  VBE_DISPI_INDEX_XRES   = 1;
  VBE_DISPI_INDEX_YRES   = 2;
  VBE_DISPI_INDEX_BPP    = 3;
  VBE_DISPI_INDEX_ENABLE = 4;
  VBE_DISPI_INDEX_BANK   = 5;
  VBE_DISPI_INDEX_VIRT_WIDTH = 6;
  VBE_DISPI_INDEX_VIRT_HEIGHT = 7;
  VBE_DISPI_INDEX_X_OFFSET = 8;
  VBE_DISPI_INDEX_Y_OFFSET = 9;

  VBE_DISPI_LFB_ENABLED = $40;

procedure BgaWriteRegister(IndexValue, DataValue: word);
  begin
    Outportw(VBE_DISPI_IOPORT_INDEX, IndexValue);
    Outportw(VBE_DISPI_IOPORT_DATA, DataValue);
  end;

function TBochsGFX.GetDevDesc: PDeviceDescriptor;
  begin
    Result := @fDevDesc;
  end;

function TBochsGFX.GetModeCount: PtrInt;
  begin
    Result := high(fModes) + 1;
  end;

function TBochsGFX.GetCurrentMode(Buffer: PModeInfo): PtrInt;
  begin
    Result := fCurrentMode;
    if Result > -1 then
      buffer^ := fModes[Result];
  end;

function TBochsGFX.GetModes(Buffer: PModeInfo; Count: PtrInt): PtrInt;
  begin
    Result := 0;

    if not assigned(buffer) then
      exit;

    if Count > 0 then
      begin
        if Count > (high(fModes) + 1) then
          Count := high(fModes) + 1;

        Result := Count;
        Move(fModes[0], Buffer^, Count * SizeOf(TModeInfo));
      end;
  end;

function TBochsGFX.SetMode(ModeDesc: PtrInt): boolean;
  begin
    Result := False;

    if modedesc = fCurrentMode then
      exit(True);

    fCurrentMode := modedesc;

    BgaWriteRegister(VBE_DISPI_INDEX_ENABLE, VBE_DISPI_DISABLED);
    BgaWriteRegister(VBE_DISPI_INDEX_XRES, fModes[fCurrentMode].Width);
    BgaWriteRegister(VBE_DISPI_INDEX_YRES, fModes[fCurrentMode].Height);
    BgaWriteRegister(VBE_DISPI_INDEX_BPP, fModes[fCurrentMode].ColorDepth);
    BgaWriteRegister(VBE_DISPI_INDEX_ENABLE, VBE_DISPI_ENABLED or VBE_DISPI_LFB_ENABLED);

    Result := True;
  end;

function TBochsGFX.GetFrameBuffer(Size: PPtrInt): Pointer;
  begin
    Result := nil;

    if not assigned(size) then
      exit;
    if fCurrentMode = -1 then
      exit;

    Result := fFB;
    size^ := fModes[fCurrentMode].Width * fModes[fCurrentMode].Height * fModes[fCurrentMode].BytePerPixel;
  end;

constructor TBochsGFX.Create;
  begin
    inherited Create;
    fFB := pointer($E0000000);

    fCurrentMode := -1;

    fModes[0].ModeDescriptor := 0;
    fModes[0].Width := 800;
    fModes[0].Height := 600;
    fModes[0].ColorDepth := 32;
    fModes[0].BytePerPixel := 4;

    fModes[0].BMask := $0000FF;
    fModes[0].BShift := 0;
    fModes[0].GMask := $00FF00;
    fModes[0].GShift := 8;
    fModes[0].RMask := $FF0000;
    fModes[0].RShift := 16;

    fDevDesc.Info.DeviceType := DT_Video;
    fDevDesc.Info.DeviceFlags := 0;
    fDevDesc.Info.DeviceName := 'Bochs Graphics adapter';

    fDevDesc.AccelerationIntf := nil;

    fDevDesc.GetModeCount := @GetModeCount;
    fDevDesc.GetModes := @GetModes;
    fDevDesc.SetMode := @SetMode;
    fDevDesc.GetCurrentMode := @GetCurrentMode;

    fDevDesc.GetFrameBuffer := @GetFrameBuffer;
  end;

destructor TBochsGFX.Destroy;
  begin
    inherited Destroy;
  end;

end.

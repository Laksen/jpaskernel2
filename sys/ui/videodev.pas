unit videodev;

interface

uses cclasses, hal, devicetypes;

type
 TVideoAcceleration = class
 private
  fIntf: TVideoAccelerationInterface;
 public
  function GetScreenSurface: TSurfaceHandle; virtual;
  
  function AllocateSurface(Width, Height, Format, Flags: PtrInt): TSurfaceHandle; virtual;
  function DeallocateSurface(Handle: TSurfaceHandle): PtrInt; virtual;
  
  function LockSurface(Surf: TSurfaceHandle): Pointer; virtual;
  procedure UnlockSurface(Surf: TSurfaceHandle); virtual;
  
  procedure FillRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte); virtual;
  procedure DrawRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte); virtual;
  procedure DrawLine(Surf: TSurfaceHandle; X0,Y0,X1,Y1: PtrInt; R,G,B: byte); virtual;
  
  procedure BlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect); virtual;
  procedure AlphaBlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect; Alpha: byte); virtual;
  
  constructor CreateReal(Intf: PVideoAccelerationInterface);
 end;
 
 TEmulatedVideoAcceleration = class(TVideoAcceleration)
 private
  fFB: Pointer;
  fFBSize: PtrInt;
  fMode: TModeInfo;
  
  fSurfaceCounter: Longint;
  fSurfaces: TDictionary;
 protected
  function GetColor(R,G,B: byte): longword;
  procedure UpdateMode(FB: Pointer; FBSize: PtrInt; const ModeInfo: TModeInfo);
 public
  function GetScreenSurface: TSurfaceHandle; override;
  
  function AllocateSurface(Width, Height, Format, Flags: PtrInt): TSurfaceHandle; override;
  function DeallocateSurface(Handle: TSurfaceHandle): PtrInt; override;
  
  function LockSurface(Surf: TSurfaceHandle): Pointer; override;
  procedure UnlockSurface(Surf: TSurfaceHandle); override;
  
  procedure FillRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte); override;
  procedure DrawRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte); override;
  procedure DrawLine(Surf: TSurfaceHandle; X0,Y0,X1,Y1: PtrInt; R,G,B: byte); override;
  
  procedure BlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect); override;
  
  procedure AlphaBlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect; Alpha: byte); override;
  
  constructor Create;
 end;
 
 TVideoDevice = class(TDevice)
 private
  fDevData: TVideoDevDescriptor;
  fAccel: TVideoAcceleration;
  fEmulated: boolean;
 public
  function GetModeCount: PtrInt;
  function GetModes(var Buffer: TModeInfo; Count: PtrInt): PtrInt;
  function GetCurrentMode(var Buffer: TModeInfo): PtrInt;
  function SetMode(ModeDesc: PtrInt): boolean;
  
  function GetFrameBuffer(var Size: PtrInt): Pointer;
  
  constructor Create(DevData: PVideoDevDescriptor);
  
  property AccelIntf: TVideoAcceleration read fAccel;
 end;

implementation

uses emualpha;

function TVideoAcceleration.GetScreenSurface: TSurfaceHandle;
begin
	result := fIntf.GetScreenSurface();
end;

function TVideoAcceleration.AllocateSurface(Width, Height, Format, Flags: PtrInt): TSurfaceHandle;
begin
	result := fIntf.AllocateSurface(Width, Height, Format, Flags);
end;

function TVideoAcceleration.DeallocateSurface(Handle: TSurfaceHandle): PtrInt;
begin
	result := fIntf.DeallocateSurface(Handle);
end;

function TVideoAcceleration.LockSurface(Surf: TSurfaceHandle): Pointer;
begin
	result := fIntf.LockSurface(Surf);
end;

procedure TVideoAcceleration.UnlockSurface(Surf: TSurfaceHandle);
begin
	fIntf.UnlockSurface(Surf);
end;

procedure TVideoAcceleration.FillRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte);
begin

end;

procedure TVideoAcceleration.DrawRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte);
begin

end;

procedure TVideoAcceleration.DrawLine(Surf: TSurfaceHandle; X0,Y0,X1,Y1: PtrInt; R,G,B: byte);
begin

end;

procedure TVideoAcceleration.BlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect);
begin
	fIntf.BlitSurface(Src, Dest, SrcRect, DestRect);
end;

procedure TVideoAcceleration.AlphaBlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect; Alpha: byte);
begin

end;

constructor TVideoAcceleration.CreateReal(Intf: PVideoAccelerationInterface);
begin
	inherited Create;
	FillChar(fIntf, SizeOf(fIntf), 0);
end;

type
 TEmuSurface = class
 private
  fSurface: Pointer;
  fOwn: boolean;
  fW,fH,fFormat: PtrInt;
  fRect: TSurfaceRect;
 public
  procedure UpdateScreen(FB: Pointer; W,H,Format: PtrInt);
  
  function GetPixelPos(X, Y: PtrInt): PByte;
  function GetPixelWidth: PtrInt;
  
  constructor Create(W,H,Format,Flags: PtrInt);
  constructor CreateScreen(FB: Pointer; W,H,Format: PtrInt);
  destructor Destroy; override;
  
  property Data: Pointer read fSurface;
  
  property Rect: TSurfaceRect read fRect;
  
  property Width: PtrInt read fW;
  property Height: PtrInt read fH;
  property Format: PtrInt read fFormat;
 end;

function TEmuSurface.GetPixelPos(X, Y: PtrInt): PByte;
begin
	result := Pointer(PtrUInt(fSurface)+PtrUInt((x+y*fW)*4));
end;

function TEmuSurface.GetPixelWidth: PtrInt;
begin
	result := 4*fW;
end;

constructor TEmuSurface.Create(W,H,Format,Flags: PtrInt);
begin
	inherited Create;
	fSurface := GetMem(W*H*4);
	fOwn := true;
	fW := W;
	fH := H;
	fFormat := Format;
	
	fRect.X := 0;
	fRect.Y := 0;
	fRect.W := W;
	fRect.H := H;
end;

procedure TEmuSurface.UpdateScreen(FB: Pointer; W,H,Format: PtrInt);
begin
	fSurface := FB;
	fOwn := false;
	fW := W;
	fH := H;
	fFormat := Format;
	
	fRect.X := 0;
	fRect.Y := 0;
	fRect.W := W;
	fRect.H := H;
end;

constructor TEmuSurface.CreateScreen(FB: Pointer; W,H,Format: PtrInt);
begin
	inherited Create;
	fSurface := FB;
	fOwn := false;
	fW := W;
	fH := H;
	fFormat := Format;
	
	fRect.X := 0;
	fRect.Y := 0;
	fRect.W := W;
	fRect.H := H;
end;

destructor TEmuSurface.Destroy;
begin
	if fOwn then
		FreeMem(fSurface);
	inherited Destroy;
end;


function Rect(X,Y,W,H: PtrInt): TSurfaceRect;
begin
	result.X := x;
	result.y := y;
	result.w := w;
	result.h := h;
end;

procedure Swap(var a,b: PtrInt);
var t: PtrInt;
begin
	t := a;
	a := b;
	b := t;
end;

function Abs(i: longint): longint;
begin
	result := i;
	if i < 0 then
		result := -i;
end;

function Max(a,b: PtrInt): PtrInt;
begin
	if a > b then
		result := a
	else
		result := b;
end;

function Min(a,b: PtrInt): PtrInt;
begin
	if a < b then
		result := a
	else
		result := b;
end;

function RectP(X,Y,X1,Y1: PtrInt): TSurfaceRect;
begin
	if x > x1 then swap(x,x1);
	if y > y1 then swap(y,y1);
	
	result.X := x;
	result.y := y;
	result.w := x1-x;
	result.h := y1-y;
end;

function RectIntersection(const a,b: TSurfaceRect): TSurfaceRect;
begin
	result := RectP(max(a.x,b.x), max(a.y,b.y), min(a.x+a.w,b.x+b.w), min(a.y+a.h,b.y+b.h));
end;

function RectClip(const a, clip: TSurfaceRect; var Src: TSurfaceRect): TSurfaceRect;
var d: PtrInt;
begin
	result := rect(a.x, a.y, min(src.w, a.w), min(src.h, a.h));
	result := RectIntersection(a, clip);
	
	if result.x < clip.x then
	begin
		d := clip.x-result.x;
		
		inc(src.x, d);
		dec(src.w, d);
		result.x := clip.x;
	end;
	
	if result.y < clip.y then
	begin
		d := clip.y-result.y;
		
		inc(src.y, d);
		dec(src.h, d);
		result.y := clip.y;
	end;
end;

function ClipLine(const r: TSurfaceRect; var X0,Y0,X1,Y1: PtrInt): boolean;
type
 edge = (LEFT,RIGHT,BOTTOM,TOP);
 outcode = set of edge;

var
    accept,done : boolean;
    outcode0,outcode1,outcodeOut : outcode;
    {Outcodes for P0,P1, and whichever point lies outside the clip rectangle}
    x,y,xmin,xmax,ymin,ymax: PtrInt;

	procedure CompOutCode(x,y: PtrInt; var code:outcode);
	begin
		code := [];
		if y > ymax then code := [TOP]
		else if y < ymin then code := [BOTTOM];
		if x > xmax then code := code +[RIGHT]
		else if x < xmin then code := code +[LEFT]
	end;
begin
	xmin := r.x;
	ymin := r.y;
	xmax := r.x+r.w-1;
	ymax := r.y+r.h-1;
	
	accept := false;  done := false;
	CompOutCode (x0,y0,outcode0); CompOutCode (x1,y1,outcode1);
   repeat
      if(outcode0=[]) and (outcode1=[]) then {Trivial accept and exit}
      begin
			accept := true;
			done:=true;
		end
      else if (outcode0*outcode1) <> [] then
			done := true    {Logical intersection is true, so trivial reject and exit.}
      else
		{Failed both tests, so calculate the line segment to clip;
		from an outside point to an intersection with clip edge.}
		begin
         {At least one endpoint is outside the clip rectangle; pick it.}
			if outcode0 <> [] then
				outcodeOut := outcode0 else outcodeOut := outcode1;
         {Now find intersection point;
         use formulas y=y0+slope*(x-x0),x=x0+(1/slope)*(y-y0).}
			if TOP in outcodeOut then
			begin     {Divide line at top of clip rectangle}
				x := x0 + (x1 - x0) * (ymax - y0) div (y1 - y0);
				y := ymax
			end
			else if BOTTOM in outcodeOut then
			begin     {Divide line at bottom of clip rectangle}
			  x := x0 + (x1 - x0) * (ymin - y0) div (y1 - y0);
			  y := ymax
			end
			else if RIGHT in outcodeOut then
			begin     {Divide line at right edge of clip rectangle}
				y := y0 + (y1 - y0) * (xmax - x0) div (x1 - x0);
				x := xmax
			end
			else if LEFT in outcodeOut then
			begin     {Divide line at left edge of clip rectangle}
				y := y0 + (y1 - y0) * (xmin - x0) div (x1 - x0);
				x := xmin
			end;
         {Now we move outside point to intersection point to clip,
         and get ready for next pass.}
			if (outcodeOut = outcode0) then
			begin
				x0 := x; y0 := y; CompOutCode(x0,y0,outcode0)
			end
			else
			begin
				x1 := x;
				y1 := y;
				CompOutCode(x1,y1,outcode1);
			end;
		end;
	until done;
	
	result := accept;
	//if accept then MidpointLineReal(x0,y0,x1,y1,value)
end;


function TEmulatedVideoAcceleration.GetScreenSurface: TSurfaceHandle;
begin
	result := 0;
end;

function TEmulatedVideoAcceleration.AllocateSurface(Width, Height, Format, Flags: PtrInt): TSurfaceHandle;
begin
	result := InterlockedIncrement(fSurfaceCounter);
	fSurfaces.Add(result, TEmuSurface.Create(Width, Height, Format, Flags));
end;

function TEmulatedVideoAcceleration.DeallocateSurface(Handle: TSurfaceHandle): PtrInt;
var s: TEmuSurface;
begin
	result := 0;
	
	s := TEmuSurface(fSurfaces[handle]);
	
	if assigned(s) then
	begin
		fSurfaces.Delete(handle);
		s.Free;
		result := 1;
	end;
end;

function TEmulatedVideoAcceleration.GetColor(R,G,B: byte): longword;
begin
	result := ((r shl fMode.RShift) and fMode.RMask) or
	          ((g shl fMode.GShift) and fMode.GMask) or
             ((b shl fMode.BShift) and fMode.BMask);
end;

procedure TEmulatedVideoAcceleration.FillRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte);
var s: TEmuSurface;
	 sr: TSurfaceRect;
	 sd: PByte;
	 c: longword;
	 cnt, sw, y: longint;
begin
	s := TEmuSurface(fSurfaces[Surf]);
	
	if not assigned(s) then exit;
	
	c := GetColor(r,g,b);
	
	if Rect = nil then
	begin
		cnt := s.width*s.height;
		
		FillDWord(pbyte(s.Data)^, cnt, c);
	end
	else
	begin
		sr := RectIntersection(Rect^, s.Rect);
		
		sd := s.GetPixelPos(sr.x, sr.y);
		
		cnt := sr.w;
		
		sw := s.GetPixelWidth;
		
		for y := 0 to sr.h-1 do
		begin
			FillDWord(sd^, cnt, c);
			inc(sd, sw);
		end;
	end;
end;

procedure TEmulatedVideoAcceleration.DrawRect(Surf: TSurfaceHandle; Rect: PSurfaceRect; R,G,B: byte);
var s: TEmuSurface;
begin
	if not assigned(rect) then exit;
	
	s := TEmuSurface(fSurfaces[Surf]);
	
	if not assigned(s) then exit;
	
	DrawLine(surf, rect^.x, rect^.y, rect^.x+rect^.w, rect^.y, r,g,b);
	DrawLine(surf, rect^.x, rect^.y+rect^.h, rect^.x+rect^.w, rect^.y+rect^.h, r,g,b);
	DrawLine(surf, rect^.x, rect^.y, rect^.x, rect^.y+rect^.h, r,g,b);
	DrawLine(surf, rect^.x+rect^.w, rect^.y, rect^.x+rect^.w, rect^.y+rect^.h, r,g,b);
end;

procedure TEmulatedVideoAcceleration.DrawLine(Surf: TSurfaceHandle; X0,Y0,X1,Y1: PtrInt; R,G,B: byte);
var s: TEmuSurface;
	 data: PByte;
	 c, sw: Longword;
	 steep: boolean;
	 deltax,deltay,error, ystep,y,x: longint;

	procedure Plot(x,y: longint);
	begin
		plongword(@(data[y*sw]))[x] := c;
	end;

begin
	s := TEmuSurface(fSurfaces[Surf]);
	
	if not assigned(s) then exit;
	
	c := GetColor(r,g,b);
	data := s.Data;
	sw := s.GetPixelWidth;
	
	if ClipLine(S.Rect, X0,Y0,X1,Y1) then
	begin
		steep := abs(y1 - y0) > abs(x1 - x0);
		if steep then
		begin
         swap(x0, y0);
         swap(x1, y1);
		end;
		
		if x0 > x1 then
		begin
         swap(x0, x1);
         swap(y0, y1);
		end;
		deltax := x1 - x0;
		deltay := abs(y1 - y0);
		error := deltax div 2;
		
		y := y0;
		
		if y0 < y1 then ystep := 1 else ystep := -1;
		
		for x := x0 to x1 do
		begin
         if steep then plot(y,x) else plot(x,y);
         error := error - deltay;
         if error < 0 then
			begin
				y := y + ystep;
				error := error + deltax;
			end;
		end;
	end;
end;

function TEmulatedVideoAcceleration.LockSurface(Surf: TSurfaceHandle): Pointer;
var s: TEmuSurface;
begin
	result := nil;
	s := TEmuSurface(fSurfaces[Surf]);
	if assigned(s) then
		result := s.Data;
end;

procedure TEmulatedVideoAcceleration.UnlockSurface(Surf: TSurfaceHandle);
begin
end;

procedure TEmulatedVideoAcceleration.BlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect);
var s,d: TEmuSurface;
	 sr, dr: TSurfaceRect;
	 ps, pd: PByte;
	 sw,dw,copywidth,i: PtrInt;
begin
	s := TEmuSurface(fSurfaces[Src]);
	d := TEmuSurface(fSurfaces[dest]);
	
	if assigned(s) and assigned(d) then
	begin
		if srcrect = nil then
			sr := s.Rect
		else
			sr := SrcRect^;
		
		if destrect = nil then
			dr := sr
		else
			dr := destrect^;
		
		dr := RectClip(dr, d.rect, sr);
		
		ps := s.GetPixelPos(sr.x, sr.y);
		pd := d.GetPixelPos(dr.x, dr.y);
		
		copywidth := dr.w*4;
		
		sw := s.GetPixelWidth;
		dw := d.GetPixelWidth;
		
		for i := 0 to dr.h-1 do
		begin
			Move(ps^, pd^, copywidth);
			
			inc(ps,sw);
			inc(pd,dw);
		end;
	end;
end;

procedure TEmulatedVideoAcceleration.AlphaBlitSurface(Src, Dest: TSurfaceHandle; SrcRect, DestRect: PSurfaceRect; Alpha: byte);
var s,d: TEmuSurface;
	 sr, dr: TSurfaceRect;
	 ps, pd: PByte;
	 sw,dw: PtrInt;
begin
	s := TEmuSurface(fSurfaces[Src]);
	d := TEmuSurface(fSurfaces[dest]);
	
	if assigned(s) and assigned(d) then
	begin
		if srcrect = nil then
			sr := s.Rect
		else
			sr := SrcRect^;
		
		if destrect = nil then
			dr := sr
		else
			dr := DestRect^;
		
		dr := RectClip(dr, d.rect, sr);
		
		ps := s.GetPixelPos(sr.x, sr.y);
		pd := d.GetPixelPos(dr.x, dr.y);
		
		sw := s.GetPixelWidth;
		dw := d.GetPixelWidth;
		
		EmulatedAlphaBlendFixed(ps,pd,dr.w,dr.h,sw,dw, alpha);
	end;
end;

procedure TEmulatedVideoAcceleration.UpdateMode(FB: Pointer; FBSize: PtrInt; const ModeInfo: TModeInfo);
begin
	fFB := FB;
	fFBSize := fbsize;
	
	fMode := ModeInfo;
	
	TEmuSurface(fSurfaces[0]).UpdateScreen(fb,fMode.Width,fMode.Height,0);
end;

constructor TEmulatedVideoAcceleration.Create;
begin
	inherited Create;
	fFB := nil;
	fFBSize := 0;
	
	fSurfaceCounter := 0;
	
	fSurfaces := TDictionary.Create(nil);
	fSurfaces.Add(0, TEmuSurface.CreateScreen(nil, 0,0,0));
end;

function TVideoDevice.GetModeCount: PtrInt;
begin
	result := fDevData.GetModeCount();
end;

function TVideoDevice.GetModes(var Buffer: TModeInfo; Count: PtrInt): PtrInt;
begin
	result := fDevData.GetModes(@Buffer, Count);
end;

function TVideoDevice.SetMode(ModeDesc: PtrInt): boolean;
var info: TModeInfo;
	 fb: pointer;
	 sz: ptrint;
begin
	result := fDevData.SetMode(ModeDesc);
	
	if fEmulated and result then
	begin
		getCurrentMode(info);
		fb := GetFrameBuffer(sz);
		
		TEmulatedVideoAcceleration(fAccel).UpdateMode(fb, sz, info);
	end;
end;

function TVideoDevice.GetCurrentMode(var Buffer: TModeInfo): PtrInt;
begin
	result := fDevData.GetCurrentMode(@buffer);
end;

function TVideoDevice.GetFrameBuffer(var Size: PtrInt): Pointer;
begin
	result := fDevData.GetFrameBuffer(@size);
end;

constructor TVideoDevice.Create(DevData: PVideoDevDescriptor);
begin
	inherited Create(PDeviceDescriptor(DevData));
	fDevData := DevData^;
	fEmulated := not (((fDevData.Info.DeviceFlags and DF_Video_Acceleration) = DF_Video_Acceleration) and assigned(fDevData.AccelerationIntf));
	
	if not fEmulated then
		fAccel := TVideoAcceleration.CreateReal(fDevData.AccelerationIntf)
	else
		fAccel := TEmulatedVideoAcceleration.Create;
end;

end.

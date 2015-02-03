unit emualpha;

interface

type
 PLookupLevel = ^TLookupLevel;
 TLookupLevel = array[0..255] of byte;
 TLookupTable = array[0..255] of TLookupLevel;

procedure EmulatedAlphaBlendFixed(Src, Dest: PByte; Width, Height, SrcJump, DestJump: longint; Alpha: byte);
procedure EmulatedAlphaBlendSrc(Src, Dest: PByte; Width, Height, SrcJump, DestJump: longint; Alpha: byte);

implementation

var AlphaTable: TLookupTable;

function Clipbyte(const value: longint): byte;
const
 andmask: array[boolean] of byte = ($FF, 0);
 ormask: array[boolean] of byte = (0, $FF);
begin
	result := (value and andmask[value < 0]) or ormask[value > 255];
end;

procedure InitTable;
var iAlpha, iValue: word;
begin
	for iAlpha := 0 to 255 do
		for iValue := 0 to 255 do
			AlphaTable[iAlpha, iValue] := ClipByte((iValue*iAlpha) div 255);
end;

function LookupPointer(alpha: longint): PLookupLevel;
begin
	result := @AlphaTable[clipbyte(alpha)];
end;

procedure EmulatedAlphaBlendFixed(Src, Dest: PByte; Width, Height, SrcJump, DestJump: longint; Alpha: byte);
var lutD, lutS: PLookupLevel;
	 x, y: longint;
begin
	luts := LookupPointer(alpha);
	lutd := LookupPointer(255-alpha);
	
	for y := 0 to Height-1 do
	begin
		for x := 0 to Width-1 do
		begin
			dest[x*4+0] := clipbyte(lutd^[dest[x*4+0]]+luts^[src[x*4+0]]);
			dest[x*4+1] := clipbyte(lutd^[dest[x*4+1]]+luts^[src[x*4+1]]);
			dest[x*4+2] := clipbyte(lutd^[dest[x*4+2]]+luts^[src[x*4+2]]);
		end;
		
		inc(src, srcjump);
		inc(dest, destjump);
	end;
end;

procedure EmulatedAlphaBlendSrc(Src, Dest: PByte; Width, Height, SrcJump, DestJump: longint; Alpha: byte);
var lutD, lutS: PLookupLevel;
	 x, y: longint;
	 a: byte;
begin
	
	for y := 0 to Height-1 do
	begin
		for x := 0 to Width-1 do
		begin
			a := (alpha*src[x*4+3]) div 255;
			
			luts := LookupPointer(a);
			lutd := LookupPointer(255-a);
			
			dest[x*4+0] := clipbyte(lutd^[dest[x*4+0]]+luts^[src[x*4+0]]);
			dest[x*4+1] := clipbyte(lutd^[dest[x*4+1]]+luts^[src[x*4+1]]);
			dest[x*4+2] := clipbyte(lutd^[dest[x*4+2]]+luts^[src[x*4+2]]);
		end;
		
		inc(src, srcjump);
		inc(dest, destjump);
	end;
end;

initialization
	InitTable;

end.

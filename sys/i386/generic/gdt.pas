{
 Copyright 2008 (c) Jeppe Græsdal Johansen
 All rights reserved
 
 Redistribution and use in all forms is permitted as long as I'm credited rightfully for my work
 Provided "as is", bla bla bla
}

unit gdt;

interface

uses TSS;

type
 TGDTEntry = packed record
  LimitL,
  BaseL: word;
  BaseM,
  Flags,
  LimitH,
  BaseH: byte;
 end;

 PGDTEntries = ^TGDTEntries;
 TGDTEntries = packed array[0..255] of TGDTEntry;

 TGDT = TGDTEntries;
 
procedure GDTInit(var fGDT: TGDT);
procedure GDTLoad(var g: TGDT);
function GDTGetTSSDesc(var g: TGDT; var TSS: TTSS): longint;

var SystemGDT: TGDT;

implementation

function GetFreeSel(const g: TGDT): longint;
var i: longint;
begin
	result := -1;
	for i := 1 to 255 do
	begin
		if (g[i].flags and $80) = 0 then
		begin
			result := i;
			exit;
		end;
	end;
end;

procedure CodeDescriptor(var Sel: TGDTEntry; Base, Limit: DWord; DPL: byte);
begin
	sel.LimitL := Limit and $FFFF;
	Sel.LimitH := ((Limit shr 16) and $F) or $C0;
	
	Sel.BaseL := base and $FFFF;
	Sel.BaseM := (base shr 16) and $FF;
	Sel.BaseH := (base shr 24) and $FF;
	
	Sel.Flags := $9A or (DPL shl 5);
end;

procedure DataDescriptor(var Sel: TGDTEntry; Base, Limit: DWord; DPL: byte);
begin
	sel.LimitL := Limit and $FFFF;
	Sel.LimitH := ((Limit shr 16) and $F) or $C0;
	
	Sel.BaseL := base and $FFFF;
	Sel.BaseM := (base shr 16) and $FF;
	Sel.BaseH := (base shr 24) and $FF;
	
	Sel.Flags := $92 or (DPL shl 5);
end;

{$asmmode intel}

procedure GDTInit(var fGDT: TGDT);
begin
	FillChar(fGDT[0], sizeof(TGDT), 0);
	
	CodeDescriptor(fGDT[1], 0, $FFFFF, 0);
	DataDescriptor(fGDT[2], 0, $FFFFF, 0);
	CodeDescriptor(fGDT[3], 0, $FFFFF, 3);
	DataDescriptor(fGDT[4], 0, $FFFFF, 3);
end;

procedure GDTLoad(var g: TGDT);
var GDTD: packed record limit: word; offset: DWord; end;
begin
	GDTD.Offset := DWord(@g[0]);
	GDTD.Limit := Sizeof(TGDTEntry)*256-1;
	
	asm
		LGDT [GDTD]
	end;
end;

function GDTGetTSSDesc(var g: TGDT; var TSS: TTSS): longint;
var t: longint;
begin
	t := GetFreeSel(g);
	if t = -1 then
		exit(0);
	
	with g[t] do
	begin
		LimitL := sizeof(TTSS) and $FFFF;
		LimitH := (sizeof(TTSS) shr 16) and $F;
		
		BaseL := dword(@tss) and $FFFF;
		BaseM := (dword(@tss) shr 16) and $FF;
		BaseH := (dword(@tss) shr 24) and $FF;
		
		flags := $89;
	end;
	
   result := t shl 3;
end;

initialization
	GDTInit(SystemGDT);
	GDTLoad(SystemGDT);

end.

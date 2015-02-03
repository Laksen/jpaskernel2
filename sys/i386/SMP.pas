{
 Copyright 2008 (c) Jeppe Græsdal Johansen
 All rights reserved
 
 Redistribution and use in all forms is permitted as long as I'm credited rightfully for my work
 Provided "as is", bla bla bla
}

unit SMP;

interface

type
 TSMPConfig = record
  CPUCount: longint;
  HasSMP: boolean;
 end;

var SMPConfig: TSMPConfig;

implementation

type
 PMPTable = ^TMPTable;
 TMPTable = packed record
  Sig: array[0..3] of char;
  Len: word;
  SpecRev,
  CS: byte;
  OemIDString: array[0..7] of char;
  ProdIDString: array[0..11] of char;
  OemTable: dword;
  OemTableSize,
  EntryCount: word;
  APICAddress: dword;
  ExtTableLength: word;
  ExtTableCS,
  res: byte;
  Table: dword;
 end;

 PMPFloatTable = ^TMPFloatTable;
 TMPFloatTable = packed record
  Sig: array[0..3] of char;
  MPTable: dword;
  Length,
  SpecRev,
  chksum: byte;
  MpFeatures: array[0..4] of byte;
 end;

function CheckSumSMP(Addr: longint): boolean;
var len: byte;
	 c,i: longint;
begin
	len := pbyte(Addr+$8)^;
	c := 0;
	for i := 0 to len*16-1 do
	begin
		c := (c + pbyte(Addr+i)^) mod 256;
	end;
	result := c=0;
end;

procedure ParseTableSMP(Addr: PMPFloatTable);
var len, i: longint;
	 a: pbyte;
	 Conf: PMPTable;
	 //ia: TIOApic;
begin
	Conf := Pointer(Addr^.MPTable);
	
	if Conf = nil then
		exit;
	
	SMPConfig.CPUCount := 0;
   SMPConfig.hasSMP := true;
	
	len := conf^.EntryCount;
	a := @Conf^.Table;
	for i := 0 to len-1 do
	begin
		if a^ = 0 then
		begin
			inc(a, 20);
			
			if (a[3] and 1) = 1 then
				inc(SMPConfig.CPUCount);
		end
		else if a^ = 2 then
		begin
			if (a[3] and 1) = 1 then
			begin
				{ia := TIOApic.Create(plongword(a)[1]);
				ia.Free;
				
				outportb($22, $70);
				outportb($23, $1);}
				
				//mask pic
				{outportb($21, $ff);
				outportb($A1, $ff);}
			end;
			inc(a, 8);
		end
		else
		begin
			inc(a, 8);
		end;
	end;
end;

function FindSMPHere(From, UpTo: longword): boolean;
var i: longint;
begin
	FindSMPHere := true;
	for i := From to UpTo do
	begin
		if (pbyte(i)^ = $5F) and (pbyte(i+1)^ = $4D) and (pbyte(i+2)^ = $50) and (pbyte(i+3)^ = $5F) then
		//if plongint(pointer(i))^ = $5F50 4D5F then
		begin
			if CheckSumSMP(i) then
			begin
				ParseTableSMP(pointer(i));
				exit;
			end;
		end;
	end;
	FindSMPHere := false;
end;

function FindSMP: boolean;
begin                  
   result := false;
	//(1) in the first kilobyte of the extended BIOS data area,
	if not FindSMPHere($9FC00, $9FE00) then
	begin
		//(2) the last kilobyte of base memory,
		if not FindSMPHere($9F9FF, $9FBFF) then
		begin
			//(3) the top of physical memory, or 
			if not false then
			begin
				//(4) the BIOS read-only memory space between 0xe0000 and 0xfffff
				if not FindSMPHere($e0000, $fffff) then
				begin
					exit;
				end;
			end;
		end;
	end;
   result := true;
end;

initialization
   SmpConfig.hasSMP := false;
   if not findsmp then
      SMPConfig.CPUCount := 1;

end.

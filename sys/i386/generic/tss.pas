{
 Copyright 2008 (c) Jeppe Græsdal Johansen
 All rights reserved
 
 Redistribution and use in all forms is permitted as long as I'm credited rightfully for my work
 Provided "as is", bla bla bla
}

unit tss;

interface

type
 PTSS = ^TTSS;
 TTSS = packed record
  LINK, _reserved: word;
  ESP0: DWord;
  SS0, _reserved0: word;
  ESP1: DWord;
  SS1, _reserved1: word;
  ESP2: DWord;
  SS2, _reserved2: word;
  CR3: DWord;
  EIP: DWord;
  EFLAGS: DWord;
  EAX: DWord;
  ECX: DWord;
  EDX: DWord;
  EBX: DWord;
  ESP: DWord;
  EBP: DWord;
  ESI: DWord;
  EDI: DWord;
  ES,_reserved3: word;
  CS,_reserved4: word;
  SS,_reserved5: word;
  DS,_reserved6: word;
  FS,_reserved7: word;
  GS,_reserved8: word;
  LDTR,_reserved9: word;
  _reserved10, IOPB: word;
  {IntBits: array[0..31] of byte;
  Bitmap: array[0..8191] of byte;}
 end;

procedure LoadTSS(Sel: word);
procedure InitTSS(var tbl: TTSS; Esp: PtrUInt);

implementation

{$asmmode intel}

procedure InitTSS(var tbl: TTSS; Esp: PtrUInt);
begin
	fillchar(tbl, sizeof(TTSS), 0);
	//fillchar(tbl.IntBits[0], 32, $0);
	//tbl.IntBits[0] := $3;
	
	tbl.eflags := $3202;
   
	tbl.cs := $8;
	tbl.ds := $10;
	tbl.es := $10;
	tbl.fs := $10;
	tbl.gs := $10;
	tbl.ss := $10;
	tbl.SS0 := $10;
	tbl.SS1 := $10;
	tbl.SS2 := $10;
   
	tbl.ESP := ESP;
	tbl.ESP0 := tbl.ESP;
	tbl.ESP1 := tbl.ESP;
	tbl.ESP2 := tbl.ESP;
	
	tbl.EBP := tbl.ESP;
	//tbl.IOPB := 104+32;
end;

procedure LoadTSS(Sel: word);
begin
	asm
		ltr sel
	end;
end;

end.

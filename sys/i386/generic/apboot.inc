{
 Copyright 2008 (c) Jeppe Græsdal Johansen
 All rights reserved
 
 Redistribution and use in all forms is permitted as long as I'm credited rightfully for my work
 Provided "as is", bla bla bla
}

{$ASMMODE Intel}

function PrepareBootCode(StackSize: longword; EntryProc, this: pointer): pointer;
var BootPage, addr: longword;
label a,b;
begin
   bootPage := $2000;
   Move(Pbyte(@a)^, PByte(BootPage)^,longword(@b)-longword(@a));
   plongword($2200)^ := longword(GetMem(StackSize))+StackSize;
   plongword($2208)^ := longword(EntryProc);
   plongword($220C)^ := longword(this);
   PrepareBootCode := pointer(bootPage);
   exit;
a:
   asm
		cli
		db $0F,$01,$16
		//4
		dw $2013
		mov eax, CR0
		or al, $1
		mov cr0, eax
		db $EA
		//f
		dw $2031
		db $08,$00
		//13
		dw 0023
		//15
		dd $00002019
		//19
		dd $00000000,$00000000
		dw $FFFF
      dw 0
      db 0
      db $9A
      db $CF
      db 0
		dw $FFFF
      dw 0
      db 0
      db $92
      db $CF
      db 0
		//31
		mov ax, $10
      mov ds, ax
      mov es, ax
      mov ss, ax
        
      mov eax, [$2200]
      mov esp, eax

      mov eax, [$220C]
      mov ebx, [$2208]
      call ebx

      hlt
		
		{db $FA
		db $0F,$01,$16
		db $29,$20
		db $0F,$20,$C0
		db $0C,$01
		db $0F,$22,$C0
		db $EA,$13,$20,$08,$00,$66,$B8
		db $10,$00
		db $8E,$D8
		db $8E,$C0
		db $8E,$D0
		db $A1,$00,$22,$00,$00
		db $89,$C4
		db $E9,$1E,$20,$00,$00
		db $17
		db $00,$2F
		db $00,$00
		db $00,$00
		db $00,$00
		db $00,$00
		db $00,$00
		db $00,$FF
		db $FF,$00
		db $00,$00
		db $9A,$CF,$00,$FF,$FF,$00,$00
		db $00
		db $92
		db $CF
		db $00
		db $F4}
   end;
b:
end;
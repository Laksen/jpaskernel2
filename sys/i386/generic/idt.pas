unit idt;

interface

uses machine, machineimpl, io;

type
 TIDTEntry = packed record
  OffsetL,
  CS: word;
  res,
  flags: byte;
  OffsetH: word;
 end;

 PIDTEntries = ^TIDTEntries;
 TIDTEntries = packed array[0..255] of TIDTEntry;
 
 PIntHandlers = ^TIntHandlers;
 TIntHandlers = TInterruptRequest;
 
 PIDT = ^TIDT;
 TIDT = record
  fIDT: TIDTEntries;
  fIrqtable: array[0..255] of array[0..31] of byte;
  fIntTable: TIntHandlers;
 end;

procedure IDTSetHandler(var fIdt: TIDT; Handler: TInterruptRequest);
procedure IDTLoad(var fIDt: TIDT);
procedure IDTInit(var fIDt: TIDT);

implementation

{$asmmode intel}

procedure ISR(var regs: TContext); cdecl;
begin
	PIntHandlers(regs.HandlerTable)^(regs.int, regs, sizeof(TContext));
	
	//Ack the PIC
	if (regs.int >= $20) and (regs.int < $30) then
   begin
      if regs.int >= $28 then
         outportb($A0, $20);
      outportb($20, $20);
   end;
end;

procedure LowISR; assembler; nostackframe;
asm
  pushad
  push ds
  push es
  push fs
  push gs

  mov ax, $10
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  mov ebx, esp
  push ebx
  call ISR
  pop ebx

  pop gs
  pop fs
  pop es
  pop ds
  popad

  add esp,3*4

  iret
end;

procedure IDTSetHandler(var fidt: TIDT; Handler: TInterruptRequest);
begin
	fidt.fIntTable := Handler;
end;

procedure BuildIntTable(var fidt: TIDT);
var i,l: longint;

    procedure writebyte(b: byte);
    begin
       fidt.fIrqTable[i,l] := b;
       inc(l);
    end;

    procedure writeword(b: word);
    begin
       pword(@fidt.fIrqTable[i,l])^ := b;
       inc(l,2);
    end;

    procedure writedword(b: longword);
    begin
       plongword(@fidt.fIrqTable[i,l])^ := b;
       inc(l,4);
    end;

begin
	for i := 0 to 255 do
   begin
      l := 0;
      if i in [8,17,10..14] then
      begin
         writebyte($FA); // CLI
         writebyte($68); writedword(i); // PUSH i
         writebyte($68); writedword(ptruint(@fidt.fIntTable)); // PUSH @fidt.fIntTable[0]
         writebyte($EA); writedword(ptruint(@LowISR)); writeword($0008); // JMP far 8:LowIsr
      end
      else
      begin
         writebyte($FA); // CLI
         writebyte($68); writedword(0); // PUSH 0
         writebyte($68); writedword(i); // PUSH i
         writebyte($68); writedword(ptruint(@fidt.fIntTable)); // PUSH @fidt.fIntTable[0]
         writebyte($EA); writedword(ptruint(@LowISR)); writeword($0008); // JMP far 8:LowIsr
      end;
   end;
end;

procedure IntGate(var Entry: TIDTEntry; Offset: pointer; cs: word; flags, dpl: byte);
begin
	Entry.OffsetL := DWord(Offset) and $FFFF;
	Entry.OffsetH := (DWord(Offset) shr 16) and $FFFF;
	
	Entry.CS := cs;
	Entry.Flags := flags or ((dpl and 3) shl 5);
	
	Entry.Res := 0;
end;

procedure IDTLoad(var fIDT: TIDT);
var IDTD: packed record limit: word; offset: pointer; end;
begin
	IDTD.Offset := @fIDT.fIDT[0];
	IDTD.Limit := Sizeof(TIDTEntry)*256-1;
	
	asm
		LIDT [IDTD]
	end;
end;

procedure IrqRemap;
begin	
   outportb($20, $11);
   outportb($A0, $11);
   outportb($21, $20);
   outportb($A1, $28);
   outportb($21, $04);
   outportb($A1, $02);
   outportb($21, $1);
   outportb($A1, $1);
   outportb($21, $0);
   outportb($A1, $0);
end;

procedure IDTInit(var fIDT: TIDT);
var i: longint;
begin
	FillChar(fIDT.fIDT[0], Sizeof(TIDTEntries), 0);
	BuildIntTable(fIDT);
	
	for i := 0 to 255 do
	begin
      if i in [$B0] then
         IntGate(fIDT.fIDT[i], @fidt.fIrqtable[i,0], $8, $8E, 3)
      else
         IntGate(fIDT.fIDT[i], @fidt.fIrqtable[i,0], $8, $8E, 0);
	end;
end;

initialization
	IrqRemap;

end.

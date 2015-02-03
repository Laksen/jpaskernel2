unit io;

interface

function InPortB(Port: Word): byte; cdecl;
function InPortW(Port: Word): Word; cdecl;
function InPortD(Port: Word): DWord; cdecl;

procedure OutPortB(Port: Word; data: Byte); cdecl;
procedure OutPortW(Port: Word; data: Word); cdecl;
procedure OutPortD(Port: Word; data: DWord); cdecl;

function ReadCR0: DWord;
procedure WriteCR0(value: DWord);
function ReadCR2: DWord;
function ReadCR3: DWord;
procedure WriteCR3(value: DWord);
function ReadCR4: DWord;
procedure WriteCR4(value: DWord);

procedure SetTS;
procedure ClearTS;

procedure ResetFPU;
procedure RestoreFPU(fpuState: pointer);
procedure SaveFPU(fpuState: pointer);

procedure hlt;
procedure cli;
procedure Sti;

implementation

{$asmmode intel}

procedure hlt;
begin
	asm
		hlt
	end;
end;

procedure cli;
begin
	asm
		cli
	end;
end;

procedure Sti;
begin
	asm
		sti
	end;
end;

function ReadCR0: DWord;
begin
	asm
		mov eax, cr0
	end;
end;

procedure ResetFPU;
begin
	asm
		FINIT
	end;
end;

procedure RestoreFPU(fpuState: pointer);
begin
	asm
		mov eax, fpustate
		fxrstor [eax]
	end;
end;

procedure SaveFPU(fpuState: pointer);
begin
	asm
		mov eax, fpustate
		fxsave [eax]
	end;
end;

procedure SetTS;
begin
	asm
		mov eax, cr0
		or eax, 8
		mov cr0, eax
	end ['eax'];
end;

procedure ClearTS;
begin
	asm
		mov eax, cr0
		and eax, not(8)
		mov cr0, eax
	end ['eax'];
end;

procedure WriteCR0(value: DWord);
begin
	asm
		mov eax, value
		mov cr0, eax
	end;
end;

function ReadCR2: DWord;
begin
	asm
		mov eax, cr2
	end;
end;

function ReadCR3: DWord;
begin
	asm
		mov eax, cr3
	end;
end;

procedure WriteCR3(value: DWord);
begin
	asm
		mov eax, value
		mov cr3, eax
	end;
end;

function ReadCR4: DWord;
begin
	asm
		mov eax, cr4
	end;
end;

procedure WriteCR4(value: DWord);
begin
	asm
		mov eax, value
		mov cr4, eax
	end;
end;

{$asmmode att}

procedure outportb(port : word; data : byte); cdecl;
begin
   asm
      movw port, %dx
      movb data, %al
      outb %al, %dx
   end ['edx','eax'];
end;

function inportb(port : word): byte; cdecl;
begin
   asm
      movw port, %dx
      inb %dx, %al
      mov %al, inportb
   end ['edx'];
end;

procedure outportw(port, data: word); cdecl;
begin
   asm
      mov port, %dx
      mov data, %ax
      outw %ax, %dx
   end ['edx','eax'];
end;

function inportw(port : word): word; cdecl;
begin
   asm
      movw port, %dx
      inw %dx, %ax
      movw %ax, inportw
   end ['edx'];
end;

procedure outportd(port: word; data: DWord); cdecl;
begin
   asm
      movw port,%dx
      movl data, %eax
      outl %eax, %dx
   end ['edx','eax'];
end;

function inportd(port : word): DWord; cdecl;
begin
   asm
      movw port,%dx
      inl %dx,%eax
      movl %eax, inportd
   end ['edx'];
end;

end.

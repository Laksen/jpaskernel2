{
 Copyright 2008 (c) Jeppe Græsdal Johansen
 All rights reserved
 
 Redistribution and use in all forms is permitted as long as I'm credited rightfully for my work
 Provided "as is", bla bla bla
}

unit apic;

interface

type
  TDelivery = (dFixed = 0, dLowPriority = 1, dSMI = 2, dNMI = 4, dINIT = 5, dStartUp = 6);
  TTriggerMode = (tmLevel = 0, tmEdge = 1);
  TDestShorthand = (dsNoShorthand, dsSelf, dsAllSelf, dsAllNoSelf);

procedure LAPICSendIPI(Vector: byte; DestField: longword; Delivery: TDelivery; DestLogical: boolean; Trigger: TTriggerMode; DeAssert: boolean; DestShorthand: TDestShorthand);

procedure LAPICSetupPeriodicTimer(FreqDivision, IntNumber: byte; InitCount: longword);
procedure LAPICSetupOneshotTimer(FreqDivision, IntNumber: byte; InitCount: longword);
procedure LAPICSetupTimedown(NewCount: longword);

procedure LAPICEnable;
procedure LAPICSendStartup(Destination: byte; BootAddress: longword);
procedure LAPICSignalEOI;

function LAPICGetCurrentCPU: longint;
procedure LAPICSetCurrentCPU(const Value: longint);

implementation

{$asmmode intel}

var
  LocalAPICAddr: longword = $FEE00000;

const
  ApicID      = $20;
  ApicVersion = $30;
  ApicLogDest = $D0;

  ApicTimer     = $320;
  ApicTimerInit = $380;
  ApicTimerCurrent = $390;
  ApicTimerDivisor = $3E0;

  ApicEOI    = $B0;
  ApicEnable = $F0;
  ApicError  = $280;

  ApicErr   = $380;
  ApicLINT0 = $350;
  ApicLINT1 = $360;
  ApicSPU   = $F0;

  ApicICRlo = $300;
  ApicICRhi = $310;

function ApicGet(Register: longword): longword;
  begin
    ApicGet := PDWord(LocalAPICAddr + Register)^;
  end;

procedure ApicSet(Register, Value: longword);
  begin
    PDword(LocalAPICAddr + Register)^ := Value;
  end;

procedure LAPICSendIPI(Vector: byte; DestField: longword; Delivery: TDelivery; DestLogical: boolean; Trigger: TTriggerMode; DeAssert: boolean; DestShorthand: TDestShorthand);
  begin
    ApicSet(ApicICRhi, DestField shl 24);
    ApicSet(ApicICRlo, Vector or (byte(Delivery) shl 8) or (byte(DestLogical) shl 11) or (byte(DeAssert) shl 14) or (byte(Trigger) shl 15) or (byte(DestShorthand) shl 18));
  end;

function LAPICGetCurrentCPU: longint;
  begin
    Result := ApicGet(ApicID) shr 24;
  end;

procedure LAPICSetCurrentCPU(const Value: longint);
  begin
    ApicSet(ApicID, Value shl 24);
  end;

procedure LAPICSetupPeriodicTimer(FreqDivision, IntNumber: byte; InitCount: longword);
  const
    Divisors: array[0..7] of longint = (11, 0, 1, 2, 3, 8, 9, 10);
  begin
    ApicSet(ApicTimerDivisor, Divisors[FreqDivision]);
    ApicSet(ApicTimer, (1 shl 17) or IntNumber);
    ApicSet(ApicTimerInit, InitCount);
  end;

procedure LAPICSetupOneshotTimer(FreqDivision, IntNumber: byte; InitCount: longword);
  const
    Divisors: array[0..7] of longint = (11, 0, 1, 2, 3, 8, 9, 10);
  begin
    ApicSet(ApicTimerDivisor, Divisors[FreqDivision]);
    ApicSet(ApicTimer, IntNumber);
    ApicSet(ApicTimerInit, InitCount);
  end;

procedure LAPICSetupTimedown(NewCount: longword);
  begin
    ApicSet(ApicTimerInit, NewCount);
  end;

procedure LAPICSignalEOI;
  begin
    ApicSet(ApicEOI, 0);
  end;

procedure LAPICEnable;
  begin
    ApicSet(ApicEnable, ApicGet(ApicEnable) or $100);

  {ApicSet(ApicLINT0, $B0);
  ApicSet(ApicLINT1, $B1);}
  end;

procedure LAPICSendStartup(Destination: byte; BootAddress: longword);
  var
    i: longint;
  begin
    LAPICSendIPI(0, Destination, dInit, False, tmLevel, True, dsNoShorthand);
    for i := 0 to 20000 do
      begin
        asm
          NOP
        end;
      end;
    LAPICSendIPI(0, Destination, dInit, False, tmLevel, True, dsNoShorthand);
    for i := 0 to 40000 do
      begin
        asm
          NOP
        end;
      end;
    LAPICSendIPI((BootAddress div 4096), Destination, dStartUp, False, tmLevel, False, dsNoShorthand);
  end;

end.

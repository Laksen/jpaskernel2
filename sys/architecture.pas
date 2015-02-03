unit architecture;

interface

type
 TArchFlags = set of (afNoProtection);
 
 TArchInfo = record
  Name: PChar;
  Flags: TArchFlags;
 end;

const
 ArchInfo: TArchInfo = (
{$ifdef CPUI386}
	Name: 'i386';
	Flags: [afNoProtection];
{$endif}
{$ifdef CPUARM}
 {$if defined(CPUCORTEXM3) or defined(CPUARMV7M) or defined(CPUARMV7A)}
	Name: 'ARM for Thumb2';
 {$else}
   Name: 'ARM';
 {$endif}
	Flags: [afNoProtection];
{$endif}
 );

implementation

end.

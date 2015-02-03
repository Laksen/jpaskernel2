unit vgaoutput;

interface

uses consoleio;

implementation

var
  x, y: integer;
  Screen: array[0..24] of array[0..79] of word absolute $B8000;

function WriteOutput(ACh: char; AUserData: pointer): boolean;
  var
    i: integer;
  begin
    if ach = #13 then
      x := 0
    else if ach = #10 then
      Inc(y)
    else
      begin
        Screen[y][x] := byte(ACh) or $700;
        Inc(x);
      end;

    if x >= 80 then
      begin
        x := 0;
        Inc(y);
      end;

    if y >= 24 then
      begin
        while y >= 24 do
          begin
            //Move(Screen[1][0], Screen[0][0], 24*80*2);
            for i := 0 to 23 do
              Screen[i] := Screen[i + 1];
            Dec(y);
          end;
        FillWord(Screen[24][0], 80, $720);
      end;

    Result := True;
  end;

procedure InitOutput;
  begin
    FillWord(Screen[0][0], 80 * 25, $720);

    OpenIO(Output, @WriteOutput, nil, fmOutput, nil);
    OpenIO(ErrOutput, @WriteOutput, nil, fmOutput, nil);
    OpenIO(StdOut, @WriteOutput, nil, fmOutput, nil);
    OpenIO(StdErr, @WriteOutput, nil, fmOutput, nil);
  end;

initialization
  InitOutput;

end.


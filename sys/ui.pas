unit ui;

interface

uses devicetypes, videodev;

type
 TUI = class
  procedure RegisterOutput(Dev: TVideoDevice);
 end;

var UIManager: TUI;

implementation

procedure TUI.RegisterOutput(Dev: TVideoDevice);
begin
	
end;

initialization
	UIManager := TUI.Create;

end.

unit ScreenSaver;

interface

uses
  Windows, SysUtils;

var
  Parent : THandle;

procedure RunScr;

implementation

uses
  Main;

procedure RunScr;
var
  param1 : string;
begin
  Randomize;
  if ParamCount < 1 then
    ContextCustomize
  else
  begin
    param1 := LowerCase(ParamStr(1));
    if param1 = '/s' then
      Run
    else if param1 = '/p' then
    begin
      Parent := StrToInt(ParamStr(2));
      Preview;
    end
    else if Copy(param1, 1, 2) = '/c' then
    begin
      if param1 <> '/c' then
        Parent := StrToInt(Copy(param1, 4, 64));
      Customize;
    end
    else if param1 = '/debug' then
      RunDebug
    else if param1 = '/install' then
      Install
    else
    begin
      MessageBox(Parent, 'Invalid command line', 'MagicStone screensaver', MB_OK or MB_ICONERROR);
      Halt;
    end;
  end;
end;

initialization
  Parent := 0;
end.


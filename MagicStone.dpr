program MagicStone;

{$E scr}
{$R *.res}
{$DEFINE DEBUG}

{$IFDEF DEBUG}
{$W+,D+,L+,Y+,C+}
{$DEFINE FPS}
{$ELSE}
{$O+,W-,R-,Q-,D-,L-,Y-,C-}
{$ENDIF}

uses
  Randoms,
  Memory,
  ScreenSaver in 'ScreenSaver.pas',
  Main in 'Main.pas',
  Window in 'Window.pas',
  ImageMBlur in 'ImageMBlur.pas',
  ObjectMBlur in 'ObjectMBlur.pas',
  Present in 'Present.pas',
  Render in 'Render.pas',
  Engine in 'Engine.pas';

begin
  RunScr;
end.


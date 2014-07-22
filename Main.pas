unit Main;

interface

uses
  Windows, SysUtils, Memory, Randoms,
  ScreenSaver, Window, Present, Render, Engine, ObjectMBlur;

procedure Run;
procedure RunDebug;
procedure Preview;
procedure Customize;
procedure ContextCustomize;
procedure Install;

var
  ThreadHandle: THandle;
  ThreadId: Cardinal;

implementation

const
  ObjectMoutionBlurDepth = 64;

var
  MaxStepFreq : Float;
  MinStepFreq : Float;
  MinStepTime : Float;
  MaxStepTime : Float;
  Speed : Float;

function ThreadMain(param: Pointer): Integer;
var
  A, B, Freq : Int64;
  Time : Double;
  Lag2 : Double;
  temp : string;
begin
  QueryPerformanceFrequency(Freq);
  QueryPerformanceCounter(A);
  MinStepFreq := MaxStepFreq * 0.5;
  MinStepTime := 1 / MaxStepFreq;
  MaxStepTime := 1 / MinStepFreq;
  VideoInitialize;
  try
   try
    EngineInitialize;
    OmbCount := PointsCount;
    OmbInitialize;
    Lag2 := 0;
    repeat
      B := A;
      QueryPerformanceCounter(A);
      Time := (A - B) / Freq;
      Lag2 := Lag2 + Time;
      if Lag2 >= MinStepTime then
      begin
        if Lag2 > MaxStepTime then
          EngineStep(MaxStepTime * Speed)
        else
          EngineStep(Lag2 * Speed);
        Lag2 := 0;
      end;
      VideoBegin;
      Fill4($00000000, VideoData, VideoPitch * VideoHeight);
      OmbRender;
      VideoEnd;
    until WndFinishing;
    EngineFinalize;
    OmbFinalize;
    except
      on E:Exception do
      begin
        temp := E.ClassName;
        MessageBox(Parent, PChar(E.Message), PChar(temp), MB_OK or MB_ICONERROR);
      end;
    end;
  finally
    VideoFinalize;
    ExitThread(0);
  end;
  Result := 0;
end;

procedure Run2;
begin
  WndShow;
  ThreadHandle := BeginThread(nil, 0, @ThreadMain, nil, 0, ThreadId);
  WndRun;
  if WaitForSingleObject(ThreadHandle, 1000) = WAIT_TIMEOUT then
//  begin
//    MessageBox(0, 'Time elapsed, but the main thread isn''t finished yet. Terminating program now.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt(1);
//  end;
end;

procedure RunPrepare;
begin
  VideoWidth := WndWidth;
  VideoHeight := WndHeight;
  PointsCount := RandomI2(128, 512);
  OmbDepth := Round(ObjectMoutionBlurDepth * VideoHeight / 600);
  Drawer := @DrawPrecise2Proc;
  MaxStepFreq := OmbDepth / 2;
  Speed := 0.5;
end;

procedure Run;
begin
  WndPrepare;
  WndCreateFullscreen;
  RunPrepare;
  ShowCursor(False);
  Run2;
end;

procedure RunDebug;
begin
  WndWidth := 800;
  WndHeight := 600;
  WndPrepare;
  WndCreateDebug;
  RunPrepare;
  Run2;
end;

procedure Preview;
begin
  WndPrepare;
  WndCreatePreview;
  RunPrepare;
  PointsCount := PointsCount div 8;
  OmbDepth := ObjectMoutionBlurDepth * 2;
  MaxStepFreq := ObjectMoutionBlurDepth / 4;
  Speed := 1.0;
  Drawer := @DrawPreciseProc;
  Run2;
end;

procedure Customize;
begin
  MessageBox(Parent, 'This screensaver isn''t yet customizeable.'#13#10#13#10'MagicStone 3.0'#13#10'© 2013 Silver Unicorn', 'MagicStone screensaver', MB_OK or MB_ICONINFORMATION);
end;

procedure ContextCustomize;
begin
  Customize;
end;

procedure Install;
const
  path = '%systemroot%\MagicStone.scr';
var
  buf : PChar;
  len : Cardinal;
begin
  len := ExpandEnvironmentStrings(path, nil, 0);
  GetMem(buf, len);
  Assert(len >= ExpandEnvironmentStrings(path, buf, len));
  CopyFile(PChar(ParamStr(0)), buf, False);
  FreeMem(buf);
end;

end.

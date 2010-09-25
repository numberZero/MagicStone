PROGRAM MagicStone;

{$E scr}
{$R *.res}
USES
  Windows,
  Messages,
  Types,
  SysUtils,
  Misc IN 'Misc.pas',
  DirectX,
  Math,
  UnitMain IN 'UnitMain.pas';

CONST ThreadWait = 1000;
      MouseEps   = 10;

PROCEDURE M1(a, b : Word); FORWARD;
PROCEDURE M2(a, b : Word); FORWARD;

VAR
  Fullscreen : Boolean;
  Finishing : Boolean;
  hWindow : HWND;
  hThread : THandle;
  dwThread : Cardinal;
  MProc : PROCEDURE(a, b : Word) = M1;
  mx, my : Word;
  Time   : Integer = ThreadWait;

FUNCTION IsMouseMoved(CurrentX, CurrentY : Integer) : Boolean;
BEGIN
  Result := True;
  Dec(CurrentX, mx);
  IF (CurrentX < -MouseEps) OR (CurrentX > MouseEps) THEN
    Exit;
  Dec(CurrentY, my);
  IF (CurrentY < -MouseEps) OR (CurrentY > MouseEps) THEN
    Exit;
  Result := False;
END;

PROCEDURE M1;
BEGIN
  IF Time > 0 THEN
    Exit;
  mx := a;
  my := b;
  MProc := M2;
END;

PROCEDURE M2;
BEGIN
  IF IsMouseMoved(a, b) THEN
    PostMessage(hWindow, WM_CLOSE, 0, 0);
END;

FUNCTION WndProc(h : HWND; m : UINT; w : WPARAM; l : LPARAM) : LRESULT; STDCALL;
BEGIN
  Result := 0;
  CASE m OF
    WM_ACTIVATE,
      WM_ACTIVATEAPP,
      WM_NCACTIVATE :
      IF w = 0 THEN
        PostMessage(h, WM_CLOSE, 0, 0);

//    WM_SETCURSOR : SetCursor(0);

    WM_LBUTTONDOWN,
      WM_RBUTTONDOWN,
      WM_MBUTTONDOWN,
      WM_KEYDOWN,
      WM_KEYUP : PostMessage(h, WM_CLOSE, 0, 0);

    WM_MOUSEMOVE :
      BEGIN
        MProc(LOWORD(l), HIWORD(l));
      END; // PostMessage(h, WM_CLOSE, 0, 0);

    WM_DESTROY : PostQuitMessage(0);

    WM_SYSCOMMAND : IF (w AND $FFF0 = SC_CLOSE) OR (w AND $FFF0 = SC_SCREENSAVE) THEN
        Result := 0;

    WM_CLOSE :
      BEGIN
        Finishing := True;
        IF WaitForSingleObject(hThread, ThreadWait) = WAIT_TIMEOUT THEN
          MessageBox(h, 'Time elapsed, but the main thread isn''t finished yet. Terminating program now.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
        DestroyWindow(h);
      END;

  ELSE Result := DefWindowProc(h, m, w, l);
  END;
END;

PROCEDURE Preview(Wnd : HWND);
BEGIN
END;

PROCEDURE Customize(Wnd : HWND);
BEGIN
  MessageBox(Wnd, 'This screensaver is not customizeable.', '"Magic stone" screensaver', 0);
END;

PROCEDURE Test(What : HRESULT);
BEGIN
  IF What AND $80000000 = 0 THEN
    Exit;
  MessageBox(0, PChar(Format('Unknown error: 0x%8x', [What])), '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
  ExitThread(1);
END;

FUNCTION Main(Wnd : HWND) : Integer; STDCALL;
CONST
  MinGenFreq = 15;
  MaxGenFreq = 30;
  MinGenTime = 1 / MaxGenFreq;
  MaxGenTime = 1 / MinGenFreq;
  FPSScale = 10;
  FPSLabels = 10;
  ClipRect : TRect = (Left : 0; Top : 0; Right : ImageSizeX; Bottom : ImageSizeY);
VAR
  DDraw : IDirectDraw7;
  Primary : IDirectDrawSurface7;
  Surface : IDirectDrawSurface7;
  DDSD : TDDSurfaceDesc2;

  A, B, Freq : Int64;
  LagInt : Double;
  Lag2   : Double;
{$IFDEF DEBUG}
  I : Integer;
  Frames : Integer;
  FPSCnt : Double;
  FPS : Double;
  Frames2 : Integer;
  FPSCnt2 : Double;
  FPS2 : Double;
{$ENDIF}
BEGIN
  Test(DirectDrawCreateEx(NIL, DDraw, IID_IDirectDraw7, NIL));
  IF Fullscreen THEN
  BEGIN
    Test(DDraw.SetCooperativeLevel(Wnd, {DDSCL_NORMAL} DDSCL_EXCLUSIVE OR DDSCL_FULLSCREEN));
    Test(DDraw.SetDisplayMode(ImageSizeX, ImageSizeY, 32, 75, 0));
  END
  ELSE
    Test(DDraw.SetCooperativeLevel(Wnd, DDSCL_NORMAL));
  FillChar(DDSD, SizeOf(DDSD), 0);
  WITH DDSD DO
  BEGIN
    dwSize := SizeOf(DDSD);
    dwFlags := DDSD_CAPS;
    ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE OR DDSCAPS_VIDEOMEMORY;
  END;
  Test(DDraw.CreateSurface(DDSD, Primary, NIL));
  WITH DDSD DO
  BEGIN
    dwSize := SizeOf(DDSD);
    dwFlags := DDSD_CAPS OR DDSD_WIDTH OR DDSD_HEIGHT;
    dwWidth := ImageSizeX;
    dwHeight := ImageSizeY;
    ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN OR DDSCAPS_SYSTEMMEMORY;
  END;
  Test(DDraw.CreateSurface(DDSD, Surface, NIL));
  QueryPerformanceFrequency(Freq);
  QueryPerformanceCounter(A);

{$IFDEF DEBUG}
  Frames := 0;
  FPSCnt := 0;
  FPS := 0;
  Frames2 := 0;
  FPSCnt2 := 0;
  FPS2 := 0;
{$ENDIF}
  Lag2 := 0;

  Generate;

  TRY
    REPEAT
      B := A;
      QueryPerformanceCounter(A);
      LagInt := (A - B) / Freq;
      Time := Time - Round(LagInt * 1000);
      Lag2 := Lag2 + LagInt;
      IF Lag2 >= MinGenTime THEN
      BEGIN
        FillChar(DDSD, SizeOf(DDSD), 0);
        DDSD.dwSize := SizeOf(DDSD);
        Test(Surface.Lock(NIL, DDSD, DDLOCK_WAIT, 0));
        Pixels := DDSD.lpSurface;
        Fill4(Pixels^, ImageSizeX * ImageSizeY, $00000000);

        IF Lag2 >= MaxGenTime THEN
          Lag2 := MaxGenTime;
        LagCount := Lag2;//Trunc(Lag2 / MinGenTime) * MinGenTime;
        Lag2 := 0;//Lag2 - LagCount;
        Step;
{$IFDEF DEBUG}
        I := Round(FPS * FPSScale);
        IF I <= ImageSizeX THEN
          Bar(0, 6, I, 4, $0000FF00)
        ELSE
          FullBar(6, 4, $0000FFFF);

        I := Round(FPS2 * FPSScale);
        IF I <= ImageSizeX THEN
          Bar(0, 10, I, 4, $0000FF00)
        ELSE
          FullBar(10, 4, $0000FFFF);

        FOR I := 1 TO (ImageSizeX - 1) DIV FPSScale DIV 10 DO
          VLine(I * FPSScale * 10, 0, 20, $00FF0000);

        VLine(MinGenFreq * FPSScale, 0, 20, $000000FF);
        VLine(MaxGenFreq * FPSScale, 0, 20, $000000FF);
        VLine(60 * FPSScale, 0, 20, $000000FF);
        VLine(75 * FPSScale, 0, 20, $000000FF);
{$ENDIF}
        Test(Surface.UnLock(Pixels));
{$IFDEF DEBUG}
        Inc(Frames2);
        FPSCnt2 := FPSCnt2 + LagCount;
        IF FPSCnt2 >= 1 THEN
        BEGIN
          FPS2 := Frames2 / FPSCnt2;
          Frames2 := 0;
          FPSCnt2 := 0;
        END;
{$ENDIF}
      END;
      Primary.Blt(ClipRect, Surface, ClipRect, DDBLT_DONOTWAIT, PDDBltFx(NIL)^);
{$IFDEF DEBUG}
      Inc(Frames);
      FPSCnt := FPSCnt + LagInt;
      IF FPSCnt >= 1 THEN
      BEGIN
        FPS := Frames / FPSCnt;
        Frames := 0;
        FPSCnt := 0;
      END;
{$ENDIF}
    UNTIL Finishing;
  FINALLY
    Surface._Release;
    Primary._Release;
    DDraw._Release;
  END;
  ExitThread(0);
  Result := 0;
END;

PROCEDURE Start;
VAR WC : WNDCLASSEX;
  Msg : TMsg;
BEGIN
  WITH WC DO
  BEGIN
    cbSize := SizeOf(WC);
    style := CS_CLASSDC;
    lpfnWndProc := @WndProc;
    cbClsExtra := 0;
    cbWndExtra := 0;
    hInstance := SysInit.HInstance;
    hIcon := 0;
    hCursor := 0;
    hbrBackground := HBRUSH(COLOR_BTNFACE + 1);
    lpszMenuName := NIL;
    lpszClassName := 'ScrSvrWC';
    hIconSm := 0;
  END;
  IF RegisterClassEx(WC) = 0 THEN
  BEGIN
    MessageBox(0, 'Cannot create window class.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt;
  END;
// WS_EX_TOPMOST
  mx := $FFFF;
  my := $FFFF;
  hWindow := CreateWindowEx(WS_EX_TOPMOST, 'ScrSvrWC', 'ScrSvr', WS_POPUP, 0, 0, ImageSizeX, ImageSizeY, 0, 0, HInstance, NIL);
  IF hWindow = 0 THEN
  BEGIN
    MessageBox(0, 'Cannot create screensaver window.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt;
  END;
  ShowWindow(hWindow, SW_SHOW);
  UpdateWindow(hWindow);
  ShowCursor(False);
  hThread := CreateThread(NIL, 0, @Main, Pointer(hWindow), 0, dwThread);
  WHILE GetMessage(Msg, 0, 0, 0) DO
  BEGIN
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  END;
  IF WaitForSingleObject(hThread, ThreadWait) = WAIT_TIMEOUT THEN
    MessageBox(0, 'Time elapsed, but the main thread isn''t finished yet. Terminating program now.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
// MessageBox(0, 'This screensaver isn''t ready to using yet.', '"Magic stone" screensaver', 0);
END;

// ParamStr(1) = '/p' - small preview. ParamStr(2) is parent window handle.
// ParamStr(1) = '/c:xxx' - customizing. xxx is parent window handle.
// ParamStr(1) = '/s' - screensaver start.

BEGIN
  Randomize;
  IF ParamCount < 1 THEN
  BEGIN
    Fullscreen := False;
    Start;
  END
  ELSE
    IF ParamStr(1) = '/s' THEN
    BEGIN
      Fullscreen := True;
      Start;
    END
    ELSE IF ParamStr(1) = '/p' THEN
      Preview(StrToInt(ParamStr(2)))
    ELSE IF Copy(ParamStr(1), 1, 2) = '/c' THEN
      IF ParamStr(1) = '/c' THEN
        Customize(0)
      ELSE
        Customize(StrToInt(Copy(ParamStr(1), 4, 64)));
END.


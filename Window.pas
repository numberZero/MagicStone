unit Window;

interface

uses
  Windows, Messages, ScreenSaver;

procedure WndPrepare;
procedure WndCreateFullscreen;
procedure WndCreateDebug;
procedure WndCreatePreview;
procedure WndShow;
procedure WndRun;
procedure WndSetupWatch(ScreenSaverMode: Boolean);

var
  WndHandle : HWND;
  WndWidth  : Integer;
  WndHeight : Integer;
  WndFinishing : Boolean = False;

implementation

uses
  Main;

const
  WM_XBUTTONDOWN    = $020B;
  WM_XBUTTONUP      = $020C;
  WM_XBUTTONDBLCLK  = $020D;
  WM_MOUSEHWHEEL    = $020E;

var
  WndWatchActive : Boolean;
  WndWatchKeyboard : Boolean;
  WndWatchMouseButtons : Boolean;
  WndWatchMouseMove : Boolean;
  WndWatchMouseScroll : Boolean;

  MousePos : TPoint;

function WndProc(h : HWND; m : UINT; w : WPARAM; l : LPARAM) : LRESULT; stdcall;

  procedure Close;
  begin
    PostMessage(h, WM_CLOSE, 0, 0);
  end;

  procedure MProc;
  var
    Pos : TPoint;
  begin
    GetCursorPos(Pos);
    if (MousePos.X <> Pos.X) or (MousePos.Y <> Pos.Y) then
      Close;
  end;

begin
  Result := 0;
  CASE m OF
    WM_ACTIVATE,
    WM_ACTIVATEAPP,
    WM_NCACTIVATE:
      IF WndWatchActive and (w = 0) THEN
        Close;

    WM_KEYDOWN,
    WM_KEYUP,
    WM_CHAR:
      if WndWatchKeyboard then
        Close;

    WM_MOUSEWHEEL,
    WM_MOUSEHWHEEL:
      if WndWatchMouseScroll then
        Close;

    WM_LBUTTONDOWN,
    WM_RBUTTONDOWN,
    WM_MBUTTONDOWN,
    WM_XBUTTONDOWN,
    WM_LBUTTONUP,
    WM_RBUTTONUP,
    WM_MBUTTONUP,
    WM_XBUTTONUP:
      if WndWatchMouseButtons then
        Close;

    WM_MOUSEMOVE:
      if WndWatchMouseMove then
        MProc;

    WM_CREATE:
      begin
        GetCursorPos(MousePos);
        Result := 0;
      end;

    WM_DESTROY:
      begin
        WndFinishing := True;
        if WaitForSingleObject(ThreadHandle, 1000) = WAIT_TIMEOUT then
        begin
          MessageBox(h, 'Time elapsed, but the main thread isn''t finished yet. Terminating program now.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
          TerminateThread(ThreadHandle, 1);
        end;
        PostQuitMessage(0);
      end;

//    WM_SYSCOMMAND:
//      if (w and $FFF0 = SC_CLOSE) or (w and $FFF0 = SC_SCREENSAVE) then
//        Result := 0
//      else
//        Result := DefWindowProc(h, m, w, l);

    WM_CLOSE :
      begin
        WndFinishing := True;
        if WaitForSingleObject(ThreadHandle, 1000) = WAIT_TIMEOUT then
        begin
          MessageBox(h, 'Time elapsed, but the main thread isn''t finished yet. Terminating program now.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
          TerminateThread(ThreadHandle, 1);
        end;
        DestroyWindow(h);
      end;

  else
    Result := DefWindowProc(h, m, w, l);
  end;
end;

procedure WndSetupWatch;
begin
  if ScreenSaverMode then
  begin
    WndWatchActive := True;
    WndWatchKeyboard := True;
    WndWatchMouseButtons := True;
    WndWatchMouseMove := True;
    WndWatchMouseScroll := True;
  end
  else
  begin
    WndWatchActive := False;
    WndWatchKeyboard := False;
    WndWatchMouseButtons := False;
    WndWatchMouseMove := False;
    WndWatchMouseScroll := False;
  end;
end;

procedure WndPrepare;
var WindowClass: WNDCLASSEX;
begin
  with WindowClass do
  begin
    cbSize := SizeOf(WindowClass);
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
  end;
  if RegisterClassEx(WindowClass) = 0 then
  begin
    MessageBox(0, 'Cannot create window class.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt;
  end;
end;

procedure WndCreateFullscreen;
begin
  WndSetupWatch(True);
  WndWidth := GetSystemMetrics(SM_CXSCREEN);
  WndHeight := GetSystemMetrics(SM_CYSCREEN);

  WndHandle := CreateWindowEx(0, 'ScrSvrWC', 'ScrSvr',
    WS_POPUP, 0, 0, WndWidth, WndHeight,
    Parent, 0, HInstance, NIL);
  if WndHandle = 0 then
  begin
    MessageBox(0, 'Cannot create screensaver window.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt;
  end;
end;

procedure WndCreateDebug;
var
  Style : Integer;
  R : TRect;
begin
  WndSetupWatch(False);
  Style := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU;
  R.Left := 0;
  R.Top := 0;
  R.Right := WndWidth;
  R.Bottom := WndHeight;
  AdjustWindowRect(R, Style, False);
  WndHandle := CreateWindowEx(0, 'ScrSvrWC', 'ScrSvr',
    Style,
    Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT),
    R.Right - R.Left,
    R.Bottom - R.Top,
    Parent, 0, HInstance, NIL);
  if WndHandle = 0 then
  begin
    MessageBox(0, 'Cannot create screensaver window.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt;
  end;
end;

procedure WndCreatePreview;
var
  R : TRect;
begin
  GetWindowRect(Parent, R);
  WndSetupWatch(False);
  WndWidth := R.Right - R.Left;
  WndHeight := R.Bottom - R.Top;
{
  Parent := CreateWindowEx(0, 'ScrSvrWC', 'ScrSvr1',
    WS_POPUP, 0, 0, 800, 600,
    0, 0, HInstance, NIL);
  ShowWindow(Parent, SW_SHOW);
}
  WndHandle := CreateWindowEx(0, 'ScrSvrWC', 'ScrSvr',
    WS_CHILD, 0, 0, WndWidth, WndHeight,
    Parent, 0, HInstance, NIL);
  if WndHandle = 0 then
  begin
    MessageBox(0, 'Cannot create screensaver window.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
    Halt;
  end;
end;

procedure WndShow;
begin
  ShowWindow(WndHandle, SW_SHOW);
  UpdateWindow(WndHandle);
  BringWindowToTop(WndHandle);
end;

procedure WndRun;
var Msg: TMsg;
begin
  while GetMessage(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

(*
PROCEDURE Start;
BEGIN
  mx := $FFFF;
  my := $FFFF;
  WndInit;
  WndShow;
  hThread := CreateThread(NIL, 0, @Main, Pointer(hWindow), 0, dwThread);
  WndRun;
  IF WaitForSingleObject(hThread, ThreadWait) = WAIT_TIMEOUT THEN
    MessageBox(0, 'Time elapsed, but the main thread isn''t finished yet. Terminating program now.', '"Magic stone" screensaver', MB_ICONERROR OR MB_OK);
END;
*)
end.

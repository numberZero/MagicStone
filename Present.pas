unit Present;

interface

uses
  Windows, SysUtils, DirectX;

var
  VideoData : PIntegerArray = nil;
  VideoWidth : Integer;
  VideoHeight : Integer;
  VideoPitch : Integer;

procedure VideoInitialize;
procedure VideoFinalize;
procedure VideoBegin;
procedure VideoEnd;

implementation

uses
  Window;

var
  DDraw : IDirectDraw7;
  Primary : IDirectDrawSurface7;
  Surface : IDirectDrawSurface7;
  DDSD : TDDSurfaceDesc2;
  ClipRect : TRect;

procedure Test(Result : HRESULT);
begin
  if Failed(Result) then
  begin
    MessageBox(0, PChar(Format('DirectDraw error 0x%8x', [Result])), '"Magic stone" screensaver', MB_ICONERROR or MB_OK);
    ExitThread(1);
  end;
end;

procedure VideoInitialize;
begin
  Test(DirectDrawCreateEx(nil, DDraw, IID_IDirectDraw7, nil));
  Test(DDraw.SetCooperativeLevel(WndHandle, DDSCL_NORMAL or DDSCL_ALLOWREBOOT));
  FillChar(DDSD, SizeOf(DDSD), 0);
  with DDSD do
  begin
    dwSize := SizeOf(DDSD);
    dwFlags := DDSD_CAPS;
    ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_VIDEOMEMORY;
  end;
  Test(DDraw.CreateSurface(DDSD, Primary, nil));
  with DDSD do
  begin
    dwSize := SizeOf(DDSD);
    dwFlags := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT or DDSD_PIXELFORMAT;
    dwWidth := VideoWidth;
    dwHeight := VideoHeight;
    ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;
  end;
  DDSD.ddpfPixelFormat.dwSize := SizeOf(DDSD.ddpfPixelFormat);
  DDSD.ddpfPixelFormat.dwFlags := DDPF_RGB;
  DDSD.ddpfPixelFormat.dwRGBBitCount := 32;
  DDSD.ddpfPixelFormat.dwRBitMask := $00FF0000;
  DDSD.ddpfPixelFormat.dwGBitMask := $0000FF00;
  DDSD.ddpfPixelFormat.dwBBitMask := $000000FF;
  Test(DDraw.CreateSurface(DDSD, Surface, nil));
end;

procedure VideoFinalize;
begin
  Surface := nil;
  Primary := nil;
  DDraw := nil;
end;

procedure VideoBegin;
begin
  Assert(VideoData = nil);
  FillChar(DDSD, SizeOf(DDSD), 0);
  DDSD.dwSize := SizeOf(DDSD);
  Test(Surface.Lock(nil, DDSD, DDLOCK_WAIT, 0));
  VideoData := DDSD.lpSurface;
  if DDSD.dwFlags and DDSD_WIDTH <> 0 then
    VideoWidth := DDSD.dwWidth
  else
    VideoWidth := 0;
  if DDSD.dwFlags and DDSD_HEIGHT <> 0 then
    VideoHeight := DDSD.dwHeight
  else
    VideoHeight := 0;
  if DDSD.dwFlags and DDSD_PITCH <> 0 then
    VideoPitch := DDSD.lPitch div 4
  else if DDSD.dwFlags and DDSD_LINEARSIZE <> 0 then
    VideoPitch := Integer(DDSD.dwLinearSize) div (VideoHeight * 4)
  else
    VideoPitch := VideoWidth;
end;

procedure VideoEnd;
var
  Border : Integer;
begin
  Assert(VideoData <> nil);
  Test(Surface.UnLock(VideoData));
  VideoData := nil;
  if not IsWindow(WndHandle) then
  begin
    VideoFinalize;
    ExitThread(0);
  end;
  GetWindowRect(WndHandle, ClipRect);
  Border := (ClipRect.Right - ClipRect.Left - WndWidth) div 2;
  Dec(ClipRect.Bottom, Border);
  Inc(ClipRect.Left, Border);
  ClipRect.Top := ClipRect.Bottom - WndHeight;
  ClipRect.Right := ClipRect.Left + WndWidth;
  Primary.Blt(ClipRect, Surface, PRect(nil)^, DDBLT_DONOTWAIT, PDDBltFx(NIL)^);
end;

(*
  FPSScale : Integer;

  FPSLabelMin : Integer;
  FPSLabelMax : Integer;
  FPSLabelA : Integer;
  FPSLabelB : Integer;

  I : Integer;
  Frames : Integer;
  FPSCnt : Double;
  FPS : Double;
  Frames2 : Integer;
  FPSCnt2 : Double;
  FPS2 : Double;
BEGIN
  FPSScale := 10;

  FPSLabelMin := Round(MinGenFreq * FPSScale);
  FPSLabelMax := Round(MaxGenFreq * FPSScale);
  FPSLabelA := Round(60 * FPSScale);
  FPSLabelB := Round(75 * FPSScale);
  Frames := 0;
  FPSCnt := 0;
  FPS := 0;
  Frames2 := 0;
  FPSCnt2 := 0;
  FPS2 := 0;

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

        VLine(FPSLabelMin, 10, 10, $00FFFF00);
        VLine(FPSLabelMax, 10, 10, $00FFFF00);
        VLine(FPSLabelA, 0, 20, $000000FF);
        VLine(FPSLabelB, 0, 20, $000000FF);

        Inc(Frames2);
        FPSCnt2 := FPSCnt2 + LagCount;
        IF FPSCnt2 >= 1 THEN
        BEGIN
          FPS2 := Frames2 / FPSCnt2;
          Frames2 := 0;
          FPSCnt2 := 0;
        END;

      Inc(Frames);
      FPSCnt := FPSCnt + LagInt;
      IF FPSCnt >= 1 THEN
      BEGIN
        FPS := Frames / FPSCnt;
        Frames := 0;
        FPSCnt := 0;
      END;

*)
end.

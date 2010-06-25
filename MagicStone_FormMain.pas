UNIT MagicStone_FormMain;

INTERFACE

USES Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
 Dialogs, ExtCtrls, DIB, DirectX, DXClass, Math, DXDraws;

TYPE TFormMain = CLASS(TForm)
  DXT : TDXTimer;
    DXD: TDXDraw;
  PROCEDURE Initialize(Sender : TObject);
  PROCEDURE DXTTimer(Sender : TObject; Lag : Integer);
  PROCEDURE Regenerate(Sender : TObject);
 END;
 
VAR FormMain : TFormMain;
 
IMPLEMENTATION

USES MagicStones_UnitMain;

{$R *.dfm}

CONST ImageSize = 512;
 ImageSize2 = ImageSize DIV 2;
 PointsCount = 1024;
 PointsMax = PointsCount - 1;
 ObjectMoutionBlurDepth = 8;
 ObjectMoutionBlurMax = ObjectMoutionBlurDepth - 1;

 MinVelA = Pi / 3000;
 MaxVelA = Pi / 2000;
 BasePosR = 192;
 BaseVelR = 0.00;
 VelRPerS = 0.0010;
 MaxPosH = 45;
 MinVelH = 0.005;
 MaxVelH = 0.030;
 
TYPE TObj = RECORD
  PosA : Double;
  PosR : Double;
  PosH : Double;
  VelA : Double;
  VelR : Double;
  VelH : Double;
 END;
 TColor3I = RECORD
  R, G, B : Integer;
 END;
 TOMBPoint = RECORD
  X, Y : SmallInt;
  Color : Integer;
 END;
 TImageData = ARRAY[0..ImageSize - 1, 0..ImageSize - 1] OF Integer;
 
VAR Points : ARRAY[0..PointsMax] OF TObj;
 OMBObjs : ARRAY[0..ObjectMoutionBlurMax, 0..PointsMax] OF TOMBPoint;
 OMBIndex : Integer;
 Pic : TDIB;
 DDSD : TDDSurfaceDesc;
 Pixels : ^TImageData;
 LagCount : Integer;
 TimeBeforeRestart : Integer;
 
PROCEDURE TFormMain.Initialize;
BEGIN
 RandomIze;
 DXD.Surface.Fill(0);
 WITH DXD.Surface.Canvas DO
  BEGIN
   Brush.Color := clBlack;
   Pen.Color := clWhite;
   Font.Name := 'Arial';
   Font.Size := 10;
   Font.Color := clWhite;
  END;
 Pic := TDIB.Create;
 Pic.SetSize(ImageSize, ImageSize, 32);
 Regenerate(NIL);
END;

PROCEDURE TFormMain.DXTTimer;

VAR Src1 : TRGBQuad;
 Dst1 : TRGBQuad;
 Src2 : TColor3I;
 Dst2 : TColor3I;
 Opac : Integer;
 
 FUNCTION AddTransparentColor(Bkg, Clr : Integer) : Integer;
 BEGIN
  Src1 := TRGBQuad(Clr);
  Dst1 := TRGBQuad(Bkg);
  Src2.R := Src1.rgbRed;
  Src2.G := Src1.rgbGreen;
  Src2.B := Src1.rgbBlue;
  Dst2.R := Dst1.rgbRed;
  Dst2.G := Dst1.rgbGreen;
  Dst2.B := Dst1.rgbBlue;
  Dst2.R := Dst2.R + ((Src2.R * Opac) SHR 8);
  Dst2.G := Dst2.G + ((Src2.G * Opac) SHR 8);
  Dst2.B := Dst2.B + ((Src2.B * Opac) SHR 8);
  IF Dst2.R < 0 THEN
   Dst2.R := 0
  ELSE
   IF Dst2.R > $FF THEN Dst2.R := $FF;
  IF Dst2.G < 0 THEN
   Dst2.G := 0
  ELSE
   IF Dst2.G > $FF THEN Dst2.G := $FF;
  IF Dst2.B < 0 THEN
   Dst2.B := 0
  ELSE
   IF Dst2.B > $FF THEN Dst2.B := $FF;
  Dst1.rgbRed := Dst2.R;
  Dst1.rgbGreen := Dst2.G;
  Dst1.rgbBlue := Dst2.B;
  Result := Integer(Dst1);
 END;
 
 FUNCTION AddTransparentColor2(Bkg, Clr, Opac : Integer) : Integer;
 BEGIN
  Src1 := TRGBQuad(Clr);
  Dst1 := TRGBQuad(Bkg);
  Src2.R := Src1.rgbRed;
  Src2.G := Src1.rgbGreen;
  Src2.B := Src1.rgbBlue;
  Dst2.R := Dst1.rgbRed;
  Dst2.G := Dst1.rgbGreen;
  Dst2.B := Dst1.rgbBlue;
  Dst2.R := Dst2.R + ((Src2.R * Opac) SHR 8);
  Dst2.G := Dst2.G + ((Src2.G * Opac) SHR 8);
  Dst2.B := Dst2.B + ((Src2.B * Opac) SHR 8);
  IF Dst2.R < 0 THEN
   Dst2.R := 0
  ELSE
   IF Dst2.R > $FF THEN Dst2.R := $FF;
  IF Dst2.G < 0 THEN
   Dst2.G := 0
  ELSE
   IF Dst2.G > $FF THEN Dst2.G := $FF;
  IF Dst2.B < 0 THEN
   Dst2.B := 0
  ELSE
   IF Dst2.B > $FF THEN Dst2.B := $FF;
  Dst1.rgbRed := Dst2.R;
  Dst1.rgbGreen := Dst2.G;
  Dst1.rgbBlue := Dst2.B;
  Result := Integer(Dst1);
 END;
 
VAR I, J : Integer;
 X, Y : Integer;
 Color : Integer;

 PROCEDURE DrawOMBImage(ObjsIndex, Index : Integer);
 VAR A, B, I : Integer;
 BEGIN
  Opac := Round((1 - IntPower(Index / ObjectMoutionBlurMax, 2)) * 255);
  A := Opac * $A0 SHR 8;
  B := Opac * $60 SHR 8;
  FOR I := 0 TO PointsMax DO
   WITH OMBObjs[ObjsIndex, I] {, Points[I]} DO
    BEGIN
     IF (X < 1) OR (X > (ImageSize - 2)) THEN
      Continue;
     IF (Y < 1) OR (Y > (ImageSize - 2)) THEN
      Continue;
     Pixels[X, Y] := AddTransparentColor(Pixels[X, Y], Color);
     Pixels[X - 1, Y] := AddTransparentColor2(Pixels[X - 1, Y], Color, A);
     Pixels[X + 1, Y] := AddTransparentColor2(Pixels[X + 1, Y], Color, A);
     Pixels[X, Y - 1] := AddTransparentColor2(Pixels[X, Y - 1], Color, A);
     Pixels[X, Y + 1] := AddTransparentColor2(Pixels[X, Y + 1], Color, A);
     Pixels[X - 1, Y - 1] := AddTransparentColor2(Pixels[X - 1, Y - 1], Color,
      B);
     Pixels[X - 1, Y + 1] := AddTransparentColor2(Pixels[X - 1, Y + 1], Color,
      B);
     Pixels[X + 1, Y - 1] := AddTransparentColor2(Pixels[X + 1, Y - 1], Color,
      B);
     Pixels[X + 1, Y + 1] := AddTransparentColor2(Pixels[X + 1, Y + 1], Color,
      B);
    END;
 END;

LABEL Finish;
BEGIN
 Inc(LagCount, Lag * Integer(DXT.Interval));
 IF LagCount < 50 THEN
  GOTO Finish;
 Dec(TimeBeforeRestart, LagCount);
 IF TimeBeforeRestart <= 0 THEN
  Regenerate(NIL);
 DXD.Surface.Lock(DDSD);
 IF DDSD.ddpfPixelFormat.dwRGBBitCount <> 32 THEN
  BEGIN
   DXT.Enabled := False;
   MessageDlg('Only 32bpp color mode supported', mtError, [mbOk], 0);
   Halt(1);
  END;
 Pixels := DDSD.lpSurface;
 FillChar(Pixels^, SizeOf(Pixels^), 0);
 FOR I := 0 TO PointsMax DO
  WITH Points[I] DO
   BEGIN
    VelR := VelR - (PosR * (LagCount * (VelRPerS / 1000)));
    PosA := PosA + VelA * LagCount;
    PosR := PosR + VelR * LagCount;
    PosH := PosH + VelH * LagCount;
    IF PosH >= +180 THEN
     PosH := PosH - 360
    ELSE
     IF PosH <= -180 THEN PosH := PosH + 360;
    X := Round(Sin(PosA) * PosR) + ImageSize2;
    Y := Round(Cos(PosA) * PosR) + ImageSize2;
    IF (X < 1) OR (X > (ImageSize - 2)) THEN
     Continue;
    IF (Y < 1) OR (Y > (ImageSize - 2)) THEN
     Continue;
    Color := Make_RGB_From_H(PosH);
    Pixels[X, Y] := Color;
    Pixels[X - 1, Y] := AddTransparentColor2(Pixels[X - 1, Y], Color, $A0);
    Pixels[X + 1, Y] := AddTransparentColor2(Pixels[X + 1, Y], Color, $A0);
    Pixels[X, Y - 1] := AddTransparentColor2(Pixels[X, Y - 1], Color, $A0);
    Pixels[X, Y + 1] := AddTransparentColor2(Pixels[X, Y + 1], Color, $A0);
    Pixels[X - 1, Y - 1] := AddTransparentColor2(Pixels[X - 1, Y - 1], Color,
     $60);
    Pixels[X - 1, Y + 1] := AddTransparentColor2(Pixels[X - 1, Y + 1], Color,
     $60);
    Pixels[X + 1, Y - 1] := AddTransparentColor2(Pixels[X + 1, Y - 1], Color,
     $60);
    Pixels[X + 1, Y + 1] := AddTransparentColor2(Pixels[X + 1, Y + 1], Color,
     $60);
    OMBObjs[OMBIndex, I].X := X;
    OMBObjs[OMBIndex, I].Y := Y;
    OMBObjs[OMBIndex, I].Color := Color;
   END;
 J := 0;
 FOR I := OMBIndex - 1 DOWNTO 0 DO
  BEGIN
   DrawOMBImage(I, J);
   Inc(J);
  END;
 FOR I := ObjectMoutionBlurMax DOWNTO OMBIndex + 1 DO
  BEGIN
   DrawOMBImage(I, J);
   Inc(J);
  END;
 Inc(OMBIndex);
 IF OMBIndex = ObjectMoutionBlurDepth THEN
  OMBIndex := 0;
 DXD.Surface.UnLock;
 LagCount := 0;
 Finish :
 DXD.Surface.Canvas.TextOut(8, 8, IntToStr(DXT.FrameRate));
 DXD.Surface.Canvas.Release;
 DXD.Flip;
END;

PROCEDURE TFormMain.Regenerate;
VAR Index : Integer;
 BaseH : Double;
 BaseVelH : Double;
BEGIN
 BaseH := RandomF2(-180, 180);
 BaseVelH := RandomF4(-MaxVelH, -MinVelH, +MinVelH, +MaxVelH);
 TimeBeforeRestart := Random(20000) + 10000;
 FOR Index := 0 TO PointsMax DO
  WITH Points[Index] DO
   BEGIN
    PosA := RandomF2(-Pi, +Pi);
    PosR := RandomF1(BasePosR);
    PosH := BaseH + RandomF2(-MaxPosH, MaxPosH);
    VelA := RandomF4(-MaxVelA, -MinVelA, +MinVelA, +MaxVelA);
    VelR := RandomF2(-BaseVelR, +BaseVelR);
    VelH := BaseVelH;
   END;
END;

END.


UNIT MagicStone_FormMain;

INTERFACE

USES Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
     Dialogs, DIB, ExtCtrls, DXClass, Math;

TYPE TForm1 = CLASS(TForm)
    Panel1: TPanel;
    DXPB: TDXPaintBox;
    DXT: TDXTimer;
    PROCEDURE FormCreate(Sender: TObject);
    PROCEDURE DXTTimer(Sender: TObject; LagCount: Integer);
    procedure DXPBClick(Sender: TObject);
END;

VAR Form1 : TForm1;

IMPLEMENTATION

{$R *.dfm}
{DEFINE MoutionBlur_Image}
{$DEFINE MoutionBlur_Object}
{$DEFINE SmoothPoints}

CONST ImageSize   = 512;
      ImageSize2  = ImageSize DIV 2;
      PointsCount = 1024;
      PointsMax   = PointsCount - 1;
{$IFDEF MoutionBlur_Image}
      ImageMoutionBlurDepth = 4;
      ImageMoutionBlurMax = ImageMoutionBlurDepth - 1;
{$ENDIF}
{$IFDEF MoutionBlur_Object}
      ObjectMoutionBlurDepth = 8;
      ObjectMoutionBlurMax = ObjectMoutionBlurDepth - 1;
{$ENDIF}

      MinVelA = Pi / 3000;
      MaxVelA = Pi / 2000;
      BasePosR = 192;
      BaseVelR = 0.00;
      VelRPerS = 0.0010;

TYPE TObj = RECORD
 PosA : Double;
 PosR : Double;
 VelA : Double;
 VelR : Double;
 Color : Integer;
END;
     TColor3I = RECORD
 R, G, B : Integer;
END;
     TOMBPoint = RECORD
 X, Y  : SmallInt;
 Color : Integer;
END;

VAR Points   : ARRAY[0..PointsMax] OF TObj;
{$IFDEF MoutionBlur_Image}
    IMBBufs  : ARRAY[0..ImageMoutionBlurMax] OF TDIB;
    IMBIndex : Integer;
{$ENDIF}
{$IFDEF MoutionBlur_Object}
    OMBObjs  : ARRAY[0..ObjectMoutionBlurMax, 0..PointsMax] OF TOMBPoint;
    OMBIndex : Integer;
{$ENDIF}

PROCEDURE TForm1.FormCreate;
{$IFDEF MoutionBlur_Image}
VAR Index : Integer;
{$ENDIF}
BEGIN
 RandomIze;
 DXPB.DIB.SetSize(ImageSize, ImageSize, 32);
 FillChar(DXPB.DIB.PBits^, DXPB.DIB.Size, 0);
{$IFDEF MoutionBlur_Image}
 IMBIndex := 0;
 FOR Index := 0 TO ImageMoutionBlurMax DO
  BEGIN
   IMBBufs[Index] := TDIB.Create;
   IMBBufs[Index].SetSize(ImageSize, ImageSize, 32);
   Fill4(0, IMBBufs[Index].PBits, ImageSize * ImageSize);
  END;
{$ENDIF}
 DXPBClick(NIL);
END;

PROCEDURE TForm1.DXTTimer;

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
  IF Dst2.R < 0 THEN Dst2.R := 0 ELSE IF Dst2.R > $FF THEN Dst2.R := $FF;
  IF Dst2.G < 0 THEN Dst2.G := 0 ELSE IF Dst2.G > $FF THEN Dst2.G := $FF;
  IF Dst2.B < 0 THEN Dst2.B := 0 ELSE IF Dst2.B > $FF THEN Dst2.B := $FF;
  Dst1.rgbRed   := Dst2.R;
  Dst1.rgbGreen := Dst2.G;
  Dst1.rgbBlue  := Dst2.B;
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
  IF Dst2.R < 0 THEN Dst2.R := 0 ELSE IF Dst2.R > $FF THEN Dst2.R := $FF;
  IF Dst2.G < 0 THEN Dst2.G := 0 ELSE IF Dst2.G > $FF THEN Dst2.G := $FF;
  IF Dst2.B < 0 THEN Dst2.B := 0 ELSE IF Dst2.B > $FF THEN Dst2.B := $FF;
  Dst1.rgbRed   := Dst2.R;
  Dst1.rgbGreen := Dst2.G;
  Dst1.rgbBlue  := Dst2.B;
  Result := Integer(Dst1);
 END;

VAR I, J : Integer;
    X, Y : Integer;
    Pic  : TDIB;
{$IFDEF MoutionBlur_Image}
    SrcL : PIntegerArray;
    DstL : PIntegerArray;

 PROCEDURE DrawIMBImage(Image : TDIB; Index : Integer);
 VAR X, Y : Integer;
 BEGIN
  Opac := Round((1 - IntPower(Index / ImageMoutionBlurMax, 2)) * 255);
  FOR Y := 0 TO ImageSize - 1 DO
   BEGIN
    SrcL := Image.ScanLineReadOnly[Y];
    DstL := DXPB.DIB.ScanLine[Y];
    FOR X := 0 TO ImageSize - 1 DO
     DstL[X] := AddTransparentColor(DstL[X], SrcL[X]);
   END;
 END;
{$ENDIF}
{$IFDEF MoutionBlur_Object}
 PROCEDURE DrawOMBImage(ObjsIndex, Index : Integer);
 VAR A, B, I : Integer;
 BEGIN
  Opac := Round((1 - IntPower(Index / ObjectMoutionBlurMax, 2)) * 255);
  A := Opac * $A0 SHR 8;
  B := Opac * $60 SHR 8;
  FOR I := 0 TO PointsMax DO
   WITH OMBObjs[ObjsIndex, I]{, Points[I]} DO
    BEGIN
{$IFDEF SmoothPoints}
     Pic.Pixels[X, Y] := AddTransparentColor(Pic.Pixels[X, Y], Color);
     Pic.Pixels[X-1, Y] := AddTransparentColor2(Pic.Pixels[X-1, Y], Color, A);
     Pic.Pixels[X+1, Y] := AddTransparentColor2(Pic.Pixels[X+1, Y], Color, A);
     Pic.Pixels[X, Y-1] := AddTransparentColor2(Pic.Pixels[X, Y-1], Color, A);
     Pic.Pixels[X, Y+1] := AddTransparentColor2(Pic.Pixels[X, Y+1], Color, A);
     Pic.Pixels[X-1, Y-1] := AddTransparentColor2(Pic.Pixels[X-1, Y-1], Color, B);
     Pic.Pixels[X-1, Y+1] := AddTransparentColor2(Pic.Pixels[X-1, Y+1], Color, B);
     Pic.Pixels[X+1, Y-1] := AddTransparentColor2(Pic.Pixels[X+1, Y-1], Color, B);
     Pic.Pixels[X+1, Y+1] := AddTransparentColor2(Pic.Pixels[X+1, Y+1], Color, B);
{$ELSE}
     Pic.Pixels[X, Y]   := AddTransparentColor(Pic.Pixels[X, Y]  , Color);
     Pic.Pixels[X-1, Y] := AddTransparentColor(Pic.Pixels[X-1, Y], Color);
     Pic.Pixels[X+1, Y] := AddTransparentColor(Pic.Pixels[X+1, Y], Color);
     Pic.Pixels[X, Y-1] := AddTransparentColor(Pic.Pixels[X, Y-1], Color);
     Pic.Pixels[X, Y+1] := AddTransparentColor(Pic.Pixels[X, Y+1], Color);
{$ENDIF}
    END;
 END;
{$ENDIF}

BEGIN
// LagCount := 100;
{$IFDEF MoutionBlur_Image}
 Pic := IMBBufs[IMBIndex];
{$ELSE}
 Pic := DXPB.DIB;
{$ENDIF}
 FillChar(Pic.PBits^, Pic.Size, 0);
 FOR I := 0 TO PointsMax DO
  WITH Points[I] DO
   BEGIN
    VelR := VelR - (PosR * (LagCount * (VelRPerS / 1000)));
    PosA := PosA + VelA * LagCount;
    PosR := PosR + VelR * LagCount;
    X := Round(Sin(PosA) * PosR) + ImageSize2;
    Y := Round(Cos(PosA) * PosR) + ImageSize2;
{$IFDEF SmoothPoints}
    Pic.Pixels[X, Y] := Color;
    Pic.Pixels[X-1, Y] := AddTransparentColor2(Pic.Pixels[X-1, Y], Color, $A0);
    Pic.Pixels[X+1, Y] := AddTransparentColor2(Pic.Pixels[X+1, Y], Color, $A0);
    Pic.Pixels[X, Y-1] := AddTransparentColor2(Pic.Pixels[X, Y-1], Color, $A0);
    Pic.Pixels[X, Y+1] := AddTransparentColor2(Pic.Pixels[X, Y+1], Color, $A0);
    Pic.Pixels[X-1, Y-1] := AddTransparentColor2(Pic.Pixels[X-1, Y-1], Color, $60);
    Pic.Pixels[X-1, Y+1] := AddTransparentColor2(Pic.Pixels[X-1, Y+1], Color, $60);
    Pic.Pixels[X+1, Y-1] := AddTransparentColor2(Pic.Pixels[X+1, Y-1], Color, $60);
    Pic.Pixels[X+1, Y+1] := AddTransparentColor2(Pic.Pixels[X+1, Y+1], Color, $60);
{$ELSE}
    Pic.Pixels[X, Y] := Color;
    Pic.Pixels[X-1, Y] := Color;
    Pic.Pixels[X+1, Y] := Color;
    Pic.Pixels[X, Y-1] := Color;
    Pic.Pixels[X, Y+1] := Color;
{$ENDIF}
{$IFDEF MoutionBlur_Object}
    OMBObjs[OMBIndex, I].X := X;
    OMBObjs[OMBIndex, I].Y := Y;
    OMBObjs[OMBIndex, I].Color := Color;
{$ENDIF}
   END;
{$IFDEF MoutionBlur_Image}
 Move(IMBBufs[IMBIndex].PBits^, DXPB.DIB.PBits^, ImageSize * ImageSize * 4);
 J := 0;
 FOR I := IMBIndex - 1 DOWNTO 0 DO
  BEGIN
   DrawIMBImage(IMBBufs[I], J);
   Inc(J);
  END;
 FOR I := ImageMoutionBlurMax DOWNTO IMBIndex + 1 DO
  BEGIN
   DrawIMBImage(IMBBufs[I], J);
   Inc(J);
  END;
 Inc(IMBIndex);
 IF IMBIndex = ImageMoutionBlurDepth THEN
  IMBIndex := 0;
{$ENDIF}
{$IFDEF MoutionBlur_Object}
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
{$ENDIF}
 Pic.Canvas.TextOut(8, 8, IntToStr(DXT.FrameRate));
 DXPB.Paint;
END;

FUNCTION RandomF1(Max : Single) : Single;
BEGIN
 Result := Random * Max;
END;

FUNCTION RandomF2(Min, Max : Single) : Single;
BEGIN
 Result := Min + Random * (Max - Min);
END;

FUNCTION RandomF3(Min, Mid, Max : Single) : Single;
BEGIN
 Result := RandomF2(RandomF2(Min, Mid), Max);
END;

FUNCTION RandomF4(Min1, Max1, Min2, Max2 : Single) : Single;
VAR A, B : Single;
BEGIN
 A := Abs(Max1 - Min1) + Abs(Max2 - Min2);
 B := Random * A + Min1;
 IF B > Max1 THEN
  B := B + (Min2 - Max1);
 Result := B;
END;

FUNCTION RandomD(R1, R2, G1, G2, B1, B2, A1, A2 : Byte) : Cardinal;
VAR R, G, B, A : Byte;
BEGIN
 R := Random(R2 - R1) + R1;
 G := Random(G2 - G1) + G1;
 B := Random(B2 - B1) + B1;
 A := Random(A2 - A1) + A1;
 Result := (A SHL 24) OR (R SHL 16) OR (G SHL 8) OR B;
END;

PROCEDURE TForm1.DXPBClick;
VAR Index : Integer;
BEGIN
 FOR Index := 0 TO PointsMax DO
  WITH Points[Index] DO
   BEGIN
    PosA := RandomF2(-Pi, +Pi);
    PosR := RandomF1(BasePosR);
    VelA := RandomF4(-MaxVelA, -MinVelA, +MinVelA, +MaxVelA);
    VelR := RandomF2(-BaseVelR, +BaseVelR);
//    Color := RandomD(255, 255, 0, 255, 0, 0, 0, 0);
    Color := RandomD(0, 255, 0, 255, 255, 255, 0, 0);
   END;
END;

END.


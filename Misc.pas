UNIT Misc;

INTERFACE

USES Windows, Math;

FUNCTION Make_RGB_From_H(Hue : Double) : Integer;
FUNCTION RandomF1(Max : Single) : Single;
FUNCTION RandomF2(Min, Max : Single) : Single;
FUNCTION RandomF3(Min, Mid, Max : Single) : Single;
FUNCTION RandomF4(Min1, Max1, Min2, Max2 : Single) : Single;
FUNCTION RandomD(R1, R2, G1, G2, B1, B2, A1, A2 : Byte) : Cardinal;
PROCEDURE AddTransparentColor(VAR Pixel : Integer; Color : Integer);
PROCEDURE AddTransparentColor2(VAR Pixel : Integer; Color, Opacity : Integer);
PROCEDURE Fill4(VAR X; Count : Integer; Filler : Cardinal);

IMPLEMENTATION

FUNCTION Make_RGB_From_H;
VAR Color : TRGBQuad ABSOLUTE Result;
BEGIN
  IF Hue < 0
    THEN
    Hue := Hue + 360
  ELSE
    IF Hue >= 360
      THEN Hue := Hue - 360;
  Result := $00000000;
  IF Hue <= 60 THEN
  BEGIN
    Color.rgbRed := 255;
    Color.rgbGreen := Round((Hue) * (255 / 60));
  END
  ELSE
    IF Hue <= 120 THEN
    BEGIN
      Color.rgbRed := Round((120 - Hue) * (255 / 60));
      Color.rgbGreen := 255;
    END
    ELSE
      IF Hue <= 180 THEN
      BEGIN
        Color.rgbGreen := 255;
        Color.rgbBlue := Round((Hue - 120) * (255 / 60));
      END
      ELSE
        IF Hue <= 240 THEN
        BEGIN
          Color.rgbGreen := Round((240 - Hue) * (255 / 60));
          Color.rgbBlue := 255;
        END
        ELSE
          IF Hue <= 300 THEN
          BEGIN
            Color.rgbRed := Round((Hue - 240) * (255 / 60));
            Color.rgbBlue := 255;
          END
          ELSE
            IF Hue <= 360 THEN
            BEGIN
              Color.rgbRed := 255;
              Color.rgbBlue := Round((360 - Hue) * (255 / 60));
            END
            ELSE
              Result := $00FFFFFF;
END;

FUNCTION RandomF1;
BEGIN
  Result := Random * Max;
END;

FUNCTION RandomF2;
BEGIN
  Result := Min + Random * (Max - Min);
END;

FUNCTION RandomF3;
BEGIN
  Result := RandomF2(RandomF2(Min, Mid), Max);
END;

FUNCTION RandomF4;
VAR A, B : Single;
BEGIN
  A := Abs(Max1 - Min1) + Abs(Max2 - Min2);
  B := Random * A + Min1;
  IF B > Max1 THEN
    B := B + (Min2 - Max1);
  Result := B;
END;

FUNCTION RandomD;
VAR R, G, B, A : Byte;
BEGIN
  R := Random(R2 - R1) + R1;
  G := Random(G2 - G1) + G1;
  B := Random(B2 - B1) + B1;
  A := Random(A2 - A1) + A1;
  Result := (A SHL 24) OR (R SHL 16) OR (G SHL 8) OR B;
END;

PROCEDURE AddTransparentColor;
VAR Pix : TRGBQuad ABSOLUTE Pixel;
  Clr : TRGBQuad ABSOLUTE Color;
BEGIN
  Pix.rgbRed := EnsureRange(Integer(Pix.rgbRed) + Integer(Clr.rgbRed), 0, 255);
  Pix.rgbGreen := EnsureRange(Integer(Pix.rgbGreen) + Integer(Clr.rgbGreen), 0, 255);
  Pix.rgbBlue := EnsureRange(Integer(Pix.rgbBlue) + Integer(Clr.rgbBlue), 0, 255);
END;

PROCEDURE AddTransparentColor2;
BEGIN
{  Src1 := TRGBQuad(Clr);
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
  Result := Integer(Dst1);}
END;

PROCEDURE Fill4(VAR X; Count : Integer; Filler : Cardinal);
ASM
 PUSH EAX
 PUSH ECX
 PUSH EDI
 CLD
 MOV EDI, EAX
 MOV EAX, ECX
 MOV ECX, EDX
 REP STOSD
 POP EDI
 POP ECX
 POP EAX
END;

END.

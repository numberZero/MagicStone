UNIT MagicStone_UnitMain;

INTERFACE

USES Windows;

FUNCTION Make_RGB_From_H(Hue : Double) : Integer;
FUNCTION RandomF1(Max : Single) : Single;
FUNCTION RandomF2(Min, Max : Single) : Single;
FUNCTION RandomF3(Min, Mid, Max : Single) : Single;
FUNCTION RandomF4(Min1, Max1, Min2, Max2 : Single) : Single;
FUNCTION RandomD(R1, R2, G1, G2, B1, B2, A1, A2 : Byte) : Cardinal;

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
 Result := $00111111;
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

END.


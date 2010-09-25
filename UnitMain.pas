UNIT UnitMain;

INTERFACE

USES DirectX, Math;

CONST
  ImageSizeX = 800;
  ImageSizeY = 600;
  ImageCenterX = ImageSizeX DIV 2;
  ImageCenterY = ImageSizeY DIV 2;
  PointsCount = 256;
  PointsMax = PointsCount - 1;
  ObjectMoutionBlurDepth = 64;
  ObjectMoutionBlurMax = ObjectMoutionBlurDepth - 1;

  BaseSpeed = 0.3;

  BaseVelA = 0.5;
  MinVelA = Pi / 3 * BaseVelA * BaseSpeed;
  MaxVelA = Pi / 2 * BaseVelA * BaseSpeed;
  MinPosR = 0;
  MaxPosR = 192;
  BaseVelR = 512 * BaseSpeed;
  VelRPerS = 1 * BaseSpeed;
  MaxPosH = 45;
  MinVelH = 5 * BaseSpeed;
  MaxVelH = 30 * BaseSpeed;

TYPE
  Float = Single;

  TObj = RECORD
    PosA : Float;
    PosR : Float;
    PosH : Float;
    VelA : Float;
    VelR : Float;
    VelH : Float;
  END;
  TColor3I = RECORD
    R, G, B : Integer;
  END;
  TOMBPoint = RECORD
    X, Y : SmallInt;
    Color : Integer;
  END;
  TImageData = ARRAY[0..ImageSizeY - 1, 0..ImageSizeX - 1] OF Integer;

VAR
  Points : ARRAY[0..PointsMax] OF TObj;
  OMBObjs : ARRAY[0..ObjectMoutionBlurMax, 0..PointsMax] OF TOMBPoint;
  OMBIndex : Integer;
  Pixels : ^TImageData;
  LagCount : Float;
  OpacityCoef : ARRAY[0..ObjectMoutionBlurMax] OF Integer;

PROCEDURE Generate;
PROCEDURE Step;

PROCEDURE FullBar(Y, Height, Color : Integer);
PROCEDURE Bar(X, Y, Width, Height, Color : Integer);
PROCEDURE HLine(X, Y, Length, Color : Integer);
PROCEDURE VLine(X, Y, Length, Color : Integer);

IMPLEMENTATION

USES Misc;

PROCEDURE FullBar;
BEGIN
  IF (Y < 0) OR (Y >= ImageSizeY) THEN
    Exit;
  IF (Y + Height) >= ImageSizeY THEN
    Height := ImageSizeY - Y;
  Fill4(Pixels[Y], Height * ImageSizeX, Color);
END;

PROCEDURE Bar;
VAR J : Integer;
BEGIN
  IF (X < 0) OR (Y < 0) OR (X >= ImageSizeX) OR (Y >= ImageSizeY) THEN
    Exit;
  IF (X + Width) >= ImageSizeX THEN Width := ImageSizeX - X;
  IF (Y + Height) >= ImageSizeY THEN Height := ImageSizeY - Y;
  FOR J := Y TO Y + Height - 1 DO
    Fill4(Pixels[J, X], Width, Color);
END;

PROCEDURE HLine;
BEGIN
  IF (X < 0) OR (Y < 0) OR (X >= ImageSizeX) OR (Y >= ImageSizeY) THEN
    Exit;
  IF (X + Length) >= ImageSizeX THEN
    Length := ImageSizeX - X - 1;
  Fill4(Pixels[Y, X], Length, Color);
END;

PROCEDURE VLine;
VAR J : Integer;
BEGIN
  IF (X < 0) OR (Y < 0) OR (X >= ImageSizeX) OR (Y >= ImageSizeY) THEN
    Exit;
  IF (Y + Length) >= ImageSizeY THEN
    Length := ImageSizeY - Y - 1;
  FOR J := Y TO Y + Length - 1 DO
    Pixels[J, X] := Color;
END;

PROCEDURE Generate;
VAR Index : Integer;
  BaseH : Double;
  BaseVelH : Double;
BEGIN
  BaseH := RandomF2(-180, 180);
  BaseVelH := RandomF4(-MaxVelH, -MinVelH, +MinVelH, +MaxVelH);
  FOR Index := 0 TO PointsMax DO
    WITH Points[Index] DO
    BEGIN
      PosA := RandomF2(-Pi, +Pi);
      PosR := RandomF2(MinPosR, MaxPosR);
//      PosR := RandomF1(MaxPosR - MinPosR);
      PosH := BaseH + RandomF2(-MaxPosH, MaxPosH);
      VelA := RandomF4(-MaxVelA, -MinVelA, +MinVelA, +MaxVelA);
      VelR := RandomF2(-BaseVelR, +BaseVelR);
      VelH := BaseVelH;
    END;
END;

PROCEDURE Step;

  PROCEDURE Draw(X, Y, Color, Opacity : Integer);

    PROCEDURE Add(VAR Pix : Integer; Color : Integer);
    ASM
{(*}
    ADD [EAX], DL
    JNC @@1
    MOV BYTE PTR [EAX], $FF
   @@1:
    INC EAX
    ADD [EAX], DH
    JNC @@2
    MOV BYTE PTR [EAX], $FF
   @@2:
    INC EAX
    SHR EDX, 16
    ADD [EAX], DL
    JNC @@3
    MOV BYTE PTR [EAX], $FF
   @@3:
    INC EAX
    ADD [EAX], DH
    JNC @@4
    MOV BYTE PTR [EAX], $FF
   @@4:
{*)}
    END;

    PROCEDURE AddOpacity(VAR Pix : Integer; Color, Opacity : Integer); REGISTER;
    ASM
{(*}
    PUSH EBX
    XOR BH, BH
    MOV BL, DL
    IMUL BX, CX
    JNC @@A
    MOV BH, $FF;
   @@A:
    ADD [EAX], BH
    JNC @@1
    MOV BYTE PTR [EAX], $FF
   @@1:
    INC EAX
    XOR BH, BH
    MOV BL, DH
    IMUL BX, CX
    JNC @@B
    MOV BH, $FF;
   @@B:
    ADD [EAX], BH
    JNC @@2
    MOV BYTE PTR [EAX], $FF
   @@2:
    INC EAX
    SHR EDX, 16
    XOR BH, BH
    MOV BL, DL
    IMUL BX, CX
    JNC @@C
    MOV BH, $FF;
   @@C:
    ADD [EAX], BH
    JNC @@3
    MOV BYTE PTR [EAX], $FF
   @@3:
    INC EAX
    XOR BH, BH
    MOV BL, DH
    IMUL BX, CX
    JNC @@D
    MOV BH, $FF;
   @@D:
    ADD [EAX], BH
    JNC @@4
    MOV BYTE PTR [EAX], $FF
   @@4:
    POP EBX
{*)}
    END;

  BEGIN
    IF (X < 1) OR (Y < 1) OR (X > (ImageSizeX - 2)) OR (Y > (ImageSizeY - 2)) THEN
      Exit;
    AddOpacity(Pixels[Y - 1, X - 1], Color, Opacity DIV 3);
    AddOpacity(Pixels[Y - 1, X], Color, Opacity DIV 2);
    AddOpacity(Pixels[Y - 1, X + 1], Color, Opacity DIV 3);
    AddOpacity(Pixels[Y, X - 1], Color, Opacity DIV 2);
    AddOpacity(Pixels[Y, X], Color, Opacity);
    AddOpacity(Pixels[Y, X + 1], Color, Opacity DIV 2);
    AddOpacity(Pixels[Y + 1, X - 1], Color, Opacity DIV 3);
    AddOpacity(Pixels[Y + 1, X], Color, Opacity DIV 2);
    AddOpacity(Pixels[Y + 1, X + 1], Color, Opacity DIV 3);
  END;

VAR Index : Integer;
  X, Y : Integer;
  Color : Integer;
  OMB : Integer;
  Opac : Integer;
BEGIN
  FOR Index := 0 TO PointsMax DO
    WITH Points[Index] DO
    BEGIN
      VelR := VelR - PosR * LagCount * VelRPerS;
      PosA := PosA + VelA * LagCount;
      PosR := PosR + VelR * LagCount;
      PosH := PosH + VelH * LagCount;
      IF PosH >= +180 THEN
        PosH := PosH - 360
      ELSE
        IF PosH <= -180 THEN PosH := PosH + 360;
      IF PosR < 0 THEN
      BEGIN
        PosR := -PosR;
        VelR := -VelR;
        PosA := PosA + Pi;
      END;
      IF PosA < -Pi THEN
        PosA := PosA + Pi * 2
      ELSE
        IF PosA > +Pi THEN
          PosA := PosA - Pi * 2;
      X := Round(Sin(PosA) * PosR) + ImageCenterX;
      Y := Round(Cos(PosA) * PosR) + ImageCenterY;
      Color := Make_RGB_From_H(PosH);
      OMBObjs[OMBIndex, Index].X := X;
      OMBObjs[OMBIndex, Index].Y := Y;
      OMBObjs[OMBIndex, Index].Color := Color;
//    Draw(256);
    END;

  FOR OMB := 0 TO OMBIndex DO
  BEGIN
    Opac := OMBIndex - OMB;
//    IF Opac > ObjectMoutionBlurMax THEN
//      Opac := Opac - ObjectMoutionBlurDepth;
    Opac := OpacityCoef[Opac];
    FOR Index := 0 TO PointsMax DO
      WITH OMBObjs[OMB, Index] DO
        Draw(X, Y, Color, Opac);
  END;

  FOR OMB := OMBIndex + 1 TO ObjectMoutionBlurMax DO
  BEGIN
    Opac := ObjectMoutionBlurMax - OMB + OMBIndex + 1;
//    IF Opac < 0 THEN
//      Opac := Opac + ObjectMoutionBlurDepth;
    Opac := OpacityCoef[Opac];
    FOR Index := 0 TO PointsMax DO
      WITH OMBObjs[OMB, Index] DO
        Draw(X, Y, Color, Opac);
  END;

  Inc(OMBIndex);
  IF OMBIndex = ObjectMoutionBlurDepth THEN
    OMBIndex := 0;
END;

PROCEDURE MakeOpacityCoeficents;
CONST
  BeforeHead = ObjectMoutionBlurDepth DIV 4;
  AfterHead  = ObjectMoutionBlurMax - BeforeHead;
  Multiplier = 0.7;
VAR I : Integer;
BEGIN
  FOR I := 0 TO BeforeHead - 1 DO
    OpacityCoef[I] := Round(Min(Sqr(I / (BeforeHead + 1)), 1) * (256 * Multiplier));
  FOR I := BeforeHead TO ObjectMoutionBlurMax DO
    OpacityCoef[I] := Round(Min(Sqr((AfterHead - (I - BeforeHead) + 1) / (AfterHead + 1)), 1) * (256 * Multiplier));
END;

INITIALIZATION
  MakeOpacityCoeficents;
END.


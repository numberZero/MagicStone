unit Render;

interface

uses
  Math;

const
  RGBMAX = 255;
  HMAX = 360;

type
  Float = Single;
  PFloat = ^Float;

  TFloatArray = array[0..0] of Float;
  PFloatArray = ^TFloatArray;

  TPointF = record
    X, Y : Float;
  end;

  PDrawable = ^TDrawable;
  TDrawable = record
    Pos : TPointF;
    Color : Integer;
  end;

  PDrawables = ^TDrawables;
  TDrawables = array[0..0] of TDrawable;

  TDrawingProc = procedure(X, Y : Float; Color : Integer; Alpha : Float);

procedure DrawDot(X, Y : Integer; Color : Integer; Alpha : Integer = 255);
procedure DrawSharp(X, Y : Integer; Color : Integer; Alpha : Integer = 255);
procedure DrawCross(X, Y : Integer; Color : Integer; Alpha : Integer = 255);
procedure DrawSmooth(X, Y : Integer; Color : Integer; Alpha : Float = 1.0);
procedure DrawPrecise(X, Y : Float; Color : Integer; Alpha : Float = 1.0);
procedure DrawPrecise2(X, Y : Float; Color : Integer; Alpha : Float = 1.0);

procedure DrawDotProc(X, Y : Float; Color : Integer; Alpha : Float);
procedure DrawSharpProc(X, Y : Float; Color : Integer; Alpha : Float);
procedure DrawCrossProc(X, Y : Float; Color : Integer; Alpha : Float);
procedure DrawSmoothProc(X, Y : Float; Color : Integer; Alpha : Float);
procedure DrawPreciseProc(X, Y : Float; Color : Integer; Alpha : Float);
procedure DrawPrecise2Proc(X, Y : Float; Color : Integer; Alpha : Float);

procedure DrawArray(Data : PDrawables; Count : Integer; Alpha : Float); overload;
procedure DrawArray(var Data; BytesPerObj, Count : Integer; Alpha : Float); overload;

function ColorHLSToRGB(Hue, Luminance, Saturation: Double): Integer;

var
  Drawer : TDrawingProc;

implementation

uses
  Present;

function ColorHLSToRGB;

  function RoundColor(Value: Double): Integer;
  begin
    Result := EnsureRange(Round(Value * 255), 0, 255);
  end;

var
  X: Integer;
  R, G, B: Double;
  Magic1, Magic2: Double;
begin
  if (Saturation = 0) then
  begin
     R := (Luminance * RGBMAX);
     G := R;
     B := R;
  end
  else
  begin
    Magic1 := Hue / (HMAX/6);
    X := Trunc(Magic1) mod 6;
    if Hue < 0 then
    begin
      X := (5 + X) mod 6;
      Magic1 := 1 + Frac(Magic1);
    end
    else
    begin
      Magic1 := Frac(Magic1);
    end;
    if X mod 2 <> 0 then
      Magic1 := 1 - Magic1;
    R := 0;
    G := 0;
    B := 0;
    case X of
      0, 5: R := 1;
      1, 2: G := 1;
      3, 4: B := 1;
    end;
    case X of
      0, 3: G := Magic1;
      2, 5: B := Magic1;
      4, 1: R := Magic1;
    end;
    Magic2 := (1 - Saturation) * (Magic1 + 1) / 3;
    R := (R * Saturation + Magic2) * (Luminance * 2);
    G := (G * Saturation + Magic2) * (Luminance * 2);
    B := (B * Saturation + Magic2) * (Luminance * 2);
    if Luminance > 0.5 then
    begin
      Magic1 := 2 - Luminance * 2;
      Magic2 := 1 - Magic1;
      R := R * Magic1 + Magic2;
      G := G * Magic1 + Magic2;
      B := B * Magic1 + Magic2;
    end;
  end;
  Result := (RoundColor(R) shl 16) or (RoundColor(G) shl 8) or RoundColor(B);
end;

procedure AddOpacity(var Pix : Integer; Color, Opacity : Integer); register;
asm
    PUSH EBX
    shr ecx, 1
    XOR BH, BH
    MOV BL, DL
    IMUL BX, CX
    JNC @@A
    MOV BH, $FF;
   @@A:
    shl BH, 1
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
    shl BH, 1
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
    shl BH, 1
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
    shl BH, 1
    ADD [EAX], BH
    JNC @@4
    MOV BYTE PTR [EAX], $FF
   @@4:
    POP EBX
end;

procedure DrawDot;
begin
  if (x < 0) or (y < 0) or (x >= VideoWidth) or (y >= VideoHeight) then
    Exit;
  if Alpha < 0 then
    Exit;
  AddOpacity(VideoData[Y * VideoPitch + X], Color, Alpha);
end;

procedure DrawSharp;
begin
  if (x < 1) or (y < 1) or (x > VideoWidth - 2) or (y > VideoHeight - 2) then
    Exit;
  AddOpacity(VideoData[(Y - 1) * VideoPitch + X], Color, Alpha);
  AddOpacity(VideoData[(Y + 1) * VideoPitch + X], Color, Alpha);
  AddOpacity(VideoData[Y * VideoPitch + X - 1], Color, Alpha);
  AddOpacity(VideoData[Y * VideoPitch + X + 1], Color, Alpha);
  AddOpacity(VideoData[Y * VideoPitch + X], Color, Alpha);
end;

procedure DrawCross;
begin
  if (x < 1) or (y < 1) or (x > VideoWidth - 2) or (y > VideoHeight - 2) then
    Exit;
  AddOpacity(VideoData[(Y - 1) * VideoPitch + X - 1], Color, Alpha);
  AddOpacity(VideoData[(Y - 1) * VideoPitch + X + 1], Color, Alpha);
  AddOpacity(VideoData[(Y + 1) * VideoPitch + X - 1], Color, Alpha);
  AddOpacity(VideoData[(Y + 1) * VideoPitch + X + 1], Color, Alpha);
  AddOpacity(VideoData[Y * VideoPitch + X], Color, Alpha);
end;

procedure DrawSmooth;
begin
  if (x < 1) or (y < 1) or (x > VideoWidth - 2) or (y > VideoHeight - 2) then
    Exit;
  AddOpacity(VideoData[(Y - 1) * VideoPitch + X - 1], Color, Round(Alpha * (255 * 0.5)));
  AddOpacity(VideoData[(Y - 1) * VideoPitch + X + 1], Color, Round(Alpha * (255 * 0.5)));
  AddOpacity(VideoData[(Y + 1) * VideoPitch + X - 1], Color, Round(Alpha * (255 * 0.5)));
  AddOpacity(VideoData[(Y + 1) * VideoPitch + X + 1], Color, Round(Alpha * (255 * 0.5)));
  AddOpacity(VideoData[(Y - 1) * VideoPitch + X], Color, Round(Alpha * (255 * 0.7)));
  AddOpacity(VideoData[(Y + 1) * VideoPitch + X], Color, Round(Alpha * (255 * 0.7)));
  AddOpacity(VideoData[Y * VideoPitch + X - 1], Color, Round(Alpha * (255 * 0.7)));
  AddOpacity(VideoData[Y * VideoPitch + X + 1], Color, Round(Alpha * (255 * 0.7)));
  AddOpacity(VideoData[Y * VideoPitch + X], Color, Round(Alpha * (255 * 1.0)));
end;

procedure DrawPrecise;
var
  U, V : Integer;
  dU, dV : Float;
//  I1, I2 : Integer;
//  J1, J2 : Integer;
begin
  if (x < 1) or (y < 1) or (x > VideoWidth - 2) or (y > VideoHeight - 2) then
    Exit;
{  SetRoundMode(rmTruncate);
  U := Round(X);
  V := Round(Y);
  SetRoundMode(rmNearest);
  dU := X - U;
  dV := Y - V;
}
  U := Trunc(X);
  V := Trunc(Y);
  dU := Frac(X);
  dV := Frac(Y);
  DrawDot(U    , V    , Color, Round((1 - dU) * (1 - dV) * Alpha * 255));
  DrawDot(U + 1, V    , Color, Round(     dU  * (1 - dV) * Alpha * 255));
  DrawDot(U    , V + 1, Color, Round((1 - dU) *      dV  * Alpha * 255));
  DrawDot(U + 1, V + 1, Color, Round(     dU  *      dV  * Alpha * 255));
end;

procedure DrawPrecise2;
var
  U, V : Integer;
  dU, dV : Float;
begin
  if (x < 1) or (y < 1) or (x > VideoWidth - 2) or (y > VideoHeight - 2) then
    Exit;
{  SetRoundMode(rmTruncate);
  U := Round(X);
  V := Round(Y);
  SetRoundMode(rmNearest);
  dU := X - U;
  dV := Y - V;
}
  U := Trunc(X);
  V := Trunc(Y);
  dU := Frac(X);
  dV := Frac(Y);
  DrawDot(U, V, Color, Round(Alpha * 255));
  DrawDot(U - 1, V, Color, Round((1 - dU) * Alpha * 255));
  DrawDot(U + 1, V, Color, Round(     dU  * Alpha * 255));
  DrawDot(U, V - 1, Color, Round((1 - dV) * Alpha * 255));
  DrawDot(U, V + 1, Color, Round(     dV  * Alpha * 255));
{  if dU < 0.5 then
    DrawDot(U - 1, V, Color, Round(2 * (0.5 - dU) * Alpha * 255))
  else
    DrawDot(U + 1, V, Color, Round(2 * (dU - 0.5) * Alpha * 255));
  if dV < 0.5 then
    DrawDot(U, V - 1, Color, Round(2 * (0.5 - dV) * Alpha * 255))
  else
    DrawDot(U, V + 1, Color, Round(2 * (dV - 0.5) * Alpha * 255));
}end;

procedure DrawDotProc;
begin
  DrawDot(Round(X), Round(Y), Color, Round(Alpha * 255));
end;

procedure DrawSharpProc;
begin
  DrawSharp(Round(X), Round(Y), Color, Round(Alpha * 255));
end;

procedure DrawCrossProc;
begin
  DrawCross(Round(X), Round(Y), Color, Round(Alpha * 255));
end;

procedure DrawSmoothProc;
begin
  DrawSmooth(Round(X), Round(Y), Color, Alpha);
end;

procedure DrawPreciseProc;
begin
  DrawPrecise(X, Y, Color, Alpha);
end;

procedure DrawPrecise2Proc;
begin
  DrawPrecise2(X, Y, Color, Alpha);
end;

procedure DrawArray(Data : PDrawables; Count : Integer; Alpha : Float);
begin
  DrawArray(Data^, SizeOf(TDrawable), Count, Alpha);
end;

procedure DrawArray(var Data; BytesPerObj, Count : Integer; Alpha : Float);
var
  S : PDrawable;
  P : Cardinal absolute S;
begin
  S := @Data;
  while Count > 0 do
  begin
    Drawer(S.Pos.X, S.Pos.Y, S.Color, Alpha);
    Dec(Count);
    Inc(P, BytesPerObj);
  end;
end;

initialization
  case SizeOf(Float) of
    SizeOf(Single): SetPrecisionMode(pmSingle);
    SizeOf(Double): SetPrecisionMode(pmDouble);
    SizeOf(Extended): SetPrecisionMode(pmExtended);
  end;
end.


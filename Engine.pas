unit Engine;

interface

uses
  Randoms,
  Present, Render, ObjectMBlur;

procedure EngineInitialize;
procedure EngineFinalize;
procedure EngineStep(LagCount : Float);

const
  BaseSpeed = 0.3;

  BaseVelA {: Float} = 0.5;
  MinVelA {: Float} = Pi / 3 * BaseVelA * BaseSpeed;
  MaxVelA {: Float} = Pi / 2 * BaseVelA * BaseSpeed;
  MinPosR {: Float} = 0;
  MaxPosR {: Float} = 0.48;
  BaseVelR {: Float} = MaxPosR / 0.725 * BaseSpeed;
  VelRPerS {: Float} = BaseSpeed;
  MaxPosH {: Float} = 45;
  MinVelH {: Float} = 5;// * BaseSpeed;
  MaxVelH {: Float} = 30;// * BaseSpeed;

var
  PointsCount : Integer;

implementation

type
  TObj = record
    PosA : Float;
    PosR : Float;
    PosH : Float;
    VelA : Float;
    VelR : Float;
    VelH : Float;
  end;

  TObjs = array[0..0] of TObj;
  PObjs = ^TObjs;

var
  Points : PObjs;
  Count : Integer;

procedure Generate;
var
  Index : Integer;
  BaseH : Double;
  BaseVelH : Double;
begin
  Count := PointsCount;
  GetMem(Points, SizeOf(TObj) * Count);
  BaseH := RandomF2(-180, 180);
  BaseVelH := RandomF4(-MaxVelH, -MinVelH, +MinVelH, +MaxVelH);
  for Index := 0 to Count - 1 do
    with Points[Index] do
    begin
      PosA := RandomF2(-Pi, +Pi);
      PosR := RandomF2(MinPosR, MaxPosR);
      PosH := BaseH + RandomF2(-MaxPosH, MaxPosH);
      VelA := RandomF4(-MaxVelA, -MinVelA, +MinVelA, +MaxVelA);
      VelR := RandomF2(-BaseVelR, +BaseVelR);
      VelH := BaseVelH;
    end;
end;

procedure Clear;
begin
  FreeMem(Points);
end;

procedure Process(LagCount : Float);
var
  Index : Integer;
begin
  for Index := 0 to Count - 1 do
    with Points[Index] do
    begin
      VelR := VelR - PosR * LagCount * VelRPerS;
      PosA := PosA + VelA * LagCount;
      PosR := PosR + VelR * LagCount;
      PosH := PosH + VelH * LagCount;
      if PosH >= +180 then
        PosH := PosH - 360
      else if PosH <= -180 then
        PosH := PosH + 360;
      if PosR < 0 then
      begin
        PosR := -PosR;
        VelR := -VelR;
        PosA := PosA + Pi;
      end;
      if PosA < -Pi then
        PosA := PosA + Pi * 2
      else if PosA > +Pi then
        PosA := PosA - Pi * 2;
    end;
end;

procedure PresentToOmb;
var
  Index : Integer;
begin
  for Index := 0 to Count - 1 do
    with Points[Index], OmbCurrent[Index] do
    begin
      Pos.X := Sin(PosA) * PosR * VideoHeight + VideoWidth div 2;
      Pos.Y := Cos(PosA) * PosR * VideoHeight + VideoHeight div 2;
      Color := ColorHLSToRGB(PosH, 0.5, 0.9);
    end;
end;

procedure Step(LagCount : Float);
begin
  Process(LagCount);
  OmbCount := Count;
  OmbBegin;
  PresentToOmb;
  OmbEnd;
end;

procedure EngineInitialize;
begin
  Generate;
end;

procedure EngineFinalize;
begin
  Clear;
end;

procedure EngineStep;
begin
  Step(LagCount);
end;

end.

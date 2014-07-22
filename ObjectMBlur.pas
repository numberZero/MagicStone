unit ObjectMBlur;

interface

uses
  Math,
  Render;

var
  OmbCurrent : PDrawables;
  OmbCount : Integer;
  OmbDepth : Integer;

procedure OmbInitialize;
procedure OmbFinalize;
procedure OmbBegin;
procedure OmbEnd;
procedure OmbPlainRender;
procedure OmbRender;

implementation

type
  POmbState = ^TOmbState;
  TOmbState = record
    Next : POmbState;
    Data : PDrawables;
    Count : Integer;
    Capacity : Integer;
  end;

var
  Current : POmbState;
  OpacityCoef : PFloat;

procedure InitOne;
begin
  New(Current);
  Current.Count := 0;
  Current.Capacity := OmbCount;
  GetMem(Current.Data, Current.Capacity * SizeOf(TDrawable));
end;

procedure MakeOpacityCoeficents;
{$O-}
const
  Multiplier = 0.7;
var
  I : Integer;
  BeforeHead : Integer;
  AfterHead  : Integer;
  Coef : PFloat;
begin
  BeforeHead := OmbDepth div 4;
  AfterHead  := OmbDepth - BeforeHead - 1;
  GetMem(OpacityCoef, OmbDepth * SizeOf(Float));
  Coef := @(PFloatArray(OpacityCoef)[OmbDepth]);
  for I := 0 to BeforeHead - 1 do
  begin
    Dec(Coef);
    Coef^ := Min(Sqr(I / (BeforeHead + 1)), 1) * Multiplier;
  end;
  for I := 0 to AfterHead do
  begin
    Dec(Coef);
    Coef^ := Min(Sqr((AfterHead - I + 1) / (AfterHead + 1)), 1) * Multiplier;
  end;
end;

procedure OmbInitialize;
var
  Last : POmbState;
  Next : POmbState;
  Index : Integer;
begin
  MakeOpacityCoeficents;
  InitOne;
  Last := Current;
  for Index := 0 to OmbDepth - 2 do
  begin
    Next := Current;
    InitOne;
    Current.Next := Next;
  end;
  Last.Next := Current;
end;

procedure OmbFinalize;
var
  Next : POmbState;
  Index : Integer;
begin
  for Index := 0 to OmbDepth - 1 do
  begin
    Next := Current.Next;
    Dispose(Current);
    Current := Next;
  end;
end;

procedure OmbBegin;
begin
  Current := Current.Next;
  Current.Count := OmbCount;
  if Current.Capacity < Current.Count then
  begin
    FreeMem(Current.Data);
    Current.Capacity := Current.Count;
    GetMem(Current.Data, Current.Capacity * SizeOf(TDrawable));
  end;
  OmbCurrent := Current.Data;
end;

procedure OmbEnd;
begin
  OmbCurrent := nil;
end;

procedure OmbPlainRender;
begin
  DrawArray(Current.Data, Current.Count, 1.0);
end;

procedure OmbRender;
var
  State : POmbState;
  Coef : PFloat;
  Index : Integer;
begin
  State := Current;
  Coef := OpacityCoef;
  for Index := 0 to OmbDepth - 1 do
  begin
//    DrawArray(State.Data, State.Count, Index / OmbDepth);
    DrawArray(State.Data, State.Count, Coef^);
    State := State.Next;
    Inc(Coef);
  end;
end;

end.


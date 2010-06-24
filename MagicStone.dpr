program MagicStone;

uses
  Forms,
  MagicStone_FormMain in 'MagicStone_FormMain.pas' {FormMain},
  MagicStone_UnitMain in 'MagicStone_UnitMain.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

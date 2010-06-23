program MagicStone;

uses
  Forms,
  MagicStone_Form_Main in 'MagicStone_Form_Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

program darktest;

uses
  Vcl.Forms,
  main in 'main.pas' {FrmDarknet},
  Darknet4D.Classes in 'Darknet4D.Classes.pas',
  Darknet4D.old in 'Darknet4D.old.pas',
  Darknet4D in 'Darknet4D.pas',
  Darknet4D.Strings in 'Darknet4D.Strings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmDarknet, FrmDarknet);
  Application.Run;
end.

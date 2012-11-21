program skype_popup;

uses
  Forms,
  uMain in 'uMain.pas' {frmSkypePopup};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmSkypePopup, frmSkypePopup);
  
  Application.Run;
end.

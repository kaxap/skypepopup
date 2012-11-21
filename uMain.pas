unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, cef, ceflib;

const
  ID_URL = 0;
  ID_FALLBACK = 1;

type
  TfrmSkypePopup = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Chromium1: TChromium;
    tmrMousePos: TTimer;
    tmrCursorInWindowTracker: TTimer;
    tmrHide: TTimer;
    tmrShow: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Chromium1BeforePopup(const parentBrowser: ICefBrowser;
      var popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
      var url: ustring; var client: ICefBase; out Result: Boolean);
    procedure Chromium1LoadEnd(Sender: TCustomChromium;
      const browser: ICefBrowser; const frame: ICefFrame;
      httpStatusCode: Integer; out Result: Boolean);
    procedure Chromium1AfterCreated(Sender: TCustomChromium;
      const browser: ICefBrowser);
    procedure FormCreate(Sender: TObject);
    procedure Chromium1JsAlert(Sender: TCustomChromium;
      const browser: ICefBrowser; const frame: ICefFrame;
      const message: ustring; out Result: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrMousePosTimer(Sender: TObject);
    procedure tmrCursorInWindowTrackerTimer(Sender: TObject);
    procedure tmrShowTimer(Sender: TObject);
    procedure tmrHideTimer(Sender: TObject);
  private
    { Private declarations }
    mouse_pos: TPoint;
    last_url: String;
    procedure parseDimenstions(const s: String);
    procedure OnUrlFromSkype(var msg: TWMCopyData); message WM_COPYDATA;
    procedure OnException(Sender: TObject; E: Exception);
  public
    { Public declarations }
    bCapable: Boolean;
    browser: ICefBrowser;
    procedure loadImage(const url: string);
    procedure ShowImageAtPosition;
    procedure HideImage;
    function isMouseInForm: Boolean;
    procedure ShowAlphaAnim;
    procedure HideAlphaAnim;
  end;

var
  frmSkypePopup: TfrmSkypePopup;
  sRootDir: String;
  sTemplateUrl: String;

implementation

{$R *.dfm}

procedure initmon(b: boolean); stdcall; external 'skype_interc.dll';

procedure TfrmSkypePopup.Button1Click(Sender: TObject);
var
  url: String;
begin
  //Chromium1.Load('');
  url := 'file://i:/src/skype_popup/test/gif01.gif';
  //browser.GetMainFrame.ExecuteJavaScript('loadImage("' + url + '")', '', 0);
  loadImage(url);
end;

procedure TfrmSkypePopup.Chromium1BeforePopup(const parentBrowser: ICefBrowser;
  var popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
  var url: ustring; var client: ICefBase; out Result: Boolean);
begin
  Result := False;
end;

procedure TfrmSkypePopup.Chromium1LoadEnd(Sender: TCustomChromium;
  const browser: ICefBrowser; const frame: ICefFrame;
  httpStatusCode: Integer; out Result: Boolean);
begin
  bCapable := True;
end;

procedure TfrmSkypePopup.Chromium1AfterCreated(Sender: TCustomChromium;
  const browser: ICefBrowser);
begin
  bCapable := False;
  browser.GetMainFrame.LoadUrl(sTemplateUrl);
  Self.browser := browser;
end;

procedure TfrmSkypePopup.FormCreate(Sender: TObject);
begin
  sRootDir := ExtractFilePath(Application.ExeName);
  bCapable := False;
  sTemplateUrl := 'file://' + sRootDir + '/template/index.html';
  initmon(true);
  Application.ShowMainForm := False;
  Application.OnException := OnException;

end;

procedure TfrmSkypePopup.Chromium1JsAlert(Sender: TCustomChromium;
  const browser: ICefBrowser; const frame: ICefFrame;
  const message: ustring; out Result: Boolean);
var
  i: Integer;
  pref, body: String;
begin
  //JS code may call alert to pass an event to application
  //should contain prefix and body
  Result := False;
  i := Pos(':', message);
  if i < 0 then
    Exit;

  //get prefix and boy of alert message
  pref := Copy(message, 1, i);
  body := Copy(message, i + 1, Length(message));

  if pref = 'dims:' then
  begin
    //Caption := body;
    parseDimenstions(body);
    Result := True;
  end else if pref = 'error:' then
  begin
    //if body = 'image_failed' then

    Result := True;
  end
  else
    Result := False;

end;

procedure TfrmSkypePopup.parseDimenstions(const s: String);
var
  w, h: Integer;
  i: Integer;
begin
  i := Pos(',', s);
  if TryStrToInt(Copy(s, 1, i - 1), w) then
    if TryStrToInt(Copy(s, i + 1, Length(s)), h) then
    begin
      Chromium1.Width := w;
      Chromium1.Height := h;
      ClientWidth := w;
      ClientHeight := h;
    end;
end;

procedure TfrmSkypePopup.loadImage(const url: string);
var
  ext: String;
  s: String;
  preload: String;
begin
  s := url;
  ext := LowerCase(ExtractFileExt(url));
  if (ext <> '.jpeg') AND (ext <> '.jpg') AND (ext <> '.png') AND
    (ext <> '.gif') then
  begin
    if Pos('imgur.com', LowerCase(s)) > 0 then
      s := s + '.jpg'
    else
      Exit;
  end;

  //don't preload gifs, can take long time
  if (ext = '.gif') then preload := 'false' else
    preload := 'true';

  browser.GetMainFrame.ExecuteJavaScript(Format(
    'loadImage("%s", %s);', [s, preload]), '', 0);
  ShowImageAtPosition;
end;

procedure TfrmSkypePopup.OnUrlFromSkype(var msg: TWMCopyData);
var
  url: String;
  in_action: Boolean;
begin
  //remember last url
  url := PChar(msg.CopyDataStruct.lpData);

  //look if one of our timers still working in sweat shop
  in_action := (tmrShow.Enabled OR tmrHide.Enabled OR
    tmrCursorInWindowTracker.Enabled);

  if (last_url = url) then
  begin
    if in_action then Exit;
  end else
  begin
    if in_action then
    begin
      {
      //shutdown... EVERYTHING
      tmrShow.Enabled := False;
      tmrHide.Enabled := False;
      tmrCursorInWindowTracker.Enabled := False;
      AlphaBlendValue := 255;
      Chromium1.ReCreateBrowser(sTemplateUrl);}
    end;
  end;

  last_url := url;

  if msg.CopyDataStruct.dwData = ID_URL then
  begin
    loadImage(url);
  end else if msg.CopyDataStruct.dwData = ID_FALLBACK then
  begin
    if isMouseInForm then
    begin
      tmrCursorInWindowTracker.Enabled := True;
    end
    else
      HideImage;
  end;
end;

procedure TfrmSkypePopup.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  initmon(false);
end;

procedure TfrmSkypePopup.OnException(Sender: TObject; E: Exception);
begin
  //
end;

procedure TfrmSkypePopup.ShowImageAtPosition;
var
  offsetX, offsetY: Integer;
begin
  GetCursorPos(mouse_pos);
  Left := mouse_pos.X + 5;
  Top := mouse_pos.Y;

  with frmSkypePopup do
  begin
    offsetX := (Monitor.Left + Monitor.Width) - (mouse_pos.X + Width + 5);
    offsetY := (Monitor.Top + Monitor.Height) - (mouse_pos.Y + Height + 5);

    //ShowMessage(IntToStr(Monitor.width));
    if offsetX < 0 then
      Left := mouse_pos.X + offsetX
    else
      Left := mouse_pos.X - 5;

    if offsetY < 0 then
      Top := mouse_pos.Y + offsetY
    else
      Top := mouse_pos.Y - 5;

  end;

  ShowWindow(Handle, SW_SHOWNA);
  //Visible := True;
  tmrMousePos.Enabled := True;
  ShowWindow(Application.Handle, SW_HIDE);
  ShowAlphaAnim;
end;

procedure TfrmSkypePopup.tmrMousePosTimer(Sender: TObject);
var
  p: TPoint;
begin
  GetCursorPos(p);
  if (Abs(p.X - mouse_pos.X) > 200) OR
    (Abs(p.Y - mouse_pos.Y) > 200) then
  begin
    HideImage;
    tmrMousePos.Enabled := False;
  end;
end;

procedure TfrmSkypePopup.HideImage;
begin
  //ShowWindow(Handle, SW_HIDE);
  HideAlphaAnim;
  
end;

function TfrmSkypePopup.isMouseInForm: Boolean;
var
  p: TPoint;
  r: TRect;
begin
  GetCursorPos(p);
  GetWindowRect(Handle, r);
  Result := (p.X >= r.Left) AND (p.Y <= r.Right) AND
    (p.Y >= r.Top) AND (p.Y <= r.Bottom);
end;

procedure TfrmSkypePopup.tmrCursorInWindowTrackerTimer(Sender: TObject);
begin
  if isMouseInForm then
    Exit;
  tmrCursorInWindowTracker.Enabled := False;
  HideImage;
end;

procedure TfrmSkypePopup.ShowAlphaAnim;
var
  i: Integer;
begin
  AlphaBlend := True;
  AlphaBlendValue := 0;
  ShowWindow(Handle, SW_SHOWNA);
  Visible := True;

  tmrHide.Enabled := False;
  tmrShow.Enabled := True;
end;

procedure TfrmSkypePopup.HideAlphaAnim;
var
  i: Integer;
begin
  AlphaBlend := True;
  AlphaBlendValue := 255;

  tmrShow.Enabled := False;
  tmrHide.Enabled := True;
end;

procedure TfrmSkypePopup.tmrShowTimer(Sender: TObject);
begin

  AlphaBlendValue := AlphaBlendValue + 10;
  Update;

  if (AlphaBlendValue >= 250) then
  begin
    tmrShow.Enabled := False;
    AlphaBlendValue := 255;
  end;
end;

procedure TfrmSkypePopup.tmrHideTimer(Sender: TObject);
begin

  AlphaBlendValue := AlphaBlendValue - 10;
  Update;

  if (AlphaBlendValue <= 10) then
  begin
    tmrHide.Enabled := False;
    Visible := False;
    AlphaBlendValue := 255;
    Chromium1.ReCreateBrowser(sTemplateUrl);
  end;
end;

end.

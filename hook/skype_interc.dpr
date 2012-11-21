library IEWatcher;

uses
  SysUtils, Windows, Messages;

  type
    Tjmp_far = packed record
      instr_push: BYTE;
      arg: DWORD;
      instr_ret: BYTE;
	end;

const
  LIB_NAME = 'gdi32.dll';
  FUNC_NAME = 'ExtTextOutW';
  ID_URL = 0;
  ID_FALLBACK = 1;

var
  g_hhook1, g_hhook2, g_hhook3: Integer;
  origExtTextOutW: TJmp_far;
  prev_link: String;

function ShowError(const s: String): String;
begin
  MessageBox(0, PChar(SysErrorMessage(GetLastError()) + ' ... ' + s), '', 0);
end;

procedure InterceptFunction(pszCalleeModName: PChar; pszFuncName: PChar;
  pfnHook: pointer; var read: TJMP_far; setup: boolean);
var adr: Integer;
    w, w1: cardinal;
    write:TJMP_FAR;
begin
    //MessageBox(0, 'Intercepting.', '', 0);
    adr := Integer(GetProcAddress(GetModuleHandle(pszCalleeModName), pszFuncName));
    if adr = 0 then
    begin
      ShowError('GetProcAddress returned 0');
    end;

    {if NOT VirtualProtect(pointer(adr), sizeof(write), PAGE_EXECUTE_READWRITE, w) then
    begin
      ShowError('VirtualProtect failed.');
    end;}

    if setup then
    begin
      if NOT ReadProcessMemory(GetCurrentProcess(),pointer(adr), @read, sizeof(read), w1) then
      begin
        ShowError('ReadProcessMemory failed');
      end;

      write.instr_push := $68;		// push pfnHook
      write.arg := dword(pfnHook);
      write.instr_ret := $C3;		// ret
      if NOT WriteProcessMemory(GetCurrentProcess(), pointer(adr), @write, sizeof(write), w1) then
      begin
        ShowError('WriteProcessMemory failed');
      end;
    end else
      if NOT WriteProcessMemory(GetCurrentProcess(), pointer(adr), @read, sizeof(read), w1) then
      begin
        ShowError('WriteProcessMemory (2) failed');
      end;

    {if NOT VirtualProtect(pointer(adr), sizeof(write), w, nil) then
    begin
      ShowError('VirtualProtect failed');
    end;}
end;

procedure sendUrl(const s: String);
var
  wnd: HWND;
  data: CopyDataStruct;
begin
  wnd := FindWindow('TfrmSkypePopup', 'SkypePopup5738');
  if wnd > 0 then
  begin
    data.dwData := ID_URL;
    data.cbData := Length(s) + 1;
    data.lpData := PChar(s);
    SendMessage(wnd, WM_COPYDATA, 0, lParam(@data));
    prev_link := s;
  end;
end;

procedure sendFallback(const s: String);
var
  wnd: HWND;
  data: CopyDataStruct;
begin
  wnd := FindWindow('TfrmSkypePopup', 'SkypePopup5738');
  if wnd > 0 then
  begin
    data.dwData := ID_FALLBACK;
    data.cbData := Length(s) + 1;
    data.lpData := PChar(s);
    SendMessage(wnd, WM_COPYDATA, 0, lParam(@data));
  end;
end;

function checkMetrics(dc: HDC): Boolean;
var
  tm: TEXTMETRICA;
begin
  GetTextMetrics(DC, tm);
  Result := tm.tmUnderlined <> 0;
end;

function ExtTextOutW__(DC: HDC; X, Y: Integer; Options: Longint;
  Rect: PRect; Str: PWideChar; Count: Longint; Dx: PInteger): BOOL; stdcall;
begin
  InterceptFunction(LIB_NAME, FUNC_NAME, nil, origExtTextOutW, false);
  result := ExtTextOutW(DC, X, Y, Options, Rect, Str, Count, Dx);
  InterceptFunction(LIB_NAME, FUNC_NAME , @ExtTextOUtW__, origExtTextOutW, true);

  if (Copy(Str, 1, 5) = 'http:') AND (GetTextColor(DC) = $FF9933) then
  begin
    if checkMetrics(DC) then
      sendUrl(Str) else
    begin
      if Str = prev_link then
        sendFallback(Str);
    end;
  end;
    //MessageBox(0, PChar(Format('%x', [GetTextColor(DC)])), '', 0);
end;

procedure LibraryProc(Reason: Integer);
var s:string;
begin
  s := ExtractFileName(ParamStr(0));
  if AnsiLowerCase(s) <> 'skype.exe' then Exit; // ��� ����� ��� �����, �� ������� ����������

  //MessageBox(0, PChar(s), nil, 0);
  //Windows.Beep(1000, 100);
  case Reason of
  DLL_PROCESS_ATTACH:
  begin
    InterceptFunction(LIB_NAME, FUNC_NAME , @ExtTextOutW__, origExtTextOutW, true);
  end;

  DLL_PROCESS_DETACH:
  begin
    InterceptFunction(LIB_NAME, FUNC_NAME , nil, origExtTextOutW, false);
  end;
end;

end;

function GetMsgProc1(code:integer; wParam:Longint; lParam:Longint):integer;stdcall;
begin
  result:= CallNextHookEx(g_hhook1, code, wParam, lParam);
end;

function GetMsgProc2(code:integer; wParam:Longint; lParam:Longint):integer;stdcall;
begin
  result:= CallNextHookEx(g_hhook2, code, wParam, lParam);
end;

function GetMsgProc3(code:integer; wParam:Longint; lParam:Longint):integer;stdcall;
begin
  result:= CallNextHookEx(g_hhook3, code, wParam, lParam);
end;

procedure initmon(b:boolean);stdcall;
begin
  if b then begin
    g_hhook1 := SetWindowsHookEx(WH_SHELL, @GetMsgProc1, HInstance,0);
    g_hhook2 := SetWindowsHookEx(WH_SYSMSGFILTER, @GetMsgProc2,HInstance,0);
    g_hhook3 := SetWindowsHookEx(WH_GETMESSAGE, @GetMsgProc3, HInstance,0);
  end
  else begin
    UnhookWindowsHookEx(g_hhook1);
    UnhookWindowsHookEx(g_hhook2);
    UnhookWindowsHookEx(g_hhook3);
  end;
end;

exports initmon;

begin
  DLLProc:=@LibraryProc;
  LibraryProc(DLL_PROCESS_ATTACH);
end.
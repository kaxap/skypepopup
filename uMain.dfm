object frmSkypePopup: TfrmSkypePopup
  Left = 192
  Top = 124
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderStyle = bsNone
  Caption = 'SkypePopup5738'
  ClientHeight = 210
  ClientWidth = 182
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 96
    Top = 112
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    Visible = False
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 96
    Top = 144
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    Visible = False
  end
  object Chromium1: TChromium
    Left = 0
    Top = 0
    Width = 89
    Height = 81
    TabOrder = 2
    OnBeforePopup = Chromium1BeforePopup
    OnAfterCreated = Chromium1AfterCreated
    OnLoadEnd = Chromium1LoadEnd
    OnJsAlert = Chromium1JsAlert
  end
  object tmrMousePos: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrMousePosTimer
    Left = 8
    Top = 96
  end
  object tmrCursorInWindowTracker: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrCursorInWindowTrackerTimer
    Left = 8
    Top = 136
  end
  object tmrHide: TTimer
    Enabled = False
    Interval = 10
    OnTimer = tmrHideTimer
    Left = 48
    Top = 96
  end
  object tmrShow: TTimer
    Enabled = False
    Interval = 10
    OnTimer = tmrShowTimer
    Left = 48
    Top = 136
  end
end

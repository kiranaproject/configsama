// configsama.window.pas — main application window and settings integration
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Window;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ftpas, ftpas.types, ftpas.api, ftpas.app, ftpas.canvas, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.views, ftpas.dialogs, ftpas.ftml,
  ConfigSama.Settings;

type
  { TConfigSamaWindow — GNOME Settings styled application with FTML and ECA }
  TConfigSamaWindow = class(TFtFTMLForm)
  private
    FSettings: TConfigSettings;
    FUpdatingControls: Boolean;

    // Header controls
    FAppTitle: TFtLabel;
    FSectionTitle: TFtLabel;

    // Sidebar controls
    FSearchEntry: TFtEntry;
    FCategoryTree: TFtTreeView;

    // Content Pages
    FPageAppearance: TFtWidget;
    FPageDisplays: TFtWidget;
    FPageDesktop: TFtWidget;
    FPageSound: TFtWidget;
    FPagePower: TFtWidget;
    FPageMouse: TFtWidget;
    FPageKeyboard: TFtWidget;
    FPageApps: TFtWidget;
    FPageAbout: TFtWidget;

    // Appearance page controls
    FSwDarkMode: TFtSwitch;
    FCmbAccent: TFtComboBox;
    FCmbWallpaperMode: TFtComboBox;
    FTxtWallpaperPath: TFtEntry;
    FBtnChooseWallpaper: TFtButton;

    // Displays page controls
    FCmbDisplay: TFtComboBox;
    FCmbResolution: TFtComboBox;
    FCmbRefreshRate: TFtComboBox;
    FCmbScale: TFtComboBox;
    FSwNightLight: TFtSwitch;

    // Desktop page controls
    FCmbDockPosition: TFtComboBox;
    FCmbDockIconSize: TFtComboBox;
    FSwDockAutoHide: TFtSwitch;
    FCmbDockMargin: TFtComboBox;
    FSwShowDesktopBtn: TFtSwitch;
    FSwClock24h: TFtSwitch;

    // Sound page controls
    FCmbOutputDevice: TFtComboBox;
    FSlVolume: TFtSlider;
    FSwMute: TFtSwitch;
    FSwSoundEffects: TFtSwitch;

    // Power page controls
    FCmbPowerMode: TFtComboBox;
    FCmbScreenBlank: TFtComboBox;
    FSwAutoSuspend: TFtSwitch;
    FTxtPowerStatus: TFtEntry;

    // Mouse page controls
    FCmbPrimaryBtn: TFtComboBox;
    FSlPointerSpeed: TFtSlider;
    FSwNaturalScroll: TFtSwitch;
    FSwTapToClick: TFtSwitch;

    // Keyboard page controls
    FCmbKeyboardLayout: TFtComboBox;
    FSlKeyDelay: TFtSlider;
    FSlKeyRate: TFtSlider;
    FSwSuperLauncher: TFtSwitch;

    // Applications page controls
    FCmbBrowser: TFtComboBox;
    FCmbFileManager: TFtComboBox;
    FCmbTerminal: TFtComboBox;
    FCmbEditor: TFtComboBox;

    // About page controls
    FTxtAboutOs: TFtEntry;
    FTxtAboutShell: TFtEntry;
    FTxtAboutWm: TFtEntry;
    FTxtAboutToolkit: TFtEntry;
    FTxtAboutKernel: TFtEntry;
    FTxtAboutCpu: TFtEntry;
    FTxtAboutMem: TFtEntry;

    procedure SetupUI();
    procedure PopulateControls();

    // Event Handlers
    procedure HandleCategorySelect(Sender: TFtTreeView; Node: TFtTreeNode);
    procedure HandleSearchChange(Sender: TFtWidget; const AText: string);
    procedure HandleDarkModeToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleAccentChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleWallpaperModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleChooseWallpaperClick(Sender: TFtButton);
    procedure HandleDisplayChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleResolutionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleRefreshRateChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleScaleChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleNightLightToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleDockPositionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleDockIconSizeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleDockAutoHideToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleDockMarginChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleShowDesktopToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleClock24hToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleOutputDeviceChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleVolumeChange(Sender: TFtSlider; AValue: Double);
    procedure HandleMuteToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleSoundEffectsToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandlePowerModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleScreenBlankChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleAutoSuspendToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandlePrimaryBtnChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandlePointerSpeedChange(Sender: TFtSlider; AValue: Double);
    procedure HandleNaturalScrollToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleTapToClickToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleKeyboardLayoutChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleKeyDelayChange(Sender: TFtSlider; AValue: Double);
    procedure HandleKeyRateChange(Sender: TFtSlider; AValue: Double);
    procedure HandleSuperLauncherToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleBrowserChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleFileManagerChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleTerminalChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleEditorChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
  protected
    procedure DoMouseDown(AX, AY, AButton: Integer); override;
  public
    constructor Create(); reintroduce;
    destructor Destroy(); override;

    procedure SelectCategoryByName(const AName: string);

    property Settings: TConfigSettings read FSettings;
    property SectionTitle: TFtLabel read FSectionTitle;
    property CategoryTree: TFtTreeView read FCategoryTree;
    property SearchEntry: TFtEntry read FSearchEntry;
    property SwDarkMode: TFtSwitch read FSwDarkMode;
    property CmbAccent: TFtComboBox read FCmbAccent;
    property TxtWallpaperPath: TFtEntry read FTxtWallpaperPath;
    property SlVolume: TFtSlider read FSlVolume;
    property SwMute: TFtSwitch read FSwMute;
  end;

implementation

{$R configsama.res}

{ TConfigSamaWindow }

constructor TConfigSamaWindow.Create();
begin
  inherited Create(960, 640, 'Settings', 'TConfigSamaWindow');

  FSettings := TConfigSettings.Create();
  SetupUI();
  PopulateControls();
end;

destructor TConfigSamaWindow.Destroy();
begin
  if Assigned(FSettings) then
  begin
    FSettings.Free();
    FSettings := nil;
  end;
  inherited Destroy();
end;

procedure TConfigSamaWindow.DoMouseDown(AX, AY, AButton: Integer);
var
  wx, wy: Integer;
begin
  inherited DoMouseDown(AX, AY, AButton);

  // ECA Header window dragging
  if (AButton = 1) and (AY <= 48) then
  begin
    GetPosition(wx, wy);
    BeginWindowMove(wx + AX, wy + AY);
  end;
end;

procedure TConfigSamaWindow.SetupUI();
var
  w: TFtWidget;
begin
  // Header
  w := FindWidget('appTitle');
  if w is TFtLabel then FAppTitle := TFtLabel(w);

  w := FindWidget('sectionTitle');
  if w is TFtLabel then FSectionTitle := TFtLabel(w);

  // Sidebar
  w := FindWidget('searchEntry');
  if w is TFtEntry then
  begin
    FSearchEntry := TFtEntry(w);
    FSearchEntry.OnChange := @HandleSearchChange;
  end;

  w := FindWidget('categoryTree');
  if w is TFtTreeView then
  begin
    FCategoryTree := TFtTreeView(w);
    FCategoryTree.OnSelect := @HandleCategorySelect;
  end;

  // Content Pages
  FPageAppearance := FindWidget('pageAppearance');
  FPageDisplays := FindWidget('pageDisplays');
  FPageDesktop := FindWidget('pageDesktop');
  FPageSound := FindWidget('pageSound');
  FPagePower := FindWidget('pagePower');
  FPageMouse := FindWidget('pageMouse');
  FPageKeyboard := FindWidget('pageKeyboard');
  FPageApps := FindWidget('pageApps');
  FPageAbout := FindWidget('pageAbout');

  // Appearance controls
  w := FindWidget('swDarkMode');
  if w is TFtSwitch then
  begin
    FSwDarkMode := TFtSwitch(w);
    FSwDarkMode.OnToggle := @HandleDarkModeToggle;
  end;

  w := FindWidget('cmbAccent');
  if w is TFtComboBox then
  begin
    FCmbAccent := TFtComboBox(w);
    FCmbAccent.OnChange := @HandleAccentChange;
  end;

  w := FindWidget('cmbWallpaperMode');
  if w is TFtComboBox then
  begin
    FCmbWallpaperMode := TFtComboBox(w);
    FCmbWallpaperMode.OnChange := @HandleWallpaperModeChange;
  end;

  w := FindWidget('txtWallpaperPath');
  if w is TFtEntry then FTxtWallpaperPath := TFtEntry(w);

  w := FindWidget('btnChooseWallpaper');
  if w is TFtButton then
  begin
    FBtnChooseWallpaper := TFtButton(w);
    FBtnChooseWallpaper.OnClick := @HandleChooseWallpaperClick;
  end;

  // Displays controls
  w := FindWidget('cmbDisplay');
  if w is TFtComboBox then
  begin
    FCmbDisplay := TFtComboBox(w);
    FCmbDisplay.OnChange := @HandleDisplayChange;
  end;

  w := FindWidget('cmbResolution');
  if w is TFtComboBox then
  begin
    FCmbResolution := TFtComboBox(w);
    FCmbResolution.OnChange := @HandleResolutionChange;
  end;

  w := FindWidget('cmbRefreshRate');
  if w is TFtComboBox then
  begin
    FCmbRefreshRate := TFtComboBox(w);
    FCmbRefreshRate.OnChange := @HandleRefreshRateChange;
  end;

  w := FindWidget('cmbScale');
  if w is TFtComboBox then
  begin
    FCmbScale := TFtComboBox(w);
    FCmbScale.OnChange := @HandleScaleChange;
  end;

  w := FindWidget('swNightLight');
  if w is TFtSwitch then
  begin
    FSwNightLight := TFtSwitch(w);
    FSwNightLight.OnToggle := @HandleNightLightToggle;
  end;

  // Desktop & Dock controls
  w := FindWidget('cmbDockPosition');
  if w is TFtComboBox then
  begin
    FCmbDockPosition := TFtComboBox(w);
    FCmbDockPosition.OnChange := @HandleDockPositionChange;
  end;

  w := FindWidget('cmbDockIconSize');
  if w is TFtComboBox then
  begin
    FCmbDockIconSize := TFtComboBox(w);
    FCmbDockIconSize.OnChange := @HandleDockIconSizeChange;
  end;

  w := FindWidget('swDockAutoHide');
  if w is TFtSwitch then
  begin
    FSwDockAutoHide := TFtSwitch(w);
    FSwDockAutoHide.OnToggle := @HandleDockAutoHideToggle;
  end;

  w := FindWidget('cmbDockMargin');
  if w is TFtComboBox then
  begin
    FCmbDockMargin := TFtComboBox(w);
    FCmbDockMargin.OnChange := @HandleDockMarginChange;
  end;

  w := FindWidget('swShowDesktopBtn');
  if w is TFtSwitch then
  begin
    FSwShowDesktopBtn := TFtSwitch(w);
    FSwShowDesktopBtn.OnToggle := @HandleShowDesktopToggle;
  end;

  w := FindWidget('swClock24h');
  if w is TFtSwitch then
  begin
    FSwClock24h := TFtSwitch(w);
    FSwClock24h.OnToggle := @HandleClock24hToggle;
  end;

  // Sound controls
  w := FindWidget('cmbOutputDevice');
  if w is TFtComboBox then
  begin
    FCmbOutputDevice := TFtComboBox(w);
    FCmbOutputDevice.OnChange := @HandleOutputDeviceChange;
  end;

  w := FindWidget('slVolume');
  if w is TFtSlider then
  begin
    FSlVolume := TFtSlider(w);
    FSlVolume.SetRange(0.0, 100.0);
    FSlVolume.OnChange := @HandleVolumeChange;
  end;

  w := FindWidget('swMute');
  if w is TFtSwitch then
  begin
    FSwMute := TFtSwitch(w);
    FSwMute.OnToggle := @HandleMuteToggle;
  end;

  w := FindWidget('swSoundEffects');
  if w is TFtSwitch then
  begin
    FSwSoundEffects := TFtSwitch(w);
    FSwSoundEffects.OnToggle := @HandleSoundEffectsToggle;
  end;

  // Power controls
  w := FindWidget('cmbPowerMode');
  if w is TFtComboBox then
  begin
    FCmbPowerMode := TFtComboBox(w);
    FCmbPowerMode.OnChange := @HandlePowerModeChange;
  end;

  w := FindWidget('cmbScreenBlank');
  if w is TFtComboBox then
  begin
    FCmbScreenBlank := TFtComboBox(w);
    FCmbScreenBlank.OnChange := @HandleScreenBlankChange;
  end;

  w := FindWidget('swAutoSuspend');
  if w is TFtSwitch then
  begin
    FSwAutoSuspend := TFtSwitch(w);
    FSwAutoSuspend.OnToggle := @HandleAutoSuspendToggle;
  end;

  w := FindWidget('txtPowerStatus');
  if w is TFtEntry then FTxtPowerStatus := TFtEntry(w);

  // Mouse controls
  w := FindWidget('cmbPrimaryBtn');
  if w is TFtComboBox then
  begin
    FCmbPrimaryBtn := TFtComboBox(w);
    FCmbPrimaryBtn.OnChange := @HandlePrimaryBtnChange;
  end;

  w := FindWidget('slPointerSpeed');
  if w is TFtSlider then
  begin
    FSlPointerSpeed := TFtSlider(w);
    FSlPointerSpeed.SetRange(0.0, 100.0);
    FSlPointerSpeed.OnChange := @HandlePointerSpeedChange;
  end;

  w := FindWidget('swNaturalScroll');
  if w is TFtSwitch then
  begin
    FSwNaturalScroll := TFtSwitch(w);
    FSwNaturalScroll.OnToggle := @HandleNaturalScrollToggle;
  end;

  w := FindWidget('swTapToClick');
  if w is TFtSwitch then
  begin
    FSwTapToClick := TFtSwitch(w);
    FSwTapToClick.OnToggle := @HandleTapToClickToggle;
  end;

  // Keyboard controls
  w := FindWidget('cmbKeyboardLayout');
  if w is TFtComboBox then
  begin
    FCmbKeyboardLayout := TFtComboBox(w);
    FCmbKeyboardLayout.OnChange := @HandleKeyboardLayoutChange;
  end;

  w := FindWidget('slKeyDelay');
  if w is TFtSlider then
  begin
    FSlKeyDelay := TFtSlider(w);
    FSlKeyDelay.SetRange(100.0, 1000.0);
    FSlKeyDelay.OnChange := @HandleKeyDelayChange;
  end;

  w := FindWidget('slKeyRate');
  if w is TFtSlider then
  begin
    FSlKeyRate := TFtSlider(w);
    FSlKeyRate.SetRange(5.0, 60.0);
    FSlKeyRate.OnChange := @HandleKeyRateChange;
  end;

  w := FindWidget('swSuperLauncher');
  if w is TFtSwitch then
  begin
    FSwSuperLauncher := TFtSwitch(w);
    FSwSuperLauncher.OnToggle := @HandleSuperLauncherToggle;
  end;

  // Application controls
  w := FindWidget('cmbBrowser');
  if w is TFtComboBox then
  begin
    FCmbBrowser := TFtComboBox(w);
    FCmbBrowser.OnChange := @HandleBrowserChange;
  end;

  w := FindWidget('cmbFileManager');
  if w is TFtComboBox then
  begin
    FCmbFileManager := TFtComboBox(w);
    FCmbFileManager.OnChange := @HandleFileManagerChange;
  end;

  w := FindWidget('cmbTerminal');
  if w is TFtComboBox then
  begin
    FCmbTerminal := TFtComboBox(w);
    FCmbTerminal.OnChange := @HandleTerminalChange;
  end;

  w := FindWidget('cmbEditor');
  if w is TFtComboBox then
  begin
    FCmbEditor := TFtComboBox(w);
    FCmbEditor.OnChange := @HandleEditorChange;
  end;

  // About controls
  w := FindWidget('txtAboutOs');
  if w is TFtEntry then FTxtAboutOs := TFtEntry(w);

  w := FindWidget('txtAboutShell');
  if w is TFtEntry then FTxtAboutShell := TFtEntry(w);

  w := FindWidget('txtAboutWm');
  if w is TFtEntry then FTxtAboutWm := TFtEntry(w);

  w := FindWidget('txtAboutToolkit');
  if w is TFtEntry then FTxtAboutToolkit := TFtEntry(w);

  w := FindWidget('txtAboutKernel');
  if w is TFtEntry then FTxtAboutKernel := TFtEntry(w);

  w := FindWidget('txtAboutCpu');
  if w is TFtEntry then FTxtAboutCpu := TFtEntry(w);

  w := FindWidget('txtAboutMem');
  if w is TFtEntry then FTxtAboutMem := TFtEntry(w);
end;

procedure TConfigSamaWindow.PopulateControls();
begin
  if FSettings = nil then Exit();

  FUpdatingControls := True;
  try
    FtApp.DarkMode := FSettings.DarkMode;

    // Appearance
    if Assigned(FSwDarkMode) then
      FSwDarkMode.Checked := FSettings.DarkMode;

    if Assigned(FCmbAccent) then
      FCmbAccent.Text := FSettings.AccentColor;

    if Assigned(FCmbWallpaperMode) then
      FCmbWallpaperMode.Text := FSettings.WallpaperMode;

    if Assigned(FTxtWallpaperPath) then
      FTxtWallpaperPath.Text := FSettings.WallpaperPath;

    // Displays
    if Assigned(FCmbResolution) then
      FCmbResolution.Text := FSettings.Resolution;

    if Assigned(FSwNightLight) then
      FSwNightLight.Checked := FSettings.NightLight;

    // Desktop & Dock
    if Assigned(FCmbDockPosition) then
      FCmbDockPosition.Text := FSettings.DockPosition;

    if Assigned(FCmbDockIconSize) then
      FCmbDockIconSize.Text := IntToStr(FSettings.DockIconSize) + ' px';

    if Assigned(FSwDockAutoHide) then
      FSwDockAutoHide.Checked := FSettings.DockAutoHide;

    if Assigned(FCmbDockMargin) then
      FCmbDockMargin.Text := IntToStr(FSettings.DockMargin) + ' px';

    if Assigned(FSwShowDesktopBtn) then
      FSwShowDesktopBtn.Checked := FSettings.ShowDesktopButton;

    if Assigned(FSwClock24h) then
      FSwClock24h.Checked := (FSettings.ClockFormat = '24h');

    // Sound
    if Assigned(FCmbOutputDevice) then
      FCmbOutputDevice.Text := FSettings.OutputDevice;

    if Assigned(FSlVolume) then
      FSlVolume.Value := FSettings.OutputVolume;

    if Assigned(FSwMute) then
      FSwMute.Checked := FSettings.Muted;

    if Assigned(FSwSoundEffects) then
      FSwSoundEffects.Checked := FSettings.SoundEffects;

    // Power
    if Assigned(FCmbPowerMode) then
      FCmbPowerMode.Text := FSettings.PowerMode;

    if Assigned(FSwAutoSuspend) then
      FSwAutoSuspend.Checked := FSettings.AutoSuspend;

    // Mouse
    if Assigned(FCmbPrimaryBtn) then
      FCmbPrimaryBtn.Text := FSettings.PrimaryButton;

    if Assigned(FSlPointerSpeed) then
      FSlPointerSpeed.Value := FSettings.PointerSpeed;

    if Assigned(FSwNaturalScroll) then
      FSwNaturalScroll.Checked := FSettings.NaturalScrolling;

    if Assigned(FSwTapToClick) then
      FSwTapToClick.Checked := FSettings.TapToClick;

    // Keyboard
    if Assigned(FCmbKeyboardLayout) then
      FCmbKeyboardLayout.Text := FSettings.KeyboardLayout;

    if Assigned(FSlKeyDelay) then
      FSlKeyDelay.Value := FSettings.KeyRepeatDelay;

    if Assigned(FSlKeyRate) then
      FSlKeyRate.Value := FSettings.KeyRepeatRate;

    if Assigned(FSwSuperLauncher) then
      FSwSuperLauncher.Checked := FSettings.SuperKeyLauncher;

    // Applications
    if Assigned(FCmbBrowser) then
      FCmbBrowser.Text := FSettings.DefaultBrowser;

    if Assigned(FCmbFileManager) then
      FCmbFileManager.Text := FSettings.DefaultFileManager;

    if Assigned(FCmbTerminal) then
      FCmbTerminal.Text := FSettings.DefaultTerminal;

    if Assigned(FCmbEditor) then
      FCmbEditor.Text := FSettings.DefaultTextEditor;

    // About
    if Assigned(FTxtAboutOs) then
      FTxtAboutOs.Text := FSettings.GetOsName() + ' ' + FSettings.GetOsVersion();

    if Assigned(FTxtAboutKernel) then
      FTxtAboutKernel.Text := FSettings.GetKernelVersion();

    if Assigned(FTxtAboutCpu) then
      FTxtAboutCpu.Text := FSettings.GetCpuModel();

    if Assigned(FTxtAboutMem) then
      FTxtAboutMem.Text := FSettings.GetMemoryTotal();
  finally
    FUpdatingControls := False;
  end;
end;

procedure TConfigSamaWindow.SelectCategoryByName(const AName: string);
begin
  if FPageAppearance <> nil then FPageAppearance.Visible := SameText(AName, 'Appearance');
  if FPageDisplays <> nil then FPageDisplays.Visible := SameText(AName, 'Displays');
  if FPageDesktop <> nil then FPageDesktop.Visible := SameText(AName, 'Desktop & Dock');
  if FPageSound <> nil then FPageSound.Visible := SameText(AName, 'Sound');
  if FPagePower <> nil then FPagePower.Visible := SameText(AName, 'Power');
  if FPageMouse <> nil then FPageMouse.Visible := SameText(AName, 'Mouse & Touchpad');
  if FPageKeyboard <> nil then
    FPageKeyboard.Visible := SameText(AName, 'Keyboard & Shortcuts') or SameText(AName, 'Keyboard');
  if FPageApps <> nil then
    FPageApps.Visible := SameText(AName, 'Default Applications') or SameText(AName, 'Applications');
  if FPageAbout <> nil then FPageAbout.Visible := SameText(AName, 'About');

  if FSectionTitle <> nil then
    FSectionTitle.Text := AName;

  Invalidate();
end;

procedure TConfigSamaWindow.HandleCategorySelect(Sender: TFtTreeView; Node: TFtTreeNode);
begin
  if Node = nil then Exit();
  SelectCategoryByName(Node.Text);
end;

procedure TConfigSamaWindow.HandleSearchChange(Sender: TFtWidget; const AText: string);
var
  q: string;
begin
  q := LowerCase(Trim(AText));
  if q = '' then Exit();

  if Pos('appear', q) > 0 then SelectCategoryByName('Appearance')
  else if (Pos('disp', q) > 0) or (Pos('screen', q) > 0) or (Pos('resolut', q) > 0) then SelectCategoryByName('Displays')
  else if (Pos('dock', q) > 0) or (Pos('panel', q) > 0) or (Pos('desk', q) > 0) then SelectCategoryByName('Desktop & Dock')
  else if (Pos('sound', q) > 0) or (Pos('vol', q) > 0) or (Pos('audio', q) > 0) then SelectCategoryByName('Sound')
  else if (Pos('power', q) > 0) or (Pos('batt', q) > 0) or (Pos('sleep', q) > 0) then SelectCategoryByName('Power')
  else if (Pos('mouse', q) > 0) or (Pos('touch', q) > 0) or (Pos('cursor', q) > 0) then SelectCategoryByName('Mouse & Touchpad')
  else if (Pos('key', q) > 0) or (Pos('short', q) > 0) then SelectCategoryByName('Keyboard & Shortcuts')
  else if (Pos('app', q) > 0) or (Pos('browser', q) > 0) or (Pos('term', q) > 0) then SelectCategoryByName('Default Applications')
  else if (Pos('about', q) > 0) or (Pos('sys', q) > 0) or (Pos('info', q) > 0) then SelectCategoryByName('About');
end;

procedure TConfigSamaWindow.HandleDarkModeToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  FSettings.DarkMode := AToggled;
  FSettings.Save();
  FtApp.DarkMode := AToggled;
  Invalidate();
end;

procedure TConfigSamaWindow.HandleAccentChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.AccentColor := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleWallpaperModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.WallpaperMode := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleChooseWallpaperClick(Sender: TFtButton);
var
  picked: string;
begin
  picked := TFtFileDialog.OpenFile('Select Desktop Wallpaper', GetEnvironmentVariable('HOME'), 'Images (*.png;*.jpg;*.jpeg)|*.png;*.jpg;*.jpeg');
  if picked <> '' then
  begin
    if FTxtWallpaperPath <> nil then
      FTxtWallpaperPath.Text := picked;
    if FSettings <> nil then
    begin
      FSettings.WallpaperPath := picked;
      FSettings.Save();
    end;
  end;
end;

procedure TConfigSamaWindow.HandleDisplayChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  // Display output selection
end;

procedure TConfigSamaWindow.HandleResolutionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p: Integer;
  res: string;
begin
  if FSettings = nil then Exit();
  res := AText;
  p := Pos(' ', res);
  if p > 0 then
    res := Copy(res, 1, p - 1);
  FSettings.Resolution := res;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleRefreshRateChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, rate: Integer;
  rateStr: string;
begin
  if FSettings = nil then Exit();
  rateStr := AText;
  p := Pos(' ', rateStr);
  if p > 0 then
    rateStr := Copy(rateStr, 1, p - 1);
  rate := StrToIntDef(rateStr, 60);
  FSettings.RefreshRate := rate;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleScaleChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, scaleVal: Integer;
  scaleStr: string;
begin
  if FSettings = nil then Exit();
  scaleStr := AText;
  p := Pos('%', scaleStr);
  if p > 0 then
    scaleStr := Copy(scaleStr, 1, p - 1);
  scaleVal := StrToIntDef(scaleStr, 100);
  FSettings.Scale := scaleVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleNightLightToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.NightLight := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockPositionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DockPosition := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockIconSizeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, sizeVal: Integer;
  sizeStr: string;
begin
  if FSettings = nil then Exit();
  sizeStr := AText;
  p := Pos(' ', sizeStr);
  if p > 0 then
    sizeStr := Copy(sizeStr, 1, p - 1);
  sizeVal := StrToIntDef(sizeStr, 48);
  FSettings.DockIconSize := sizeVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockAutoHideToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.DockAutoHide := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockMarginChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, marginVal: Integer;
  mStr: string;
begin
  if FSettings = nil then Exit();
  mStr := AText;
  p := Pos(' ', mStr);
  if p > 0 then
    mStr := Copy(mStr, 1, p - 1);
  marginVal := StrToIntDef(mStr, 3);
  FSettings.DockMargin := marginVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleShowDesktopToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.ShowDesktopButton := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleClock24hToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  if AToggled then
    FSettings.ClockFormat := '24h'
  else
    FSettings.ClockFormat := '12h';
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleOutputDeviceChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.OutputDevice := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleVolumeChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.OutputVolume := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleMuteToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.Muted := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleSoundEffectsToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.SoundEffects := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandlePowerModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.PowerMode := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleScreenBlankChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  delayVal: Integer;
begin
  if FSettings = nil then Exit();
  if Pos('1 ', AText) = 1 then delayVal := 1
  else if Pos('5 ', AText) = 1 then delayVal := 5
  else if Pos('10 ', AText) = 1 then delayVal := 10
  else if Pos('15 ', AText) = 1 then delayVal := 15
  else delayVal := 0;

  FSettings.ScreenBlankDelay := delayVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleAutoSuspendToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.AutoSuspend := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandlePrimaryBtnChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.PrimaryButton := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandlePointerSpeedChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.PointerSpeed := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleNaturalScrollToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.NaturalScrolling := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleTapToClickToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.TapToClick := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleKeyboardLayoutChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.KeyboardLayout := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleKeyDelayChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.KeyRepeatDelay := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleKeyRateChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.KeyRepeatRate := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleSuperLauncherToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.SuperKeyLauncher := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleBrowserChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultBrowser := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleFileManagerChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultFileManager := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleTerminalChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultTerminal := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleEditorChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultTextEditor := AText;
  FSettings.Save();
end;

end.

// configsama.window.test.pas — integration tests for application window, FTML, and ECA
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Window.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ftpas, ftpas.types, ftpas.api, ftpas.app, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.views, ftpas.ftml,
  ConfigSama.Settings, ConfigSama.Window,
  ConfigSama.Wlan, ConfigSama.Wired, ConfigSama.Display,
  ConfigSama.Bluetooth, ConfigSama.Sound, ConfigSama.Power, ConfigSama.Desktop,
  ConfigSama.Background;

type
  { TConfigWindowTest }
  TConfigWindowTest = class(TTestCase)
  private
    FWindow: TConfigSamaWindow;
    FTestIniPath: string;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestWindowCreationAndFTMLResolution();
    procedure TestExtendedClientAreaEnabled();
    procedure TestCategoryNavigation();
    procedure TestSearchFiltering();
    procedure TestDarkModeInteraction();
    procedure TestWiredControlsAndToggle();
    procedure TestDisplayControlsAndInteraction();
    procedure TestBluetoothControlsAndToggle();
    procedure TestSoundControlsAndInteraction();
    procedure TestPowerControlsAndInteraction();
    procedure TestDesktopAndDockControls();
    procedure TestBackgroundControls();
    procedure TestAppearanceControlsAndFonts();
    procedure TestPageContainersScrollableAndResetOnNavigation();
  end;

implementation

procedure TConfigWindowTest.SetUp();
begin
  if not FtIsLibLoaded() then
  begin
    if not FtLoadLib() then
      Fail('Could not load libft.so');
  end;

  try
    FtApp().Initialize();
  except
    on E: Exception do
      Fail('FtApp.Initialize failed: ' + E.Message);
  end;

  // Enforce mock mode during tests to isolate from live X11 and network adapters
  DisplayService().EnableMockMode(True);
  WiredService().EnableMockMode(True);
  WlanService().EnableMockMode(True);
  BluetoothService().EnableMockMode(True);
  SoundService().EnableMockMode(True);
  PowerService().EnableMockMode(True);
  DesktopService().EnableMockMode(True);
  DesktopService().SetMockDockSettings('Bottom', 48, False, 3);
  DesktopService().SetMockPanelSettings(True, '24h');
  BackgroundService().SetMockMode(True);
  BackgroundService().SetMockData('/usr/share/backgrounds/samarinda.jpg', 'fill');

  FTestIniPath := Format('/tmp/configsama_win_test_%d_%d.ini', [GetProcessID(), Random(100000)]);
  FWindow := TConfigSamaWindow.Create(FTestIniPath);
end;

procedure TConfigWindowTest.TearDown();
begin
  if FWindow <> nil then
  begin
    FWindow.Free();
    FWindow := nil;
  end;
  if (FTestIniPath <> '') and FileExists(FTestIniPath) then
    DeleteFile(FTestIniPath);

  DisplayService().EnableMockMode(False);
  WiredService().EnableMockMode(False);
  WlanService().EnableMockMode(False);
  BluetoothService().EnableMockMode(False);
  SoundService().EnableMockMode(False);
  PowerService().EnableMockMode(False);
  DesktopService().SetMockDockSettings('Bottom', 48, False, 3);
  DesktopService().SetMockPanelSettings(True, '24h');
  DesktopService().EnableMockMode(False);
  BackgroundService().SetMockData('/usr/share/backgrounds/samarinda.jpg', 'fill');
  BackgroundService().SetMockMode(False);
end;

procedure TConfigWindowTest.TestWindowCreationAndFTMLResolution();
begin
  AssertNotNull('Window must be created', FWindow);
  AssertNotNull('CategoryTree must be resolved from FTML', FWindow.CategoryTree);
  AssertNotNull('SearchEntry must be resolved from FTML', FWindow.SearchEntry);
  AssertNotNull('AppTitle must be resolved from FTML', FWindow.AppTitle);
  AssertNotNull('SectionTitle must be resolved from FTML', FWindow.SectionTitle);
  AssertNotNull('SwDarkMode must be resolved from FTML', FWindow.SwDarkMode);
  AssertNotNull('CmbAccent must be resolved from FTML', FWindow.CmbAccent);
  AssertNotNull('TxtWallpaperPath must be resolved from FTML', FWindow.TxtWallpaperPath);
  AssertNotNull('SlVolume must be resolved from FTML', FWindow.SlVolume);
  AssertNotNull('SwMute must be resolved from FTML', FWindow.SwMute);

  AssertFalse('AppTitle must not be selectable', FWindow.AppTitle.Selectable);
  AssertFalse('SectionTitle must not be selectable', FWindow.SectionTitle.Selectable);
  AssertEquals('Initial section title is WLAN', 'WLAN', FWindow.SectionTitle.Text);
end;

procedure TConfigWindowTest.TestExtendedClientAreaEnabled();
begin
  AssertNotNull('Window must exist', FWindow);
  AssertTrue('Window ExtendedClientArea must be true from FTML markup', FWindow.ExtendedClientArea);
end;

procedure TConfigWindowTest.TestCategoryNavigation();
begin
  FWindow.SelectCategoryByName('Displays');
  AssertEquals('Section title updated to Displays', 'Displays', FWindow.SectionTitle.Text);

  FWindow.SelectCategoryByName('Desktop & Dock');
  AssertEquals('Section title updated to Desktop & Dock', 'Desktop & Dock', FWindow.SectionTitle.Text);

  FWindow.SelectCategoryByName('Sound');
  AssertEquals('Section title updated to Sound', 'Sound', FWindow.SectionTitle.Text);

  FWindow.SelectCategoryByName('Power');
  AssertEquals('Section title updated to Power', 'Power', FWindow.SectionTitle.Text);

  FWindow.SelectCategoryByName('About');
  AssertEquals('Section title updated to About', 'About', FWindow.SectionTitle.Text);
end;

procedure TConfigWindowTest.TestSearchFiltering();
begin
  FWindow.SearchEntry.Text := 'dock';
  AssertEquals('Search dock navigates to Desktop & Dock', 'Desktop & Dock', FWindow.SectionTitle.Text);

  FWindow.SearchEntry.Text := 'vol';
  AssertEquals('Search vol navigates to Sound', 'Sound', FWindow.SectionTitle.Text);

  FWindow.SearchEntry.Text := 'resolut';
  AssertEquals('Search resolut navigates to Displays', 'Displays', FWindow.SectionTitle.Text);

  FWindow.SearchEntry.Text := 'sys';
  AssertEquals('Search sys navigates to About', 'About', FWindow.SectionTitle.Text);
end;

procedure TConfigWindowTest.TestDarkModeInteraction();
var
  initialMode: Boolean;
begin
  initialMode := FWindow.SwDarkMode.Checked;
  FWindow.SwDarkMode.Checked := not initialMode;
  AssertEquals('Settings DarkMode must match toggle', not initialMode, FWindow.Settings.DarkMode);

  // Revert back
  FWindow.SwDarkMode.Checked := initialMode;
  AssertEquals('Settings DarkMode reverted', initialMode, FWindow.Settings.DarkMode);
end;

procedure TConfigWindowTest.TestWiredControlsAndToggle();
begin
  FWindow.SelectCategoryByName('Wired');
  AssertEquals('Section title updated to Wired', 'Wired', FWindow.SectionTitle.Text);

  AssertNotNull('SwWired must exist', FWindow.SwWired);
  AssertNotNull('LblWiredStatus must exist', FWindow.LblWiredStatus);

  // Toggle wired off
  FWindow.SwWired.Checked := False;
  AssertFalse('Wired switch must be unchecked', FWindow.SwWired.Checked);
  AssertEquals('Wired status must show turned off', 'Wired is turned off', FWindow.LblWiredStatus.Text);

  // Toggle wired back on
  FWindow.SwWired.Checked := True;
  AssertTrue('Wired switch must be checked', FWindow.SwWired.Checked);
end;

procedure TConfigWindowTest.TestDisplayControlsAndInteraction();
begin
  FWindow.SelectCategoryByName('Displays');
  AssertEquals('Section title updated to Displays', 'Displays', FWindow.SectionTitle.Text);

  AssertNotNull('CmbDisplay must exist', FWindow.CmbDisplay);
  AssertNotNull('CmbResolution must exist', FWindow.CmbResolution);
  AssertNotNull('CmbRefreshRate must exist', FWindow.CmbRefreshRate);
  AssertNotNull('SldBrightness must exist', FWindow.SldBrightness);
  AssertNotNull('BtnDisplayApply must exist', FWindow.BtnDisplayApply);
  AssertNotNull('LblDisplayInfo must exist', FWindow.LblDisplayInfo);
  AssertNotNull('SegScale must exist', FWindow.SegScale);

  // Test brightness slider interaction
  FWindow.SldBrightness.Value := 75.0;
  AssertEquals('Brightness value must be 75', 75, Round(FWindow.SldBrightness.Value));

  // Test scale segmented control
  FWindow.SegScale.SelectedIndex := 2; // 150%
  AssertEquals('Settings Scale updated to 150', 150, FWindow.Settings.Scale);
end;

procedure TConfigWindowTest.TestBluetoothControlsAndToggle();
begin
  FWindow.SelectCategoryByName('Bluetooth');
  AssertEquals('Section title updated to Bluetooth', 'Bluetooth', FWindow.SectionTitle.Text);

  AssertNotNull('PageBluetooth must exist', FWindow.PageBluetooth);
  AssertTrue('PageBluetooth must be visible', FWindow.PageBluetooth.Visible);
  AssertNotNull('SwBluetooth must exist', FWindow.SwBluetooth);
  AssertNotNull('LblBluetoothStatus must exist', FWindow.LblBluetoothStatus);
  AssertNotNull('BtnBluetoothScan must exist', FWindow.BtnBluetoothScan);
  AssertNotNull('CardBluetoothDevices must exist', FWindow.CardBluetoothDevices);

  // Toggle Bluetooth Off
  FWindow.SwBluetooth.Checked := False;
  AssertFalse('Bluetooth switch must be unchecked', FWindow.SwBluetooth.Checked);
  AssertFalse('Bluetooth service disabled', BluetoothService().IsBluetoothEnabled());

  // Toggle Bluetooth back On
  FWindow.SwBluetooth.Checked := True;
  AssertTrue('Bluetooth switch must be checked', FWindow.SwBluetooth.Checked);
  AssertTrue('Bluetooth service re-enabled', BluetoothService().IsBluetoothEnabled());
end;

procedure TConfigWindowTest.TestSoundControlsAndInteraction();
begin
  FWindow.SelectCategoryByName('Sound');
  AssertEquals('Section title updated to Sound', 'Sound', FWindow.SectionTitle.Text);

  AssertNotNull('PageSound must exist', FWindow.PageSound);
  AssertTrue('PageSound must be visible', FWindow.PageSound.Visible);
  AssertNotNull('CmbOutputDevice must exist', FWindow.CmbOutputDevice);
  AssertNotNull('SlVolume must exist', FWindow.SlVolume);
  AssertNotNull('SwMute must exist', FWindow.SwMute);
  AssertNotNull('BtnTestSound must exist', FWindow.BtnTestSound);
  AssertNotNull('CmbInputDevice must exist', FWindow.CmbInputDevice);
  AssertNotNull('SlInputVolume must exist', FWindow.SlInputVolume);
  AssertNotNull('SwInputMute must exist', FWindow.SwInputMute);
  AssertNotNull('SwSoundEffects must exist', FWindow.SwSoundEffects);

  // Test volume interaction
  FWindow.SlVolume.Value := 85.0;
  AssertEquals('Settings OutputVolume updated to 85', 85, FWindow.Settings.OutputVolume);

  // Test mute toggle
  FWindow.SwMute.Checked := True;
  AssertTrue('Settings Muted is True', FWindow.Settings.Muted);
  FWindow.SwMute.Checked := False;
  AssertFalse('Settings Muted is False', FWindow.Settings.Muted);
end;

procedure TConfigWindowTest.TestPowerControlsAndInteraction();
begin
  FWindow.SelectCategoryByName('Power');
  AssertEquals('Section title updated to Power', 'Power', FWindow.SectionTitle.Text);

  AssertNotNull('PageBattery must exist', FWindow.PageBattery);
  AssertTrue('PageBattery must be visible', FWindow.PageBattery.Visible);
  AssertNotNull('CardBatteryBanner must exist', FWindow.CardBatteryBanner);
  AssertNotNull('CardBatteryFill must exist', FWindow.CardBatteryFill);
  AssertNotNull('ImgBatteryBolt must exist', FWindow.ImgBatteryBolt);
  AssertNotNull('LblBatteryPercent must exist', FWindow.LblBatteryPercent);
  AssertNotNull('LblBatteryRemaining must exist', FWindow.LblBatteryRemaining);
  AssertNotNull('SegPowerMode must exist', FWindow.SegPowerMode);
  AssertNotNull('CmbScreenBlank must exist', FWindow.CmbScreenBlank);
  AssertNotNull('SwAutoSuspend must exist', FWindow.SwAutoSuspend);

  // Battery icon must not show charging bolt when discharging
  AssertEquals('Battery icon must be battery-outline-white when discharging', 'battery-outline-white', FWindow.BatteryIconName);

  // Card fill width must be proportional to battery percentage
  AssertTrue('CardBatteryFill width should be > 0 when battery percentage > 0', FWindow.CardBatteryFill.Width > 0);
  AssertTrue('CardBatteryFill width should be <= CardBatteryBanner width', FWindow.CardBatteryFill.Width <= FWindow.CardBatteryBanner.Width);

  // When charging, battery icon switches to battery-bolt
  PowerService().SetMockBattery(True, 85, 'Charging', True);
  FWindow.SelectCategoryByName('Power');
  AssertEquals('Battery icon must be battery-bolt when charging', 'battery-bolt', FWindow.BatteryIconName);

  // Restore discharging state
  PowerService().SetMockBattery(True, 85, 'Discharging', False);
  FWindow.SelectCategoryByName('Power');
  AssertEquals('Battery icon must return to battery-outline-white when discharging', 'battery-outline-white', FWindow.BatteryIconName);

  // Test Power Mode segmented select
  FWindow.SegPowerMode.SelectedIndex := 0; // Power Saver
  AssertEquals('Settings PowerMode updated to Power Saver', 'Power Saver', FWindow.Settings.PowerMode);

  FWindow.SegPowerMode.SelectedIndex := 2; // Performance
  AssertEquals('Settings PowerMode updated to Performance', 'Performance', FWindow.Settings.PowerMode);
end;

procedure TConfigWindowTest.TestDesktopAndDockControls();
begin
  FWindow.SelectCategoryByName('Desktop & Dock');
  AssertEquals('Section title updated to Desktop & Dock', 'Desktop & Dock', FWindow.SectionTitle.Text);

  AssertNotNull('PageDesktop must exist', FWindow.PageDesktop);
  AssertTrue('PageDesktop must be visible', FWindow.PageDesktop.Visible);
  AssertNotNull('SegDockPosition must exist', FWindow.SegDockPosition);
  AssertNotNull('CmbDockPosition must exist', FWindow.CmbDockPosition);
  AssertNotNull('CmbDockIconSize must exist', FWindow.CmbDockIconSize);
  AssertNotNull('SwDockAutoHide must exist', FWindow.SwDockAutoHide);
  AssertNotNull('CmbDockMargin must exist', FWindow.CmbDockMargin);
  AssertNotNull('SwShowDesktopBtn must exist', FWindow.SwShowDesktopBtn);
  AssertNotNull('SwClock24h must exist', FWindow.SwClock24h);

  // Initial mock values
  AssertEquals('Default dock position is Bottom', 'Bottom', DesktopService().GetDockPosition());
  AssertEquals('SegDockPosition selected index is 1 (Bottom)', 1, FWindow.SegDockPosition.SelectedIndex);
  AssertEquals('Icon size text is 48 px', '48 px', FWindow.CmbDockIconSize.Text);
  AssertFalse('Dock auto-hide is False', FWindow.SwDockAutoHide.Checked);
  AssertEquals('Dock margin is 3 px (Standard)', '3 px (Standard)', FWindow.CmbDockMargin.Text);
  AssertTrue('Show desktop button is True', FWindow.SwShowDesktopBtn.Checked);
  AssertTrue('24-Hour time format is True', FWindow.SwClock24h.Checked);

  // Position change via SegmentedControl
  FWindow.SegDockPosition.SelectedIndex := 0; // Left
  AssertEquals('Dock position updated to Left', 'Left', DesktopService().GetDockPosition());
  AssertEquals('CmbDockPosition text updated to Left', 'Left', FWindow.CmbDockPosition.Text);

  FWindow.SegDockPosition.SelectedIndex := 2; // Right
  AssertEquals('Dock position updated to Right', 'Right', DesktopService().GetDockPosition());
  AssertEquals('CmbDockPosition text updated to Right', 'Right', FWindow.CmbDockPosition.Text);

  // Icon size change
  FWindow.CmbDockIconSize.Text := '32 px';
  AssertEquals('Dock icon size updated to 32', 32, DesktopService().GetDockIconSize());

  // Auto-hide toggle
  FWindow.SwDockAutoHide.Checked := True;
  AssertTrue('Dock auto-hide enabled', DesktopService().GetDockAutoHide());

  // Margin change
  FWindow.CmbDockMargin.Text := '5 px';
  AssertEquals('Dock margin updated to 5', 5, DesktopService().GetDockMargin());

  // Show desktop button toggle
  FWindow.SwShowDesktopBtn.Checked := False;
  AssertFalse('Show desktop button disabled', DesktopService().GetShowDesktopButton());

  // Clock format toggle
  FWindow.SwClock24h.Checked := False;
  AssertEquals('Clock format updated to 12h', '12h', DesktopService().GetClockFormat());

  // External update through service triggers UI refresh
  DesktopService().SetMockDockSettings('Bottom', 64, True, 8);
  AssertEquals('SegDockPosition updated to 1 on external change', 1, FWindow.SegDockPosition.SelectedIndex);
  AssertEquals('CmbDockIconSize updated to 64 px on external change', '64 px', FWindow.CmbDockIconSize.Text);
  AssertTrue('SwDockAutoHide updated on external change', FWindow.SwDockAutoHide.Checked);
  AssertEquals('CmbDockMargin updated on external change', '8 px', FWindow.CmbDockMargin.Text);
end;

procedure TConfigWindowTest.TestAppearanceControlsAndFonts();
begin
  FWindow.SelectCategoryByName('Appearance');
  AssertEquals('Section title updated to Appearance', 'Appearance', FWindow.SectionTitle.Text);

  AssertNotNull('PageAppearance must exist', FWindow.PageAppearance);
  AssertTrue('PageAppearance must be visible', FWindow.PageAppearance.Visible);
  AssertNotNull('BtnThemeLight must exist', FWindow.BtnThemeLight);
  AssertNotNull('BtnThemeDark must exist', FWindow.BtnThemeDark);
  AssertNotNull('SwDarkMode must exist', FWindow.SwDarkMode);
  AssertNotNull('BtnStandardFont must exist', FWindow.BtnStandardFont);
  AssertNotNull('BtnMonospaceFont must exist', FWindow.BtnMonospaceFont);

  // Test Font cycle interaction
  FWindow.CycleStandardFont();
  AssertTrue('Standard font updated', FWindow.Settings.StandardFont <> '');

  FWindow.CycleMonospaceFont();
  AssertTrue('Monospace font updated', FWindow.Settings.MonospaceFont <> '');
end;

procedure TConfigWindowTest.TestPageContainersScrollableAndResetOnNavigation();
var
  pages: array[0..15] of TFtWidget;
  i: Integer;
  w, h: Double;
  child: TFtWidget;
begin
  pages[0] := FWindow.PageWlan;
  pages[1] := FWindow.PageWired;
  pages[2] := FWindow.PageBluetooth;
  pages[3] := FWindow.PageDisplays;
  pages[4] := FWindow.PageAppearance;
  pages[5] := FWindow.PageBackground;
  pages[6] := FWindow.PageDesktop;
  pages[7] := FWindow.PageUser;
  pages[8] := FWindow.PageLanguage;
  pages[9] := FWindow.PageBattery;
  pages[10] := FWindow.PageAbout;
  pages[11] := FWindow.PageSound;
  pages[12] := FWindow.PagePower;
  pages[13] := FWindow.PageMouse;
  pages[14] := FWindow.PageKeyboard;
  pages[15] := FWindow.PageApps;

  for i := 0 to 15 do
  begin
    AssertNotNull(Format('Page container %d must not be nil', [i]), pages[i]);
    AssertTrue(Format('Page %d must be TFtContainer', [i]), pages[i] is TFtContainer);
    AssertTrue(Format('Page %d must have vertical scrollbar mode', [i]),
      TFtContainer(pages[i]).ScrollBarMode = ftsbmVerticalOnly);
    TFtContainer(pages[i]).GetContentSize(w, h);
    WriteLn(Format('Page %d (%s): W=%d H=%d ContentW=%.1f ContentH=%.1f Overflows=%s',
      [i, pages[i].ClassName, pages[i].Width, pages[i].Height, w, h, BoolToStr(h > pages[i].Height, True)]));
  end;

  // Test Appearance page scrolling and scroll position reset on category switch
  FWindow.SelectCategoryByName('Appearance');
  AssertTrue('PageAppearance must be visible', FWindow.PageAppearance.Visible);

  // Resize window so content (486px) overflows the window viewport
  FWindow.SetSize(960, 450);

  TFtContainer(FWindow.PageAppearance).GetContentSize(w, h);
  AssertTrue('Appearance page content height must overflow window height', h > FWindow.PageAppearance.Height);

  // Scroll down
  TFtContainer(FWindow.PageAppearance).SetScrollPos(0.0, 50.0);
  AssertTrue('Page scroll offset must be scrolled down', TFtContainer(FWindow.PageAppearance).ScrollY > 0.0);

  // Switch away to WLAN and then back to Appearance
  FWindow.SelectCategoryByName('WLAN');
  AssertTrue('PageWlan must be visible', FWindow.PageWlan.Visible);

  FWindow.SelectCategoryByName('Appearance');
  AssertTrue('PageAppearance must be visible again', FWindow.PageAppearance.Visible);
  AssertEquals('Page scroll offset must reset to top on navigation', 0.0, TFtContainer(FWindow.PageAppearance).ScrollY);

  // Restore window height
  FWindow.SetSize(960, 640);
end;

procedure TConfigWindowTest.TestBackgroundControls();
begin
  FWindow.SelectCategoryByName('Background');
  AssertTrue('PageBackground must be visible', FWindow.PageBackground.Visible);

  AssertNotNull('TxtWallpaperPath must be resolved', FWindow.TxtWallpaperPath);
  AssertNotNull('CmbWallpaperMode must be resolved', FWindow.CmbWallpaperMode);
  AssertNotNull('BtnChooseWallpaper must be resolved', FWindow.BtnChooseWallpaper);
  AssertNotNull('ImgWallpaperThumb must be resolved', FWindow.ImgWallpaperThumb);
  AssertNotNull('LblWallpaperName must be resolved', FWindow.LblWallpaperName);
  AssertNotNull('CardWallpaperPresets must be resolved', FWindow.CardWallpaperPresets);

  AssertEquals('Default wallpaper path matches mock', '/usr/share/backgrounds/samarinda.jpg', FWindow.TxtWallpaperPath.Text);
  AssertEquals('Default wallpaper name is Samarinda', 'Samarinda', FWindow.LblWallpaperName.Text);
  AssertEquals('Default wallpaper mode is Fill', 'Fill', FWindow.CmbWallpaperMode.Text);

  // Check presets grid
  AssertTrue('Preset buttons count >= 4 in mock mode', Length(FWindow.WallpaperPresetButtons) >= 4);
  AssertTrue('First preset button is active', Pos('active', FWindow.WallpaperPresetButtons[0].StyleClass) > 0);

  // Click second preset (Mountains)
  FWindow.WallpaperPresetButtons[1].OnClick(FWindow.WallpaperPresetButtons[1]);
  AssertEquals('Wallpaper path updated to Mountains', '/usr/share/backgrounds/mountains.jpg', BackgroundService().GetWallpaperPath());
  AssertEquals('TxtWallpaperPath updated to Mountains', '/usr/share/backgrounds/mountains.jpg', FWindow.TxtWallpaperPath.Text);
  AssertEquals('LblWallpaperName updated to Mountains', 'Mountains', FWindow.LblWallpaperName.Text);
  AssertTrue('Second preset button is now active', Pos('active', FWindow.WallpaperPresetButtons[1].StyleClass) > 0);
  AssertFalse('First preset button is no longer active', Pos('active', FWindow.WallpaperPresetButtons[0].StyleClass) > 0);

  // Change wallpaper mode
  FWindow.CmbWallpaperMode.Text := 'Stretch';
  FWindow.CmbWallpaperMode.OnChange(FWindow.CmbWallpaperMode, 2, 'Stretch');
  AssertEquals('Wallpaper mode updated to stretch', 'stretch', BackgroundService().GetWallpaperMode());

  // Add custom wallpaper
  BackgroundService().AddCustomWallpaper('/tmp/my_custom_photo.jpg');
  FWindow.RefreshBackgroundUI();
  AssertEquals('Custom wallpaper path active', '/tmp/my_custom_photo.jpg', BackgroundService().GetWallpaperPath());
  AssertEquals('TxtWallpaperPath matches custom', '/tmp/my_custom_photo.jpg', FWindow.TxtWallpaperPath.Text);
  AssertEquals('LblWallpaperName matches custom', 'My Custom Photo', FWindow.LblWallpaperName.Text);
end;

initialization
  RegisterTest(TConfigWindowTest);

end.

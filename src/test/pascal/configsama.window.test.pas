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
  ConfigSama.Bluetooth, ConfigSama.Sound, ConfigSama.Power;

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
    procedure TestAppearanceControlsAndFonts();
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
  AssertNotNull('LblBatteryPercent must exist', FWindow.LblBatteryPercent);
  AssertNotNull('LblBatteryRemaining must exist', FWindow.LblBatteryRemaining);
  AssertNotNull('SegPowerMode must exist', FWindow.SegPowerMode);
  AssertNotNull('CmbScreenBlank must exist', FWindow.CmbScreenBlank);
  AssertNotNull('SwAutoSuspend must exist', FWindow.SwAutoSuspend);

  // Test Power Mode segmented select
  FWindow.SegPowerMode.SelectedIndex := 0; // Power Saver
  AssertEquals('Settings PowerMode updated to Power Saver', 'Power Saver', FWindow.Settings.PowerMode);

  FWindow.SegPowerMode.SelectedIndex := 2; // Performance
  AssertEquals('Settings PowerMode updated to Performance', 'Performance', FWindow.Settings.PowerMode);
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

initialization
  RegisterTest(TConfigWindowTest);

end.

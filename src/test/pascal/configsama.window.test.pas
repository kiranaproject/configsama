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
  ConfigSama.Wlan, ConfigSama.Wired, ConfigSama.Display;

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

initialization
  RegisterTest(TConfigWindowTest);

end.

// configsama.window.test.pas — integration tests for application window, FTML, and ECA
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Window.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ftpas, ftpas.types, ftpas.api, ftpas.app, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.views, ftpas.ftml,
  ConfigSama.Settings, ConfigSama.Window;

type
  { TConfigWindowTest }
  TConfigWindowTest = class(TTestCase)
  private
    FWindow: TConfigSamaWindow;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestWindowCreationAndFTMLResolution();
    procedure TestExtendedClientAreaEnabled();
    procedure TestCategoryNavigation();
    procedure TestSearchFiltering();
    procedure TestDarkModeInteraction();
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

  FWindow := TConfigSamaWindow.Create();
end;

procedure TConfigWindowTest.TearDown();
begin
  if FWindow <> nil then
  begin
    FWindow.Free();
    FWindow := nil;
  end;
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
  AssertEquals('Initial section title is Appearance', 'Appearance', FWindow.SectionTitle.Text);
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

initialization
  RegisterTest(TConfigWindowTest);

end.

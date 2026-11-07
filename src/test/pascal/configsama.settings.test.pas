// configsama.settings.test.pas — unit tests for settings model and persistence
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Settings.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Settings;

type
  { TConfigSettingsTest }
  TConfigSettingsTest = class(TTestCase)
  private
    FSettings: TConfigSettings;
    FTestIniPath: string;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestDefaultValues();
    procedure TestSaveAndReload();
    procedure TestWallpaperSync();
    procedure TestSystemInfoHelpers();
  end;

implementation

procedure TConfigSettingsTest.SetUp();
begin
  FTestIniPath := '/tmp/configsama_test_' + IntToStr(GetProcessID()) + '.ini';
  if FileExists(FTestIniPath) then
    DeleteFile(FTestIniPath);
  FSettings := TConfigSettings.Create(FTestIniPath);
end;

procedure TConfigSettingsTest.TearDown();
begin
  if Assigned(FSettings) then
  begin
    FSettings.Free();
    FSettings := nil;
  end;
  if FileExists(FTestIniPath) then
    DeleteFile(FTestIniPath);
end;

procedure TConfigSettingsTest.TestDefaultValues();
begin
  AssertNotNull('Settings store must exist', FSettings);
  AssertFalse('Default dark mode is false', FSettings.DarkMode);
  AssertEquals('Default accent color is Blue', 'Blue', FSettings.AccentColor);
  AssertEquals('Default wallpaper mode is fill', 'fill', FSettings.WallpaperMode);
  AssertEquals('Default resolution is 1920x1080', '1920x1080', FSettings.Resolution);
  AssertEquals('Default refresh rate is 60', 60, FSettings.RefreshRate);
  AssertEquals('Default dock position is Bottom', 'Bottom', FSettings.DockPosition);
  AssertEquals('Default dock icon size is 48', 48, FSettings.DockIconSize);
  AssertEquals('Default dock margin is 3', 3, FSettings.DockMargin);
  AssertTrue('Default show desktop button is true', FSettings.ShowDesktopButton);
  AssertEquals('Default volume is 75', 75, FSettings.OutputVolume);
  AssertFalse('Default mute is false', FSettings.Muted);
  AssertTrue('Default super key launcher is true', FSettings.SuperKeyLauncher);
end;

procedure TConfigSettingsTest.TestSaveAndReload();
var
  reloaded: TConfigSettings;
begin
  FSettings.DarkMode := True;
  FSettings.AccentColor := 'Crimson';
  FSettings.Resolution := '2560x1440';
  FSettings.RefreshRate := 144;
  FSettings.DockMargin := 5;
  FSettings.OutputVolume := 88;
  FSettings.Muted := True;
  FSettings.Save();

  reloaded := TConfigSettings.Create(FTestIniPath);
  try
    AssertTrue('Reloaded dark mode must be true', reloaded.DarkMode);
    AssertEquals('Reloaded accent color must be Crimson', 'Crimson', reloaded.AccentColor);
    AssertEquals('Reloaded resolution must be 2560x1440', '2560x1440', reloaded.Resolution);
    AssertEquals('Reloaded refresh rate must be 144', 144, reloaded.RefreshRate);
    AssertEquals('Reloaded dock margin must be 5', 5, reloaded.DockMargin);
    AssertEquals('Reloaded volume must be 88', 88, reloaded.OutputVolume);
    AssertTrue('Reloaded mute must be true', reloaded.Muted);
  finally
    reloaded.Free();
  end;
end;

procedure TConfigSettingsTest.TestWallpaperSync();
var
  shellConfPath: string;
  lines: TStringList;
begin
  FSettings.WallpaperPath := '/tmp/test_bg.png';
  FSettings.WallpaperMode := 'fit';
  FSettings.Save();

  shellConfPath := GetEnvironmentVariable('HOME') + '/.config/shellsama/desktop.conf';
  AssertTrue('Shellsama desktop.conf must exist', FileExists(shellConfPath));

  lines := TStringList.Create();
  try
    lines.LoadFromFile(shellConfPath);
    AssertTrue('Config contains wallpaper path', Pos('/tmp/test_bg.png', lines.Text) > 0);
    AssertTrue('Config contains mode=fit', Pos('mode=fit', lines.Text) > 0);
  finally
    lines.Free();
  end;
end;

procedure TConfigSettingsTest.TestSystemInfoHelpers();
begin
  AssertEquals('OS Name is Samarinda OS', 'Samarinda OS', FSettings.GetOsName());
  AssertEquals('OS Version is 1.0 "Kutai"', '1.0 "Kutai"', FSettings.GetOsVersion());
  AssertTrue('Kernel version non empty', Length(FSettings.GetKernelVersion()) > 0);
  AssertTrue('CPU model non empty', Length(FSettings.GetCpuModel()) > 0);
  AssertTrue('Memory total non empty', Length(FSettings.GetMemoryTotal()) > 0);
end;

initialization
  RegisterTest(TConfigSettingsTest);

end.

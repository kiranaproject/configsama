// configsama.background.test.pas — unit tests for Background and Wallpaper service layer
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Background.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Background;

type
  { TConfigBackgroundTest }
  TConfigBackgroundTest = class(TTestCase)
  private
    FChangedCount: Integer;
    procedure HandleChange(Sender: TObject);
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockModeToggle();
    procedure TestMockWallpaperSettings();
    procedure TestScanWallpapers();
    procedure TestFindWallpaperIndex();
    procedure TestAddCustomWallpaper();
    procedure TestThumbnailPath();
    procedure TestChangeNotification();
  end;

implementation

procedure TConfigBackgroundTest.HandleChange(Sender: TObject);
begin
  Inc(FChangedCount);
end;

procedure TConfigBackgroundTest.SetUp();
begin
  FChangedCount := 0;
  BackgroundService().SetMockMode(True);
  BackgroundService().SetMockData('/usr/share/backgrounds/samarinda.jpg', 'fill');
  BackgroundService().OnChange := @HandleChange;
  FChangedCount := 0;
end;

procedure TConfigBackgroundTest.TearDown();
begin
  BackgroundService().OnChange := nil;
  BackgroundService().SetMockData('/usr/share/backgrounds/samarinda.jpg', 'fill');
  BackgroundService().SetMockMode(False);
end;

procedure TConfigBackgroundTest.TestServiceSingleton();
var
  svc1, svc2: TConfigBackgroundService;
begin
  svc1 := BackgroundService();
  svc2 := BackgroundService();
  AssertNotNull('BackgroundService must return non-nil instance', svc1);
  AssertTrue('BackgroundService must return identical singleton', svc1 = svc2);
end;

procedure TConfigBackgroundTest.TestMockModeToggle();
var
  svc: TConfigBackgroundService;
begin
  svc := BackgroundService();
  AssertTrue('Mock mode is initially true in SetUp', svc.MockMode);
  svc.SetMockMode(False);
  AssertFalse('Mock mode is disabled', svc.MockMode);
  svc.SetMockMode(True);
  AssertTrue('Mock mode is re-enabled', svc.MockMode);
end;

procedure TConfigBackgroundTest.TestMockWallpaperSettings();
var
  svc: TConfigBackgroundService;
begin
  svc := BackgroundService();
  AssertEquals('Default wallpaper path matches mock', '/usr/share/backgrounds/samarinda.jpg', svc.GetWallpaperPath());
  AssertEquals('Default wallpaper mode matches mock', 'fill', svc.GetWallpaperMode());

  svc.SetWallpaperPath('/tmp/custom_wallpaper.png');
  AssertEquals('Wallpaper path updated', '/tmp/custom_wallpaper.png', svc.GetWallpaperPath());

  svc.SetWallpaperMode('stretch');
  AssertEquals('Wallpaper mode updated', 'stretch', svc.GetWallpaperMode());

  svc.SetWallpaperMode('fit');
  AssertEquals('Wallpaper mode updated to fit', 'fit', svc.GetWallpaperMode());
end;

procedure TConfigBackgroundTest.TestScanWallpapers();
var
  svc: TConfigBackgroundService;
  count: Integer;
  item: TWallpaperItem;
begin
  svc := BackgroundService();
  count := svc.ScanWallpapers();
  AssertTrue('ScanWallpapers returns non-negative count', count >= 0);
  AssertEquals('WallpaperCount matches returned count', count, svc.WallpaperCount);

  if count > 0 then
  begin
    item := svc.GetWallpaper(0);
    AssertTrue('Wallpaper item path is non-empty', item.Path <> '');
    AssertTrue('Wallpaper item name is non-empty', item.Name <> '');
  end;

  // Invalid index returns empty record
  item := svc.GetWallpaper(-1);
  AssertEquals('Invalid index returns empty path', '', item.Path);
  item := svc.GetWallpaper(count + 10);
  AssertEquals('Out of range index returns empty path', '', item.Path);
end;

procedure TConfigBackgroundTest.TestFindWallpaperIndex();
var
  svc: TConfigBackgroundService;
  idx: Integer;
begin
  svc := BackgroundService();
  idx := svc.FindWallpaperIndex('/nonexistent/wallpaper/test_path_xyz.jpg');
  AssertEquals('Non-existent path returns -1', -1, idx);
end;

procedure TConfigBackgroundTest.TestAddCustomWallpaper();
var
  svc: TConfigBackgroundService;
  tmpFile: string;
  f: TextFile;
  prevCount, newCount: Integer;
  item: TWallpaperItem;
begin
  svc := BackgroundService();
  tmpFile := '/tmp/test_custom_wallpaper_' + IntToStr(GetTickCount64()) + '.png';
  AssignFile(f, tmpFile);
  Rewrite(f);
  WriteLn(f, 'fake png image data');
  CloseFile(f);

  try
    prevCount := svc.WallpaperCount;
    svc.AddCustomWallpaper(tmpFile);
    newCount := svc.WallpaperCount;
    AssertTrue('Custom wallpaper added to list', newCount >= prevCount);
    AssertEquals('Custom wallpaper set as current', tmpFile, svc.GetWallpaperPath());

    item := svc.GetWallpaper(0);
    AssertEquals('Custom wallpaper is prepended at index 0', tmpFile, item.Path);
    AssertTrue('Custom wallpaper marked as custom', item.IsCustom);
  finally
    if FileExists(tmpFile) then
      DeleteFile(tmpFile);
  end;
end;

procedure TConfigBackgroundTest.TestThumbnailPath();
var
  svc: TConfigBackgroundService;
  p: string;
begin
  svc := BackgroundService();
  p := svc.GetThumbnailPath('/usr/share/backgrounds/samarinda.jpg');
  AssertTrue('Thumbnail path has .thumb.png extension', Pos('.thumb.png', p) > 0);
  AssertTrue('Thumbnail path contains sanitized characters', Pos('_usr_share_backgrounds_samarinda_jpg', p) > 0);
end;

procedure TConfigBackgroundTest.TestChangeNotification();
var
  svc: TConfigBackgroundService;
begin
  svc := BackgroundService();
  FChangedCount := 0;

  svc.SetWallpaperPath('/usr/share/backgrounds/nature.png');
  AssertTrue('Setting wallpaper path triggered OnChange', FChangedCount > 0);

  FChangedCount := 0;
  svc.SetWallpaperMode('center');
  AssertTrue('Setting wallpaper mode triggered OnChange', FChangedCount > 0);
end;

initialization
  RegisterTest(TConfigBackgroundTest);

end.

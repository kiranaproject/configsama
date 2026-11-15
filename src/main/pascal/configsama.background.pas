// configsama.background.pas — Background & Wallpaper Service
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Background;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ftpas.api, ftpas, ftpas.canvas,
  ConfigSama.Settings;

type
  TWallpaperItem = record
    Path: string;
    Name: string;
    IsCustom: Boolean;
  end;

  TWallpaperArray = array of TWallpaperItem;

  TConfigBackgroundService = class
  private
    FMockMode: Boolean;
    FMockWallpaperPath: string;
    FMockWallpaperMode: string;
    FWallpapers: TWallpaperArray;
    FOnChange: TNotifyEvent;
    FCacheDir: string;

    function SanitizePath(const APath: string): string;
    procedure EnsureCacheDir();
    procedure ScanDirectory(const ADir: string; AIsCustom: Boolean);
    function IsImageFile(const APath: string): Boolean;
  protected
    procedure NotifyChange(); virtual;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    function CleanWallpaperName(const AFileName: string): string;

    procedure SetMockMode(AValue: Boolean);
    procedure SetMockData(const APath, AMode: string);

    // Wallpaper discovery
    function ScanWallpapers(): Integer;
    function GetWallpaperCount(): Integer;
    function GetWallpaper(AIndex: Integer): TWallpaperItem;
    function FindWallpaperIndex(const APath: string): Integer;
    procedure AddCustomWallpaper(const APath: string);

    // Settings
    function GetWallpaperPath(): string;
    procedure SetWallpaperPath(const APath: string);
    function GetWallpaperMode(): string;
    procedure SetWallpaperMode(const AMode: string);

    // Thumbnail generation and caching
    function GetThumbnailPath(const APath: string): string;
    function GetThumbnail(const APath: string; AWidth: Integer = 200; AHeight: Integer = 120): TFtBitmap;

    property MockMode: Boolean read FMockMode write SetMockMode;
    property WallpaperCount: Integer read GetWallpaperCount;
    property WallpaperPath: string read GetWallpaperPath write SetWallpaperPath;
    property WallpaperMode: string read GetWallpaperMode write SetWallpaperMode;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

function BackgroundService(): TConfigBackgroundService;

implementation

var
  GBackgroundServiceInstance: TConfigBackgroundService = nil;

function BackgroundService(): TConfigBackgroundService;
begin
  if GBackgroundServiceInstance = nil then
    GBackgroundServiceInstance := TConfigBackgroundService.Create();
  Result := GBackgroundServiceInstance;
end;

{ TConfigBackgroundService }

constructor TConfigBackgroundService.Create();
var
  homeDir: string;
begin
  inherited Create();
  FMockMode := False;
  FMockWallpaperPath := '/usr/share/backgrounds/samarinda.jpg';
  FMockWallpaperMode := 'fill';
  SetLength(FWallpapers, 0);

  homeDir := GetEnvironmentVariable('HOME');
  if homeDir <> '' then
    FCacheDir := IncludeTrailingPathDelimiter(homeDir) + '.cache/samarinda/wallpapers/'
  else
    FCacheDir := '/tmp/samarinda/wallpapers/';
end;

destructor TConfigBackgroundService.Destroy();
begin
  SetLength(FWallpapers, 0);
  inherited Destroy();
end;

procedure TConfigBackgroundService.SetMockMode(AValue: Boolean);
begin
  FMockMode := AValue;
  SetLength(FWallpapers, 0);
end;

procedure TConfigBackgroundService.SetMockData(const APath, AMode: string);
begin
  FMockWallpaperPath := APath;
  FMockWallpaperMode := AMode;
  SetLength(FWallpapers, 0);
  NotifyChange();
end;

procedure TConfigBackgroundService.NotifyChange();
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TConfigBackgroundService.SanitizePath(const APath: string): string;
var
  s: string;
  i: Integer;
begin
  s := APath;
  for i := 1 to Length(s) do
  begin
    if s[i] in ['/', '\', ':', ' ', '.', '~'] then
      s[i] := '_';
  end;
  Result := s;
end;

procedure TConfigBackgroundService.EnsureCacheDir();
begin
  if not DirectoryExists(FCacheDir) then
    ForceDirectories(FCacheDir);
end;

function TConfigBackgroundService.IsImageFile(const APath: string): Boolean;
var
  ext: string;
begin
  ext := LowerCase(ExtractFileExt(APath));
  Result := (ext = '.jpg') or (ext = '.jpeg') or (ext = '.png') or (ext = '.webp') or (ext = '.svg');
end;

function TConfigBackgroundService.CleanWallpaperName(const AFileName: string): string;
var
  nameNoExt: string;
  i: Integer;
  capitalizeNext: Boolean;
begin
  nameNoExt := ChangeFileExt(AFileName, '');
  for i := 1 to Length(nameNoExt) do
  begin
    if nameNoExt[i] in ['_', '-'] then
      nameNoExt[i] := ' ';
  end;

  // Title case formatting
  capitalizeNext := True;
  for i := 1 to Length(nameNoExt) do
  begin
    if nameNoExt[i] = ' ' then
      capitalizeNext := True
    else if capitalizeNext and (nameNoExt[i] in ['a'..'z']) then
    begin
      nameNoExt[i] := UpCase(nameNoExt[i]);
      capitalizeNext := False;
    end
    else
      capitalizeNext := False;
  end;

  Result := Trim(nameNoExt);
  if Result = '' then
    Result := AFileName;
end;

procedure TConfigBackgroundService.ScanDirectory(const ADir: string; AIsCustom: Boolean);
var
  sr: TSearchRec;
  fullPath: string;
  k: Integer;
begin
  if not DirectoryExists(ADir) then Exit;

  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, sr) = 0 then
  begin
    try
      repeat
        if (sr.Name = '.') or (sr.Name = '..') then Continue;
        fullPath := IncludeTrailingPathDelimiter(ADir) + sr.Name;

        if (sr.Attr and faDirectory) <> 0 then
        begin
          // Recursively scan 1 level subdirectories (e.g. /usr/share/backgrounds/kirana/)
          ScanDirectory(fullPath, AIsCustom);
        end
        else if IsImageFile(sr.Name) then
        begin
          if FindWallpaperIndex(fullPath) < 0 then
          begin
            k := Length(FWallpapers);
            SetLength(FWallpapers, k + 1);
            FWallpapers[k].Path := fullPath;
            FWallpapers[k].Name := CleanWallpaperName(sr.Name);
            FWallpapers[k].IsCustom := AIsCustom;
          end;
        end;
      until FindNext(sr) <> 0;
    finally
      FindClose(sr);
    end;
  end;
end;

function TConfigBackgroundService.ScanWallpapers(): Integer;
var
  homeDir, userWallDir: string;
  currentWall: string;
  k, i: Integer;
begin
  SetLength(FWallpapers, 0);

  if FMockMode then
  begin
    SetLength(FWallpapers, 4);
    FWallpapers[0].Path := '/usr/share/backgrounds/samarinda.jpg';
    FWallpapers[0].Name := 'Samarinda';
    FWallpapers[0].IsCustom := False;

    FWallpapers[1].Path := '/usr/share/backgrounds/mountains.jpg';
    FWallpapers[1].Name := 'Mountains';
    FWallpapers[1].IsCustom := False;

    FWallpapers[2].Path := '/usr/share/backgrounds/sunset.jpg';
    FWallpapers[2].Name := 'Sunset';
    FWallpapers[2].IsCustom := False;

    FWallpapers[3].Path := '/usr/share/backgrounds/aurora.jpg';
    FWallpapers[3].Name := 'Aurora';
    FWallpapers[3].IsCustom := False;

    currentWall := GetWallpaperPath();
    if (currentWall <> '') and (FindWallpaperIndex(currentWall) < 0) then
    begin
      k := Length(FWallpapers);
      SetLength(FWallpapers, k + 1);
      for i := k downto 1 do
        FWallpapers[i] := FWallpapers[i - 1];
      FWallpapers[0].Path := currentWall;
      FWallpapers[0].Name := CleanWallpaperName(ExtractFileName(currentWall));
      FWallpapers[0].IsCustom := True;
    end;

    Exit(Length(FWallpapers));
  end;

  // 1. Scan system wallpapers
  ScanDirectory('/usr/share/backgrounds', False);

  // 2. Scan user wallpapers directory
  homeDir := GetEnvironmentVariable('HOME');
  if homeDir <> '' then
  begin
    userWallDir := IncludeTrailingPathDelimiter(homeDir) + 'Pictures/Wallpapers';
    ScanDirectory(userWallDir, True);
  end;

  // 3. Ensure current wallpaper is in the list
  currentWall := GetWallpaperPath();
  if (currentWall <> '') and FileExists(currentWall) and (FindWallpaperIndex(currentWall) < 0) then
  begin
    // Prepend as user custom wallpaper
    k := Length(FWallpapers);
    SetLength(FWallpapers, k + 1);
    for i := k downto 1 do
      FWallpapers[i] := FWallpapers[i - 1];
    FWallpapers[0].Path := currentWall;
    FWallpapers[0].Name := CleanWallpaperName(ExtractFileName(currentWall));
    FWallpapers[0].IsCustom := True;
  end;

  Result := Length(FWallpapers);
end;

function TConfigBackgroundService.GetWallpaperCount(): Integer;
begin
  Result := Length(FWallpapers);
end;

function TConfigBackgroundService.GetWallpaper(AIndex: Integer): TWallpaperItem;
begin
  if (AIndex >= 0) and (AIndex < Length(FWallpapers)) then
    Result := FWallpapers[AIndex]
  else
  begin
    Result.Path := '';
    Result.Name := '';
    Result.IsCustom := False;
  end;
end;

function TConfigBackgroundService.FindWallpaperIndex(const APath: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(FWallpapers) do
  begin
    if SameText(FWallpapers[i].Path, APath) then
      Exit(i);
  end;
end;

procedure TConfigBackgroundService.AddCustomWallpaper(const APath: string);
var
  idx, i, k: Integer;
begin
  if (APath = '') or (not FMockMode and not FileExists(APath)) then Exit;

  idx := FindWallpaperIndex(APath);
  if idx < 0 then
  begin
    // Prepend to list
    k := Length(FWallpapers);
    SetLength(FWallpapers, k + 1);
    for i := k downto 1 do
      FWallpapers[i] := FWallpapers[i - 1];
    FWallpapers[0].Path := APath;
    FWallpapers[0].Name := CleanWallpaperName(ExtractFileName(APath));
    FWallpapers[0].IsCustom := True;
  end;

  SetWallpaperPath(APath);
end;

function TConfigBackgroundService.GetWallpaperPath(): string;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockWallpaperPath);

  st := ConfigSettings();
  if st <> nil then
    Result := st.WallpaperPath
  else
    Result := FMockWallpaperPath;
end;

procedure TConfigBackgroundService.SetWallpaperPath(const APath: string);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockWallpaperPath := APath;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.WallpaperPath := APath;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigBackgroundService.GetWallpaperMode(): string;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockWallpaperMode);

  st := ConfigSettings();
  if st <> nil then
    Result := st.WallpaperMode
  else
    Result := FMockWallpaperMode;
end;

procedure TConfigBackgroundService.SetWallpaperMode(const AMode: string);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockWallpaperMode := AMode;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.WallpaperMode := AMode;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigBackgroundService.GetThumbnailPath(const APath: string): string;
begin
  EnsureCacheDir();
  Result := FCacheDir + SanitizePath(APath) + '.thumb.png';
end;

function TConfigBackgroundService.GetThumbnail(const APath: string; AWidth: Integer = 200; AHeight: Integer = 120): TFtBitmap;
var
  cachePath: string;
  sourceAge, cacheAge: LongInt;
  rawBmp, thumbBmp: TFtBitmap;
begin
  Result := nil;
  if (APath = '') or not FileExists(APath) then Exit;
  if not FtIsLibLoaded() then Exit;

  cachePath := GetThumbnailPath(APath);
  sourceAge := FileAge(APath);

  // Check if cache is valid and up to date
  if FileExists(cachePath) then
  begin
    cacheAge := FileAge(cachePath);
    if cacheAge >= sourceAge then
    begin
      try
        Result := TFtBitmap.CreateFromFile(cachePath);
        if (Result <> nil) and (Result.Handle <> nil) then Exit;
        if Result <> nil then
        begin
          Result.Free();
          Result := nil;
        end;
      except
        // Cache file invalid or corrupted, fallback to regeneration
      end;
    end;
  end;

  // Generate thumbnail
  try
    rawBmp := TFtBitmap.CreateFromFile(APath);
    if (rawBmp = nil) or (rawBmp.Handle = nil) then
    begin
      if rawBmp <> nil then
        rawBmp.Free();
      Exit(nil);
    end;
    try
      thumbBmp := rawBmp.CreateScaled(AWidth, AHeight);
      if thumbBmp <> nil then
      begin
        try
          thumbBmp.SaveToFile(cachePath);
        except
          // Disk write failed, still return the generated thumbnail
        end;
        Result := thumbBmp;
      end;
    finally
      rawBmp.Free();
    end;
  except
    Result := nil;
  end;
end;

finalization
  if GBackgroundServiceInstance <> nil then
  begin
    GBackgroundServiceInstance.Free();
    GBackgroundServiceInstance := nil;
  end;

end.

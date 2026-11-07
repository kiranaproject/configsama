// configsama.settings.pas — settings model and persistence for Samarinda Desktop
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

type
  { TConfigSettings — Samarinda desktop settings store }
  TConfigSettings = class
  private
    FIniPath: string;

    // Appearance
    FDarkMode: Boolean;
    FAccentColor: string;
    FWallpaperPath: string;
    FWallpaperMode: string;

    // Displays
    FResolution: string;
    FRefreshRate: Integer;
    FScale: Integer;
    FNightLight: Boolean;

    // Desktop & Dock
    FDockPosition: string;
    FDockIconSize: Integer;
    FDockAutoHide: Boolean;
    FDockMargin: Integer;
    FShowDesktopButton: Boolean;
    FClockFormat: string;

    // Sound
    FOutputVolume: Integer;
    FMuted: Boolean;
    FSoundEffects: Boolean;
    FOutputDevice: string;

    // Power
    FPowerMode: string;
    FScreenBlankDelay: Integer;
    FAutoSuspend: Boolean;
    FSuspendDelay: Integer;

    // Mouse & Touchpad
    FPointerSpeed: Integer;
    FNaturalScrolling: Boolean;
    FTapToClick: Boolean;
    FPrimaryButton: string;

    // Keyboard
    FKeyboardLayout: string;
    FKeyRepeatDelay: Integer;
    FKeyRepeatRate: Integer;
    FSuperKeyLauncher: Boolean;

    // Applications
    FDefaultBrowser: string;
    FDefaultFileManager: string;
    FDefaultTerminal: string;
    FDefaultTextEditor: string;

    function  GetConfigDir(): string;
  public
    constructor Create(const ACustomIniPath: string = '');
    destructor Destroy(); override;

    procedure SetDefaults();
    procedure Load();
    procedure Save();
    procedure SyncWallpaperToShell();

    // System Information Helpers
    function GetKernelVersion(): string;
    function GetCpuModel(): string;
    function GetMemoryTotal(): string;
    function GetOsName(): string;
    function GetOsVersion(): string;

    // Properties
    property IniPath: string read FIniPath;

    // Appearance
    property DarkMode: Boolean read FDarkMode write FDarkMode;
    property AccentColor: string read FAccentColor write FAccentColor;
    property WallpaperPath: string read FWallpaperPath write FWallpaperPath;
    property WallpaperMode: string read FWallpaperMode write FWallpaperMode;

    // Displays
    property Resolution: string read FResolution write FResolution;
    property RefreshRate: Integer read FRefreshRate write FRefreshRate;
    property Scale: Integer read FScale write FScale;
    property NightLight: Boolean read FNightLight write FNightLight;

    // Desktop & Dock
    property DockPosition: string read FDockPosition write FDockPosition;
    property DockIconSize: Integer read FDockIconSize write FDockIconSize;
    property DockAutoHide: Boolean read FDockAutoHide write FDockAutoHide;
    property DockMargin: Integer read FDockMargin write FDockMargin;
    property ShowDesktopButton: Boolean read FShowDesktopButton write FShowDesktopButton;
    property ClockFormat: string read FClockFormat write FClockFormat;

    // Sound
    property OutputVolume: Integer read FOutputVolume write FOutputVolume;
    property Muted: Boolean read FMuted write FMuted;
    property SoundEffects: Boolean read FSoundEffects write FSoundEffects;
    property OutputDevice: string read FOutputDevice write FOutputDevice;

    // Power
    property PowerMode: string read FPowerMode write FPowerMode;
    property ScreenBlankDelay: Integer read FScreenBlankDelay write FScreenBlankDelay;
    property AutoSuspend: Boolean read FAutoSuspend write FAutoSuspend;
    property SuspendDelay: Integer read FSuspendDelay write FSuspendDelay;

    // Mouse & Touchpad
    property PointerSpeed: Integer read FPointerSpeed write FPointerSpeed;
    property NaturalScrolling: Boolean read FNaturalScrolling write FNaturalScrolling;
    property TapToClick: Boolean read FTapToClick write FTapToClick;
    property PrimaryButton: string read FPrimaryButton write FPrimaryButton;

    // Keyboard
    property KeyboardLayout: string read FKeyboardLayout write FKeyboardLayout;
    property KeyRepeatDelay: Integer read FKeyRepeatDelay write FKeyRepeatDelay;
    property KeyRepeatRate: Integer read FKeyRepeatRate write FKeyRepeatRate;
    property SuperKeyLauncher: Boolean read FSuperKeyLauncher write FSuperKeyLauncher;

    // Applications
    property DefaultBrowser: string read FDefaultBrowser write FDefaultBrowser;
    property DefaultFileManager: string read FDefaultFileManager write FDefaultFileManager;
    property DefaultTerminal: string read FDefaultTerminal write FDefaultTerminal;
    property DefaultTextEditor: string read FDefaultTextEditor write FDefaultTextEditor;
  end;

implementation

{ TConfigSettings }

function TConfigSettings.GetConfigDir(): string;
var
  h: string;
begin
  h := GetEnvironmentVariable('HOME');
  if h = '' then h := '/tmp';
  Result := h + '/.config/samarinda';
end;

constructor TConfigSettings.Create(const ACustomIniPath: string = '');
var
  d: string;
begin
  inherited Create();
  if ACustomIniPath <> '' then
  begin
    FIniPath := ACustomIniPath;
    d := ExtractFilePath(FIniPath);
    if (d <> '') and not DirectoryExists(d) then
      ForceDirectories(d);
  end
  else
  begin
    d := GetConfigDir();
    if not DirectoryExists(d) then
      ForceDirectories(d);
    FIniPath := d + '/settings.ini';
  end;
  SetDefaults();
  Load();
end;

destructor TConfigSettings.Destroy();
begin
  inherited Destroy();
end;

procedure TConfigSettings.SetDefaults();
begin
  // Appearance defaults
  FDarkMode := False;
  FAccentColor := 'Blue';
  FWallpaperPath := '/usr/share/backgrounds/samarinda.jpg';
  FWallpaperMode := 'fill';

  // Displays defaults
  FResolution := '1920x1080';
  FRefreshRate := 60;
  FScale := 100;
  FNightLight := False;

  // Desktop defaults
  FDockPosition := 'Bottom';
  FDockIconSize := 48;
  FDockAutoHide := False;
  FDockMargin := 3;
  FShowDesktopButton := True;
  FClockFormat := '24h';

  // Sound defaults
  FOutputVolume := 75;
  FMuted := False;
  FSoundEffects := True;
  FOutputDevice := 'Default Audio Sink';

  // Power defaults
  FPowerMode := 'Balanced';
  FScreenBlankDelay := 10;
  FAutoSuspend := False;
  FSuspendDelay := 30;

  // Mouse defaults
  FPointerSpeed := 50;
  FNaturalScrolling := False;
  FTapToClick := True;
  FPrimaryButton := 'Left';

  // Keyboard defaults
  FKeyboardLayout := 'us';
  FKeyRepeatDelay := 500;
  FKeyRepeatRate := 30;
  FSuperKeyLauncher := True;

  // Applications defaults
  FDefaultBrowser := 'Default Web Browser';
  FDefaultFileManager := 'filesama';
  FDefaultTerminal := 'samarinda-terminal';
  FDefaultTextEditor := 'Default Text Editor';
end;

procedure TConfigSettings.Load();
var
  ini: TIniFile;
begin
  if not FileExists(FIniPath) then
  begin
    Save();
    Exit();
  end;

  ini := TIniFile.Create(FIniPath);
  try
    // Appearance
    FDarkMode := ini.ReadBool('Appearance', 'DarkMode', FDarkMode);
    FAccentColor := ini.ReadString('Appearance', 'AccentColor', FAccentColor);
    FWallpaperPath := ini.ReadString('Appearance', 'Wallpaper', FWallpaperPath);
    FWallpaperMode := ini.ReadString('Appearance', 'WallpaperMode', FWallpaperMode);

    // Displays
    FResolution := ini.ReadString('Displays', 'Resolution', FResolution);
    FRefreshRate := ini.ReadInteger('Displays', 'RefreshRate', FRefreshRate);
    FScale := ini.ReadInteger('Displays', 'Scale', FScale);
    FNightLight := ini.ReadBool('Displays', 'NightLight', FNightLight);

    // Desktop
    FDockPosition := ini.ReadString('Desktop', 'DockPosition', FDockPosition);
    FDockIconSize := ini.ReadInteger('Desktop', 'DockIconSize', FDockIconSize);
    FDockAutoHide := ini.ReadBool('Desktop', 'DockAutoHide', FDockAutoHide);
    FDockMargin := ini.ReadInteger('Desktop', 'DockMargin', FDockMargin);
    FShowDesktopButton := ini.ReadBool('Desktop', 'ShowDesktopButton', FShowDesktopButton);
    FClockFormat := ini.ReadString('Desktop', 'ClockFormat', FClockFormat);

    // Sound
    FOutputVolume := ini.ReadInteger('Sound', 'OutputVolume', FOutputVolume);
    FMuted := ini.ReadBool('Sound', 'Muted', FMuted);
    FSoundEffects := ini.ReadBool('Sound', 'SoundEffects', FSoundEffects);
    FOutputDevice := ini.ReadString('Sound', 'OutputDevice', FOutputDevice);

    // Power
    FPowerMode := ini.ReadString('Power', 'PowerMode', FPowerMode);
    FScreenBlankDelay := ini.ReadInteger('Power', 'ScreenBlankDelay', FScreenBlankDelay);
    FAutoSuspend := ini.ReadBool('Power', 'AutoSuspend', FAutoSuspend);
    FSuspendDelay := ini.ReadInteger('Power', 'SuspendDelay', FSuspendDelay);

    // Mouse
    FPointerSpeed := ini.ReadInteger('Mouse', 'PointerSpeed', FPointerSpeed);
    FNaturalScrolling := ini.ReadBool('Mouse', 'NaturalScrolling', FNaturalScrolling);
    FTapToClick := ini.ReadBool('Mouse', 'TapToClick', FTapToClick);
    FPrimaryButton := ini.ReadString('Mouse', 'PrimaryButton', FPrimaryButton);

    // Keyboard
    FKeyboardLayout := ini.ReadString('Keyboard', 'Layout', FKeyboardLayout);
    FKeyRepeatDelay := ini.ReadInteger('Keyboard', 'RepeatDelay', FKeyRepeatDelay);
    FKeyRepeatRate := ini.ReadInteger('Keyboard', 'RepeatRate', FKeyRepeatRate);
    FSuperKeyLauncher := ini.ReadBool('Keyboard', 'SuperKeyLauncher', FSuperKeyLauncher);

    // Applications
    FDefaultBrowser := ini.ReadString('Applications', 'Browser', FDefaultBrowser);
    FDefaultFileManager := ini.ReadString('Applications', 'FileManager', FDefaultFileManager);
    FDefaultTerminal := ini.ReadString('Applications', 'Terminal', FDefaultTerminal);
    FDefaultTextEditor := ini.ReadString('Applications', 'TextEditor', FDefaultTextEditor);
  finally
    ini.Free();
  end;
end;

procedure TConfigSettings.Save();
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(FIniPath);
  try
    // Appearance
    ini.WriteBool('Appearance', 'DarkMode', FDarkMode);
    ini.WriteString('Appearance', 'AccentColor', FAccentColor);
    ini.WriteString('Appearance', 'Wallpaper', FWallpaperPath);
    ini.WriteString('Appearance', 'WallpaperMode', FWallpaperMode);

    // Displays
    ini.WriteString('Displays', 'Resolution', FResolution);
    ini.WriteInteger('Displays', 'RefreshRate', FRefreshRate);
    ini.WriteInteger('Displays', 'Scale', FScale);
    ini.WriteBool('Displays', 'NightLight', FNightLight);

    // Desktop
    ini.WriteString('Desktop', 'DockPosition', FDockPosition);
    ini.WriteInteger('Desktop', 'DockIconSize', FDockIconSize);
    ini.WriteBool('Desktop', 'DockAutoHide', FDockAutoHide);
    ini.WriteInteger('Desktop', 'DockMargin', FDockMargin);
    ini.WriteBool('Desktop', 'ShowDesktopButton', FShowDesktopButton);
    ini.WriteString('Desktop', 'ClockFormat', FClockFormat);

    // Sound
    ini.WriteInteger('Sound', 'OutputVolume', FOutputVolume);
    ini.WriteBool('Sound', 'Muted', FMuted);
    ini.WriteBool('Sound', 'SoundEffects', FSoundEffects);
    ini.WriteString('Sound', 'OutputDevice', FOutputDevice);

    // Power
    ini.WriteString('Power', 'PowerMode', FPowerMode);
    ini.WriteInteger('Power', 'ScreenBlankDelay', FScreenBlankDelay);
    ini.WriteBool('Power', 'AutoSuspend', FAutoSuspend);
    ini.WriteInteger('Power', 'SuspendDelay', FSuspendDelay);

    // Mouse
    ini.WriteInteger('Mouse', 'PointerSpeed', FPointerSpeed);
    ini.WriteBool('Mouse', 'NaturalScrolling', FNaturalScrolling);
    ini.WriteBool('Mouse', 'TapToClick', FTapToClick);
    ini.WriteString('Mouse', 'PrimaryButton', FPrimaryButton);

    // Keyboard
    ini.WriteString('Keyboard', 'Layout', FKeyboardLayout);
    ini.WriteInteger('Keyboard', 'RepeatDelay', FKeyRepeatDelay);
    ini.WriteInteger('Keyboard', 'RepeatRate', FKeyRepeatRate);
    ini.WriteBool('Keyboard', 'SuperKeyLauncher', FSuperKeyLauncher);

    // Applications
    ini.WriteString('Applications', 'Browser', FDefaultBrowser);
    ini.WriteString('Applications', 'FileManager', FDefaultFileManager);
    ini.WriteString('Applications', 'Terminal', FDefaultTerminal);
    ini.WriteString('Applications', 'TextEditor', FDefaultTextEditor);
  finally
    ini.Free();
  end;

  SyncWallpaperToShell();
end;

procedure TConfigSettings.SyncWallpaperToShell();
var
  shellConfDir, shellConfFile: string;
  lines: TStringList;
begin
  shellConfDir := GetEnvironmentVariable('HOME') + '/.config/shellsama';
  if not DirectoryExists(shellConfDir) then
    ForceDirectories(shellConfDir);
  shellConfFile := shellConfDir + '/desktop.conf';

  lines := TStringList.Create();
  try
    lines.Add('# shellsama desktop wallpaper configuration');
    lines.Add('wallpaper=' + FWallpaperPath);
    lines.Add('mode=' + LowerCase(FWallpaperMode));
    lines.SaveToFile(shellConfFile);
  except
    // Non-fatal if shellsama directory is write protected
  end;
  lines.Free();
end;

function TConfigSettings.GetKernelVersion(): string;
var
  lines: TStringList;
  procVer: string;
begin
  Result := 'Linux';
  if FileExists('/proc/version') then
  begin
    lines := TStringList.Create();
    try
      lines.LoadFromFile('/proc/version');
      if lines.Count > 0 then
      begin
        procVer := lines[0];
        // e.g. "Linux version 6.6.137 ... "
        if Pos('Linux version ', procVer) = 1 then
        begin
          Delete(procVer, 1, Length('Linux version '));
          if Pos(' ', procVer) > 0 then
            Result := 'Linux ' + Copy(procVer, 1, Pos(' ', procVer) - 1)
          else
            Result := 'Linux ' + procVer;
        end;
      end;
    finally
      lines.Free();
    end;
  end;
end;

function TConfigSettings.GetCpuModel(): string;
var
  lines: TStringList;
  i, p: Integer;
  line: string;
begin
  Result := 'Generic x86_64 Processor';
  if FileExists('/proc/cpuinfo') then
  begin
    lines := TStringList.Create();
    try
      lines.LoadFromFile('/proc/cpuinfo');
      for i := 0 to lines.Count - 1 do
      begin
        line := lines[i];
        if (Pos('model name', LowerCase(line)) = 1) then
        begin
          p := Pos(':', line);
          if p > 0 then
          begin
            Result := Trim(Copy(line, p + 1, Length(line)));
            Break;
          end;
        end;
      end;
    finally
      lines.Free();
    end;
  end;
end;

function TConfigSettings.GetMemoryTotal(): string;
var
  lines: TStringList;
  i, p, kbVal: Integer;
  line, numStr: string;
  gbVal: Double;
begin
  Result := '8.0 GiB';
  if FileExists('/proc/meminfo') then
  begin
    lines := TStringList.Create();
    try
      lines.LoadFromFile('/proc/meminfo');
      for i := 0 to lines.Count - 1 do
      begin
        line := lines[i];
        if Pos('MemTotal:', line) = 1 then
        begin
          p := Pos(':', line);
          numStr := Trim(Copy(line, p + 1, Length(line)));
          p := Pos(' ', numStr);
          if p > 0 then
            numStr := Copy(numStr, 1, p - 1);
          kbVal := StrToIntDef(numStr, 0);
          if kbVal > 0 then
          begin
            gbVal := kbVal / (1024.0 * 1024.0);
            Result := Format('%.1f GiB', [gbVal]);
            Break;
          end;
        end;
      end;
    finally
      lines.Free();
    end;
  end;
end;

function TConfigSettings.GetOsName(): string;
begin
  Result := 'Samarinda OS';
end;

function TConfigSettings.GetOsVersion(): string;
begin
  Result := '1.0 "Kutai"';
end;

end.

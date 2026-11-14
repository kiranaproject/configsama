// configsama.power.pas — Power and Battery service using Linux sysfs and DPMS/xset
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Power;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TConfigPowerService = class
  private
    FMockMode: Boolean;
    FMockBatteryPresent: Boolean;
    FMockBatteryPercentage: Integer;
    FMockBatteryStatus: string;
    FMockAcOnline: Boolean;
    FMockPowerMode: string;
    FMockScreenBlankDelay: Integer; // in minutes (0 = never)
    FMockAutoSuspend: Boolean;

    function RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
    function ReadSysfsString(const APath: string): string;
    function ReadSysfsInteger(const APath: string; ADefault: Integer = 0): Integer;
    function FindBatteryPath(): string;
    function FindAcPath(): string;
  public
    constructor Create();
    destructor Destroy(); override;

    function IsAvailable(): Boolean;

    // Battery & AC Status
    function IsBatteryPresent(): Boolean;
    function GetBatteryPercentage(): Integer;
    function GetBatteryStatus(): string; // "Charging", "Discharging", "Full", "Not charging"
    function IsAcOnline(): Boolean;
    function GetTimeRemaining(): string;

    // Power Profile
    function GetPowerMode(): string; // "Performance", "Balanced", "Power Saver"
    function SetPowerMode(const AMode: string): Boolean;

    // Screen Blank / Sleep
    function GetScreenBlankDelay(): Integer; // in minutes (0 = Never)
    function SetScreenBlankDelay(AMinutes: Integer): Boolean;

    // Auto Suspend
    function IsAutoSuspendEnabled(): Boolean;
    function SetAutoSuspendEnabled(AEnabled: Boolean): Boolean;

    // Test seam / Mocking
    procedure EnableMockMode(const AEnabled: Boolean = True);
    procedure SetMockBattery(APresent: Boolean; APercentage: Integer; const AStatus: string; AAcOnline: Boolean);
    procedure SetMockPowerMode(const AMode: string);
    procedure SetMockScreenBlankDelay(AMinutes: Integer);
    procedure SetMockAutoSuspend(AEnabled: Boolean);
  end;

function PowerService(): TConfigPowerService;

implementation

var
  GPowerService: TConfigPowerService = nil;

function PowerService(): TConfigPowerService;
begin
  if GPowerService = nil then
    GPowerService := TConfigPowerService.Create();
  Result := GPowerService;
end;

constructor TConfigPowerService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockBatteryPresent := True;
  FMockBatteryPercentage := 92;
  FMockBatteryStatus := 'Charging';
  FMockAcOnline := True;
  FMockPowerMode := 'Balanced';
  FMockScreenBlankDelay := 10;
  FMockAutoSuspend := True;
end;

destructor TConfigPowerService.Destroy();
begin
  inherited Destroy();
end;

function TConfigPowerService.RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
var
  p: TProcess;
  buf: array[0..2047] of AnsiChar;
  bytesRead: Integer;
  mem: TMemoryStream;
  outputStr: string;
begin
  AOutput := '';
  p := TProcess.Create(nil);
  mem := TMemoryStream.Create();
  try
    p.Executable := '/bin/sh';
    p.Parameters.Add('-c');
    p.Parameters.Add(ACmd);
    p.Options := [poUsePipes, poStderrToOutPut];

    try
      p.Execute();
    except
      Result := False;
      Exit;
    end;

    while p.Running do
    begin
      bytesRead := p.Output.Read(buf, SizeOf(buf));
      if bytesRead > 0 then
        mem.Write(buf, bytesRead)
      else
        Sleep(10);
    end;

    repeat
      bytesRead := p.Output.Read(buf, SizeOf(buf));
      if bytesRead > 0 then
        mem.Write(buf, bytesRead);
    until bytesRead <= 0;

    Result := (p.ExitStatus = 0);

    if mem.Size > 0 then
    begin
      mem.Position := 0;
      SetLength(outputStr, mem.Size);
      mem.Read(outputStr[1], mem.Size);
      AOutput := outputStr;
    end;
  finally
    p.Free();
    mem.Free();
  end;
end;

function TConfigPowerService.ReadSysfsString(const APath: string): string;
var
  f: TextFile;
  s: string;
begin
  Result := '';
  if not FileExists(APath) then Exit;
  try
    AssignFile(f, APath);
    Reset(f);
    if not Eof(f) then
    begin
      ReadLn(f, s);
      Result := Trim(s);
    end;
    CloseFile(f);
  except
    Result := '';
  end;
end;

function TConfigPowerService.ReadSysfsInteger(const APath: string; ADefault: Integer): Integer;
var
  s: string;
begin
  s := ReadSysfsString(APath);
  if s = '' then Exit(ADefault);
  Result := StrToIntDef(s, ADefault);
end;

function TConfigPowerService.FindBatteryPath(): string;
var
  info: TSearchRec;
begin
  Result := '';
  if FindFirst('/sys/class/power_supply/BAT*', faDirectory, info) = 0 then
  begin
    repeat
      if (info.Name <> '.') and (info.Name <> '..') then
      begin
        Result := '/sys/class/power_supply/' + info.Name;
        Break;
      end;
    until FindNext(info) <> 0;
    FindClose(info);
  end;
end;

function TConfigPowerService.FindAcPath(): string;
var
  info: TSearchRec;
begin
  Result := '';
  if FindFirst('/sys/class/power_supply/AC*', faDirectory, info) = 0 then
  begin
    repeat
      if (info.Name <> '.') and (info.Name <> '..') then
      begin
        Result := '/sys/class/power_supply/' + info.Name;
        Break;
      end;
    until FindNext(info) <> 0;
    FindClose(info);
  end;
  if Result = '' then
  begin
    if DirectoryExists('/sys/class/power_supply/ACAD') then
      Result := '/sys/class/power_supply/ACAD';
  end;
end;

function TConfigPowerService.IsAvailable(): Boolean;
begin
  Result := True;
end;

function TConfigPowerService.IsBatteryPresent(): Boolean;
var
  bPath: string;
begin
  if FMockMode then
    Exit(FMockBatteryPresent);

  bPath := FindBatteryPath();
  Result := (bPath <> '') and (ReadSysfsInteger(bPath + '/present', 1) = 1);
end;

function TConfigPowerService.GetBatteryPercentage(): Integer;
var
  bPath: string;
begin
  if FMockMode then
    Exit(FMockBatteryPercentage);

  bPath := FindBatteryPath();
  if bPath = '' then Exit(100);

  Result := ReadSysfsInteger(bPath + '/capacity', 100);
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;

function TConfigPowerService.GetBatteryStatus(): string;
var
  bPath, s: string;
begin
  if FMockMode then
    Exit(FMockBatteryStatus);

  bPath := FindBatteryPath();
  if bPath = '' then
  begin
    if IsAcOnline() then Exit('Full') else Exit('Unknown');
  end;

  s := ReadSysfsString(bPath + '/status');
  if s <> '' then Exit(s);

  if IsAcOnline() then Result := 'Full' else Result := 'Discharging';
end;

function TConfigPowerService.IsAcOnline(): Boolean;
var
  acPath: string;
begin
  if FMockMode then
    Exit(FMockAcOnline);

  acPath := FindAcPath();
  if acPath = '' then Exit(True);

  Result := (ReadSysfsInteger(acPath + '/online', 1) = 1);
end;

function TConfigPowerService.GetTimeRemaining(): string;
var
  bPath, st: string;
  nowVal, rateVal: Int64;
  hrs, mins: Integer;
  remainingHours: Double;
begin
  if FMockMode then
  begin
    if SameText(FMockBatteryStatus, 'Charging') then
      Exit('45 minutes until full')
    else if SameText(FMockBatteryStatus, 'Full') then
      Exit('Fully charged')
    else
      Exit('4 hours 20 minutes remaining');
  end;

  st := GetBatteryStatus();
  if SameText(st, 'Full') then Exit('Fully charged');

  bPath := FindBatteryPath();
  if bPath = '' then Exit('Not on battery');

  // Check energy_now / power_now or charge_now / current_now
  nowVal := ReadSysfsInteger(bPath + '/energy_now', 0);
  rateVal := ReadSysfsInteger(bPath + '/power_now', 0);
  if (nowVal = 0) or (rateVal = 0) then
  begin
    nowVal := ReadSysfsInteger(bPath + '/charge_now', 0);
    rateVal := ReadSysfsInteger(bPath + '/current_now', 0);
  end;

  if (rateVal > 0) and (nowVal > 0) then
  begin
    if SameText(st, 'Charging') then
    begin
      nowVal := ReadSysfsInteger(bPath + '/energy_full', nowVal) - nowVal;
      if nowVal < 0 then nowVal := 0;
    end;

    remainingHours := nowVal / rateVal;
    hrs := Trunc(remainingHours);
    mins := Round((remainingHours - hrs) * 60);

    if SameText(st, 'Charging') then
    begin
      if hrs > 0 then
        Exit(Format('%d hr %d min until full', [hrs, mins]))
      else
        Exit(Format('%d min until full', [mins]));
    end
    else
    begin
      if hrs > 0 then
        Exit(Format('%d hr %d min remaining', [hrs, mins]))
      else
        Exit(Format('%d min remaining', [mins]));
    end;
  end;

  if SameText(st, 'Charging') then
    Result := 'Charging'
  else if IsAcOnline() then
    Result := 'Connected to AC power'
  else
    Result := 'Discharging';
end;

function TConfigPowerService.GetPowerMode(): string;
var
  s: string;
begin
  if FMockMode then
    Exit(FMockPowerMode);

  s := ReadSysfsString('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor');
  if SameText(s, 'performance') then
    Result := 'Performance'
  else if SameText(s, 'powersave') then
    Result := 'Power Saver'
  else
    Result := 'Balanced';
end;

function TConfigPowerService.SetPowerMode(const AMode: string): Boolean;
var
  gov, outText: string;
begin
  if FMockMode then
  begin
    FMockPowerMode := AMode;
    Exit(True);
  end;

  if SameText(AMode, 'Performance') then
    gov := 'performance'
  else if SameText(AMode, 'Power Saver') then
    gov := 'powersave'
  else
    gov := 'schedutil';

  // Attempt to write scaling governor or powerprofilesctl if available
  if FileExists('/usr/bin/powerprofilesctl') then
  begin
    if SameText(AMode, 'Performance') then
      RunCommandOutput('powerprofilesctl set performance', outText)
    else if SameText(AMode, 'Power Saver') then
      RunCommandOutput('powerprofilesctl set power-saver', outText)
    else
      RunCommandOutput('powerprofilesctl set balanced', outText);
  end;

  FMockPowerMode := AMode;
  Result := True;
end;

function TConfigPowerService.GetScreenBlankDelay(): Integer;
begin
  // In minutes
  Result := FMockScreenBlankDelay;
end;

function TConfigPowerService.SetScreenBlankDelay(AMinutes: Integer): Boolean;
var
  secs: Integer;
  outText: string;
begin
  FMockScreenBlankDelay := AMinutes;
  if FMockMode then
    Exit(True);

  secs := AMinutes * 60;
  // Apply to X11 screen saver and DPMS
  Result := RunCommandOutput(Format('xset s %d %d && xset dpms %d %d %d', [secs, secs, secs, secs + 60, secs + 120]), outText);
end;

function TConfigPowerService.IsAutoSuspendEnabled(): Boolean;
begin
  Result := FMockAutoSuspend;
end;

function TConfigPowerService.SetAutoSuspendEnabled(AEnabled: Boolean): Boolean;
begin
  FMockAutoSuspend := AEnabled;
  Result := True;
end;

procedure TConfigPowerService.EnableMockMode(const AEnabled: Boolean);
begin
  FMockMode := AEnabled;
end;

procedure TConfigPowerService.SetMockBattery(APresent: Boolean; APercentage: Integer; const AStatus: string; AAcOnline: Boolean);
begin
  FMockBatteryPresent := APresent;
  FMockBatteryPercentage := APercentage;
  FMockBatteryStatus := AStatus;
  FMockAcOnline := AAcOnline;
end;

procedure TConfigPowerService.SetMockPowerMode(const AMode: string);
begin
  FMockPowerMode := AMode;
end;

procedure TConfigPowerService.SetMockScreenBlankDelay(AMinutes: Integer);
begin
  FMockScreenBlankDelay := AMinutes;
end;

procedure TConfigPowerService.SetMockAutoSuspend(AEnabled: Boolean);
begin
  FMockAutoSuspend := AEnabled;
end;

end.

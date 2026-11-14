// configsama.wired.pas — Ethernet / Wired network service using NetworkManager (nmcli)
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Wired;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TWiredInterface = record
    Device: string;          // e.g. "enp2s0", "eth0"
    State: string;           // "connected", "unavailable", "disconnected", "connecting", etc.
    ConnectionName: string;  // e.g. "Wired connection 1"
    HwAddr: string;          // MAC address e.g. "A8:1E:84:E5:3C:B2"
    IpAddress: string;       // e.g. "192.168.1.100/24"
    Gateway: string;         // e.g. "192.168.1.1"
    Dns: string;             // e.g. "192.168.1.1, 1.1.1.1"
    Speed: Integer;          // Speed in Mb/s (e.g. 1000, 100, 0)
    Duplex: string;          // "full", "half", "unknown"
    Carrier: Boolean;        // Cable plugged in?
    Mtu: Integer;            // e.g. 1500
    IsConnected: Boolean;
  end;
  TWiredInterfaceArray = array of TWiredInterface;

  TConfigWiredService = class
  private
    FMockMode: Boolean;
    FMockEnabled: Boolean;
    FWiredEnabled: Boolean;
    FMockInterfaces: TWiredInterfaceArray;

    function RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
    function SplitNmcliLine(const ALine: string): TStringList;
    function ReadSysfsString(const APath: string): string;
    function ReadSysfsInteger(const APath: string; ADefault: Integer = 0): Integer;
    function QueryDeviceDetails(const ADevice: string; out ADetails: TWiredInterface): Boolean;
  public
    constructor Create();
    destructor Destroy(); override;

    function IsAvailable(): Boolean;
    function IsWiredEnabled(): Boolean;
    function SetWiredEnabled(AEnable: Boolean): Boolean;

    function GetInterfaces(): TWiredInterfaceArray;
    function GetPrimaryInterface(): TWiredInterface;

    function Connect(const ADevice: string = ''): Boolean;
    function Disconnect(const ADevice: string = ''): Boolean;

    // Test seam / Mocking
    procedure EnableMockMode(const AEnabled: Boolean = True);
    procedure SetMockEnabled(AValue: Boolean);
    procedure SetMockInterfaces(const AInterfaces: TWiredInterfaceArray);
  end;

function WiredService(): TConfigWiredService;

implementation

var
  GWiredService: TConfigWiredService = nil;

function WiredService(): TConfigWiredService;
begin
  if GWiredService = nil then
    GWiredService := TConfigWiredService.Create();
  Result := GWiredService;
end;

constructor TConfigWiredService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockEnabled := True;
  FWiredEnabled := True;
  SetLength(FMockInterfaces, 0);
end;

destructor TConfigWiredService.Destroy();
begin
  SetLength(FMockInterfaces, 0);
  inherited Destroy();
end;

function TConfigWiredService.RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
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
    p.ShowWindow := swoNone;
    p.Execute();

    while p.Running or (p.Output.NumBytesAvailable > 0) do
    begin
      if p.Output.NumBytesAvailable > 0 then
      begin
        bytesRead := p.Output.Read(buf[0], SizeOf(buf));
        if bytesRead > 0 then
          mem.Write(buf[0], bytesRead);
      end
      else
        Sleep(10);
    end;

    p.WaitOnExit();
    Result := (p.ExitStatus = 0);

    if mem.Size > 0 then
    begin
      mem.Position := 0;
      SetLength(outputStr, mem.Size);
      mem.Read(outputStr[1], mem.Size);
      AOutput := Trim(outputStr);
    end;
  except
    on E: Exception do
    begin
      AOutput := '';
      Result := False;
    end;
  end;
  mem.Free();
  p.Free();
end;

function TConfigWiredService.SplitNmcliLine(const ALine: string): TStringList;
var
  i: Integer;
  curr: string;
  escaped: Boolean;
  ch: Char;
begin
  Result := TStringList.Create();
  curr := '';
  escaped := False;
  for i := 1 to Length(ALine) do
  begin
    ch := ALine[i];
    if escaped then
    begin
      curr := curr + ch;
      escaped := False;
    end
    else if ch = '\' then
      escaped := True
    else if ch = ':' then
    begin
      Result.Add(curr);
      curr := '';
    end
    else
      curr := curr + ch;
  end;
  Result.Add(curr);
end;

function TConfigWiredService.ReadSysfsString(const APath: string): string;
var
  sl: TStringList;
begin
  Result := '';
  if not FileExists(APath) then Exit();
  sl := TStringList.Create();
  try
    sl.LoadFromFile(APath);
    if sl.Count > 0 then
      Result := Trim(sl[0]);
  except
    Result := '';
  end;
  sl.Free();
end;

function TConfigWiredService.ReadSysfsInteger(const APath: string; ADefault: Integer = 0): Integer;
var
  s: string;
begin
  s := ReadSysfsString(APath);
  if s <> '' then
    Result := StrToIntDef(s, ADefault)
  else
    Result := ADefault;
end;

function TConfigWiredService.QueryDeviceDetails(const ADevice: string; out ADetails: TWiredInterface): Boolean;
var
  raw, key, val, sysPath: string;
  lines: TStringList;
  i, p: Integer;
begin
  Result := True;
  FillChar(ADetails, SizeOf(ADetails), 0);
  ADetails.Device := ADevice;
  ADetails.Mtu := 1500;
  ADetails.Duplex := 'unknown';

  sysPath := '/sys/class/net/' + ADevice;
  if DirectoryExists(sysPath) then
  begin
    ADetails.Carrier := (ReadSysfsInteger(sysPath + '/carrier', 0) = 1);
    ADetails.Speed := ReadSysfsInteger(sysPath + '/speed', 0);
    ADetails.Duplex := ReadSysfsString(sysPath + '/duplex');
    if ADetails.Duplex = '' then
      ADetails.Duplex := 'unknown';
  end;

  if RunCommandOutput('nmcli -t -f GENERAL.HWADDR,GENERAL.MTU,GENERAL.STATE,GENERAL.CONNECTION,WIRED-PROPERTIES.CARRIER,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show ' + ADevice + ' 2>/dev/null', raw) then
  begin
    lines := TStringList.Create();
    try
      lines.Text := raw;
      for i := 0 to lines.Count - 1 do
      begin
        p := Pos(':', lines[i]);
        if p > 0 then
        begin
          key := Copy(lines[i], 1, p - 1);
          val := Trim(Copy(lines[i], p + 1, Length(lines[i])));
          if key = 'GENERAL.HWADDR' then
            ADetails.HwAddr := val
          else if key = 'GENERAL.MTU' then
            ADetails.Mtu := StrToIntDef(val, 1500)
          else if key = 'GENERAL.STATE' then
            ADetails.State := val
          else if key = 'GENERAL.CONNECTION' then
          begin
            if (val <> '--') and (val <> '') then
              ADetails.ConnectionName := val;
          end
          else if key = 'WIRED-PROPERTIES.CARRIER' then
          begin
            if val = 'on' then
              ADetails.Carrier := True
            else if val = 'off' then
              ADetails.Carrier := False;
          end
          else if (Pos('IP4.ADDRESS', key) = 1) and (ADetails.IpAddress = '') then
            ADetails.IpAddress := val
          else if (key = 'IP4.GATEWAY') and (ADetails.Gateway = '') then
            ADetails.Gateway := val
          else if (Pos('IP4.DNS', key) = 1) then
          begin
            if ADetails.Dns = '' then
              ADetails.Dns := val
            else if Pos(val, ADetails.Dns) = 0 then
              ADetails.Dns := ADetails.Dns + ', ' + val;
          end;
        end;
      end;
    finally
      lines.Free();
    end;
  end;

  if (Pos('connected', LowerCase(ADetails.State)) = 1) or (Pos('(connected)', LowerCase(ADetails.State)) > 0) then
    ADetails.IsConnected := True;
end;

function TConfigWiredService.IsAvailable(): Boolean;
var
  raw: string;
begin
  if FMockMode then Exit(True);
  Result := RunCommandOutput('nmcli -v 2>/dev/null', raw);
end;

function TConfigWiredService.IsWiredEnabled(): Boolean;
var
  list: TWiredInterfaceArray;
  i: Integer;
begin
  if FMockMode then Exit(FMockEnabled);
  if not FWiredEnabled then Exit(False);

  list := GetInterfaces();
  if Length(list) = 0 then Exit(False);

  for i := 0 to High(list) do
  begin
    // If any device is connected, connecting, or available/disconnected (managed)
    if (list[i].State <> '') and (Pos('unmanaged', LowerCase(list[i].State)) = 0) then
      Exit(True);
  end;
  Result := False;
end;

function TConfigWiredService.SetWiredEnabled(AEnable: Boolean): Boolean;
var
  primary: TWiredInterface;
begin
  if FMockMode then
  begin
    FMockEnabled := AEnable;
    if Length(FMockInterfaces) > 0 then
    begin
      FMockInterfaces[0].IsConnected := AEnable;
      if AEnable then
        FMockInterfaces[0].State := '100 (connected)'
      else
        FMockInterfaces[0].State := '30 (disconnected)';
    end;
    Exit(True);
  end;

  FWiredEnabled := AEnable;
  primary := GetPrimaryInterface();
  if primary.Device = '' then Exit(True);

  if AEnable then
    Connect(primary.Device)
  else
    Disconnect(primary.Device);
  Result := True;
end;

function TConfigWiredService.GetInterfaces(): TWiredInterfaceArray;
var
  raw: string;
  lines, parts: TStringList;
  i, count: Integer;
  item: TWiredInterface;
begin
  if FMockMode then
  begin
    Result := Copy(FMockInterfaces);
    Exit();
  end;

  SetLength(Result, 0);
  if not RunCommandOutput('nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null', raw) then
    Exit();

  lines := TStringList.Create();
  try
    lines.Text := raw;
    count := 0;
    for i := 0 to lines.Count - 1 do
    begin
      parts := SplitNmcliLine(lines[i]);
      try
        if (parts.Count >= 2) and (LowerCase(parts[1]) = 'ethernet') then
        begin
          FillChar(item, SizeOf(item), 0);
          item.Device := parts[0];
          if parts.Count >= 3 then item.State := parts[2];
          if parts.Count >= 4 then item.ConnectionName := parts[3];

          QueryDeviceDetails(item.Device, item);

          Inc(count);
          SetLength(Result, count);
          Result[count - 1] := item;
        end;
      finally
        parts.Free();
      end;
    end;
  finally
    lines.Free();
  end;
end;

function TConfigWiredService.GetPrimaryInterface(): TWiredInterface;
var
  list: TWiredInterfaceArray;
  i: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  list := GetInterfaces();
  if Length(list) = 0 then Exit();

  // Return connected interface first
  for i := 0 to High(list) do
  begin
    if list[i].IsConnected then
    begin
      Result := list[i];
      Exit();
    end;
  end;

  // Return interface with carrier (cable plugged)
  for i := 0 to High(list) do
  begin
    if list[i].Carrier then
    begin
      Result := list[i];
      Exit();
    end;
  end;

  // Otherwise return first interface
  Result := list[0];
end;

function TConfigWiredService.Connect(const ADevice: string = ''): Boolean;
var
  targetDev, cmd, raw: string;
  primary: TWiredInterface;
begin
  if FMockMode then
  begin
    FMockEnabled := True;
    if Length(FMockInterfaces) > 0 then
    begin
      FMockInterfaces[0].IsConnected := True;
      FMockInterfaces[0].State := '100 (connected)';
      FMockInterfaces[0].Carrier := True;
      if FMockInterfaces[0].Speed = 0 then FMockInterfaces[0].Speed := 1000;
      if FMockInterfaces[0].Duplex = '' then FMockInterfaces[0].Duplex := 'full';
    end;
    Exit(True);
  end;

  targetDev := ADevice;
  if targetDev = '' then
  begin
    primary := GetPrimaryInterface();
    targetDev := primary.Device;
  end;
  if targetDev = '' then Exit(False);

  cmd := 'nmcli device connect ' + targetDev + ' 2>/dev/null';
  Result := RunCommandOutput(cmd, raw);
end;

function TConfigWiredService.Disconnect(const ADevice: string = ''): Boolean;
var
  targetDev, cmd, raw: string;
  primary: TWiredInterface;
begin
  if FMockMode then
  begin
    if Length(FMockInterfaces) > 0 then
    begin
      FMockInterfaces[0].IsConnected := False;
      FMockInterfaces[0].State := '30 (disconnected)';
    end;
    Exit(True);
  end;

  targetDev := ADevice;
  if targetDev = '' then
  begin
    primary := GetPrimaryInterface();
    targetDev := primary.Device;
  end;
  if targetDev = '' then Exit(False);

  cmd := 'nmcli device disconnect ' + targetDev + ' 2>/dev/null';
  Result := RunCommandOutput(cmd, raw);
end;

procedure TConfigWiredService.EnableMockMode(const AEnabled: Boolean = True);
begin
  FMockMode := AEnabled;
end;

procedure TConfigWiredService.SetMockEnabled(AValue: Boolean);
begin
  FMockEnabled := AValue;
end;

procedure TConfigWiredService.SetMockInterfaces(const AInterfaces: TWiredInterfaceArray);
begin
  FMockInterfaces := Copy(AInterfaces);
end;

finalization
  if GWiredService <> nil then
  begin
    GWiredService.Free();
    GWiredService := nil;
  end;

end.

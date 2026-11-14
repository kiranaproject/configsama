// configsama.bluetooth.pas — Bluetooth service using BlueZ (bluetoothctl)
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Bluetooth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TBluetoothDevice = record
    Address: string;      // e.g. "B6:11:03:4B:4E:19"
    Name: string;         // e.g. "AZ09 Wireless Earphones"
    Icon: string;         // e.g. "audio-headset", "input-keyboard", "input-mouse", "phone", "generic"
    Paired: Boolean;
    Connected: Boolean;
    Trusted: Boolean;
    Battery: Integer;     // -1 if unknown, 0..100 if reported
  end;
  TBluetoothDeviceArray = array of TBluetoothDevice;

  TConfigBluetoothService = class
  private
    FMockMode: Boolean;
    FMockEnabled: Boolean;
    FBluetoothEnabled: Boolean;
    FMockDevices: TBluetoothDeviceArray;

    function RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
    function ParseDeviceInfo(const AAddress: string; out ADevice: TBluetoothDevice): Boolean;
    procedure InitDefaultMockDevices();
  public
    constructor Create();
    destructor Destroy(); override;

    function IsAvailable(): Boolean;
    function IsBluetoothEnabled(): Boolean;
    function SetBluetoothEnabled(AEnable: Boolean): Boolean;

    function IsScanning(): Boolean;
    function StartScan(): Boolean;
    function StopScan(): Boolean;

    function GetDevices(): TBluetoothDeviceArray;
    function GetDevice(const AAddress: string; out ADevice: TBluetoothDevice): Boolean;

    function Connect(const AAddress: string): Boolean;
    function Disconnect(const AAddress: string): Boolean;
    function Pair(const AAddress: string): Boolean;
    function RemoveDevice(const AAddress: string): Boolean;

    // Test seam / Mocking
    procedure EnableMockMode(const AEnabled: Boolean = True);
    procedure SetMockEnabled(AValue: Boolean);
    procedure SetMockDevices(const ADevices: TBluetoothDeviceArray);
  end;

function BluetoothService(): TConfigBluetoothService;

implementation

var
  GBluetoothService: TConfigBluetoothService = nil;

function BluetoothService(): TConfigBluetoothService;
begin
  if GBluetoothService = nil then
    GBluetoothService := TConfigBluetoothService.Create();
  Result := GBluetoothService;
end;

constructor TConfigBluetoothService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockEnabled := True;
  FBluetoothEnabled := True;
  SetLength(FMockDevices, 0);
  InitDefaultMockDevices();
end;

destructor TConfigBluetoothService.Destroy();
begin
  SetLength(FMockDevices, 0);
  inherited Destroy();
end;

procedure TConfigBluetoothService.InitDefaultMockDevices();
begin
  SetLength(FMockDevices, 3);

  FMockDevices[0].Address := 'B6:11:03:4B:4E:19';
  FMockDevices[0].Name := 'AZ09 Wireless Earphones';
  FMockDevices[0].Icon := 'audio-headset';
  FMockDevices[0].Paired := True;
  FMockDevices[0].Connected := True;
  FMockDevices[0].Trusted := True;
  FMockDevices[0].Battery := 85;

  FMockDevices[1].Address := 'FC:58:FA:72:01:A2';
  FMockDevices[1].Name := 'Logitech MX Master 3S';
  FMockDevices[1].Icon := 'input-mouse';
  FMockDevices[1].Paired := True;
  FMockDevices[1].Connected := False;
  FMockDevices[1].Trusted := True;
  FMockDevices[1].Battery := 90;

  FMockDevices[2].Address := 'D0:C5:D3:88:14:6B';
  FMockDevices[2].Name := 'Keychron K2 Pro';
  FMockDevices[2].Icon := 'input-keyboard';
  FMockDevices[2].Paired := False;
  FMockDevices[2].Connected := False;
  FMockDevices[2].Trusted := False;
  FMockDevices[2].Battery := -1;
end;

function TConfigBluetoothService.RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
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

function TConfigBluetoothService.IsAvailable(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(True);

  if not FileExists('/usr/bin/bluetoothctl') then
    Exit(False);

  Result := RunCommandOutput('bluetoothctl show', outText) and (Pos('Controller', outText) > 0);
end;

function TConfigBluetoothService.IsBluetoothEnabled(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(FMockEnabled);

  if not RunCommandOutput('bluetoothctl show', outText) then
    Exit(False);

  Result := (Pos('Powered: yes', outText) > 0) or (Pos('PowerState: on', outText) > 0);
  FBluetoothEnabled := Result;
end;

function TConfigBluetoothService.SetBluetoothEnabled(AEnable: Boolean): Boolean;
var
  outText: string;
begin
  if FMockMode then
  begin
    FMockEnabled := AEnable;
    FBluetoothEnabled := AEnable;
    Exit(True);
  end;

  if AEnable then
    Result := RunCommandOutput('bluetoothctl power on', outText)
  else
    Result := RunCommandOutput('bluetoothctl power off', outText);

  if Result then
    FBluetoothEnabled := AEnable;
end;

function TConfigBluetoothService.IsScanning(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(False);

  if not RunCommandOutput('bluetoothctl show', outText) then
    Exit(False);

  Result := (Pos('Discovering: yes', outText) > 0);
end;

function TConfigBluetoothService.StartScan(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(True);

  Result := RunCommandOutput('bluetoothctl --timeout 10 scan on', outText);
end;

function TConfigBluetoothService.StopScan(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(True);

  Result := RunCommandOutput('bluetoothctl scan off', outText);
end;

function TConfigBluetoothService.ParseDeviceInfo(const AAddress: string; out ADevice: TBluetoothDevice): Boolean;
var
  outText, line, key, val: string;
  lines: TStringList;
  i, p: Integer;
begin
  ADevice.Address := AAddress;
  ADevice.Name := AAddress;
  ADevice.Icon := 'generic';
  ADevice.Paired := False;
  ADevice.Connected := False;
  ADevice.Trusted := False;
  ADevice.Battery := -1;

  if not RunCommandOutput('bluetoothctl info ' + AAddress, outText) then
    Exit(False);

  lines := TStringList.Create();
  try
    lines.Text := outText;
    for i := 0 to lines.Count - 1 do
    begin
      line := Trim(lines[i]);
      p := Pos(':', line);
      if p > 0 then
      begin
        key := Trim(Copy(line, 1, p - 1));
        val := Trim(Copy(line, p + 1, Length(line)));

        if SameText(key, 'Name') or SameText(key, 'Alias') then
        begin
          if (ADevice.Name = AAddress) or SameText(key, 'Alias') then
            ADevice.Name := val;
        end
        else if SameText(key, 'Icon') then
          ADevice.Icon := val
        else if SameText(key, 'Paired') then
          ADevice.Paired := SameText(val, 'yes')
        else if SameText(key, 'Connected') then
          ADevice.Connected := SameText(val, 'yes')
        else if SameText(key, 'Trusted') then
          ADevice.Trusted := SameText(val, 'yes')
        else if SameText(key, 'Battery Percentage') then
        begin
          p := Pos('(', val);
          if p > 0 then
            val := Copy(val, 1, p - 1);
          ADevice.Battery := StrToIntDef(Trim(val), -1);
        end;
      end;
    end;
    Result := True;
  finally
    lines.Free();
  end;
end;

function TConfigBluetoothService.GetDevices(): TBluetoothDeviceArray;
var
  outText, line, mac, name: string;
  lines: TStringList;
  i, p1, p2, count: Integer;
  dev: TBluetoothDevice;
begin
  if FMockMode then
    Exit(FMockDevices);

  SetLength(Result, 0);
  if not RunCommandOutput('bluetoothctl devices', outText) then
    Exit;

  lines := TStringList.Create();
  try
    lines.Text := outText;
    count := 0;
    for i := 0 to lines.Count - 1 do
    begin
      line := Trim(lines[i]);
      // Format: "Device XX:XX:XX:XX:XX:XX DeviceName"
      if Pos('Device ', line) = 1 then
      begin
        p1 := Length('Device ') + 1;
        p2 := Pos(' ', Copy(line, p1, Length(line)));
        if p2 > 0 then
        begin
          mac := Copy(line, p1, p2 - 1);
          name := Trim(Copy(line, p1 + p2, Length(line)));
          if ParseDeviceInfo(mac, dev) then
          begin
            if (dev.Name = mac) and (name <> '') then
              dev.Name := name;
            Inc(count);
            SetLength(Result, count);
            Result[count - 1] := dev;
          end;
        end;
      end;
    end;
  finally
    lines.Free();
  end;
end;

function TConfigBluetoothService.GetDevice(const AAddress: string; out ADevice: TBluetoothDevice): Boolean;
var
  i: Integer;
  devs: TBluetoothDeviceArray;
begin
  if FMockMode then
  begin
    for i := 0 to High(FMockDevices) do
    begin
      if SameText(FMockDevices[i].Address, AAddress) then
      begin
        ADevice := FMockDevices[i];
        Exit(True);
      end;
    end;
    Exit(False);
  end;

  devs := GetDevices();
  for i := 0 to High(devs) do
  begin
    if SameText(devs[i].Address, AAddress) then
    begin
      ADevice := devs[i];
      Exit(True);
    end;
  end;

  Result := ParseDeviceInfo(AAddress, ADevice);
end;

function TConfigBluetoothService.Connect(const AAddress: string): Boolean;
var
  outText: string;
  i: Integer;
begin
  if FMockMode then
  begin
    for i := 0 to High(FMockDevices) do
    begin
      if SameText(FMockDevices[i].Address, AAddress) then
      begin
        FMockDevices[i].Connected := True;
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  Result := RunCommandOutput('bluetoothctl connect ' + AAddress, outText) and
            (Pos('Connection successful', outText) > 0);
end;

function TConfigBluetoothService.Disconnect(const AAddress: string): Boolean;
var
  outText: string;
  i: Integer;
begin
  if FMockMode then
  begin
    for i := 0 to High(FMockDevices) do
    begin
      if SameText(FMockDevices[i].Address, AAddress) then
      begin
        FMockDevices[i].Connected := False;
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  Result := RunCommandOutput('bluetoothctl disconnect ' + AAddress, outText) and
            (Pos('Successful disconnected', outText) > 0);
end;

function TConfigBluetoothService.Pair(const AAddress: string): Boolean;
var
  outText: string;
  i: Integer;
begin
  if FMockMode then
  begin
    for i := 0 to High(FMockDevices) do
    begin
      if SameText(FMockDevices[i].Address, AAddress) then
      begin
        FMockDevices[i].Paired := True;
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  Result := RunCommandOutput('bluetoothctl pair ' + AAddress, outText);
end;

function TConfigBluetoothService.RemoveDevice(const AAddress: string): Boolean;
var
  outText: string;
  i, j: Integer;
begin
  if FMockMode then
  begin
    for i := 0 to High(FMockDevices) do
    begin
      if SameText(FMockDevices[i].Address, AAddress) then
      begin
        for j := i to High(FMockDevices) - 1 do
          FMockDevices[j] := FMockDevices[j + 1];
        SetLength(FMockDevices, Length(FMockDevices) - 1);
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  Result := RunCommandOutput('bluetoothctl remove ' + AAddress, outText);
end;

procedure TConfigBluetoothService.EnableMockMode(const AEnabled: Boolean);
begin
  FMockMode := AEnabled;
  if AEnabled and (Length(FMockDevices) = 0) then
    InitDefaultMockDevices();
end;

procedure TConfigBluetoothService.SetMockEnabled(AValue: Boolean);
begin
  FMockEnabled := AValue;
  FBluetoothEnabled := AValue;
end;

procedure TConfigBluetoothService.SetMockDevices(const ADevices: TBluetoothDeviceArray);
var
  i: Integer;
begin
  SetLength(FMockDevices, Length(ADevices));
  for i := 0 to High(ADevices) do
    FMockDevices[i] := ADevices[i];
end;

end.

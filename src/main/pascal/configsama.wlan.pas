// configsama.wlan.pas — WLAN / Wi-Fi management service using NetworkManager (nmcli)
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Wlan;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TWlanNetwork = record
    Ssid: string;
    Bssid: string;
    Signal: Integer;      // 0..100
    Security: string;    // e.g. "WPA2", "WPA3", "" (open)
    IsConnected: Boolean;
    IsSaved: Boolean;
    Bars: string;
  end;
  TWlanNetworkArray = array of TWlanNetwork;

  TWlanConnectionDetails = record
    Ssid: string;
    Device: string;
    IpAddress: string;
    Gateway: string;
    Dns: string;
    HwAddr: string;
    Signal: Integer;
    Security: string;
    State: string;
  end;

  TConfigWlanService = class
  private
    FMockMode: Boolean;
    FMockWifiEnabled: Boolean;
    FMockNetworks: TWlanNetworkArray;
    FMockDetails: TWlanConnectionDetails;

    function RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
    function SplitNmcliLine(const ALine: string): TStringList;
    function FindWifiDevice(): string;
    function QuerySavedConnections(): TStringList;
  public
    constructor Create();
    destructor Destroy(); override;

    function IsAvailable(): Boolean;
    function IsWifiEnabled(): Boolean;
    function SetWifiEnabled(AEnable: Boolean): Boolean;

    function ScanNetworks(AFreshScan: Boolean = False): TWlanNetworkArray;
    function GetConnectionDetails(): TWlanConnectionDetails;

    function Connect(const ASsid: string; const APassword: string = ''): Boolean;
    function Disconnect(): Boolean;
    function Forget(const ASsid: string): Boolean;
    function Rescan(): Boolean;

    // Test seam / Mocking
    procedure EnableMockMode(const AEnabled: Boolean = True);
    procedure SetMockWifiEnabled(AValue: Boolean);
    procedure SetMockNetworks(const ANetworks: TWlanNetworkArray);
    procedure SetMockDetails(const ADetails: TWlanConnectionDetails);
  end;

function WlanService(): TConfigWlanService;

implementation

var
  GWlanService: TConfigWlanService = nil;

function WlanService(): TConfigWlanService;
begin
  if GWlanService = nil then
    GWlanService := TConfigWlanService.Create();
  Result := GWlanService;
end;

constructor TConfigWlanService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockWifiEnabled := True;
  SetLength(FMockNetworks, 0);
  FillChar(FMockDetails, SizeOf(FMockDetails), 0);
end;

destructor TConfigWlanService.Destroy();
begin
  SetLength(FMockNetworks, 0);
  inherited Destroy();
end;

function TConfigWlanService.RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
var
  p: TProcess;
  stream: TStringList;
  outputStr: string;
  buf: array[0..2047] of AnsiChar;
  bytesRead: Integer;
  mem: TMemoryStream;
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

function TConfigWlanService.SplitNmcliLine(const ALine: string): TStringList;
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

function TConfigWlanService.FindWifiDevice(): string;
var
  raw: string;
  lines, parts: TStringList;
  i: Integer;
begin
  Result := '';
  if not RunCommandOutput('nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null', raw) then
    Exit();

  lines := TStringList.Create();
  try
    lines.Text := raw;
    for i := 0 to lines.Count - 1 do
    begin
      parts := SplitNmcliLine(lines[i]);
      try
        if (parts.Count >= 2) and (parts[1] = 'wifi') then
        begin
          Result := parts[0];
          Break;
        end;
      finally
        parts.Free();
      end;
    end;
  finally
    lines.Free();
  end;
end;

function TConfigWlanService.QuerySavedConnections(): TStringList;
var
  raw: string;
  lines, parts: TStringList;
  i: Integer;
begin
  Result := TStringList.Create();
  if not RunCommandOutput('nmcli -t -f NAME,TYPE connection show 2>/dev/null', raw) then
    Exit();

  lines := TStringList.Create();
  try
    lines.Text := raw;
    for i := 0 to lines.Count - 1 do
    begin
      parts := SplitNmcliLine(lines[i]);
      try
        if (parts.Count >= 2) and (parts[1] = '802-11-wireless') then
          Result.Add(parts[0]);
      finally
        parts.Free();
      end;
    end;
  finally
    lines.Free();
  end;
end;

function TConfigWlanService.IsAvailable(): Boolean;
var
  dummy: string;
begin
  if FMockMode then
    Exit(True);
  Result := RunCommandOutput('which nmcli 2>/dev/null', dummy);
end;

function TConfigWlanService.IsWifiEnabled(): Boolean;
var
  raw: string;
begin
  if FMockMode then
    Exit(FMockWifiEnabled);

  if RunCommandOutput('nmcli radio wifi 2>/dev/null', raw) then
    Result := (LowerCase(Trim(raw)) = 'enabled')
  else
    Result := False;
end;

function TConfigWlanService.SetWifiEnabled(AEnable: Boolean): Boolean;
var
  raw: string;
  cmd: string;
begin
  if FMockMode then
  begin
    FMockWifiEnabled := AEnable;
    Exit(True);
  end;

  if AEnable then
    cmd := 'nmcli radio wifi on 2>/dev/null'
  else
    cmd := 'nmcli radio wifi off 2>/dev/null';

  Result := RunCommandOutput(cmd, raw);
end;

function TConfigWlanService.ScanNetworks(AFreshScan: Boolean = False): TWlanNetworkArray;
var
  raw: string;
  lines, parts, savedList: TStringList;
  i, j, k, sig: Integer;
  inUse, bssid, ssid, sec: string;
  foundIdx: Integer;
  net: TWlanNetwork;
  tmp: TWlanNetwork;
begin
  if FMockMode then
  begin
    if not FMockWifiEnabled then
    begin
      SetLength(Result, 0);
      Exit();
    end;
    Result := Copy(FMockNetworks);
    Exit();
  end;

  SetLength(Result, 0);
  if not IsWifiEnabled() then Exit();

  if AFreshScan then
    RunCommandOutput('nmcli device wifi rescan 2>/dev/null', raw);

  if not RunCommandOutput('nmcli -t -f IN-USE,BSSID,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null', raw) then
    Exit();

  savedList := QuerySavedConnections();
  lines := TStringList.Create();
  try
    lines.Text := raw;
    for i := 0 to lines.Count - 1 do
    begin
      parts := SplitNmcliLine(lines[i]);
      try
        if parts.Count >= 5 then
        begin
          inUse := Trim(parts[0]);
          bssid := Trim(parts[1]);
          ssid := Trim(parts[2]);
          sig := StrToIntDef(Trim(parts[3]), 0);
          sec := Trim(parts[4]);

          // Filter out completely blank SSIDs
          if ssid = '' then
            Continue;

          // Check for duplicate SSID: keep the one that is connected, or has higher signal
          foundIdx := -1;
          for j := 0 to High(Result) do
          begin
            if Result[j].Ssid = ssid then
            begin
              foundIdx := j;
              Break;
            end;
          end;

          if foundIdx >= 0 then
          begin
            if (inUse = '*') or ((sig > Result[foundIdx].Signal) and not Result[foundIdx].IsConnected) then
            begin
              Result[foundIdx].Bssid := bssid;
              Result[foundIdx].Signal := sig;
              Result[foundIdx].Security := sec;
              if inUse = '*' then
                Result[foundIdx].IsConnected := True;
            end;
          end
          else
          begin
            net.Ssid := ssid;
            net.Bssid := bssid;
            net.Signal := sig;
            net.Security := sec;
            net.IsConnected := (inUse = '*');
            net.IsSaved := (savedList.IndexOf(ssid) >= 0);
            net.Bars := '';

            SetLength(Result, Length(Result) + 1);
            Result[High(Result)] := net;
          end;
        end;
      finally
        parts.Free();
      end;
    end;
  finally
    lines.Free();
    savedList.Free();
  end;

  // Sort networks:
  // 1. Connected network first
  // 2. Saved networks second (sorted by signal descending)
  // 3. Other networks (sorted by signal descending)
  if Length(Result) > 1 then
  begin
    for i := 0 to High(Result) - 1 do
      for j := i + 1 to High(Result) do
      begin
        // Determine whether j should come before i
        if Result[j].IsConnected and not Result[i].IsConnected then
        begin
          tmp := Result[i];
          Result[i] := Result[j];
          Result[j] := tmp;
        end
        else if (Result[j].IsConnected = Result[i].IsConnected) then
        begin
          if Result[j].IsSaved and not Result[i].IsSaved then
          begin
            tmp := Result[i];
            Result[i] := Result[j];
            Result[j] := tmp;
          end
          else if (Result[j].IsSaved = Result[i].IsSaved) and (Result[j].Signal > Result[i].Signal) then
          begin
            tmp := Result[i];
            Result[i] := Result[j];
            Result[j] := tmp;
          end;
        end;
      end;
  end;
end;

function TConfigWlanService.GetConnectionDetails(): TWlanConnectionDetails;
var
  dev, raw, key, val: string;
  lines: TStringList;
  i, p: Integer;
  nets: TWlanNetworkArray;
begin
  FillChar(Result, SizeOf(Result), 0);
  if FMockMode then
  begin
    Result := FMockDetails;
    Exit();
  end;

  dev := FindWifiDevice();
  Result.Device := dev;
  if dev = '' then Exit();

  // Find active SSID from scan or status
  nets := ScanNetworks(False);
  for i := 0 to High(nets) do
  begin
    if nets[i].IsConnected then
    begin
      Result.Ssid := nets[i].Ssid;
      Result.Signal := nets[i].Signal;
      Result.Security := nets[i].Security;
      Break;
    end;
  end;

  if RunCommandOutput('nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR,GENERAL.STATE device show ' + dev + ' 2>/dev/null', raw) then
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
          if (Pos('IP4.ADDRESS', key) = 1) and (Result.IpAddress = '') then
            Result.IpAddress := val
          else if (key = 'IP4.GATEWAY') and (Result.Gateway = '') then
            Result.Gateway := val
          else if (Pos('IP4.DNS', key) = 1) and (Result.Dns = '') then
            Result.Dns := val
          else if key = 'GENERAL.HWADDR' then
            Result.HwAddr := val
          else if key = 'GENERAL.STATE' then
            Result.State := val;
        end;
      end;
    finally
      lines.Free();
    end;
  end;
end;

function TConfigWlanService.Connect(const ASsid: string; const APassword: string = ''): Boolean;
var
  cmd, raw: string;
  saved: TStringList;
begin
  if ASsid = '' then Exit(False);

  if FMockMode then
  begin
    FMockDetails.Ssid := ASsid;
    FMockDetails.IpAddress := '192.168.1.100/24';
    FMockDetails.Gateway := '192.168.1.1';
    Exit(True);
  end;

  if APassword <> '' then
  begin
    // Escape double quotes inside password
    cmd := 'nmcli device wifi connect "' + ASsid + '" password "' + StringReplace(APassword, '"', '\"', [rfReplaceAll]) + '" 2>/dev/null';
    Result := RunCommandOutput(cmd, raw);
  end
  else
  begin
    saved := QuerySavedConnections();
    try
      if saved.IndexOf(ASsid) >= 0 then
      begin
        // Try connection up first
        cmd := 'nmcli connection up "' + ASsid + '" 2>/dev/null';
        Result := RunCommandOutput(cmd, raw);
        if not Result then
        begin
          cmd := 'nmcli device wifi connect "' + ASsid + '" 2>/dev/null';
          Result := RunCommandOutput(cmd, raw);
        end;
      end
      else
      begin
        cmd := 'nmcli device wifi connect "' + ASsid + '" 2>/dev/null';
        Result := RunCommandOutput(cmd, raw);
      end;
    finally
      saved.Free();
    end;
  end;
end;

function TConfigWlanService.Disconnect(): Boolean;
var
  dev, cmd, raw: string;
  details: TWlanConnectionDetails;
begin
  if FMockMode then
  begin
    FillChar(FMockDetails, SizeOf(FMockDetails), 0);
    Exit(True);
  end;

  dev := FindWifiDevice();
  if dev <> '' then
  begin
    cmd := 'nmcli device disconnect ' + dev + ' 2>/dev/null';
    Result := RunCommandOutput(cmd, raw);
    Exit();
  end;

  details := GetConnectionDetails();
  if details.Ssid <> '' then
  begin
    cmd := 'nmcli connection down "' + details.Ssid + '" 2>/dev/null';
    Result := RunCommandOutput(cmd, raw);
  end
  else
    Result := False;
end;

function TConfigWlanService.Forget(const ASsid: string): Boolean;
var
  cmd, raw: string;
begin
  if ASsid = '' then Exit(False);
  if FMockMode then Exit(True);

  cmd := 'nmcli connection delete "' + ASsid + '" 2>/dev/null';
  Result := RunCommandOutput(cmd, raw);
end;

function TConfigWlanService.Rescan(): Boolean;
var
  raw: string;
begin
  if FMockMode then Exit(True);
  Result := RunCommandOutput('nmcli device wifi rescan 2>/dev/null', raw);
end;

procedure TConfigWlanService.EnableMockMode(const AEnabled: Boolean = True);
begin
  FMockMode := AEnabled;
end;

procedure TConfigWlanService.SetMockWifiEnabled(AValue: Boolean);
begin
  FMockWifiEnabled := AValue;
end;

procedure TConfigWlanService.SetMockNetworks(const ANetworks: TWlanNetworkArray);
begin
  FMockNetworks := Copy(ANetworks);
end;

procedure TConfigWlanService.SetMockDetails(const ADetails: TWlanConnectionDetails);
begin
  FMockDetails := ADetails;
end;

finalization
  if GWlanService <> nil then
  begin
    GWlanService.Free();
    GWlanService := nil;
  end;

end.

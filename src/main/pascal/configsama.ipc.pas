// configsama.ipc.pas — Single-instance IPC management for Samarinda Settings
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.IPC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simpleipc, baseunix,
  ftpas.api,
  ConfigSama.Window;

function SanitizeDisplay(const ADisplay: string): string;
function GetConfigSamaServerID(const ADisplayOverride: string = ''): string;
function TryForwardToExistingInstance(const APayload: string; const AServerIDOverride: string = ''): Boolean;

type
  { TConfigSamaIPCServer — Single-instance listener that receives commands from secondary instances }
  TConfigSamaIPCServer = class
  private
    FServer: TSimpleIPCServer;
    FWindow: TConfigSamaWindow;
    FServerID: string;
    FRunning: Boolean;
    procedure ProcessPayload(const APayload: string);
  public
    constructor Create(AWindow: TConfigSamaWindow; const AServerIDOverride: string = '');
    destructor Destroy(); override;

    function Start(): Boolean;
    procedure Stop();
    procedure Poll();

    property ServerID: string read FServerID;
    property Running: Boolean read FRunning;
    property Window: TConfigSamaWindow read FWindow write FWindow;
  end;

implementation

procedure IPCTimerCallback(user_data: Pointer); cdecl;
begin
  if user_data <> nil then
    TConfigSamaIPCServer(user_data).Poll();
end;

function SanitizeDisplay(const ADisplay: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(ADisplay) do
  begin
    c := ADisplay[i];
    if c in ['a'..'z', 'A'..'Z', '0'..'9', '_', '-'] then
      Result := Result + c
    else
      Result := Result + '_';
  end;
  if Result = '' then
    Result := 'nodisp';
end;

function GetConfigSamaServerID(const ADisplayOverride: string): string;
var
  disp: string;
begin
  if ADisplayOverride <> '' then
    disp := SanitizeDisplay(ADisplayOverride)
  else
    disp := SanitizeDisplay(GetEnvironmentVariable('DISPLAY'));

  Result := 'configsama-' + IntToStr(fpGetUID()) + '-' + disp;
end;

function TryForwardToExistingInstance(const APayload: string; const AServerIDOverride: string): Boolean;
var
  client: TSimpleIPCClient;
  targetServerID: string;
begin
  Result := False;
  if AServerIDOverride <> '' then
    targetServerID := AServerIDOverride
  else
    targetServerID := GetConfigSamaServerID();

  client := TSimpleIPCClient.Create(nil);
  try
    client.ServerID := targetServerID;
    if not client.ServerRunning() then
      Exit(False);

    try
      client.Connect();
      try
        client.SendStringMessage(APayload);
        Result := True;
      finally
        client.Disconnect();
      end;
    except
      on E: Exception do
        Result := False;
    end;
  finally
    client.Free();
  end;
end;

{ TConfigSamaIPCServer }

constructor TConfigSamaIPCServer.Create(AWindow: TConfigSamaWindow; const AServerIDOverride: string);
begin
  inherited Create();
  FWindow := AWindow;
  if AServerIDOverride <> '' then
    FServerID := AServerIDOverride
  else
    FServerID := GetConfigSamaServerID();
  FServer := nil;
  FRunning := False;
end;

destructor TConfigSamaIPCServer.Destroy();
begin
  Stop();
  inherited Destroy();
end;

function TConfigSamaIPCServer.Start(): Boolean;
var
  pipeFile: string;
begin
  Result := False;
  if FRunning then Exit(True);

  pipeFile := GetTempDir(True) + FServerID;
  if FileExists(pipeFile) then
    DeleteFile(pipeFile);

  try
    FServer := TSimpleIPCServer.Create(nil);
    FServer.ServerID := FServerID;
    FServer.Global := True;
    FServer.StartServer();
    FRunning := True;

    if Assigned(ft_set_timer) then
      ft_set_timer(100, @IPCTimerCallback, Self);

    Result := True;
  except
    on E: Exception do
    begin
      FreeAndNil(FServer);
      FRunning := False;
      Result := False;
    end;
  end;
end;

procedure TConfigSamaIPCServer.Stop();
var
  pipeFile: string;
begin
  if not FRunning then Exit;
  FRunning := False;

  if Assigned(ft_set_timer) then
    ft_set_timer(0, nil, nil);

  if Assigned(FServer) then
  begin
    try
      if FServer.Active then
        FServer.StopServer();
    except
      // Discard shutdown errors
    end;
    FreeAndNil(FServer);
  end;

  pipeFile := GetTempDir(True) + FServerID;
  if FileExists(pipeFile) then
    DeleteFile(pipeFile);
end;

procedure TConfigSamaIPCServer.Poll();
var
  msg: string;
begin
  if (FServer = nil) or not FServer.Active then Exit;

  try
    while FServer.PeekMessage(0, True) do
    begin
      msg := FServer.StringMessage;
      ProcessPayload(msg);
    end;
  except
    // Discard non-fatal message polling exceptions
  end;
end;

procedure TConfigSamaIPCServer.ProcessPayload(const APayload: string);
var
  lines: TStringList;
  i: Integer;
  line: string;
begin
  if Assigned(FWindow) then
  begin
    if APayload <> '' then
    begin
      lines := TStringList.Create();
      try
        lines.Text := APayload;
        for i := 0 to lines.Count - 1 do
        begin
          line := Trim(lines[i]);
          if line = '' then Continue;
          if (line = '--dark') or (line = '-d') then
            FWindow.SetDarkMode(True)
          else if (line = '--light') or (line = '-l') then
            FWindow.SetDarkMode(False)
          else
            FWindow.SelectCategoryByName(line);
        end;
      finally
        lines.Free();
      end;
    end;

    if not FWindow.Visible then
      FWindow.Show();
    FWindow.BringToFront();
  end;
end;

end.

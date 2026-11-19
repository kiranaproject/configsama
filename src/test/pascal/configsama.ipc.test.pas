// configsama.ipc.test.pas — unit tests for single-instance IPC communication
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.IPC.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.IPC, ConfigSama.Window;

type
  { TConfigIPCTest }
  TConfigIPCTest = class(TTestCase)
  private
    FTestServerID: string;
    FWindow: TConfigSamaWindow;
    FIPCServer: TConfigSamaIPCServer;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestSanitizeDisplay();
    procedure TestGetConfigSamaServerID();
    procedure TestForwardReturnsFalseWhenNoServer();
    procedure TestForwardDeliversPayloadToRunningServer();
    procedure TestIPCServerProcessesCategoryAndThemeCommands();
    procedure TestStalePipeCleanupOnCheck();
  end;

implementation

procedure TConfigIPCTest.SetUp();
begin
  FTestServerID := 'configsama-test-' + IntToStr(GetProcessID());
  FWindow := nil;
  FIPCServer := nil;
end;

procedure TConfigIPCTest.TearDown();
begin
  if Assigned(FIPCServer) then
  begin
    FIPCServer.Free();
    FIPCServer := nil;
  end;
  if Assigned(FWindow) then
  begin
    FWindow.Free();
    FWindow := nil;
  end;

  if FileExists(GetTempDir(True) + FTestServerID) then
    DeleteFile(GetTempDir(True) + FTestServerID);
end;

procedure TConfigIPCTest.TestSanitizeDisplay();
begin
  AssertEquals('Sanitize :0', '_0', SanitizeDisplay(':0'));
  AssertEquals('Sanitize :99', '_99', SanitizeDisplay(':99'));
  AssertEquals('Sanitize :0.0', '_0_0', SanitizeDisplay(':0.0'));
  AssertEquals('Sanitize empty', 'nodisp', SanitizeDisplay(''));
  AssertEquals('Sanitize clean name', 'my_disp-1', SanitizeDisplay('my_disp-1'));
end;

procedure TConfigIPCTest.TestGetConfigSamaServerID();
var
  id: string;
begin
  id := GetConfigSamaServerID(':99');
  AssertTrue('ID starts with configsama-', Pos('configsama-', id) = 1);
  AssertTrue('ID contains _99', Pos('_99', id) > 0);
end;

procedure TConfigIPCTest.TestForwardReturnsFalseWhenNoServer();
var
  res: Boolean;
begin
  res := TryForwardToExistingInstance('Background', FTestServerID);
  AssertFalse('Forwarding must return false when no server is listening', res);
end;

procedure TConfigIPCTest.TestForwardDeliversPayloadToRunningServer();
var
  delivered: Boolean;
begin
  FIPCServer := TConfigSamaIPCServer.Create(nil, FTestServerID);
  AssertTrue('Server must start successfully', FIPCServer.Start());
  AssertTrue('Server is running', FIPCServer.Running);

  delivered := TryForwardToExistingInstance('Displays', FTestServerID);
  AssertTrue('Payload must be accepted by running server', delivered);

  FIPCServer.Stop();
  AssertFalse('Server is stopped', FIPCServer.Running);
end;

procedure TConfigIPCTest.TestIPCServerProcessesCategoryAndThemeCommands();
var
  delivered: Boolean;
begin
  FWindow := TConfigSamaWindow.Create();
  FIPCServer := TConfigSamaIPCServer.Create(FWindow, FTestServerID);
  AssertTrue('Server must start', FIPCServer.Start());

  // Deliver theme and category switch in payload
  delivered := TryForwardToExistingInstance('--dark' + #10 + 'Background', FTestServerID);
  AssertTrue('Payload must be accepted', delivered);

  // Poll server to process the queued payload
  FIPCServer.Poll();

  AssertTrue('Dark mode must be enabled after command', FWindow.Settings.DarkMode);
  AssertEquals('Section title must update to Background', 'Background', FWindow.SectionTitle.Text);

  // Deliver light mode command
  delivered := TryForwardToExistingInstance('--light' + #10 + 'Wired', FTestServerID);
  AssertTrue('Light payload must be accepted', delivered);

  FIPCServer.Poll();
  AssertFalse('Dark mode must be false after --light', FWindow.Settings.DarkMode);
  AssertEquals('Section title must update to Wired', 'Wired', FWindow.SectionTitle.Text);
end;

procedure TConfigIPCTest.TestStalePipeCleanupOnCheck();
var
  pipePath: string;
  res: Boolean;
begin
  FIPCServer := TConfigSamaIPCServer.Create(nil, FTestServerID);
  AssertTrue('Server must start', FIPCServer.Start());
  pipePath := GetTempDir(True) + FTestServerID;
  AssertTrue('Pipe file exists', FileExists(pipePath));

  // Destroy server without calling Stop() to simulate abrupt process termination
  // (leaving the named pipe on filesystem without an active reader)
  FIPCServer.Free();
  FIPCServer := nil;

  // Now forward to the orphan pipe
  res := TryForwardToExistingInstance('Background', FTestServerID);
  AssertFalse('Forwarding to orphan pipe must report false', res);
  AssertFalse('Orphan pipe must be cleaned up', FileExists(pipePath));
end;

initialization
  RegisterTest(TConfigIPCTest);
end.

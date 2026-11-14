// configsama.bluetooth.test.pas — unit tests for Bluetooth service layer
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Bluetooth.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Bluetooth;

type
  { TConfigBluetoothTest }
  TConfigBluetoothTest = class(TTestCase)
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockModeToggle();
    procedure TestMockDevices();
    procedure TestConnectAndDisconnect();
    procedure TestRemoveDevice();
  end;

implementation

procedure TConfigBluetoothTest.SetUp();
begin
  BluetoothService().EnableMockMode(True);
end;

procedure TConfigBluetoothTest.TearDown();
begin
  BluetoothService().EnableMockMode(False);
end;

procedure TConfigBluetoothTest.TestServiceSingleton();
var
  svc1, svc2: TConfigBluetoothService;
begin
  svc1 := BluetoothService();
  svc2 := BluetoothService();
  AssertNotNull('BluetoothService must return non-nil instance', svc1);
  AssertTrue('BluetoothService must return identical singleton', svc1 = svc2);
end;

procedure TConfigBluetoothTest.TestMockModeToggle();
var
  svc: TConfigBluetoothService;
begin
  svc := BluetoothService();
  svc.SetMockEnabled(True);
  AssertTrue('Bluetooth must be enabled in mock mode', svc.IsBluetoothEnabled());

  svc.SetBluetoothEnabled(False);
  AssertFalse('Bluetooth must be disabled after toggle', svc.IsBluetoothEnabled());

  svc.SetBluetoothEnabled(True);
  AssertTrue('Bluetooth must be re-enabled after toggle', svc.IsBluetoothEnabled());
end;

procedure TConfigBluetoothTest.TestMockDevices();
var
  svc: TConfigBluetoothService;
  devs: TBluetoothDeviceArray;
  dev: TBluetoothDevice;
  found: Boolean;
begin
  svc := BluetoothService();
  devs := svc.GetDevices();
  AssertTrue('Mock devices list must have items', Length(devs) > 0);

  found := svc.GetDevice('B6:11:03:4B:4E:19', dev);
  AssertTrue('Mock AZ09 earphones must be found', found);
  AssertEquals('Device address match', 'B6:11:03:4B:4E:19', dev.Address);
  AssertEquals('Device icon match', 'audio-headset', dev.Icon);
  AssertTrue('Device paired', dev.Paired);
  AssertTrue('Device connected', dev.Connected);
  AssertEquals('Device battery percentage', 85, dev.Battery);
end;

procedure TConfigBluetoothTest.TestConnectAndDisconnect();
var
  svc: TConfigBluetoothService;
  dev: TBluetoothDevice;
begin
  svc := BluetoothService();

  // Test Disconnect on AZ09
  AssertTrue('Disconnect call succeeds', svc.Disconnect('B6:11:03:4B:4E:19'));
  AssertTrue('Device found', svc.GetDevice('B6:11:03:4B:4E:19', dev));
  AssertFalse('Device should now be disconnected', dev.Connected);

  // Test Connect on MX Master 3S
  AssertTrue('Connect call succeeds', svc.Connect('FC:58:FA:72:01:A2'));
  AssertTrue('Device found', svc.GetDevice('FC:58:FA:72:01:A2', dev));
  AssertTrue('Device should now be connected', dev.Connected);
end;

procedure TConfigBluetoothTest.TestRemoveDevice();
var
  svc: TConfigBluetoothService;
  devs: TBluetoothDeviceArray;
  initialCount: Integer;
begin
  svc := BluetoothService();
  devs := svc.GetDevices();
  initialCount := Length(devs);

  AssertTrue('Remove device succeeds', svc.RemoveDevice('D0:C5:D3:88:14:6B'));
  devs := svc.GetDevices();
  AssertEquals('Device count decremented by 1', initialCount - 1, Length(devs));
end;

initialization
  RegisterTest(TConfigBluetoothTest);

end.

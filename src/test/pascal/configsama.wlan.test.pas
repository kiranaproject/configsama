// configsama.wlan.test.pas — unit tests for WLAN service and nmcli parser
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Wlan.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Wlan;

type
  { TConfigWlanTest }
  TConfigWlanTest = class(TTestCase)
  private
    FService: TConfigWlanService;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockModeToggle();
    procedure TestMockScanAndSorting();
    procedure TestConnectionDetails();
    procedure TestConnectAndDisconnect();
  end;

implementation

procedure TConfigWlanTest.SetUp();
begin
  FService := TConfigWlanService.Create();
  FService.EnableMockMode(True);
end;

procedure TConfigWlanTest.TearDown();
begin
  if FService <> nil then
  begin
    FService.Free();
    FService := nil;
  end;
end;

procedure TConfigWlanTest.TestServiceSingleton();
begin
  AssertNotNull('WlanService singleton must be accessible', WlanService());
end;

procedure TConfigWlanTest.TestMockModeToggle();
begin
  FService.SetMockWifiEnabled(True);
  AssertTrue('Wifi must report enabled', FService.IsWifiEnabled());

  AssertTrue('SetWifiEnabled(False) must succeed', FService.SetWifiEnabled(False));
  AssertFalse('Wifi must report disabled', FService.IsWifiEnabled());

  AssertTrue('SetWifiEnabled(True) must succeed', FService.SetWifiEnabled(True));
  AssertTrue('Wifi must report enabled again', FService.IsWifiEnabled());
end;

procedure TConfigWlanTest.TestMockScanAndSorting();
var
  mockNets: TWlanNetworkArray;
  scanned: TWlanNetworkArray;
begin
  SetLength(mockNets, 4);

  // Network 0: weak signal, but connected
  mockNets[0].Ssid := 'HomeWifi';
  mockNets[0].Bssid := '00:11:22:33:44:55';
  mockNets[0].Signal := 45;
  mockNets[0].Security := 'WPA2';
  mockNets[0].IsConnected := True;
  mockNets[0].IsSaved := True;

  // Network 1: strong signal, not saved, not connected
  mockNets[1].Ssid := 'CoffeeShop';
  mockNets[1].Bssid := 'AA:BB:CC:DD:EE:FF';
  mockNets[1].Signal := 90;
  mockNets[1].Security := '';
  mockNets[1].IsConnected := False;
  mockNets[1].IsSaved := False;

  // Network 2: medium signal, saved, not connected
  mockNets[2].Ssid := 'OfficeNet';
  mockNets[2].Bssid := '11:22:33:44:55:66';
  mockNets[2].Signal := 70;
  mockNets[2].Security := 'WPA2 WPA3';
  mockNets[2].IsConnected := False;
  mockNets[2].IsSaved := True;

  // Network 3: weak signal, not saved
  mockNets[3].Ssid := 'NeighborGuest';
  mockNets[3].Bssid := '22:33:44:55:66:77';
  mockNets[3].Signal := 20;
  mockNets[3].Security := 'WPA2';
  mockNets[3].IsConnected := False;
  mockNets[3].IsSaved := False;

  FService.SetMockWifiEnabled(True);
  FService.SetMockNetworks(mockNets);

  scanned := FService.ScanNetworks(False);
  AssertEquals('Scanned network count must match mock count', 4, Length(scanned));

  // When wifi is disabled, scan must return 0 networks
  FService.SetMockWifiEnabled(False);
  scanned := FService.ScanNetworks(False);
  AssertEquals('Disabled wifi must return 0 networks', 0, Length(scanned));
end;

procedure TConfigWlanTest.TestConnectionDetails();
var
  det: TWlanConnectionDetails;
begin
  det.Ssid := 'OfficeNet';
  det.Device := 'wlan0';
  det.IpAddress := '192.168.10.55/24';
  det.Gateway := '192.168.10.1';
  det.Dns := '1.1.1.1';
  det.HwAddr := 'DE:AD:BE:EF:00:01';
  det.Signal := 82;
  det.Security := 'WPA2';
  det.State := '100 (connected)';

  FService.SetMockDetails(det);

  det := FService.GetConnectionDetails();
  AssertEquals('SSID must match mock', 'OfficeNet', det.Ssid);
  AssertEquals('IP must match mock', '192.168.10.55/24', det.IpAddress);
  AssertEquals('Gateway must match mock', '192.168.10.1', det.Gateway);
  AssertEquals('MAC must match mock', 'DE:AD:BE:EF:00:01', det.HwAddr);
end;

procedure TConfigWlanTest.TestConnectAndDisconnect();
var
  det: TWlanConnectionDetails;
begin
  AssertTrue('Connect to HomeWifi must succeed', FService.Connect('HomeWifi', 'secret123'));
  det := FService.GetConnectionDetails();
  AssertEquals('Connected SSID must be HomeWifi', 'HomeWifi', det.Ssid);

  AssertTrue('Disconnect must succeed', FService.Disconnect());
  det := FService.GetConnectionDetails();
  AssertEquals('Disconnected SSID must be empty', '', det.Ssid);

  AssertTrue('Forget must succeed', FService.Forget('HomeWifi'));
end;

initialization
  RegisterTest(TConfigWlanTest);

end.

// configsama.wired.test.pas — unit tests for Wired service and parser
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Wired.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Wired;

type
  { TConfigWiredTest }
  TConfigWiredTest = class(TTestCase)
  private
    FService: TConfigWiredService;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockModeToggle();
    procedure TestMockInterfaces();
    procedure TestConnectAndDisconnect();
  end;

implementation

procedure TConfigWiredTest.SetUp();
begin
  FService := TConfigWiredService.Create();
  FService.EnableMockMode(True);
end;

procedure TConfigWiredTest.TearDown();
begin
  if FService <> nil then
  begin
    FService.Free();
    FService := nil;
  end;
end;

procedure TConfigWiredTest.TestServiceSingleton();
begin
  AssertNotNull('WiredService singleton must be accessible', WiredService());
end;

procedure TConfigWiredTest.TestMockModeToggle();
begin
  FService.SetMockEnabled(True);
  AssertTrue('Wired must report enabled', FService.IsWiredEnabled());

  AssertTrue('SetWiredEnabled(False) must succeed', FService.SetWiredEnabled(False));
  AssertFalse('Wired must report disabled', FService.IsWiredEnabled());

  AssertTrue('SetWiredEnabled(True) must succeed', FService.SetWiredEnabled(True));
  AssertTrue('Wired must report enabled again', FService.IsWiredEnabled());
end;

procedure TConfigWiredTest.TestMockInterfaces();
var
  mockList: TWiredInterfaceArray;
  retList: TWiredInterfaceArray;
  primary: TWiredInterface;
begin
  SetLength(mockList, 2);

  mockList[0].Device := 'eth0';
  mockList[0].State := '100 (connected)';
  mockList[0].ConnectionName := 'Wired Connection 1';
  mockList[0].HwAddr := '00:11:22:33:44:55';
  mockList[0].IpAddress := '192.168.1.150/24';
  mockList[0].Gateway := '192.168.1.1';
  mockList[0].Dns := '1.1.1.1, 8.8.8.8';
  mockList[0].Speed := 1000;
  mockList[0].Duplex := 'full';
  mockList[0].Carrier := True;
  mockList[0].Mtu := 1500;
  mockList[0].IsConnected := True;

  mockList[1].Device := 'eth1';
  mockList[1].State := '20 (unavailable)';
  mockList[1].ConnectionName := '';
  mockList[1].HwAddr := '00:11:22:33:44:66';
  mockList[1].IpAddress := '';
  mockList[1].Gateway := '';
  mockList[1].Dns := '';
  mockList[1].Speed := 0;
  mockList[1].Duplex := 'unknown';
  mockList[1].Carrier := False;
  mockList[1].Mtu := 1500;
  mockList[1].IsConnected := False;

  FService.SetMockInterfaces(mockList);

  retList := FService.GetInterfaces();
  AssertEquals('Returned interfaces count must match mock count', 2, Length(retList));
  AssertEquals('First device must be eth0', 'eth0', retList[0].Device);
  AssertTrue('First device must be connected', retList[0].IsConnected);
  AssertEquals('First device speed must be 1000', 1000, retList[0].Speed);

  primary := FService.GetPrimaryInterface();
  AssertEquals('Primary device must be eth0', 'eth0', primary.Device);
  AssertTrue('Primary must be connected', primary.IsConnected);
end;

procedure TConfigWiredTest.TestConnectAndDisconnect();
var
  mockList: TWiredInterfaceArray;
  primary: TWiredInterface;
begin
  SetLength(mockList, 1);
  mockList[0].Device := 'eth0';
  mockList[0].State := '30 (disconnected)';
  mockList[0].IsConnected := False;
  mockList[0].Carrier := True;

  FService.SetMockInterfaces(mockList);

  AssertTrue('Connect must succeed', FService.Connect('eth0'));
  primary := FService.GetPrimaryInterface();
  AssertTrue('Device must report connected after connect', primary.IsConnected);

  AssertTrue('Disconnect must succeed', FService.Disconnect('eth0'));
  primary := FService.GetPrimaryInterface();
  AssertFalse('Device must report disconnected after disconnect', primary.IsConnected);
end;

initialization
  RegisterTest(TConfigWiredTest);

end.

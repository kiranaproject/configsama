// configsama.power.test.pas — unit tests for Power service layer
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Power.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Power;

type
  { TConfigPowerTest }
  TConfigPowerTest = class(TTestCase)
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockBatteryStatus();
    procedure TestMockPowerMode();
    procedure TestMockScreenBlank();
    procedure TestMockAutoSuspend();
  end;

implementation

procedure TConfigPowerTest.SetUp();
begin
  PowerService().EnableMockMode(True);
end;

procedure TConfigPowerTest.TearDown();
begin
  PowerService().EnableMockMode(False);
end;

procedure TConfigPowerTest.TestServiceSingleton();
var
  svc1, svc2: TConfigPowerService;
begin
  svc1 := PowerService();
  svc2 := PowerService();
  AssertNotNull('PowerService must return non-nil instance', svc1);
  AssertTrue('PowerService must return identical singleton', svc1 = svc2);
end;

procedure TConfigPowerTest.TestMockBatteryStatus();
var
  svc: TConfigPowerService;
begin
  svc := PowerService();
  svc.SetMockBattery(True, 85, 'Discharging', False);

  AssertTrue('Battery is present', svc.IsBatteryPresent());
  AssertEquals('Battery percentage is 85', 85, svc.GetBatteryPercentage());
  AssertEquals('Battery status is Discharging', 'Discharging', svc.GetBatteryStatus());
  AssertFalse('AC is offline', svc.IsAcOnline());
  AssertTrue('Time remaining string present', Length(svc.GetTimeRemaining()) > 0);
end;

procedure TConfigPowerTest.TestMockPowerMode();
var
  svc: TConfigPowerService;
begin
  svc := PowerService();

  AssertTrue('Set Power Saver succeeds', svc.SetPowerMode('Power Saver'));
  AssertEquals('Power mode is Power Saver', 'Power Saver', svc.GetPowerMode());

  AssertTrue('Set Performance succeeds', svc.SetPowerMode('Performance'));
  AssertEquals('Power mode is Performance', 'Performance', svc.GetPowerMode());
end;

procedure TConfigPowerTest.TestMockScreenBlank();
var
  svc: TConfigPowerService;
begin
  svc := PowerService();

  AssertTrue('Set screen blank 15 min succeeds', svc.SetScreenBlankDelay(15));
  AssertEquals('Screen blank delay is 15', 15, svc.GetScreenBlankDelay());

  AssertTrue('Set screen blank never (0) succeeds', svc.SetScreenBlankDelay(0));
  AssertEquals('Screen blank delay is 0', 0, svc.GetScreenBlankDelay());
end;

procedure TConfigPowerTest.TestMockAutoSuspend();
var
  svc: TConfigPowerService;
begin
  svc := PowerService();

  AssertTrue('Set auto suspend false succeeds', svc.SetAutoSuspendEnabled(False));
  AssertFalse('Auto suspend is false', svc.IsAutoSuspendEnabled());

  AssertTrue('Set auto suspend true succeeds', svc.SetAutoSuspendEnabled(True));
  AssertTrue('Auto suspend is true', svc.IsAutoSuspendEnabled());
end;

initialization
  RegisterTest(TConfigPowerTest);

end.

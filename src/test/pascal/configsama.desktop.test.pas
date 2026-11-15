// configsama.desktop.test.pas — unit tests for Desktop and Dock service layer
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Desktop.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Desktop;

type
  { TConfigDesktopTest }
  TConfigDesktopTest = class(TTestCase)
  private
    FChangedCount: Integer;
    procedure HandleChange(Sender: TObject);
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockModeToggle();
    procedure TestMockDockPosition();
    procedure TestMockDockIconSize();
    procedure TestMockDockAutoHide();
    procedure TestMockDockMargin();
    procedure TestMockPanelSettings();
    procedure TestChangeNotification();
  end;

implementation

procedure TConfigDesktopTest.HandleChange(Sender: TObject);
begin
  Inc(FChangedCount);
end;

procedure TConfigDesktopTest.SetUp();
begin
  FChangedCount := 0;
  DesktopService().EnableMockMode(True);
  DesktopService().OnChange := @HandleChange;
  DesktopService().SetMockDockSettings('Bottom', 48, False, 3);
  DesktopService().SetMockPanelSettings(True, '24h');
  FChangedCount := 0;
end;

procedure TConfigDesktopTest.TearDown();
begin
  DesktopService().OnChange := nil;
  DesktopService().SetMockDockSettings('Bottom', 48, False, 3);
  DesktopService().SetMockPanelSettings(True, '24h');
  DesktopService().EnableMockMode(False);
end;

procedure TConfigDesktopTest.TestServiceSingleton();
var
  svc1, svc2: TConfigDesktopService;
begin
  svc1 := DesktopService();
  svc2 := DesktopService();
  AssertNotNull('DesktopService must return non-nil instance', svc1);
  AssertTrue('DesktopService must return identical singleton', svc1 = svc2);
end;

procedure TConfigDesktopTest.TestMockModeToggle();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertTrue('Mock mode is initially true in SetUp', svc.IsMockMode());
  svc.EnableMockMode(False);
  AssertFalse('Mock mode is disabled', svc.IsMockMode());
  svc.EnableMockMode(True);
  AssertTrue('Mock mode is re-enabled', svc.IsMockMode());
end;

procedure TConfigDesktopTest.TestMockDockPosition();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertEquals('Default dock position is Bottom', 'Bottom', svc.GetDockPosition());

  svc.SetDockPosition('Left');
  AssertEquals('Dock position updated to Left', 'Left', svc.GetDockPosition());

  svc.SetDockPosition('Right');
  AssertEquals('Dock position updated to Right', 'Right', svc.GetDockPosition());

  svc.SetDockPosition('Bottom');
  AssertEquals('Dock position reverted to Bottom', 'Bottom', svc.GetDockPosition());
end;

procedure TConfigDesktopTest.TestMockDockIconSize();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertEquals('Default icon size is 48', 48, svc.GetDockIconSize());

  svc.SetDockIconSize(32);
  AssertEquals('Icon size updated to 32', 32, svc.GetDockIconSize());

  svc.SetDockIconSize(64);
  AssertEquals('Icon size updated to 64', 64, svc.GetDockIconSize());

  svc.SetDockIconSize(24);
  AssertEquals('Icon size updated to 24', 24, svc.GetDockIconSize());
end;

procedure TConfigDesktopTest.TestMockDockAutoHide();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertFalse('Default auto-hide is False', svc.GetDockAutoHide());

  svc.SetDockAutoHide(True);
  AssertTrue('Auto-hide enabled', svc.GetDockAutoHide());

  svc.SetDockAutoHide(False);
  AssertFalse('Auto-hide disabled', svc.GetDockAutoHide());
end;

procedure TConfigDesktopTest.TestMockDockMargin();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertEquals('Default dock margin is 3', 3, svc.GetDockMargin());

  svc.SetDockMargin(0);
  AssertEquals('Dock margin updated to 0', 0, svc.GetDockMargin());

  svc.SetDockMargin(5);
  AssertEquals('Dock margin updated to 5', 5, svc.GetDockMargin());

  svc.SetDockMargin(8);
  AssertEquals('Dock margin updated to 8', 8, svc.GetDockMargin());
end;

procedure TConfigDesktopTest.TestMockPanelSettings();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertTrue('Default show desktop button is True', svc.GetShowDesktopButton());
  AssertEquals('Default clock format is 24h', '24h', svc.GetClockFormat());

  svc.SetShowDesktopButton(False);
  AssertFalse('Show desktop button disabled', svc.GetShowDesktopButton());

  svc.SetClockFormat('12h');
  AssertEquals('Clock format set to 12h', '12h', svc.GetClockFormat());
end;

procedure TConfigDesktopTest.TestChangeNotification();
var
  svc: TConfigDesktopService;
begin
  svc := DesktopService();
  AssertEquals('Initial change count is 0', 0, FChangedCount);

  svc.SetDockPosition('Left');
  AssertEquals('Change count incremented after dock position set', 1, FChangedCount);

  svc.SetDockIconSize(32);
  AssertEquals('Change count incremented after icon size set', 2, FChangedCount);

  svc.SetDockAutoHide(True);
  AssertEquals('Change count incremented after auto-hide set', 3, FChangedCount);

  svc.SetDockMargin(5);
  AssertEquals('Change count incremented after margin set', 4, FChangedCount);

  svc.SetShowDesktopButton(False);
  AssertEquals('Change count incremented after show desktop set', 5, FChangedCount);

  svc.SetClockFormat('12h');
  AssertEquals('Change count incremented after clock format set', 6, FChangedCount);
end;

initialization
  RegisterTest(TConfigDesktopTest);

end.

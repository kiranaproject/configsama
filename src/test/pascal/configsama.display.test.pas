// configsama.display.test.pas — unit tests for Display service and xrandr parser
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Display.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Display;

type
  { TConfigDisplayTest }
  TConfigDisplayTest = class(TTestCase)
  private
    FService: TConfigDisplayService;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockOutputs();
    procedure TestSetModeAndRotation();
    procedure TestSetBrightnessAndScale();
  end;

implementation

procedure TConfigDisplayTest.SetUp();
begin
  FService := TConfigDisplayService.Create();
  FService.EnableMockMode(True);
end;

procedure TConfigDisplayTest.TearDown();
begin
  if FService <> nil then
  begin
    FService.Free();
    FService := nil;
  end;
end;

procedure TConfigDisplayTest.TestServiceSingleton();
begin
  AssertNotNull('DisplayService singleton must be accessible', DisplayService());
end;

procedure TConfigDisplayTest.TestMockOutputs();
var
  mockOutputs: TDisplayOutputArray;
  retOutputs: TDisplayOutputArray;
  primary: TDisplayOutput;
begin
  SetLength(mockOutputs, 2);

  mockOutputs[0].Name := 'eDP-1';
  mockOutputs[0].IsConnected := True;
  mockOutputs[0].IsPrimary := True;
  mockOutputs[0].CurrentWidth := 1920;
  mockOutputs[0].CurrentHeight := 1080;
  mockOutputs[0].CurrentRate := 60.02;
  mockOutputs[0].CurrentRotation := 'normal';
  mockOutputs[0].BrightnessPercent := 85;

  SetLength(mockOutputs[0].Modes, 2);
  mockOutputs[0].Modes[0].ResolutionStr := '1920x1080';
  mockOutputs[0].Modes[0].Width := 1920;
  mockOutputs[0].Modes[0].Height := 1080;
  mockOutputs[0].Modes[0].IsCurrent := True;
  SetLength(mockOutputs[0].Modes[0].Rates, 1);
  mockOutputs[0].Modes[0].Rates[0] := 60.02;

  mockOutputs[0].Modes[1].ResolutionStr := '1680x1050';
  mockOutputs[0].Modes[1].Width := 1680;
  mockOutputs[0].Modes[1].Height := 1050;
  mockOutputs[0].Modes[1].IsCurrent := False;
  SetLength(mockOutputs[0].Modes[1].Rates, 1);
  mockOutputs[0].Modes[1].Rates[0] := 60.02;

  mockOutputs[1].Name := 'HDMI-1';
  mockOutputs[1].IsConnected := False;
  mockOutputs[1].IsPrimary := False;
  SetLength(mockOutputs[1].Modes, 0);

  FService.SetMockOutputs(mockOutputs);

  retOutputs := FService.QueryOutputs();
  AssertEquals('Outputs count must match mock count', 2, Length(retOutputs));
  AssertEquals('First output must be eDP-1', 'eDP-1', retOutputs[0].Name);
  AssertTrue('First output must be connected and primary', retOutputs[0].IsConnected and retOutputs[0].IsPrimary);

  primary := FService.GetPrimaryOutput();
  AssertEquals('Primary output must be eDP-1', 'eDP-1', primary.Name);
  AssertEquals('Primary width must be 1920', 1920, primary.CurrentWidth);
  AssertEquals('Primary height must be 1080', 1080, primary.CurrentHeight);
  AssertEquals('Primary modes count must be 2', 2, Length(primary.Modes));
end;

procedure TConfigDisplayTest.TestSetModeAndRotation();
var
  mockOutputs: TDisplayOutputArray;
  primary: TDisplayOutput;
begin
  SetLength(mockOutputs, 1);
  mockOutputs[0].Name := 'eDP-1';
  mockOutputs[0].IsConnected := True;
  mockOutputs[0].IsPrimary := True;
  mockOutputs[0].CurrentWidth := 1920;
  mockOutputs[0].CurrentHeight := 1080;
  mockOutputs[0].CurrentRate := 60.02;
  mockOutputs[0].CurrentRotation := 'normal';

  SetLength(mockOutputs[0].Modes, 2);
  mockOutputs[0].Modes[0].ResolutionStr := '1920x1080';
  mockOutputs[0].Modes[0].Width := 1920;
  mockOutputs[0].Modes[0].Height := 1080;
  mockOutputs[0].Modes[0].IsCurrent := True;

  mockOutputs[0].Modes[1].ResolutionStr := '1280x720';
  mockOutputs[0].Modes[1].Width := 1280;
  mockOutputs[0].Modes[1].Height := 720;
  mockOutputs[0].Modes[1].IsCurrent := False;

  FService.SetMockOutputs(mockOutputs);

  AssertTrue('SetMode must succeed', FService.SetMode('eDP-1', 1280, 720, 60.0));
  primary := FService.GetPrimaryOutput();
  AssertEquals('Width must update to 1280', 1280, primary.CurrentWidth);
  AssertEquals('Height must update to 720', 720, primary.CurrentHeight);

  AssertTrue('SetRotation to left must succeed', FService.SetRotation('eDP-1', 'left'));
  primary := FService.GetPrimaryOutput();
  AssertEquals('Rotation must update to left', 'left', primary.CurrentRotation);
end;

procedure TConfigDisplayTest.TestSetBrightnessAndScale();
var
  mockOutputs: TDisplayOutputArray;
  primary: TDisplayOutput;
begin
  SetLength(mockOutputs, 1);
  mockOutputs[0].Name := 'eDP-1';
  mockOutputs[0].IsConnected := True;
  mockOutputs[0].IsPrimary := True;
  mockOutputs[0].BrightnessPercent := 80;

  FService.SetMockOutputs(mockOutputs);

  AssertTrue('SetBrightness must succeed', FService.SetBrightness('eDP-1', 65));
  primary := FService.GetPrimaryOutput();
  AssertEquals('Brightness must update to 65', 65, primary.BrightnessPercent);

  AssertTrue('SetScale must succeed', FService.SetScale('eDP-1', 125));
end;

initialization
  RegisterTest(TConfigDisplayTest);

end.

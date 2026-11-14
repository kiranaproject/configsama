// configsama.sound.test.pas — unit tests for Sound service layer
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Sound.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ConfigSama.Sound;

type
  { TConfigSoundTest }
  TConfigSoundTest = class(TTestCase)
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestServiceSingleton();
    procedure TestMockVolumeAndMute();
    procedure TestMockInputControls();
    procedure TestMockDevices();
    procedure TestSoundEffectsToggle();
  end;

implementation

procedure TConfigSoundTest.SetUp();
begin
  SoundService().EnableMockMode(True);
end;

procedure TConfigSoundTest.TearDown();
begin
  SoundService().EnableMockMode(False);
end;

procedure TConfigSoundTest.TestServiceSingleton();
var
  svc1, svc2: TConfigSoundService;
begin
  svc1 := SoundService();
  svc2 := SoundService();
  AssertNotNull('SoundService must return non-nil instance', svc1);
  AssertTrue('SoundService must return identical singleton', svc1 = svc2);
end;

procedure TConfigSoundTest.TestMockVolumeAndMute();
var
  svc: TConfigSoundService;
begin
  svc := SoundService();

  svc.SetOutputVolume(75);
  AssertEquals('Output volume must be 75', 75, svc.GetOutputVolume());

  svc.SetOutputMuted(True);
  AssertTrue('Output must be muted', svc.IsOutputMuted());

  svc.SetOutputMuted(False);
  AssertFalse('Output must be unmuted', svc.IsOutputMuted());
end;

procedure TConfigSoundTest.TestMockInputControls();
var
  svc: TConfigSoundService;
begin
  svc := SoundService();

  svc.SetInputVolume(65);
  AssertEquals('Input volume must be 65', 65, svc.GetInputVolume());

  svc.SetInputMuted(True);
  AssertTrue('Input must be muted', svc.IsInputMuted());

  svc.SetInputMuted(False);
  AssertFalse('Input must be unmuted', svc.IsInputMuted());
end;

procedure TConfigSoundTest.TestMockDevices();
var
  svc: TConfigSoundService;
  outputs, inputs: TSoundDeviceArray;
begin
  svc := SoundService();

  outputs := svc.GetOutputDevices();
  AssertTrue('Mock outputs count > 0', Length(outputs) > 0);
  AssertEquals('Default output sink ID', '55', outputs[0].ID);
  AssertTrue('Default output sink is default', outputs[0].IsDefault);

  inputs := svc.GetInputDevices();
  AssertTrue('Mock inputs count > 0', Length(inputs) > 0);
  AssertEquals('Default input source ID', '56', inputs[0].ID);
  AssertTrue('Default input source is default', inputs[0].IsDefault);
end;

procedure TConfigSoundTest.TestSoundEffectsToggle();
var
  svc: TConfigSoundService;
begin
  svc := SoundService();

  svc.SetSoundEffectsEnabled(False);
  AssertFalse('Sound effects disabled', svc.AreSoundEffectsEnabled());

  svc.SetSoundEffectsEnabled(True);
  AssertTrue('Sound effects re-enabled', svc.AreSoundEffectsEnabled());

  AssertTrue('PlayTestSound succeeds in mock mode', svc.PlayTestSound());
end;

initialization
  RegisterTest(TConfigSoundTest);

end.

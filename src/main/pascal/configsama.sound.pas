// configsama.sound.pas — Sound and Audio service using PipeWire/WirePlumber (wpctl) & PulseAudio (pactl)
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Sound;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TSoundDevice = record
    ID: string;           // Device / node ID e.g. "55"
    Name: string;         // e.g. "Built-in Audio Analog Stereo"
    Description: string;
    IsDefault: Boolean;
    IsSink: Boolean;      // True for Output Sink, False for Input Source
    Volume: Integer;      // 0..100
    Muted: Boolean;
  end;
  TSoundDeviceArray = array of TSoundDevice;

  TConfigSoundService = class
  private
    FMockMode: Boolean;
    FMockOutputVolume: Integer;
    FMockOutputMuted: Boolean;
    FMockInputVolume: Integer;
    FMockInputMuted: Boolean;
    FMockSoundEffects: Boolean;
    FMockOutputDevices: TSoundDeviceArray;
    FMockInputDevices: TSoundDeviceArray;

    function RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
    procedure InitDefaultMockDevices();
  public
    constructor Create();
    destructor Destroy(); override;

    function IsAvailable(): Boolean;

    // Output Controls
    function GetOutputVolume(): Integer;
    function SetOutputVolume(AVolume: Integer): Boolean;
    function IsOutputMuted(): Boolean;
    function SetOutputMuted(AMuted: Boolean): Boolean;
    function GetOutputDevices(): TSoundDeviceArray;
    function SetDefaultOutputDevice(const AID: string): Boolean;

    // Input Controls
    function GetInputVolume(): Integer;
    function SetInputVolume(AVolume: Integer): Boolean;
    function IsInputMuted(): Boolean;
    function SetInputMuted(AMuted: Boolean): Boolean;
    function GetInputDevices(): TSoundDeviceArray;
    function SetDefaultInputDevice(const AID: string): Boolean;

    // Sound Effects
    function AreSoundEffectsEnabled(): Boolean;
    function SetSoundEffectsEnabled(AEnabled: Boolean): Boolean;
    function PlayTestSound(): Boolean;

    // Test seam / Mocking
    procedure EnableMockMode(const AEnabled: Boolean = True);
    procedure SetMockOutputVolume(AVolume: Integer);
    procedure SetMockOutputMuted(AMuted: Boolean);
    procedure SetMockInputVolume(AVolume: Integer);
    procedure SetMockInputMuted(AMuted: Boolean);
    procedure SetMockSoundEffects(AEnabled: Boolean);
    procedure SetMockOutputDevices(const ADevices: TSoundDeviceArray);
    procedure SetMockInputDevices(const ADevices: TSoundDeviceArray);
  end;

function SoundService(): TConfigSoundService;

implementation

var
  GSoundService: TConfigSoundService = nil;

function SoundService(): TConfigSoundService;
begin
  if GSoundService = nil then
    GSoundService := TConfigSoundService.Create();
  Result := GSoundService;
end;

constructor TConfigSoundService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockOutputVolume := 80;
  FMockOutputMuted := False;
  FMockInputVolume := 50;
  FMockInputMuted := False;
  FMockSoundEffects := True;
  InitDefaultMockDevices();
end;

destructor TConfigSoundService.Destroy();
begin
  SetLength(FMockOutputDevices, 0);
  SetLength(FMockInputDevices, 0);
  inherited Destroy();
end;

procedure TConfigSoundService.InitDefaultMockDevices();
begin
  SetLength(FMockOutputDevices, 2);
  FMockOutputDevices[0].ID := '55';
  FMockOutputDevices[0].Name := 'Built-in Audio Analog Stereo';
  FMockOutputDevices[0].Description := 'Internal Speakers';
  FMockOutputDevices[0].IsDefault := True;
  FMockOutputDevices[0].IsSink := True;
  FMockOutputDevices[0].Volume := 80;
  FMockOutputDevices[0].Muted := False;

  FMockOutputDevices[1].ID := '60';
  FMockOutputDevices[1].Name := 'HDMI / DisplayPort Audio';
  FMockOutputDevices[1].Description := 'External Monitor Audio';
  FMockOutputDevices[1].IsDefault := False;
  FMockOutputDevices[1].IsSink := True;
  FMockOutputDevices[1].Volume := 100;
  FMockOutputDevices[1].Muted := False;

  SetLength(FMockInputDevices, 2);
  FMockInputDevices[0].ID := '56';
  FMockInputDevices[0].Name := 'Built-in Audio Analog Stereo';
  FMockInputDevices[0].Description := 'Internal Microphone';
  FMockInputDevices[0].IsDefault := True;
  FMockInputDevices[0].IsSink := False;
  FMockInputDevices[0].Volume := 50;
  FMockInputDevices[0].Muted := False;

  FMockInputDevices[1].ID := '70';
  FMockInputDevices[1].Name := 'Headset Microphone';
  FMockInputDevices[1].Description := '3.5mm Headset Jack';
  FMockInputDevices[1].IsDefault := False;
  FMockInputDevices[1].IsSink := False;
  FMockInputDevices[1].Volume := 60;
  FMockInputDevices[1].Muted := False;
end;

function TConfigSoundService.RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
var
  p: TProcess;
  buf: array[0..2047] of AnsiChar;
  bytesRead: Integer;
  mem: TMemoryStream;
  outputStr: string;
begin
  AOutput := '';
  p := TProcess.Create(nil);
  mem := TMemoryStream.Create();
  try
    p.Executable := '/bin/sh';
    p.Parameters.Add('-c');
    p.Parameters.Add(ACmd);
    p.Options := [poUsePipes, poStderrToOutPut];

    try
      p.Execute();
    except
      Result := False;
      Exit;
    end;

    while p.Running do
    begin
      bytesRead := p.Output.Read(buf, SizeOf(buf));
      if bytesRead > 0 then
        mem.Write(buf, bytesRead)
      else
        Sleep(10);
    end;

    repeat
      bytesRead := p.Output.Read(buf, SizeOf(buf));
      if bytesRead > 0 then
        mem.Write(buf, bytesRead);
    until bytesRead <= 0;

    Result := (p.ExitStatus = 0);

    if mem.Size > 0 then
    begin
      mem.Position := 0;
      SetLength(outputStr, mem.Size);
      mem.Read(outputStr[1], mem.Size);
      AOutput := outputStr;
    end;
  finally
    p.Free();
    mem.Free();
  end;
end;

function TConfigSoundService.IsAvailable(): Boolean;
begin
  if FMockMode then
    Exit(True);

  Result := FileExists('/usr/bin/wpctl') or FileExists('/usr/bin/pactl');
end;

function TConfigSoundService.GetOutputVolume(): Integer;
var
  outText, numStr: string;
  p, p2: Integer;
  val: Double;
  fs: TFormatSettings;
begin
  if FMockMode then
    Exit(FMockOutputVolume);

  fs.DecimalSeparator := '.';
  if RunCommandOutput('wpctl get-volume @DEFAULT_AUDIO_SINK@', outText) then
  begin
    p := Pos('Volume: ', outText);
    if p > 0 then
    begin
      numStr := Trim(Copy(outText, p + 8, Length(outText)));
      p2 := Pos(' ', numStr);
      if p2 > 0 then
        numStr := Copy(numStr, 1, p2 - 1);
      if TryStrToFloat(numStr, val, fs) then
        Exit(Round(val * 100));
    end;
  end;

  Result := 100;
end;

function TConfigSoundService.SetOutputVolume(AVolume: Integer): Boolean;
var
  outText: string;
  val: Double;
begin
  if AVolume < 0 then AVolume := 0;
  if AVolume > 150 then AVolume := 150;

  if FMockMode then
  begin
    FMockOutputVolume := AVolume;
    Exit(True);
  end;

  val := AVolume / 100.0;
  Result := RunCommandOutput(Format('wpctl set-volume @DEFAULT_AUDIO_SINK@ %.2f', [val]), outText);
end;

function TConfigSoundService.IsOutputMuted(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(FMockOutputMuted);

  if RunCommandOutput('wpctl get-volume @DEFAULT_AUDIO_SINK@', outText) then
    Result := (Pos('[MUTED]', outText) > 0)
  else
    Result := False;
end;

function TConfigSoundService.SetOutputMuted(AMuted: Boolean): Boolean;
var
  outText: string;
  flag: Integer;
begin
  if FMockMode then
  begin
    FMockOutputMuted := AMuted;
    Exit(True);
  end;

  if AMuted then flag := 1 else flag := 0;
  Result := RunCommandOutput(Format('wpctl set-mute @DEFAULT_AUDIO_SINK@ %d', [flag]), outText);
end;

function TConfigSoundService.GetOutputDevices(): TSoundDeviceArray;
var
  outText, line, idStr, nameStr: string;
  lines: TStringList;
  i, inSinks, count, pDot, pCol: Integer;
  isDef: Boolean;
begin
  if FMockMode then
    Exit(FMockOutputDevices);

  SetLength(Result, 0);
  if not RunCommandOutput('wpctl status', outText) then
    Exit;

  lines := TStringList.Create();
  try
    lines.Text := outText;
    inSinks := 0;
    count := 0;

    for i := 0 to lines.Count - 1 do
    begin
      line := lines[i];
      if Pos('Sinks:', line) > 0 then
      begin
        inSinks := 1;
        Continue;
      end;
      if (inSinks = 1) and (Pos('Sources:', line) > 0) then
      begin
        inSinks := 0;
        Break;
      end;

      if inSinks = 1 then
      begin
        isDef := (Pos('*', line) > 0);
        pDot := Pos('.', line);
        if pDot > 0 then
        begin
          idStr := Trim(Copy(line, 1, pDot - 1));
          idStr := StringReplace(idStr, '*', '', [rfReplaceAll]);
          idStr := Trim(StringReplace(idStr, '│', '', [rfReplaceAll]));

          nameStr := Trim(Copy(line, pDot + 1, Length(line)));
          pCol := Pos('[', nameStr);
          if pCol > 0 then
            nameStr := Trim(Copy(nameStr, 1, pCol - 1));

          if (idStr <> '') and (nameStr <> '') then
          begin
            Inc(count);
            SetLength(Result, count);
            Result[count - 1].ID := idStr;
            Result[count - 1].Name := nameStr;
            Result[count - 1].Description := nameStr;
            Result[count - 1].IsDefault := isDef;
            Result[count - 1].IsSink := True;
            Result[count - 1].Volume := GetOutputVolume();
            Result[count - 1].Muted := IsOutputMuted();
          end;
        end;
      end;
    end;

    if count = 0 then
    begin
      // Fallback default output
      SetLength(Result, 1);
      Result[0].ID := '@DEFAULT_AUDIO_SINK@';
      Result[0].Name := 'Default Audio Sink';
      Result[0].Description := 'Default System Output';
      Result[0].IsDefault := True;
      Result[0].IsSink := True;
      Result[0].Volume := GetOutputVolume();
      Result[0].Muted := IsOutputMuted();
    end;
  finally
    lines.Free();
  end;
end;

function TConfigSoundService.SetDefaultOutputDevice(const AID: string): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(True);

  Result := RunCommandOutput('wpctl set-default ' + AID, outText);
end;

function TConfigSoundService.GetInputVolume(): Integer;
var
  outText, numStr: string;
  p, p2: Integer;
  val: Double;
  fs: TFormatSettings;
begin
  if FMockMode then
    Exit(FMockInputVolume);

  fs.DecimalSeparator := '.';
  if RunCommandOutput('wpctl get-volume @DEFAULT_AUDIO_SOURCE@', outText) then
  begin
    p := Pos('Volume: ', outText);
    if p > 0 then
    begin
      numStr := Trim(Copy(outText, p + 8, Length(outText)));
      p2 := Pos(' ', numStr);
      if p2 > 0 then
        numStr := Copy(numStr, 1, p2 - 1);
      if TryStrToFloat(numStr, val, fs) then
        Exit(Round(val * 100));
    end;
  end;

  Result := 50;
end;

function TConfigSoundService.SetInputVolume(AVolume: Integer): Boolean;
var
  outText: string;
  val: Double;
begin
  if AVolume < 0 then AVolume := 0;
  if AVolume > 150 then AVolume := 150;

  if FMockMode then
  begin
    FMockInputVolume := AVolume;
    Exit(True);
  end;

  val := AVolume / 100.0;
  Result := RunCommandOutput(Format('wpctl set-volume @DEFAULT_AUDIO_SOURCE@ %.2f', [val]), outText);
end;

function TConfigSoundService.IsInputMuted(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(FMockInputMuted);

  if RunCommandOutput('wpctl get-volume @DEFAULT_AUDIO_SOURCE@', outText) then
    Result := (Pos('[MUTED]', outText) > 0)
  else
    Result := False;
end;

function TConfigSoundService.SetInputMuted(AMuted: Boolean): Boolean;
var
  outText: string;
  flag: Integer;
begin
  if FMockMode then
  begin
    FMockInputMuted := AMuted;
    Exit(True);
  end;

  if AMuted then flag := 1 else flag := 0;
  Result := RunCommandOutput(Format('wpctl set-mute @DEFAULT_AUDIO_SOURCE@ %d', [flag]), outText);
end;

function TConfigSoundService.GetInputDevices(): TSoundDeviceArray;
var
  outText, line, idStr, nameStr: string;
  lines: TStringList;
  i, inSources, count, pDot, pCol: Integer;
  isDef: Boolean;
begin
  if FMockMode then
    Exit(FMockInputDevices);

  SetLength(Result, 0);
  if not RunCommandOutput('wpctl status', outText) then
    Exit;

  lines := TStringList.Create();
  try
    lines.Text := outText;
    inSources := 0;
    count := 0;

    for i := 0 to lines.Count - 1 do
    begin
      line := lines[i];
      if Pos('Sources:', line) > 0 then
      begin
        inSources := 1;
        Continue;
      end;
      if (inSources = 1) and (Pos('Filters:', line) > 0) then
      begin
        inSources := 0;
        Break;
      end;

      if inSources = 1 then
      begin
        isDef := (Pos('*', line) > 0);
        pDot := Pos('.', line);
        if pDot > 0 then
        begin
          idStr := Trim(Copy(line, 1, pDot - 1));
          idStr := StringReplace(idStr, '*', '', [rfReplaceAll]);
          idStr := Trim(StringReplace(idStr, '│', '', [rfReplaceAll]));

          nameStr := Trim(Copy(line, pDot + 1, Length(line)));
          pCol := Pos('[', nameStr);
          if pCol > 0 then
            nameStr := Trim(Copy(nameStr, 1, pCol - 1));

          if (idStr <> '') and (nameStr <> '') then
          begin
            Inc(count);
            SetLength(Result, count);
            Result[count - 1].ID := idStr;
            Result[count - 1].Name := nameStr;
            Result[count - 1].Description := nameStr;
            Result[count - 1].IsDefault := isDef;
            Result[count - 1].IsSink := False;
            Result[count - 1].Volume := GetInputVolume();
            Result[count - 1].Muted := IsInputMuted();
          end;
        end;
      end;
    end;

    if count = 0 then
    begin
      SetLength(Result, 1);
      Result[0].ID := '@DEFAULT_AUDIO_SOURCE@';
      Result[0].Name := 'Default Audio Source';
      Result[0].Description := 'Default System Input';
      Result[0].IsDefault := True;
      Result[0].IsSink := False;
      Result[0].Volume := GetInputVolume();
      Result[0].Muted := IsInputMuted();
    end;
  finally
    lines.Free();
  end;
end;

function TConfigSoundService.SetDefaultInputDevice(const AID: string): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(True);

  Result := RunCommandOutput('wpctl set-default ' + AID, outText);
end;

function TConfigSoundService.AreSoundEffectsEnabled(): Boolean;
begin
  Result := FMockSoundEffects;
end;

function TConfigSoundService.SetSoundEffectsEnabled(AEnabled: Boolean): Boolean;
begin
  FMockSoundEffects := AEnabled;
  Result := True;
end;

function TConfigSoundService.PlayTestSound(): Boolean;
var
  outText: string;
begin
  if FMockMode then
    Exit(True);

  if FileExists('/usr/share/sounds/freedesktop/stereo/bell.oga') then
    Result := RunCommandOutput('pw-play /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null || paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null', outText)
  else
    Result := RunCommandOutput('printf "\a"', outText);
end;

procedure TConfigSoundService.EnableMockMode(const AEnabled: Boolean);
begin
  FMockMode := AEnabled;
  if AEnabled and (Length(FMockOutputDevices) = 0) then
    InitDefaultMockDevices();
end;

procedure TConfigSoundService.SetMockOutputVolume(AVolume: Integer);
begin
  FMockOutputVolume := AVolume;
end;

procedure TConfigSoundService.SetMockOutputMuted(AMuted: Boolean);
begin
  FMockOutputMuted := AMuted;
end;

procedure TConfigSoundService.SetMockInputVolume(AVolume: Integer);
begin
  FMockInputVolume := AVolume;
end;

procedure TConfigSoundService.SetMockInputMuted(AMuted: Boolean);
begin
  FMockInputMuted := AMuted;
end;

procedure TConfigSoundService.SetMockSoundEffects(AEnabled: Boolean);
begin
  FMockSoundEffects := AEnabled;
end;

procedure TConfigSoundService.SetMockOutputDevices(const ADevices: TSoundDeviceArray);
var
  i: Integer;
begin
  SetLength(FMockOutputDevices, Length(ADevices));
  for i := 0 to High(ADevices) do
    FMockOutputDevices[i] := ADevices[i];
end;

procedure TConfigSoundService.SetMockInputDevices(const ADevices: TSoundDeviceArray);
var
  i: Integer;
begin
  SetLength(FMockInputDevices, Length(ADevices));
  for i := 0 to High(ADevices) do
    FMockInputDevices[i] := ADevices[i];
end;

end.

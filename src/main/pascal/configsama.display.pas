// configsama.display.pas — Display management service using xrandr and backlight
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Display;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TDisplayMode = record
    Width: Integer;
    Height: Integer;
    ResolutionStr: string;   // e.g. "1920x1080"
    Rates: array of Double;  // [60.02, 59.94]
    CurrentRate: Double;
    IsCurrent: Boolean;
    IsPreferred: Boolean;
  end;
  TDisplayModeArray = array of TDisplayMode;

  TDisplayOutput = record
    Name: string;            // e.g. "eDP-1", "HDMI-1"
    IsConnected: Boolean;
    IsPrimary: Boolean;
    CurrentWidth: Integer;
    CurrentHeight: Integer;
    CurrentRate: Double;
    CurrentRotation: string; // "normal", "left", "inverted", "right"
    BrightnessPercent: Integer; // 0..100
    Modes: TDisplayModeArray;
  end;
  TDisplayOutputArray = array of TDisplayOutput;

  TConfigDisplayService = class
  private
    FMockMode: Boolean;
    FMockOutputs: TDisplayOutputArray;
    FMockBrightness: Integer;

    function RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
    function ReadSysfsInteger(const APath: string; ADefault: Integer = 0): Integer;
    function ReadBacklightBrightness(): Integer;
    procedure ParseXrandrOutput(const ARaw: string; out AOutputs: TDisplayOutputArray);
    function ParseFloatInvariant(const AStr: string; ADefault: Double = 60.0): Double;
  public
    constructor Create();
    destructor Destroy(); override;

    function IsAvailable(): Boolean;
    function QueryOutputs(): TDisplayOutputArray;
    function GetPrimaryOutput(): TDisplayOutput;
    function GetOutput(const AName: string): TDisplayOutput;

    function SetMode(const AOutputName: string; AWidth, AHeight: Integer; ARate: Double = 0.0): Boolean;
    function SetRotation(const AOutputName: string; const ARotation: string): Boolean;
    function SetBrightness(const AOutputName: string; APercent: Integer): Boolean;
    function SetScale(const AOutputName: string; AScalePercent: Integer): Boolean;

    // Test seam / Mocking
    procedure EnableMockMode(const AEnabled: Boolean = True);
    procedure SetMockOutputs(const AOutputs: TDisplayOutputArray);
    procedure SetMockBrightness(AValue: Integer);
  end;

function DisplayService(): TConfigDisplayService;

implementation

var
  GDisplayService: TConfigDisplayService = nil;

function DisplayService(): TConfigDisplayService;
begin
  if GDisplayService = nil then
    GDisplayService := TConfigDisplayService.Create();
  Result := GDisplayService;
end;

constructor TConfigDisplayService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockBrightness := 80;
  SetLength(FMockOutputs, 0);
end;

destructor TConfigDisplayService.Destroy();
begin
  SetLength(FMockOutputs, 0);
  inherited Destroy();
end;

function TConfigDisplayService.RunCommandOutput(const ACmd: string; out AOutput: string): Boolean;
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
    p.ShowWindow := swoNone;
    p.Execute();

    while p.Running or (p.Output.NumBytesAvailable > 0) do
    begin
      if p.Output.NumBytesAvailable > 0 then
      begin
        bytesRead := p.Output.Read(buf[0], SizeOf(buf));
        if bytesRead > 0 then
          mem.Write(buf[0], bytesRead);
      end
      else
        Sleep(10);
    end;

    p.WaitOnExit();
    Result := (p.ExitStatus = 0);

    if mem.Size > 0 then
    begin
      mem.Position := 0;
      SetLength(outputStr, mem.Size);
      mem.Read(outputStr[1], mem.Size);
      AOutput := Trim(outputStr);
    end;
  except
    on E: Exception do
    begin
      AOutput := '';
      Result := False;
    end;
  end;
  mem.Free();
  p.Free();
end;

function TConfigDisplayService.ReadSysfsInteger(const APath: string; ADefault: Integer = 0): Integer;
var
  sl: TStringList;
begin
  Result := ADefault;
  if not FileExists(APath) then Exit();
  sl := TStringList.Create();
  try
    sl.LoadFromFile(APath);
    if sl.Count > 0 then
      Result := StrToIntDef(Trim(sl[0]), ADefault);
  except
    Result := ADefault;
  end;
  sl.Free();
end;

function TConfigDisplayService.ReadBacklightBrightness(): Integer;
var
  rec: TSearchRec;
  baseDir, subDir: string;
  actual, max: Integer;
begin
  Result := 100;
  baseDir := '/sys/class/backlight/';
  if not DirectoryExists(baseDir) then Exit();

  if FindFirst(baseDir + '*', faDirectory, rec) = 0 then
  begin
    try
      repeat
        if (rec.Name <> '.') and (rec.Name <> '..') then
        begin
          subDir := baseDir + rec.Name + '/';
          max := ReadSysfsInteger(subDir + 'max_brightness', 0);
          if max > 0 then
          begin
            actual := ReadSysfsInteger(subDir + 'actual_brightness', -1);
            if actual < 0 then
              actual := ReadSysfsInteger(subDir + 'brightness', max);
            Result := Round((actual / max) * 100.0);
            if Result < 0 then Result := 0;
            if Result > 100 then Result := 100;
            Exit();
          end;
        end;
      until FindNext(rec) <> 0;
    finally
      FindClose(rec);
    end;
  end;
end;

function TConfigDisplayService.ParseFloatInvariant(const AStr: string; ADefault: Double = 60.0): Double;
var
  fs: TFormatSettings;
begin
  fs.DecimalSeparator := '.';
  if not TryStrToFloat(AStr, Result, fs) then
  begin
    fs.DecimalSeparator := ',';
    if not TryStrToFloat(AStr, Result, fs) then
      Result := ADefault;
  end;
end;

procedure TConfigDisplayService.ParseXrandrOutput(const ARaw: string; out AOutputs: TDisplayOutputArray);
var
  lines: TStringList;
  i, j, outIdx, modeIdx, pParen, pX, pPlus, rateCount: Integer;
  line, trimmed, tok, resStr, rateStr, beforeParen, geomStr: string;
  tokens: TStringList;
  currOut: TDisplayOutput;
  currMode: TDisplayMode;
  rateVal: Double;
  isCur, isPref: Boolean;
begin
  SetLength(AOutputs, 0);
  lines := TStringList.Create();
  tokens := TStringList.Create();
  try
    lines.Text := ARaw;
    outIdx := -1;

    for i := 0 to lines.Count - 1 do
    begin
      line := lines[i];
      if Trim(line) = '' then Continue;

      // Check if line is an output definition line (no leading whitespace, not "Screen ")
      if (line[1] <> ' ') and (line[1] <> #9) and (Pos('Screen ', line) <> 1) then
      begin
        // If previous output had modes, save it back
        if outIdx >= 0 then
          AOutputs[outIdx] := currOut;

        FillChar(currOut, SizeOf(currOut), 0);
        SetLength(currOut.Modes, 0);
        currOut.CurrentRotation := 'normal';
        currOut.BrightnessPercent := 100;

        tokens.Clear();
        tokens.Delimiter := ' ';
        tokens.StrictDelimiter := False;
        tokens.DelimitedText := line;

        if tokens.Count > 0 then
          currOut.Name := tokens[0];

        currOut.IsConnected := (Pos(' connected', line) > 0);
        currOut.IsPrimary := (Pos(' primary', line) > 0);

        // Parse rotation: check word right before '('
        pParen := Pos('(', line);
        if pParen > 0 then
        begin
          beforeParen := ' ' + Copy(line, 1, pParen - 1) + ' ';
          if Pos(' left ', beforeParen) > 0 then
            currOut.CurrentRotation := 'left'
          else if Pos(' inverted ', beforeParen) > 0 then
            currOut.CurrentRotation := 'inverted'
          else if Pos(' right ', beforeParen) > 0 then
            currOut.CurrentRotation := 'right'
          else
            currOut.CurrentRotation := 'normal';
        end;

        // Parse geometry e.g. "1920x1080+0+0"
        for j := 1 to tokens.Count - 1 do
        begin
          tok := tokens[j];
          pX := Pos('x', tok);
          pPlus := Pos('+', tok);
          if (pX > 1) and (pPlus > pX) then
          begin
            geomStr := Copy(tok, 1, pPlus - 1);
            pX := Pos('x', geomStr);
            currOut.CurrentWidth := StrToIntDef(Copy(geomStr, 1, pX - 1), 0);
            currOut.CurrentHeight := StrToIntDef(Copy(geomStr, pX + 1, Length(geomStr)), 0);
            Break;
          end;
        end;

        Inc(outIdx);
        SetLength(AOutputs, outIdx + 1);
        AOutputs[outIdx] := currOut;
      end
      else if (outIdx >= 0) and currOut.IsConnected and ((line[1] = ' ') or (line[1] = #9)) then
      begin
        // Mode line under connected output
        trimmed := Trim(line);
        tokens.Clear();
        tokens.Delimiter := ' ';
        tokens.StrictDelimiter := False;
        tokens.DelimitedText := trimmed;

        if tokens.Count >= 2 then
        begin
          resStr := tokens[0];
          pX := Pos('x', resStr);
          if pX > 1 then
          begin
            FillChar(currMode, SizeOf(currMode), 0);
            SetLength(currMode.Rates, 0);
            currMode.ResolutionStr := resStr;
            currMode.Width := StrToIntDef(Copy(resStr, 1, pX - 1), 0);
            currMode.Height := StrToIntDef(Copy(resStr, pX + 1, Length(resStr)), 0);

            rateCount := 0;
            for j := 1 to tokens.Count - 1 do
            begin
              tok := tokens[j];
              if tok = '' then Continue;

              isCur := (Pos('*', tok) > 0);
              isPref := (Pos('+', tok) > 0);

              rateStr := StringReplace(tok, '*', '', [rfReplaceAll]);
              rateStr := StringReplace(rateStr, '+', '', [rfReplaceAll]);
              rateStr := StringReplace(rateStr, 'i', '', [rfReplaceAll]);

              rateVal := ParseFloatInvariant(rateStr, 60.0);

              Inc(rateCount);
              SetLength(currMode.Rates, rateCount);
              currMode.Rates[rateCount - 1] := rateVal;

              if isCur then
              begin
                currMode.IsCurrent := True;
                currMode.CurrentRate := rateVal;
                currOut.CurrentRate := rateVal;
              end;
              if isPref then
                currMode.IsPreferred := True;
            end;

            modeIdx := Length(currOut.Modes);
            SetLength(currOut.Modes, modeIdx + 1);
            currOut.Modes[modeIdx] := currMode;
          end;
        end;
      end;
    end;

    // Save final output item
    if outIdx >= 0 then
      AOutputs[outIdx] := currOut;

  finally
    tokens.Free();
    lines.Free();
  end;
end;

function TConfigDisplayService.IsAvailable(): Boolean;
var
  raw: string;
begin
  if FMockMode then Exit(True);
  Result := RunCommandOutput('xrandr --version 2>/dev/null', raw);
end;

function TConfigDisplayService.QueryOutputs(): TDisplayOutputArray;
var
  raw: string;
  i, bl: Integer;
begin
  if FMockMode then
  begin
    Result := Copy(FMockOutputs);
    Exit();
  end;

  SetLength(Result, 0);
  if not RunCommandOutput('xrandr --current 2>/dev/null', raw) then
    Exit();

  ParseXrandrOutput(raw, Result);

  bl := ReadBacklightBrightness();
  for i := 0 to High(Result) do
  begin
    if Result[i].IsConnected then
      Result[i].BrightnessPercent := bl;
  end;
end;

function TConfigDisplayService.GetPrimaryOutput(): TDisplayOutput;
var
  list: TDisplayOutputArray;
  i: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  list := QueryOutputs();
  if Length(list) = 0 then Exit();

  for i := 0 to High(list) do
  begin
    if list[i].IsConnected and list[i].IsPrimary then
    begin
      Result := list[i];
      Exit();
    end;
  end;

  for i := 0 to High(list) do
  begin
    if list[i].IsConnected then
    begin
      Result := list[i];
      Exit();
    end;
  end;

  Result := list[0];
end;

function TConfigDisplayService.GetOutput(const AName: string): TDisplayOutput;
var
  list: TDisplayOutputArray;
  i: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  list := QueryOutputs();
  for i := 0 to High(list) do
  begin
    if SameText(list[i].Name, AName) then
    begin
      Result := list[i];
      Exit();
    end;
  end;
end;

function TConfigDisplayService.SetMode(const AOutputName: string; AWidth, AHeight: Integer; ARate: Double = 0.0): Boolean;
var
  cmd, raw, rateStr: string;
  fs: TFormatSettings;
  i, j: Integer;
begin
  if (AOutputName = '') or (AWidth <= 0) or (AHeight <= 0) then Exit(False);

  if FMockMode then
  begin
    for i := 0 to High(FMockOutputs) do
    begin
      if SameText(FMockOutputs[i].Name, AOutputName) then
      begin
        FMockOutputs[i].CurrentWidth := AWidth;
        FMockOutputs[i].CurrentHeight := AHeight;
        if ARate > 0.0 then
          FMockOutputs[i].CurrentRate := ARate;
        for j := 0 to High(FMockOutputs[i].Modes) do
        begin
          FMockOutputs[i].Modes[j].IsCurrent :=
            (FMockOutputs[i].Modes[j].Width = AWidth) and (FMockOutputs[i].Modes[j].Height = AHeight);
        end;
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  cmd := 'xrandr --output ' + AOutputName + ' --mode ' + IntToStr(AWidth) + 'x' + IntToStr(AHeight);
  if ARate > 0.0 then
  begin
    fs.DecimalSeparator := '.';
    rateStr := FloatToStr(ARate, fs);
    cmd := cmd + ' --rate ' + rateStr;
  end;

  Result := RunCommandOutput(cmd + ' 2>/dev/null', raw);
end;

function TConfigDisplayService.SetRotation(const AOutputName: string; const ARotation: string): Boolean;
var
  cmd, raw, rot: string;
  i: Integer;
begin
  if AOutputName = '' then Exit(False);
  rot := LowerCase(Trim(ARotation));
  if (rot <> 'normal') and (rot <> 'left') and (rot <> 'inverted') and (rot <> 'right') then
    rot := 'normal';

  if FMockMode then
  begin
    for i := 0 to High(FMockOutputs) do
    begin
      if SameText(FMockOutputs[i].Name, AOutputName) then
      begin
        FMockOutputs[i].CurrentRotation := rot;
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  cmd := 'xrandr --output ' + AOutputName + ' --rotate ' + rot + ' 2>/dev/null';
  Result := RunCommandOutput(cmd, raw);
end;

function TConfigDisplayService.SetBrightness(const AOutputName: string; APercent: Integer): Boolean;
var
  cmd, raw, valStr: string;
  pct: Integer;
  val: Double;
  fs: TFormatSettings;
  i: Integer;
begin
  if AOutputName = '' then Exit(False);
  pct := APercent;
  if pct < 10 then pct := 10;
  if pct > 100 then pct := 100;

  if FMockMode then
  begin
    FMockBrightness := pct;
    for i := 0 to High(FMockOutputs) do
    begin
      if SameText(FMockOutputs[i].Name, AOutputName) then
      begin
        FMockOutputs[i].BrightnessPercent := pct;
        Exit(True);
      end;
    end;
    Exit(True);
  end;

  val := pct / 100.0;
  fs.DecimalSeparator := '.';
  valStr := FloatToStr(val, fs);

  cmd := 'xrandr --output ' + AOutputName + ' --brightness ' + valStr + ' 2>/dev/null';
  Result := RunCommandOutput(cmd, raw);
end;

function TConfigDisplayService.SetScale(const AOutputName: string; AScalePercent: Integer): Boolean;
var
  cmd, raw, factorStr: string;
  pct: Integer;
  factor: Double;
  fs: TFormatSettings;
begin
  if AOutputName = '' then Exit(False);
  pct := AScalePercent;
  if pct < 50 then pct := 50;
  if pct > 200 then pct := 200;

  if FMockMode then Exit(True);

  // xrandr scaling factor: 100% -> 1x1, 125% -> 0.8x0.8 (renders larger canvas)
  factor := 100.0 / pct;
  fs.DecimalSeparator := '.';
  factorStr := FloatToStr(factor, fs);

  cmd := 'xrandr --output ' + AOutputName + ' --scale ' + factorStr + 'x' + factorStr + ' 2>/dev/null';
  Result := RunCommandOutput(cmd, raw);
end;

procedure TConfigDisplayService.EnableMockMode(const AEnabled: Boolean = True);
begin
  FMockMode := AEnabled;
end;

procedure TConfigDisplayService.SetMockOutputs(const AOutputs: TDisplayOutputArray);
begin
  FMockOutputs := Copy(AOutputs);
end;

procedure TConfigDisplayService.SetMockBrightness(AValue: Integer);
begin
  FMockBrightness := AValue;
end;

finalization
  if GDisplayService <> nil then
  begin
    GDisplayService.Free();
    GDisplayService := nil;
  end;

end.

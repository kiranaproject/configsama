// configsama.pas — application entry point for Samarinda Settings
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

program configsama;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  ftpas, ftpas.app,
  ConfigSama.Settings, ConfigSama.Window;

var
  AppWindow: TConfigSamaWindow;

begin
  AppWindow := TConfigSamaWindow.Create();
  try
    AppWindow.Show();
    FtApp().Run();
  finally
    AppWindow.Free();
  end;
end.

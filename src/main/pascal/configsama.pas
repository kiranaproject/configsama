// configsama.pas — application entry point for Samarinda Settings
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

program configsama;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  ftpas, ftpas.app,
  ConfigSama.Settings, ConfigSama.Styles, ConfigSama.Window;

var
  AppWindow: TConfigSamaWindow;
  i: Integer;
  arg: string;

begin
  ApplyConfigSamaStyles();
  AppWindow := TConfigSamaWindow.Create();
  try
    for i := 1 to ParamCount() do
    begin
      arg := ParamStr(i);
      if (arg = '--dark') or (arg = '-d') then
        AppWindow.SetDarkMode(True)
      else if (arg = '--light') or (arg = '-l') then
        AppWindow.SetDarkMode(False)
      else
        AppWindow.SelectCategoryByName(arg);
    end;
    AppWindow.Show();
    FtApp().Run();
  finally
    AppWindow.Free();
  end;
end.

// configsama.pas — application entry point for Samarinda Settings
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

program configsama;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  ftpas, ftpas.app,
  ConfigSama.Settings, ConfigSama.Styles, ConfigSama.Window, ConfigSama.IPC;

var
  AppWindow: TConfigSamaWindow;
  IPCServer: TConfigSamaIPCServer;
  payload: string;
  i: Integer;
  arg: string;

begin
  payload := '';
  for i := 1 to ParamCount() do
  begin
    if i > 1 then
      payload := payload + #10;
    payload := payload + ParamStr(i);
  end;

  if TryForwardToExistingInstance(payload) then
    Exit;

  ApplyConfigSamaStyles();
  AppWindow := TConfigSamaWindow.Create();
  IPCServer := TConfigSamaIPCServer.Create(AppWindow);
  try
    AppWindow.Show();
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
    IPCServer.Start();
    FtApp().Run();
  finally
    IPCServer.Free();
    AppWindow.Free();
  end;
end.

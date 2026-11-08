// configsama.styles.pas — application-wide theme and dark mode CSS styling
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Styles;

{$mode objfpc}{$H+}

interface

procedure ApplyConfigSamaStyles();

implementation

uses
  SysUtils, ftpas.app;

const
  CONFIGSAMA_CSS =
    'window#mainWindow, #mainWindow {' + LineEnding +
    '    background-color: #f4f5f8;' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '}' + LineEnding +
    'window#mainWindow.dark, #mainWindow.dark {' + LineEnding +
    '    background-color: #18181b;' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '}' + LineEnding +
    'container#sidebar, #sidebar {' + LineEnding +
    '    background-color: #ececf4;' + LineEnding +
    '    border-right: 1px solid rgba(0, 0, 0, 0.08);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'container#sidebar.dark, #sidebar.dark {' + LineEnding +
    '    background-color: #1e1e24;' + LineEnding +
    '    border-right: 1px solid rgba(255, 255, 255, 0.08);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'treeview#categoryTree, #categoryTree {' + LineEnding +
    '    background-color: #ececf4;' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'treeview#categoryTree.dark, #categoryTree.dark {' + LineEnding +
    '    background-color: #1e1e24;' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'container#contentArea, #contentArea {' + LineEnding +
    '    background-color: #f4f5f8;' + LineEnding +
    '}' + LineEnding +
    'container#contentArea.dark, #contentArea.dark {' + LineEnding +
    '    background-color: #18181b;' + LineEnding +
    '}' + LineEnding +
    'container.settings-card, .settings-card {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    border-radius: 12px;' + LineEnding +
    '    border: 1px solid rgba(0, 0, 0, 0.08);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'container.settings-card.dark, .settings-card.dark {' + LineEnding +
    '    background-color: #24242c;' + LineEnding +
    '    border-radius: 12px;' + LineEnding +
    '    border: 1px solid rgba(255, 255, 255, 0.08);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'entry#searchEntry, #searchEntry {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '    border: 1px solid rgba(0, 0, 0, 0.1);' + LineEnding +
    '}' + LineEnding +
    'entry#searchEntry.dark, #searchEntry.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '    border: 1px solid rgba(255, 255, 255, 0.12);' + LineEnding +
    '}' + LineEnding +
    'label, text {' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '}' + LineEnding +
    'window.dark label, window.dark text, .dark label, .dark text, label.dark, text.dark {' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '}' + LineEnding +
    '';

procedure ApplyConfigSamaStyles();
begin
  FtApp().AppendCssString(CONFIGSAMA_CSS);
end;

end.

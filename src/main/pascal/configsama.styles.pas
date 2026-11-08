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
    'button#btnPurrInfo, #btnPurrInfo, button.flat, .flat {' + LineEnding +
    '    background-color: transparent;' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'button#btnPurrInfo:hover, #btnPurrInfo:hover {' + LineEnding +
    '    background-color: rgba(59, 130, 246, 0.12);' + LineEnding +
    '    border-radius: 12px;' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'button#btnPurrInfo.dark:hover, #btnPurrInfo.dark:hover {' + LineEnding +
    '    background-color: rgba(96, 165, 250, 0.18);' + LineEnding +
    '    border-radius: 12px;' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'container.battery-banner-card, .battery-banner-card {' + LineEnding +
    '    background: #3b82f6;' + LineEnding +
    '    border-radius: 12px;' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'container.card-divider, .card-divider {' + LineEnding +
    '    background-color: rgba(0, 0, 0, 0.06);' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'container.card-divider.dark, .card-divider.dark, window.dark .card-divider {' + LineEnding +
    '    background-color: rgba(255, 255, 255, 0.08);' + LineEnding +
    '    border: none;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'button.theme-preview-btn, .theme-preview-btn {' + LineEnding +
    '    background-color: transparent;' + LineEnding +
    '    border-radius: 8px;' + LineEnding +
    '    border: 2px solid rgba(0, 0, 0, 0.12);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'button.theme-preview-btn:hover, .theme-preview-btn:hover {' + LineEnding +
    '    border-color: #3b82f6;' + LineEnding +
    '}' + LineEnding +
    'button.theme-preview-btn.dark, .theme-preview-btn.dark, window.dark .theme-preview-btn {' + LineEnding +
    '    border: 2px solid rgba(255, 255, 255, 0.14);' + LineEnding +
    '}' + LineEnding +
    'button.theme-preview-btn.active, .theme-preview-btn.active {' + LineEnding +
    '    border-color: #3b82f6;' + LineEnding +
    '}' + LineEnding +
    'button.swatch-btn, .swatch-btn {' + LineEnding +
    '    border-radius: 14px;' + LineEnding +
    '    border: 2px solid rgba(0, 0, 0, 0.1);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'window.dark button.swatch-btn, window.dark .swatch-btn, button.swatch-btn.dark, .swatch-btn.dark {' + LineEnding +
    '    border: 2px solid rgba(255, 255, 255, 0.15);' + LineEnding +
    '}' + LineEnding +
    'button.swatch-multi, .swatch-multi { background-color: #3b82f6; border-color: #3b82f6; }' + LineEnding +
    'button.swatch-blue, .swatch-blue { background-color: #3b82f6; }' + LineEnding +
    'button.swatch-purple, .swatch-purple { background-color: #a855f7; }' + LineEnding +
    'button.swatch-pink, .swatch-pink { background-color: #ec4899; }' + LineEnding +
    'button.swatch-red, .swatch-red { background-color: #ef4444; }' + LineEnding +
    'button.swatch-orange, .swatch-orange { background-color: #f97316; }' + LineEnding +
    'button.swatch-yellow, .swatch-yellow { background-color: #eab308; }' + LineEnding +
    'button.swatch-green, .swatch-green { background-color: #22c55e; }' + LineEnding +
    'button.segmented-btn, .segmented-btn {' + LineEnding +
    '    background-color: #f1f5f9;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '    border: 1px solid rgba(0, 0, 0, 0.08);' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'window.dark button.segmented-btn, window.dark .segmented-btn, button.segmented-btn.dark, .segmented-btn.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border: 1px solid rgba(255, 255, 255, 0.1);' + LineEnding +
    '}' + LineEnding +
    'button.font-btn, .font-btn {' + LineEnding +
    '    background-color: #f1f5f9;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '    border: 1px solid rgba(0, 0, 0, 0.08);' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '    box-shadow: none;' + LineEnding +
    '}' + LineEnding +
    'window.dark button.font-btn, window.dark .font-btn, button.font-btn.dark, .font-btn.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border: 1px solid rgba(255, 255, 255, 0.1);' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '}' + LineEnding +
    'container.avatar-badge, .avatar-badge {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    border-radius: 25px;' + LineEnding +
    '}' + LineEnding +
    'window.dark container.avatar-badge, window.dark .avatar-badge, container.avatar-badge.dark, .avatar-badge.dark {' + LineEnding +
    '    background-color: #2563eb;' + LineEnding +
    '    border-radius: 25px;' + LineEnding +
    '}' + LineEnding +
    'container.wallpaper-thumb, .wallpaper-thumb {' + LineEnding +
    '    background-color: #1e293b;' + LineEnding +
    '    border-radius: 8px;' + LineEnding +
    '    border: 2px solid rgba(0, 0, 0, 0.12);' + LineEnding +
    '}' + LineEnding +
    'window.dark container.wallpaper-thumb, window.dark .wallpaper-thumb, container.wallpaper-thumb.dark, .wallpaper-thumb.dark {' + LineEnding +
    '    background-color: #18181b;' + LineEnding +
    '    border: 2px solid rgba(255, 255, 255, 0.14);' + LineEnding +
    '}' + LineEnding +
    '';

procedure ApplyConfigSamaStyles();
begin
  FtApp().AppendCssString(CONFIGSAMA_CSS);
end;

end.

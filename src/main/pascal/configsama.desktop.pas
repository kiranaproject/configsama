// configsama.desktop.pas — Desktop and Dock service for Kirana Desktop
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Desktop;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ConfigSama.Settings;

type
  { TConfigDesktopService — Service layer for desktop, dock, and panel settings }
  TConfigDesktopService = class
  private
    FMockMode           : Boolean;
    FMockDockPosition   : string;
    FMockDockIconSize   : Integer;
    FMockDockAutoHide   : Boolean;
    FMockDockMargin     : Integer;
    FMockShowDesktopBtn : Boolean;
    FMockClockFormat    : string;
    FOnChange           : TNotifyEvent;

    procedure NotifyChange();
  public
    constructor Create();
    destructor Destroy(); override;

    // Dock Configuration
    function  GetDockPosition(): string;
    procedure SetDockPosition(const AValue: string);

    function  GetDockIconSize(): Integer;
    procedure SetDockIconSize(AValue: Integer);

    function  GetDockAutoHide(): Boolean;
    procedure SetDockAutoHide(AValue: Boolean);

    function  GetDockMargin(): Integer;
    procedure SetDockMargin(AValue: Integer);

    // Panel & Desktop Configuration
    function  GetShowDesktopButton(): Boolean;
    procedure SetShowDesktopButton(AValue: Boolean);

    function  GetClockFormat(): string;
    procedure SetClockFormat(const AValue: string);

    // Persistence & Synchronization
    procedure Reload();
    procedure Save();

    // Mock Mode & Test Seams
    procedure EnableMockMode(const AEnabled: Boolean = True);
    function  IsMockMode(): Boolean;
    procedure SetMockDockSettings(const APosition: string; AIconSize: Integer; AAutoHide: Boolean; AMargin: Integer);
    procedure SetMockPanelSettings(AShowDesktop: Boolean; const AClockFormat: string);

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

function DesktopService(): TConfigDesktopService;

implementation

var
  GDesktopService: TConfigDesktopService = nil;

function DesktopService(): TConfigDesktopService;
begin
  if GDesktopService = nil then
    GDesktopService := TConfigDesktopService.Create();
  Result := GDesktopService;
end;

{ TConfigDesktopService }

constructor TConfigDesktopService.Create();
begin
  inherited Create();
  FMockMode := False;
  FMockDockPosition := 'Bottom';
  FMockDockIconSize := 48;
  FMockDockAutoHide := False;
  FMockDockMargin := 3;
  FMockShowDesktopBtn := True;
  FMockClockFormat := '24h';
end;

destructor TConfigDesktopService.Destroy();
begin
  inherited Destroy();
end;

procedure TConfigDesktopService.NotifyChange();
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TConfigDesktopService.GetDockPosition(): string;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockDockPosition);

  st := ConfigSettings();
  if st <> nil then
    Result := st.DockPosition
  else
    Result := FMockDockPosition;
end;

procedure TConfigDesktopService.SetDockPosition(const AValue: string);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockDockPosition := AValue;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.DockPosition := AValue;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigDesktopService.GetDockIconSize(): Integer;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockDockIconSize);

  st := ConfigSettings();
  if st <> nil then
    Result := st.DockIconSize
  else
    Result := FMockDockIconSize;
end;

procedure TConfigDesktopService.SetDockIconSize(AValue: Integer);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockDockIconSize := AValue;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.DockIconSize := AValue;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigDesktopService.GetDockAutoHide(): Boolean;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockDockAutoHide);

  st := ConfigSettings();
  if st <> nil then
    Result := st.DockAutoHide
  else
    Result := FMockDockAutoHide;
end;

procedure TConfigDesktopService.SetDockAutoHide(AValue: Boolean);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockDockAutoHide := AValue;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.DockAutoHide := AValue;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigDesktopService.GetDockMargin(): Integer;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockDockMargin);

  st := ConfigSettings();
  if st <> nil then
    Result := st.DockMargin
  else
    Result := FMockDockMargin;
end;

procedure TConfigDesktopService.SetDockMargin(AValue: Integer);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockDockMargin := AValue;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.DockMargin := AValue;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigDesktopService.GetShowDesktopButton(): Boolean;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockShowDesktopBtn);

  st := ConfigSettings();
  if st <> nil then
    Result := st.ShowDesktopButton
  else
    Result := FMockShowDesktopBtn;
end;

procedure TConfigDesktopService.SetShowDesktopButton(AValue: Boolean);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockShowDesktopBtn := AValue;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.ShowDesktopButton := AValue;
    st.Save();
  end;
  NotifyChange();
end;

function TConfigDesktopService.GetClockFormat(): string;
var
  st: TConfigSettings;
begin
  if FMockMode then
    Exit(FMockClockFormat);

  st := ConfigSettings();
  if st <> nil then
    Result := st.ClockFormat
  else
    Result := FMockClockFormat;
end;

procedure TConfigDesktopService.SetClockFormat(const AValue: string);
var
  st: TConfigSettings;
begin
  if FMockMode then
  begin
    FMockClockFormat := AValue;
    NotifyChange();
    Exit;
  end;

  st := ConfigSettings();
  if st <> nil then
  begin
    st.ClockFormat := AValue;
    st.Save();
  end;
  NotifyChange();
end;

procedure TConfigDesktopService.Reload();
var
  st: TConfigSettings;
begin
  if FMockMode then Exit;
  st := ConfigSettings();
  if st <> nil then
    st.Load();
  NotifyChange();
end;

procedure TConfigDesktopService.Save();
var
  st: TConfigSettings;
begin
  if FMockMode then Exit;
  st := ConfigSettings();
  if st <> nil then
    st.Save();
end;

procedure TConfigDesktopService.EnableMockMode(const AEnabled: Boolean);
begin
  FMockMode := AEnabled;
end;

function TConfigDesktopService.IsMockMode(): Boolean;
begin
  Result := FMockMode;
end;

procedure TConfigDesktopService.SetMockDockSettings(const APosition: string; AIconSize: Integer; AAutoHide: Boolean; AMargin: Integer);
begin
  FMockDockPosition := APosition;
  FMockDockIconSize := AIconSize;
  FMockDockAutoHide := AAutoHide;
  FMockDockMargin := AMargin;
  NotifyChange();
end;

procedure TConfigDesktopService.SetMockPanelSettings(AShowDesktop: Boolean; const AClockFormat: string);
begin
  FMockShowDesktopBtn := AShowDesktop;
  FMockClockFormat := AClockFormat;
  NotifyChange();
end;

end.

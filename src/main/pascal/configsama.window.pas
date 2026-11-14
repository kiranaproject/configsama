// configsama.window.pas — main application window and settings integration
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ConfigSama.Window;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ftpas, ftpas.types, ftpas.api, ftpas.app, ftpas.canvas, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.views, ftpas.dialogs, ftpas.ftml,
  ConfigSama.Wlan, ConfigSama.Wired, ConfigSama.Display,
  ConfigSama.Bluetooth, ConfigSama.Sound, ConfigSama.Power,
  ConfigSama.Settings, ConfigSama.Styles;

type
  { TConfigSamaWindow — GNOME Settings styled application with FTML and ECA }
  TConfigSamaWindow = class(TFtFTMLForm)
  private
    FSettings: TConfigSettings;
    FUpdatingControls: Boolean;
    FSelectingCategory: Boolean;

    // Header controls
    FAppTitle: TFtLabel;
    FSectionTitle: TFtLabel;

    // Sidebar controls
    FSearchEntry: TFtEntry;
    FCategoryTree: TFtTreeView;

    // Content Pages
    FPageWlan: TFtWidget;
    FPageWired: TFtWidget;
    FPageBluetooth: TFtWidget;
    FPageDisplays: TFtWidget;
    FPageAppearance: TFtWidget;
    FPageBackground: TFtWidget;
    FPageDesktop: TFtWidget;
    FPageUser: TFtWidget;
    FPageLanguage: TFtWidget;
    FPageBattery: TFtWidget;
    FPageSound: TFtWidget;
    FPagePower: TFtWidget;
    FPageMouse: TFtWidget;
    FPageKeyboard: TFtWidget;
    FPageApps: TFtWidget;
    FPageAbout: TFtWidget;

    // WLAN page controls
    FCardWlanToggle: TFtContainer;
    FLblWlanTitle: TFtLabel;
    FLblWlanStatus: TFtLabel;
    FBtnWlanRescan: TFtButton;
    FSwWlan: TFtSwitch;

    FContainerWlanDisabled: TFtContainer;
    FLblWlanDisabled: TFtLabel;

    FCardWlanConnected: TFtContainer;
    FImgConnWifi: TFtImage;
    FLblConnSsid: TFtLabel;
    FLblConnDetails: TFtLabel;
    FImgConnCheck: TFtImage;
    FBtnConnDetails: TFtButton;
    FBtnConnDisconnect: TFtButton;

    FCardWlanAvailable: TFtContainer;
    FLblScanStatus: TFtLabel;

    FWlanRows: array[0..5] of record
      Row: TFtContainer;
      ImgIcon: TFtImage;
      LblSsid: TFtLabel;
      LblSignal: TFtLabel;
      ImgLock: TFtImage;
      BtnConnect: TFtButton;
      Divider: TFtWidget;
      Network: TWlanNetwork;
    end;

    // Password Prompt Dialog controls
    FPwdDialog: TFtWindow;
    FPwdEntry: TFtEntry;
    FPwdSubmitted: Boolean;

    // Wired page controls
    FCardWiredToggle: TFtContainer;
    FLblWiredTitle: TFtLabel;
    FLblWiredStatus: TFtLabel;
    FBtnWiredRefresh: TFtButton;
    FSwWired: TFtSwitch;
    FContainerWiredDisabled: TFtContainer;
    FLblWiredDisabled: TFtLabel;
    FCardWired: TFtContainer;
    FImgWired: TFtImage;
    FLblWiredDevice: TFtLabel;
    FBtnWiredConnect: TFtButton;
    FLblWiredSpeed: TFtLabel;
    FLblWiredIp: TFtLabel;
    FLblWiredDns: TFtLabel;
    FLblWiredMac: TFtLabel;

    // Bluetooth page controls
    FCardBluetoothToggle: TFtContainer;
    FLblBluetoothTitle: TFtLabel;
    FLblBluetoothStatus: TFtLabel;
    FBtnBluetoothScan: TFtButton;
    FSwBluetooth: TFtSwitch;
    FContainerBluetoothDisabled: TFtContainer;
    FLblBluetoothDisabled: TFtLabel;
    FCardBluetoothDevices: TFtContainer;
    FRowBtDev0: TFtContainer;
    FRowBtDev1: TFtContainer;
    FRowBtDev2: TFtContainer;
    FLblBtName0: TFtLabel;
    FLblBtName1: TFtLabel;
    FLblBtName2: TFtLabel;
    FLblBtStatus0: TFtLabel;
    FLblBtStatus1: TFtLabel;
    FLblBtStatus2: TFtLabel;
    FBtnBtConnect0: TFtButton;
    FBtnBtConnect1: TFtButton;
    FBtnBtConnect2: TFtButton;
    FImgBtDev0: TFtImage;
    FImgBtDev1: TFtImage;
    FImgBtDev2: TFtImage;

    // Backward-compatibility aliases
    FImgWifiPurr: TFtImage;
    FImgLockPurr: TFtImage;
    FImgCheckPurr: TFtImage;
    FBtnPurrInfo: TFtButton;
    FImgWifiMeow: TFtImage;
    FImgLockMeow: TFtImage;
    FImgWifiVirgin: TFtImage;
    FImgLockVirgin: TFtImage;
    FImgWifiVM: TFtImage;
    FImgLockVM: TFtImage;

    // Appearance page controls
    FBtnThemeLight: TFtButton;
    FBtnThemeDark: TFtButton;
    FBtnStandardFont: TFtButton;
    FBtnMonospaceFont: TFtButton;
    FSwDarkMode: TFtSwitch;
    FCmbAccent: TFtComboBox;
    FCmbWallpaperMode: TFtComboBox;
    FTxtWallpaperPath: TFtEntry;
    FBtnChooseWallpaper: TFtButton;

    // Displays page controls
    FSldBrightness: TFtSlider;
    FImgBrightnessLow: TFtImage;
    FImgBrightnessHigh: TFtImage;
    FCmbDisplay: TFtComboBox;
    FCmbResolution: TFtComboBox;
    FCmbRefreshRate: TFtComboBox;
    FCmbScale: TFtComboBox;
    FSegScale: TFtSegmentedControl;
    FBtnRotate0: TFtButton;
    FBtnRotate90: TFtButton;
    FBtnRotate180: TFtButton;
    FBtnRotate270: TFtButton;
    FLblDisplayInfo: TFtLabel;
    FBtnDisplayApply: TFtButton;
    FSwNightLight: TFtSwitch;

    // Desktop page controls
    FCmbDockPosition: TFtComboBox;
    FSegDockPosition: TFtSegmentedControl;
    FCmbDockIconSize: TFtComboBox;
    FSwDockAutoHide: TFtSwitch;
    FCmbDockMargin: TFtComboBox;
    FSwShowDesktopBtn: TFtSwitch;
    FSwClock24h: TFtSwitch;

    // Language page controls
    FCmbDisplayLanguage: TFtComboBox;
    FCmbRegionalFormats: TFtComboBox;

    // Sound page controls
    FCmbOutputDevice: TFtComboBox;
    FSlVolume: TFtSlider;
    FLblVolumePercent: TFtLabel;
    FSwMute: TFtSwitch;
    FBtnTestSound: TFtButton;
    FCmbInputDevice: TFtComboBox;
    FSlInputVolume: TFtSlider;
    FLblInputVolumePercent: TFtLabel;
    FSwInputMute: TFtSwitch;
    FSwSoundEffects: TFtSwitch;

    // Power page controls
    FLblBatteryPercent: TFtLabel;
    FLblBatteryRemaining: TFtLabel;
    FImgBatteryBolt: TFtImage;
    FSegPowerMode: TFtSegmentedControl;
    FCmbPowerMode: TFtComboBox;
    FCmbScreenBlank: TFtComboBox;
    FSwAutoSuspend: TFtSwitch;
    FLblMaxCapacity: TFtLabel;
    FTxtPowerStatus: TFtEntry;

    // Mouse page controls
    FCmbPrimaryBtn: TFtComboBox;
    FSlPointerSpeed: TFtSlider;
    FSwNaturalScroll: TFtSwitch;
    FSwTapToClick: TFtSwitch;

    // Keyboard page controls
    FCmbKeyboardLayout: TFtComboBox;
    FSlKeyDelay: TFtSlider;
    FSlKeyRate: TFtSlider;
    FSwSuperLauncher: TFtSwitch;

    // Applications page controls
    FCmbBrowser: TFtComboBox;
    FCmbFileManager: TFtComboBox;
    FCmbTerminal: TFtComboBox;
    FCmbEditor: TFtComboBox;

    // About page controls
    FTxtAboutOs: TFtEntry;
    FTxtAboutShell: TFtEntry;
    FTxtAboutWm: TFtEntry;
    FTxtAboutToolkit: TFtEntry;
    FTxtAboutKernel: TFtEntry;
    FTxtAboutCpu: TFtEntry;
    FTxtAboutMem: TFtEntry;

    procedure SetupUI();
    procedure PopulateControls();
    procedure UpdateThemeIcons();

    // WLAN Event Handlers
    procedure HandleWlanToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleWlanRescan(Sender: TFtButton);
    procedure HandleConnectedDetails(Sender: TFtButton);
    procedure HandleConnectedDisconnect(Sender: TFtButton);
    procedure HandleRowConnectClick(Sender: TFtButton);
    procedure RefreshWlanUI(AFreshScan: Boolean = False);
    procedure PromptPasswordAndConnect(const ASsid: string);
    procedure ShowNetworkDetailsDialog(const ASsid: string);
    procedure HandlePasswordPromptConnect(Sender: TFtButton);
    procedure HandlePasswordPromptCancel(Sender: TFtButton);

    // Wired Event Handlers
    procedure HandleWiredToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleWiredRefresh(Sender: TFtButton);
    procedure HandleWiredConnectClick(Sender: TFtButton);
    procedure RefreshWiredUI();

    // Bluetooth Event Handlers
    procedure HandleBluetoothToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleBluetoothScanClick(Sender: TFtButton);
    procedure HandleBluetoothConnectClick(Sender: TFtButton);
    procedure RefreshBluetoothUI();

    // Sound Event Handlers
    procedure HandleTestSoundClick(Sender: TFtButton);
    procedure HandleInputDeviceChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleInputVolumeChange(Sender: TFtSlider; AValue: Double);
    procedure HandleInputMuteToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure RefreshSoundUI();

    // Power Event Handlers
    procedure HandleSegmentPowerModeSelect(Sender: TFtSegmentedControl; AIndex: Integer; const AText: string);
    procedure RefreshPowerUI();

    // Appearance Event Handlers
    procedure HandleStandardFontClick(Sender: TFtButton);
    procedure HandleMonospaceFontClick(Sender: TFtButton);
    procedure RefreshAppearanceUI();

    // Displays Event Handlers
    procedure HandleBrightnessChange(Sender: TFtSlider; AValue: Double);
    procedure HandleDisplayApplyClick(Sender: TFtButton);
    procedure RefreshDisplayUI();
    procedure UpdateRotationButtonStates(const ARotation: string);
    function GetSelectedDisplayName(): string;

    // Event Handlers
    procedure HandleCategorySelect(Sender: TFtTreeView; Node: TFtTreeNode);
    procedure HandleSearchChange(Sender: TFtWidget; const AText: string);
    procedure HandleDarkModeToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleThemeLightClick(Sender: TFtButton);
    procedure HandleThemeDarkClick(Sender: TFtButton);
    procedure HandleAccentButtonClick(Sender: TFtButton);
    procedure HandleRotateButtonClick(Sender: TFtButton);
    procedure HandleAccentChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleWallpaperModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleChooseWallpaperClick(Sender: TFtButton);
    procedure HandleWallpaperPresetClick(Sender: TFtButton);
    procedure HandleDisplayChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleResolutionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleRefreshRateChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleScaleChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleSegmentScaleSelect(Sender: TFtSegmentedControl; AIndex: Integer; const AText: string);
    procedure HandleNightLightToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleDockPositionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleSegmentDockPositionSelect(Sender: TFtSegmentedControl; AIndex: Integer; const AText: string);
    procedure HandleDockIconSizeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleDockAutoHideToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleDockMarginChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleShowDesktopToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleClock24hToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleDisplayLanguageChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleRegionalFormatsChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleOutputDeviceChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleVolumeChange(Sender: TFtSlider; AValue: Double);
    procedure HandleMuteToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleSoundEffectsToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandlePowerModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleScreenBlankChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleAutoSuspendToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandlePrimaryBtnChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandlePointerSpeedChange(Sender: TFtSlider; AValue: Double);
    procedure HandleNaturalScrollToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleTapToClickToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleKeyboardLayoutChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleKeyDelayChange(Sender: TFtSlider; AValue: Double);
    procedure HandleKeyRateChange(Sender: TFtSlider; AValue: Double);
    procedure HandleSuperLauncherToggle(Sender: TFtSwitch; AToggled: Boolean);
    procedure HandleBrowserChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleFileManagerChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleTerminalChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
    procedure HandleEditorChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
  protected
    procedure DoMouseDown(AX, AY, AButton: Integer); override;
  public
    constructor Create(const ACustomIniPath: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure SelectCategoryByName(const AName: string);
    procedure SetDarkMode(AValue: Boolean);
    procedure CycleStandardFont();
    procedure CycleMonospaceFont();

    property Settings: TConfigSettings read FSettings;
    property AppTitle: TFtLabel read FAppTitle;
    property SectionTitle: TFtLabel read FSectionTitle;
    property CategoryTree: TFtTreeView read FCategoryTree;
    property SearchEntry: TFtEntry read FSearchEntry;
    property SwDarkMode: TFtSwitch read FSwDarkMode;
    property CmbAccent: TFtComboBox read FCmbAccent;
    property TxtWallpaperPath: TFtEntry read FTxtWallpaperPath;
    property SlVolume: TFtSlider read FSlVolume;
    property SwMute: TFtSwitch read FSwMute;
    property SwWlan: TFtSwitch read FSwWlan;
    property SwWired: TFtSwitch read FSwWired;
    property SegScale: TFtSegmentedControl read FSegScale;
    property CmbDisplay: TFtComboBox read FCmbDisplay;
    property CmbResolution: TFtComboBox read FCmbResolution;
    property CmbRefreshRate: TFtComboBox read FCmbRefreshRate;
    property SldBrightness: TFtSlider read FSldBrightness;
    property BtnWiredConnect: TFtButton read FBtnWiredConnect;
    property BtnDisplayApply: TFtButton read FBtnDisplayApply;
    property LblWiredStatus: TFtLabel read FLblWiredStatus;
    property LblDisplayInfo: TFtLabel read FLblDisplayInfo;

    // Bluetooth
    property PageBluetooth: TFtWidget read FPageBluetooth;
    property SwBluetooth: TFtSwitch read FSwBluetooth;
    property LblBluetoothStatus: TFtLabel read FLblBluetoothStatus;
    property BtnBluetoothScan: TFtButton read FBtnBluetoothScan;
    property CardBluetoothDevices: TFtContainer read FCardBluetoothDevices;
    property BtnBtConnect0: TFtButton read FBtnBtConnect0;
    property BtnBtConnect1: TFtButton read FBtnBtConnect1;
    property BtnBtConnect2: TFtButton read FBtnBtConnect2;

    // Sound
    property PageSound: TFtWidget read FPageSound;
    property CmbOutputDevice: TFtComboBox read FCmbOutputDevice;
    property LblVolumePercent: TFtLabel read FLblVolumePercent;
    property BtnTestSound: TFtButton read FBtnTestSound;
    property CmbInputDevice: TFtComboBox read FCmbInputDevice;
    property SlInputVolume: TFtSlider read FSlInputVolume;
    property LblInputVolumePercent: TFtLabel read FLblInputVolumePercent;
    property SwInputMute: TFtSwitch read FSwInputMute;
    property SwSoundEffects: TFtSwitch read FSwSoundEffects;

    // Power
    property PagePower: TFtWidget read FPagePower;
    property PageBattery: TFtWidget read FPageBattery;
    property LblBatteryPercent: TFtLabel read FLblBatteryPercent;
    property LblBatteryRemaining: TFtLabel read FLblBatteryRemaining;
    property SegPowerMode: TFtSegmentedControl read FSegPowerMode;
    property CmbPowerMode: TFtComboBox read FCmbPowerMode;
    property CmbScreenBlank: TFtComboBox read FCmbScreenBlank;
    property SwAutoSuspend: TFtSwitch read FSwAutoSuspend;
    property LblMaxCapacity: TFtLabel read FLblMaxCapacity;

    // Appearance
    property PageAppearance: TFtWidget read FPageAppearance;
    property BtnThemeLight: TFtButton read FBtnThemeLight;
    property BtnThemeDark: TFtButton read FBtnThemeDark;
    property BtnStandardFont: TFtButton read FBtnStandardFont;
    property BtnMonospaceFont: TFtButton read FBtnMonospaceFont;
  end;

implementation

{$R configsama.res}

{ TConfigSamaWindow }

constructor TConfigSamaWindow.Create(const ACustomIniPath: string = '');
begin
  ApplyConfigSamaStyles();
  inherited Create(960, 640, 'Settings', 'TConfigSamaWindow');

  FSettings := TConfigSettings.Create(ACustomIniPath);
  SetupUI();
  PopulateControls();
end;

destructor TConfigSamaWindow.Destroy();
begin
  if Assigned(FSettings) then
  begin
    FSettings.Free();
    FSettings := nil;
  end;
  inherited Destroy();
end;

procedure TConfigSamaWindow.DoMouseDown(AX, AY, AButton: Integer);
var
  wx, wy: Integer;
begin
  inherited DoMouseDown(AX, AY, AButton);

  // ECA Header window dragging
  if (AButton = 1) and (AY <= 48) then
  begin
    GetPosition(wx, wy);
    BeginWindowMove(wx + AX, wy + AY);
  end;
end;

procedure TConfigSamaWindow.SetupUI();
var
  w: TFtWidget;
  i: Integer;
begin
  // Header
  w := FindWidget('appTitle');
  if w is TFtLabel then
  begin
    FAppTitle := TFtLabel(w);
    FAppTitle.Selectable := False;
  end;

  w := FindWidget('sectionTitle');
  if w is TFtLabel then
  begin
    FSectionTitle := TFtLabel(w);
    FSectionTitle.Selectable := False;
  end;

  // Sidebar
  w := FindWidget('searchEntry');
  if w is TFtEntry then
  begin
    FSearchEntry := TFtEntry(w);
    FSearchEntry.OnChange := @HandleSearchChange;
  end;

  w := FindWidget('categoryTree');
  if w is TFtTreeView then
  begin
    FCategoryTree := TFtTreeView(w);
    FCategoryTree.OnSelect := @HandleCategorySelect;
    if (FCategoryTree.Root <> nil) and (FCategoryTree.Root.ChildCount > 0) then
    begin
      if FCategoryTree.Root.Children[0].ChildCount > 0 then
        FCategoryTree.SelectedNode := FCategoryTree.Root.Children[0].Children[0];
    end;
  end;

  // Content Pages
  FPageWlan := FindWidget('pageWlan');
  FPageWired := FindWidget('pageWired');
  FPageBluetooth := FindWidget('pageBluetooth');
  FPageDisplays := FindWidget('pageDisplays');
  FPageAppearance := FindWidget('pageAppearance');
  FPageBackground := FindWidget('pageBackground');
  FPageDesktop := FindWidget('pageDesktop');
  FPageUser := FindWidget('pageUser');
  FPageLanguage := FindWidget('pageLanguage');
  FPageBattery := FindWidget('pageBattery');
  FPageSound := FindWidget('pageSound');
  FPagePower := FindWidget('pagePower');
  FPageMouse := FindWidget('pageMouse');
  FPageKeyboard := FindWidget('pageKeyboard');
  FPageApps := FindWidget('pageApps');
  FPageAbout := FindWidget('pageAbout');

  // WLAN controls
  w := FindWidget('cardWlanToggle');
  if w is TFtContainer then FCardWlanToggle := TFtContainer(w);

  w := FindWidget('lblWlanTitle');
  if w is TFtLabel then FLblWlanTitle := TFtLabel(w);

  w := FindWidget('lblWlanStatus');
  if w is TFtLabel then FLblWlanStatus := TFtLabel(w);

  w := FindWidget('btnWlanRescan');
  if w is TFtButton then
  begin
    FBtnWlanRescan := TFtButton(w);
    FBtnWlanRescan.OnClick := @HandleWlanRescan;
  end;

  w := FindWidget('swWlan');
  if w is TFtSwitch then
  begin
    FSwWlan := TFtSwitch(w);
    FSwWlan.OnToggle := @HandleWlanToggle;
  end;

  w := FindWidget('containerWlanDisabled');
  if w is TFtContainer then FContainerWlanDisabled := TFtContainer(w);

  w := FindWidget('lblWlanDisabled');
  if w is TFtLabel then FLblWlanDisabled := TFtLabel(w);

  w := FindWidget('cardWlanConnected');
  if w is TFtContainer then FCardWlanConnected := TFtContainer(w);

  w := FindWidget('imgConnWifi');
  if w is TFtImage then FImgConnWifi := TFtImage(w);

  w := FindWidget('lblConnSsid');
  if w is TFtLabel then FLblConnSsid := TFtLabel(w);

  w := FindWidget('lblConnDetails');
  if w is TFtLabel then FLblConnDetails := TFtLabel(w);

  w := FindWidget('imgConnCheck');
  if w is TFtImage then FImgConnCheck := TFtImage(w);

  w := FindWidget('btnConnDetails');
  if w is TFtButton then
  begin
    FBtnConnDetails := TFtButton(w);
    FBtnConnDetails.OnClick := @HandleConnectedDetails;
  end;

  w := FindWidget('btnConnDisconnect');
  if w is TFtButton then
  begin
    FBtnConnDisconnect := TFtButton(w);
    FBtnConnDisconnect.OnClick := @HandleConnectedDisconnect;
  end;

  w := FindWidget('cardWlanAvailable');
  if w is TFtContainer then FCardWlanAvailable := TFtContainer(w);

  w := FindWidget('lblScanStatus');
  if w is TFtLabel then FLblScanStatus := TFtLabel(w);

  for i := 0 to 5 do
  begin
    w := FindWidget('rowNet' + IntToStr(i));
    if w is TFtContainer then FWlanRows[i].Row := TFtContainer(w);

    w := FindWidget('imgNetIcon' + IntToStr(i));
    if w is TFtImage then FWlanRows[i].ImgIcon := TFtImage(w);

    w := FindWidget('lblNetSsid' + IntToStr(i));
    if w is TFtLabel then FWlanRows[i].LblSsid := TFtLabel(w);

    w := FindWidget('lblNetSignal' + IntToStr(i));
    if w is TFtLabel then FWlanRows[i].LblSignal := TFtLabel(w);

    w := FindWidget('imgNetLock' + IntToStr(i));
    if w is TFtImage then FWlanRows[i].ImgLock := TFtImage(w);

    w := FindWidget('btnNetConnect' + IntToStr(i));
    if w is TFtButton then
    begin
      FWlanRows[i].BtnConnect := TFtButton(w);
      FWlanRows[i].BtnConnect.Tag := i;
      FWlanRows[i].BtnConnect.OnClick := @HandleRowConnectClick;
    end;

    FWlanRows[i].Divider := FindWidget('divNet' + IntToStr(i));
  end;

  // Wired controls
  w := FindWidget('cardWiredToggle');
  if w is TFtContainer then FCardWiredToggle := TFtContainer(w);

  w := FindWidget('lblWiredTitle');
  if w is TFtLabel then FLblWiredTitle := TFtLabel(w);

  w := FindWidget('lblWiredStatus');
  if w is TFtLabel then FLblWiredStatus := TFtLabel(w);

  w := FindWidget('btnWiredRefresh');
  if w is TFtButton then
  begin
    FBtnWiredRefresh := TFtButton(w);
    FBtnWiredRefresh.OnClick := @HandleWiredRefresh;
  end;

  w := FindWidget('swWired');
  if w is TFtSwitch then
  begin
    FSwWired := TFtSwitch(w);
    FSwWired.OnToggle := @HandleWiredToggle;
  end;

  w := FindWidget('containerWiredDisabled');
  if w is TFtContainer then FContainerWiredDisabled := TFtContainer(w);

  w := FindWidget('lblWiredDisabled');
  if w is TFtLabel then FLblWiredDisabled := TFtLabel(w);

  w := FindWidget('cardWired');
  if w is TFtContainer then FCardWired := TFtContainer(w);

  w := FindWidget('imgWired');
  if w is TFtImage then FImgWired := TFtImage(w);

  w := FindWidget('lblWiredDevice');
  if w is TFtLabel then FLblWiredDevice := TFtLabel(w);

  w := FindWidget('btnWiredConnect');
  if w is TFtButton then
  begin
    FBtnWiredConnect := TFtButton(w);
    FBtnWiredConnect.OnClick := @HandleWiredConnectClick;
  end;

  w := FindWidget('lblWiredSpeed');
  if w is TFtLabel then
  begin
    FLblWiredSpeed := TFtLabel(w);
    FLblWiredSpeed.Alignment := ftaRight;
  end;

  w := FindWidget('lblWiredIp');
  if w is TFtLabel then
  begin
    FLblWiredIp := TFtLabel(w);
    FLblWiredIp.Alignment := ftaRight;
  end;

  w := FindWidget('lblWiredDns');
  if w is TFtLabel then
  begin
    FLblWiredDns := TFtLabel(w);
    FLblWiredDns.Alignment := ftaRight;
  end;

  w := FindWidget('lblWiredMac');
  if w is TFtLabel then
  begin
    FLblWiredMac := TFtLabel(w);
    FLblWiredMac.Alignment := ftaRight;
  end;

  // Bluetooth controls
  w := FindWidget('cardBluetoothToggle');
  if w is TFtContainer then FCardBluetoothToggle := TFtContainer(w);

  w := FindWidget('lblBluetoothTitle');
  if w is TFtLabel then FLblBluetoothTitle := TFtLabel(w);

  w := FindWidget('lblBluetoothStatus');
  if w is TFtLabel then FLblBluetoothStatus := TFtLabel(w);

  w := FindWidget('btnBluetoothScan');
  if w is TFtButton then
  begin
    FBtnBluetoothScan := TFtButton(w);
    FBtnBluetoothScan.OnClick := @HandleBluetoothScanClick;
  end;

  w := FindWidget('swBluetooth');
  if w is TFtSwitch then
  begin
    FSwBluetooth := TFtSwitch(w);
    FSwBluetooth.OnToggle := @HandleBluetoothToggle;
  end;

  w := FindWidget('containerBluetoothDisabled');
  if w is TFtContainer then FContainerBluetoothDisabled := TFtContainer(w);

  w := FindWidget('lblBluetoothDisabled');
  if w is TFtLabel then FLblBluetoothDisabled := TFtLabel(w);

  w := FindWidget('cardBluetoothDevices');
  if w is TFtContainer then FCardBluetoothDevices := TFtContainer(w);

  w := FindWidget('rowBtDev0');
  if w is TFtContainer then FRowBtDev0 := TFtContainer(w);
  w := FindWidget('imgBtDev0');
  if w is TFtImage then FImgBtDev0 := TFtImage(w);
  w := FindWidget('lblBtName0');
  if w is TFtLabel then FLblBtName0 := TFtLabel(w);
  w := FindWidget('lblBtStatus0');
  if w is TFtLabel then FLblBtStatus0 := TFtLabel(w);
  w := FindWidget('btnBtConnect0');
  if w is TFtButton then
  begin
    FBtnBtConnect0 := TFtButton(w);
    FBtnBtConnect0.Tag := 0;
    FBtnBtConnect0.OnClick := @HandleBluetoothConnectClick;
  end;

  w := FindWidget('rowBtDev1');
  if w is TFtContainer then FRowBtDev1 := TFtContainer(w);
  w := FindWidget('imgBtDev1');
  if w is TFtImage then FImgBtDev1 := TFtImage(w);
  w := FindWidget('lblBtName1');
  if w is TFtLabel then FLblBtName1 := TFtLabel(w);
  w := FindWidget('lblBtStatus1');
  if w is TFtLabel then FLblBtStatus1 := TFtLabel(w);
  w := FindWidget('btnBtConnect1');
  if w is TFtButton then
  begin
    FBtnBtConnect1 := TFtButton(w);
    FBtnBtConnect1.Tag := 1;
    FBtnBtConnect1.OnClick := @HandleBluetoothConnectClick;
  end;

  w := FindWidget('rowBtDev2');
  if w is TFtContainer then FRowBtDev2 := TFtContainer(w);
  w := FindWidget('imgBtDev2');
  if w is TFtImage then FImgBtDev2 := TFtImage(w);
  w := FindWidget('lblBtName2');
  if w is TFtLabel then FLblBtName2 := TFtLabel(w);
  w := FindWidget('lblBtStatus2');
  if w is TFtLabel then FLblBtStatus2 := TFtLabel(w);
  w := FindWidget('btnBtConnect2');
  if w is TFtButton then
  begin
    FBtnBtConnect2 := TFtButton(w);
    FBtnBtConnect2.Tag := 2;
    FBtnBtConnect2.OnClick := @HandleBluetoothConnectClick;
  end;

  // Appearance controls
  w := FindWidget('swDarkMode');
  if w is TFtSwitch then
  begin
    FSwDarkMode := TFtSwitch(w);
    FSwDarkMode.OnToggle := @HandleDarkModeToggle;
  end;

  w := FindWidget('cmbAccent');
  if w is TFtComboBox then
  begin
    FCmbAccent := TFtComboBox(w);
    FCmbAccent.OnChange := @HandleAccentChange;
  end;

  w := FindWidget('btnThemeLight');
  if w is TFtButton then
  begin
    FBtnThemeLight := TFtButton(w);
    FBtnThemeLight.OnClick := @HandleThemeLightClick;
  end;
  w := FindWidget('btnThemeDark');
  if w is TFtButton then
  begin
    FBtnThemeDark := TFtButton(w);
    FBtnThemeDark.OnClick := @HandleThemeDarkClick;
  end;

  w := FindWidget('btnAccentMulti');
  if w is TFtButton then begin w.Tag := 0; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentBlue');
  if w is TFtButton then begin w.Tag := 1; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentPurple');
  if w is TFtButton then begin w.Tag := 2; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentPink');
  if w is TFtButton then begin w.Tag := 3; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentRed');
  if w is TFtButton then begin w.Tag := 4; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentOrange');
  if w is TFtButton then begin w.Tag := 5; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentYellow');
  if w is TFtButton then begin w.Tag := 6; TFtButton(w).OnClick := @HandleAccentButtonClick; end;
  w := FindWidget('btnAccentGreen');
  if w is TFtButton then begin w.Tag := 7; TFtButton(w).OnClick := @HandleAccentButtonClick; end;

  w := FindWidget('cmbWallpaperMode');
  if w is TFtComboBox then
  begin
    FCmbWallpaperMode := TFtComboBox(w);
    FCmbWallpaperMode.OnChange := @HandleWallpaperModeChange;
  end;

  w := FindWidget('txtWallpaperPath');
  if w is TFtEntry then FTxtWallpaperPath := TFtEntry(w);

  w := FindWidget('btnChooseWallpaper');
  if w is TFtButton then
  begin
    FBtnChooseWallpaper := TFtButton(w);
    FBtnChooseWallpaper.OnClick := @HandleChooseWallpaperClick;
  end;

  w := FindWidget('btnStandardFont');
  if w is TFtButton then
  begin
    FBtnStandardFont := TFtButton(w);
    FBtnStandardFont.OnClick := @HandleStandardFontClick;
  end;

  w := FindWidget('btnMonospaceFont');
  if w is TFtButton then
  begin
    FBtnMonospaceFont := TFtButton(w);
    FBtnMonospaceFont.OnClick := @HandleMonospaceFontClick;
  end;

  // Displays controls
  w := FindWidget('imgBrightnessLow');
  if w is TFtImage then FImgBrightnessLow := TFtImage(w);

  w := FindWidget('imgBrightnessHigh');
  if w is TFtImage then FImgBrightnessHigh := TFtImage(w);

  w := FindWidget('sldBrightness');
  if w is TFtSlider then
  begin
    FSldBrightness := TFtSlider(w);
    FSldBrightness.OnChange := @HandleBrightnessChange;
  end;

  w := FindWidget('cmbDisplay');
  if w is TFtComboBox then
  begin
    FCmbDisplay := TFtComboBox(w);
    FCmbDisplay.OnChange := @HandleDisplayChange;
  end;

  w := FindWidget('cmbResolution');
  if w is TFtComboBox then
  begin
    FCmbResolution := TFtComboBox(w);
    FCmbResolution.OnChange := @HandleResolutionChange;
  end;

  w := FindWidget('cmbRefreshRate');
  if w is TFtComboBox then
  begin
    FCmbRefreshRate := TFtComboBox(w);
    FCmbRefreshRate.OnChange := @HandleRefreshRateChange;
  end;

  w := FindWidget('cmbScale');
  if w is TFtComboBox then
  begin
    FCmbScale := TFtComboBox(w);
    FCmbScale.OnChange := @HandleScaleChange;
  end;

  w := FindWidget('segScale');
  if w is TFtSegmentedControl then
  begin
    FSegScale := TFtSegmentedControl(w);
    FSegScale.OnSelect := @HandleSegmentScaleSelect;
  end;

  w := FindWidget('btnRotate0');
  if w is TFtButton then
  begin
    FBtnRotate0 := TFtButton(w);
    FBtnRotate0.Tag := 0;
    FBtnRotate0.OnClick := @HandleRotateButtonClick;
  end;

  w := FindWidget('btnRotate90');
  if w is TFtButton then
  begin
    FBtnRotate90 := TFtButton(w);
    FBtnRotate90.Tag := 1;
    FBtnRotate90.OnClick := @HandleRotateButtonClick;
  end;

  w := FindWidget('btnRotate180');
  if w is TFtButton then
  begin
    FBtnRotate180 := TFtButton(w);
    FBtnRotate180.Tag := 2;
    FBtnRotate180.OnClick := @HandleRotateButtonClick;
  end;

  w := FindWidget('btnRotate270');
  if w is TFtButton then
  begin
    FBtnRotate270 := TFtButton(w);
    FBtnRotate270.Tag := 3;
    FBtnRotate270.OnClick := @HandleRotateButtonClick;
  end;

  w := FindWidget('lblDisplayInfo');
  if w is TFtLabel then FLblDisplayInfo := TFtLabel(w);

  w := FindWidget('btnDisplayApply');
  if w is TFtButton then
  begin
    FBtnDisplayApply := TFtButton(w);
    FBtnDisplayApply.OnClick := @HandleDisplayApplyClick;
  end;

  w := FindWidget('swNightLight');
  if w is TFtSwitch then
  begin
    FSwNightLight := TFtSwitch(w);
    FSwNightLight.OnToggle := @HandleNightLightToggle;
  end;

  // Wallpaper presets
  w := FindWidget('btnWallSamarinda');
  if w is TFtButton then TFtButton(w).OnClick := @HandleWallpaperPresetClick;
  w := FindWidget('btnWallMountains');
  if w is TFtButton then TFtButton(w).OnClick := @HandleWallpaperPresetClick;
  w := FindWidget('btnWallSunset');
  if w is TFtButton then TFtButton(w).OnClick := @HandleWallpaperPresetClick;
  w := FindWidget('btnWallAurora');
  if w is TFtButton then TFtButton(w).OnClick := @HandleWallpaperPresetClick;

  // Desktop & Dock controls
  w := FindWidget('cmbDockPosition');
  if w is TFtComboBox then
  begin
    FCmbDockPosition := TFtComboBox(w);
    FCmbDockPosition.OnChange := @HandleDockPositionChange;
  end;

  w := FindWidget('segDockPosition');
  if w is TFtSegmentedControl then
  begin
    FSegDockPosition := TFtSegmentedControl(w);
    FSegDockPosition.OnSelect := @HandleSegmentDockPositionSelect;
  end;

  w := FindWidget('cmbDockIconSize');
  if w is TFtComboBox then
  begin
    FCmbDockIconSize := TFtComboBox(w);
    FCmbDockIconSize.OnChange := @HandleDockIconSizeChange;
  end;

  w := FindWidget('swDockAutoHide');
  if w is TFtSwitch then
  begin
    FSwDockAutoHide := TFtSwitch(w);
    FSwDockAutoHide.OnToggle := @HandleDockAutoHideToggle;
  end;

  w := FindWidget('cmbDockMargin');
  if w is TFtComboBox then
  begin
    FCmbDockMargin := TFtComboBox(w);
    FCmbDockMargin.OnChange := @HandleDockMarginChange;
  end;

  w := FindWidget('swShowDesktopBtn');
  if w is TFtSwitch then
  begin
    FSwShowDesktopBtn := TFtSwitch(w);
    FSwShowDesktopBtn.OnToggle := @HandleShowDesktopToggle;
  end;

  w := FindWidget('swClock24h');
  if w is TFtSwitch then
  begin
    FSwClock24h := TFtSwitch(w);
    FSwClock24h.OnToggle := @HandleClock24hToggle;
  end;

  // Language controls
  w := FindWidget('cmbDisplayLanguage');
  if w is TFtComboBox then
  begin
    FCmbDisplayLanguage := TFtComboBox(w);
    FCmbDisplayLanguage.OnChange := @HandleDisplayLanguageChange;
  end;

  w := FindWidget('cmbRegionalFormats');
  if w is TFtComboBox then
  begin
    FCmbRegionalFormats := TFtComboBox(w);
    FCmbRegionalFormats.OnChange := @HandleRegionalFormatsChange;
  end;

  // Sound controls
  w := FindWidget('cmbOutputDevice');
  if w is TFtComboBox then
  begin
    FCmbOutputDevice := TFtComboBox(w);
    FCmbOutputDevice.OnChange := @HandleOutputDeviceChange;
  end;

  w := FindWidget('slVolume');
  if w is TFtSlider then
  begin
    FSlVolume := TFtSlider(w);
    FSlVolume.SetRange(0.0, 100.0);
    FSlVolume.OnChange := @HandleVolumeChange;
  end;

  w := FindWidget('lblVolumePercent');
  if w is TFtLabel then FLblVolumePercent := TFtLabel(w);

  w := FindWidget('swMute');
  if w is TFtSwitch then
  begin
    FSwMute := TFtSwitch(w);
    FSwMute.OnToggle := @HandleMuteToggle;
  end;

  w := FindWidget('btnTestSound');
  if w is TFtButton then
  begin
    FBtnTestSound := TFtButton(w);
    FBtnTestSound.OnClick := @HandleTestSoundClick;
  end;

  w := FindWidget('cmbInputDevice');
  if w is TFtComboBox then
  begin
    FCmbInputDevice := TFtComboBox(w);
    FCmbInputDevice.OnChange := @HandleInputDeviceChange;
  end;

  w := FindWidget('slInputVolume');
  if w is TFtSlider then
  begin
    FSlInputVolume := TFtSlider(w);
    FSlInputVolume.SetRange(0.0, 100.0);
    FSlInputVolume.OnChange := @HandleInputVolumeChange;
  end;

  w := FindWidget('lblInputVolumePercent');
  if w is TFtLabel then FLblInputVolumePercent := TFtLabel(w);

  w := FindWidget('swInputMute');
  if w is TFtSwitch then
  begin
    FSwInputMute := TFtSwitch(w);
    FSwInputMute.OnToggle := @HandleInputMuteToggle;
  end;

  w := FindWidget('swSoundEffects');
  if w is TFtSwitch then
  begin
    FSwSoundEffects := TFtSwitch(w);
    FSwSoundEffects.OnToggle := @HandleSoundEffectsToggle;
  end;

  // Power controls
  w := FindWidget('lblBatteryPercent');
  if w is TFtLabel then FLblBatteryPercent := TFtLabel(w);

  w := FindWidget('lblBatteryRemaining');
  if w is TFtLabel then FLblBatteryRemaining := TFtLabel(w);

  w := FindWidget('imgBatteryBolt');
  if w is TFtImage then FImgBatteryBolt := TFtImage(w);

  w := FindWidget('segPowerMode');
  if w is TFtSegmentedControl then
  begin
    FSegPowerMode := TFtSegmentedControl(w);
    FSegPowerMode.OnSelect := @HandleSegmentPowerModeSelect;
  end;

  w := FindWidget('cmbPowerMode');
  if w is TFtComboBox then
  begin
    FCmbPowerMode := TFtComboBox(w);
    FCmbPowerMode.OnChange := @HandlePowerModeChange;
  end;

  w := FindWidget('cmbScreenBlank');
  if w is TFtComboBox then
  begin
    FCmbScreenBlank := TFtComboBox(w);
    FCmbScreenBlank.OnChange := @HandleScreenBlankChange;
  end;

  w := FindWidget('swAutoSuspend');
  if w is TFtSwitch then
  begin
    FSwAutoSuspend := TFtSwitch(w);
    FSwAutoSuspend.OnToggle := @HandleAutoSuspendToggle;
  end;

  w := FindWidget('lblMaxCapacity');
  if w is TFtLabel then FLblMaxCapacity := TFtLabel(w);

  w := FindWidget('txtPowerStatus');
  if w is TFtEntry then FTxtPowerStatus := TFtEntry(w);

  // Mouse controls
  w := FindWidget('cmbPrimaryBtn');
  if w is TFtComboBox then
  begin
    FCmbPrimaryBtn := TFtComboBox(w);
    FCmbPrimaryBtn.OnChange := @HandlePrimaryBtnChange;
  end;

  w := FindWidget('slPointerSpeed');
  if w is TFtSlider then
  begin
    FSlPointerSpeed := TFtSlider(w);
    FSlPointerSpeed.SetRange(0.0, 100.0);
    FSlPointerSpeed.OnChange := @HandlePointerSpeedChange;
  end;

  w := FindWidget('swNaturalScroll');
  if w is TFtSwitch then
  begin
    FSwNaturalScroll := TFtSwitch(w);
    FSwNaturalScroll.OnToggle := @HandleNaturalScrollToggle;
  end;

  w := FindWidget('swTapToClick');
  if w is TFtSwitch then
  begin
    FSwTapToClick := TFtSwitch(w);
    FSwTapToClick.OnToggle := @HandleTapToClickToggle;
  end;

  // Keyboard controls
  w := FindWidget('cmbKeyboardLayout');
  if w is TFtComboBox then
  begin
    FCmbKeyboardLayout := TFtComboBox(w);
    FCmbKeyboardLayout.OnChange := @HandleKeyboardLayoutChange;
  end;

  w := FindWidget('slKeyDelay');
  if w is TFtSlider then
  begin
    FSlKeyDelay := TFtSlider(w);
    FSlKeyDelay.SetRange(100.0, 1000.0);
    FSlKeyDelay.OnChange := @HandleKeyDelayChange;
  end;

  w := FindWidget('slKeyRate');
  if w is TFtSlider then
  begin
    FSlKeyRate := TFtSlider(w);
    FSlKeyRate.SetRange(5.0, 60.0);
    FSlKeyRate.OnChange := @HandleKeyRateChange;
  end;

  w := FindWidget('swSuperLauncher');
  if w is TFtSwitch then
  begin
    FSwSuperLauncher := TFtSwitch(w);
    FSwSuperLauncher.OnToggle := @HandleSuperLauncherToggle;
  end;

  // Application controls
  w := FindWidget('cmbBrowser');
  if w is TFtComboBox then
  begin
    FCmbBrowser := TFtComboBox(w);
    FCmbBrowser.OnChange := @HandleBrowserChange;
  end;

  w := FindWidget('cmbFileManager');
  if w is TFtComboBox then
  begin
    FCmbFileManager := TFtComboBox(w);
    FCmbFileManager.OnChange := @HandleFileManagerChange;
  end;

  w := FindWidget('cmbTerminal');
  if w is TFtComboBox then
  begin
    FCmbTerminal := TFtComboBox(w);
    FCmbTerminal.OnChange := @HandleTerminalChange;
  end;

  w := FindWidget('cmbEditor');
  if w is TFtComboBox then
  begin
    FCmbEditor := TFtComboBox(w);
    FCmbEditor.OnChange := @HandleEditorChange;
  end;

  // About controls
  w := FindWidget('txtAboutOs');
  if w is TFtEntry then FTxtAboutOs := TFtEntry(w);

  w := FindWidget('txtAboutShell');
  if w is TFtEntry then FTxtAboutShell := TFtEntry(w);

  w := FindWidget('txtAboutWm');
  if w is TFtEntry then FTxtAboutWm := TFtEntry(w);

  w := FindWidget('txtAboutToolkit');
  if w is TFtEntry then FTxtAboutToolkit := TFtEntry(w);

  w := FindWidget('txtAboutKernel');
  if w is TFtEntry then FTxtAboutKernel := TFtEntry(w);

  w := FindWidget('txtAboutCpu');
  if w is TFtEntry then FTxtAboutCpu := TFtEntry(w);

  w := FindWidget('txtAboutMem');
  if w is TFtEntry then FTxtAboutMem := TFtEntry(w);
end;

procedure TConfigSamaWindow.PopulateControls();
begin
  if FSettings = nil then Exit();

  FUpdatingControls := True;
  try
    FtApp.DarkMode := FSettings.DarkMode;
    UpdateThemeIcons();

    // WLAN
    if Assigned(FSwWlan) then
      FSwWlan.Checked := WlanService().IsWifiEnabled();
    RefreshWlanUI(False);

    // Wired
    RefreshWiredUI();

    // Bluetooth
    RefreshBluetoothUI();

    // Displays
    RefreshDisplayUI();

    // Appearance
    RefreshAppearanceUI();

    // Sound
    RefreshSoundUI();

    // Power
    RefreshPowerUI();

    if Assigned(FCmbAccent) then
      FCmbAccent.Text := FSettings.AccentColor;

    if Assigned(FCmbWallpaperMode) then
      FCmbWallpaperMode.Text := FSettings.WallpaperMode;

    if Assigned(FTxtWallpaperPath) then
      FTxtWallpaperPath.Text := FSettings.WallpaperPath;

    // Displays
    if Assigned(FCmbResolution) then
      FCmbResolution.Text := FSettings.Resolution;

    if Assigned(FSegScale) then
    begin
      case FSettings.Scale of
        100: FSegScale.SelectedIndex := 0;
        125: FSegScale.SelectedIndex := 1;
        150: FSegScale.SelectedIndex := 2;
        175: FSegScale.SelectedIndex := 3;
        200: FSegScale.SelectedIndex := 4;
        else FSegScale.SelectedIndex := 0;
      end;
    end;

    if Assigned(FSwNightLight) then
      FSwNightLight.Checked := FSettings.NightLight;

    // Desktop & Dock
    if Assigned(FCmbDockPosition) then
      FCmbDockPosition.Text := FSettings.DockPosition;

    if Assigned(FSegDockPosition) then
    begin
      if SameText(FSettings.DockPosition, 'Left') then
        FSegDockPosition.SelectedIndex := 0
      else if SameText(FSettings.DockPosition, 'Right') then
        FSegDockPosition.SelectedIndex := 2
      else
        FSegDockPosition.SelectedIndex := 1;
    end;

    if Assigned(FCmbDockIconSize) then
      FCmbDockIconSize.Text := IntToStr(FSettings.DockIconSize) + ' px';

    if Assigned(FSwDockAutoHide) then
      FSwDockAutoHide.Checked := FSettings.DockAutoHide;

    if Assigned(FCmbDockMargin) then
      FCmbDockMargin.Text := IntToStr(FSettings.DockMargin) + ' px';

    if Assigned(FSwShowDesktopBtn) then
      FSwShowDesktopBtn.Checked := FSettings.ShowDesktopButton;

    if Assigned(FSwClock24h) then
      FSwClock24h.Checked := (FSettings.ClockFormat = '24h');

    // Sound
    if Assigned(FCmbOutputDevice) then
      FCmbOutputDevice.Text := FSettings.OutputDevice;

    if Assigned(FSlVolume) then
      FSlVolume.Value := FSettings.OutputVolume;

    if Assigned(FSwMute) then
      FSwMute.Checked := FSettings.Muted;

    if Assigned(FSwSoundEffects) then
      FSwSoundEffects.Checked := FSettings.SoundEffects;

    // Power
    if Assigned(FCmbPowerMode) then
      FCmbPowerMode.Text := FSettings.PowerMode;

    if Assigned(FSwAutoSuspend) then
      FSwAutoSuspend.Checked := FSettings.AutoSuspend;

    // Mouse
    if Assigned(FCmbPrimaryBtn) then
      FCmbPrimaryBtn.Text := FSettings.PrimaryButton;

    if Assigned(FSlPointerSpeed) then
      FSlPointerSpeed.Value := FSettings.PointerSpeed;

    if Assigned(FSwNaturalScroll) then
      FSwNaturalScroll.Checked := FSettings.NaturalScrolling;

    if Assigned(FSwTapToClick) then
      FSwTapToClick.Checked := FSettings.TapToClick;

    // Keyboard
    if Assigned(FCmbKeyboardLayout) then
      FCmbKeyboardLayout.Text := FSettings.KeyboardLayout;

    if Assigned(FSlKeyDelay) then
      FSlKeyDelay.Value := FSettings.KeyRepeatDelay;

    if Assigned(FSlKeyRate) then
      FSlKeyRate.Value := FSettings.KeyRepeatRate;

    if Assigned(FSwSuperLauncher) then
      FSwSuperLauncher.Checked := FSettings.SuperKeyLauncher;

    // Applications
    if Assigned(FCmbBrowser) then
      FCmbBrowser.Text := FSettings.DefaultBrowser;

    if Assigned(FCmbFileManager) then
      FCmbFileManager.Text := FSettings.DefaultFileManager;

    if Assigned(FCmbTerminal) then
      FCmbTerminal.Text := FSettings.DefaultTerminal;

    if Assigned(FCmbEditor) then
      FCmbEditor.Text := FSettings.DefaultTextEditor;

    // About
    if Assigned(FTxtAboutOs) then
      FTxtAboutOs.Text := FSettings.GetOsName() + ' ' + FSettings.GetOsVersion();

    if Assigned(FTxtAboutKernel) then
      FTxtAboutKernel.Text := FSettings.GetKernelVersion();

    if Assigned(FTxtAboutCpu) then
      FTxtAboutCpu.Text := FSettings.GetCpuModel();

    if Assigned(FTxtAboutMem) then
      FTxtAboutMem.Text := FSettings.GetMemoryTotal();
  finally
    FUpdatingControls := False;
  end;
end;

procedure TConfigSamaWindow.SetDarkMode(AValue: Boolean);
begin
  if FSettings <> nil then
  begin
    FSettings.DarkMode := AValue;
    FSettings.Save();
  end;
  FtApp.DarkMode := AValue;
  if FSwDarkMode <> nil then
    FSwDarkMode.Checked := AValue;
  UpdateThemeIcons();
  Invalidate();
end;

procedure TConfigSamaWindow.SelectCategoryByName(const AName: string);
var
  i, j: Integer;
  hNode, cNode: TFtTreeNode;
begin
  if FSelectingCategory then Exit;
  FSelectingCategory := True;
  try
    if FPageWlan <> nil then
    begin
      FPageWlan.Visible := SameText(AName, 'WLAN') or SameText(AName, 'Wi-Fi');
      if FPageWlan.Visible then
        RefreshWlanUI(False);
    end;
    if FPageWired <> nil then
    begin
      FPageWired.Visible := SameText(AName, 'Wired');
      if FPageWired.Visible then
        RefreshWiredUI();
    end;
    if FPageBluetooth <> nil then
    begin
      FPageBluetooth.Visible := SameText(AName, 'Bluetooth');
      if FPageBluetooth.Visible then
        RefreshBluetoothUI();
    end;
    if FPageDisplays <> nil then
    begin
      FPageDisplays.Visible := SameText(AName, 'Display') or SameText(AName, 'Displays');
      if FPageDisplays.Visible then
        RefreshDisplayUI();
    end;
    if FPageAppearance <> nil then
    begin
      FPageAppearance.Visible := SameText(AName, 'Appearance');
      if FPageAppearance.Visible then
        RefreshAppearanceUI();
    end;
    if FPageBackground <> nil then FPageBackground.Visible := SameText(AName, 'Background');
    if FPageDesktop <> nil then FPageDesktop.Visible := SameText(AName, 'Dock') or SameText(AName, 'Desktop & Dock');
    if FPageUser <> nil then FPageUser.Visible := SameText(AName, 'User') or SameText(AName, 'Users');
    if FPageLanguage <> nil then FPageLanguage.Visible := SameText(AName, 'Language');
    if FPageBattery <> nil then
    begin
      FPageBattery.Visible := SameText(AName, 'Battery') or SameText(AName, 'Power');
      if FPageBattery.Visible then
        RefreshPowerUI();
    end;
    if FPageSound <> nil then
    begin
      FPageSound.Visible := SameText(AName, 'Sound') or SameText(AName, 'Audio');
      if FPageSound.Visible then
        RefreshSoundUI();
    end;
    if FPagePower <> nil then
    begin
      FPagePower.Visible := SameText(AName, 'Power') or SameText(AName, 'Battery');
      if FPagePower.Visible then
        RefreshPowerUI();
    end;
    if FPageMouse <> nil then FPageMouse.Visible := SameText(AName, 'Mouse & Touchpad');
    if FPageKeyboard <> nil then
      FPageKeyboard.Visible := SameText(AName, 'Keyboard & Shortcuts') or SameText(AName, 'Keyboard');
    if FPageApps <> nil then
      FPageApps.Visible := SameText(AName, 'Default Applications') or SameText(AName, 'Applications');
    if FPageAbout <> nil then FPageAbout.Visible := SameText(AName, 'About');

    if FSectionTitle <> nil then
      FSectionTitle.Text := AName;

    // Sync selected node in tree if available
    if (FCategoryTree <> nil) and (FCategoryTree.Root <> nil) then
    begin
      for i := 0 to FCategoryTree.Root.ChildCount - 1 do
      begin
        hNode := FCategoryTree.Root.Children[i];
        for j := 0 to hNode.ChildCount - 1 do
        begin
          cNode := hNode.Children[j];
          if SameText(cNode.Text, AName) or
             (SameText(AName, 'Displays') and SameText(cNode.Text, 'Display')) or
             (SameText(AName, 'Desktop & Dock') and SameText(cNode.Text, 'Dock')) or
             (SameText(AName, 'Battery') and SameText(cNode.Text, 'Power')) or
             (SameText(AName, 'Power') and SameText(cNode.Text, 'Battery')) then
          begin
            if FCategoryTree.SelectedNode <> cNode then
              FCategoryTree.SelectedNode := cNode;
            Break;
          end;
        end;
      end;
    end;

    Invalidate();
  finally
    FSelectingCategory := False;
  end;
end;

procedure TConfigSamaWindow.HandleCategorySelect(Sender: TFtTreeView; Node: TFtTreeNode);
begin
  if Node = nil then Exit();
  SelectCategoryByName(Node.Text);
end;

procedure TConfigSamaWindow.HandleSearchChange(Sender: TFtWidget; const AText: string);
var
  q: string;
begin
  q := LowerCase(Trim(AText));
  if q = '' then Exit();

  if (Pos('wifi', q) > 0) or (Pos('wlan', q) > 0) or (Pos('wirel', q) > 0) then SelectCategoryByName('WLAN')
  else if (Pos('ether', q) > 0) or (Pos('wired', q) > 0) or (Pos('lan', q) > 0) then SelectCategoryByName('Wired')
  else if (Pos('blue', q) > 0) or (Pos('bt', q) > 0) then SelectCategoryByName('Bluetooth')
  else if (Pos('appear', q) > 0) or (Pos('theme', q) > 0) or (Pos('font', q) > 0) or (Pos('dark', q) > 0) then SelectCategoryByName('Appearance')
  else if (Pos('disp', q) > 0) or (Pos('screen', q) > 0) or (Pos('resolut', q) > 0) then SelectCategoryByName('Displays')
  else if (Pos('wall', q) > 0) or (Pos('backg', q) > 0) then SelectCategoryByName('Background')
  else if (Pos('dock', q) > 0) or (Pos('panel', q) > 0) or (Pos('desk', q) > 0) then SelectCategoryByName('Desktop & Dock')
  else if (Pos('user', q) > 0) or (Pos('acc', q) > 0) then SelectCategoryByName('User')
  else if (Pos('lang', q) > 0) or (Pos('loc', q) > 0) then SelectCategoryByName('Language')
  else if (Pos('sound', q) > 0) or (Pos('vol', q) > 0) or (Pos('audio', q) > 0) or (Pos('speaker', q) > 0) then SelectCategoryByName('Sound')
  else if (Pos('power', q) > 0) or (Pos('batt', q) > 0) or (Pos('sleep', q) > 0) or (Pos('suspend', q) > 0) then SelectCategoryByName('Power')
  else if (Pos('mouse', q) > 0) or (Pos('touch', q) > 0) or (Pos('cursor', q) > 0) then SelectCategoryByName('Mouse & Touchpad')
  else if (Pos('key', q) > 0) or (Pos('short', q) > 0) then SelectCategoryByName('Keyboard & Shortcuts')
  else if (Pos('app', q) > 0) or (Pos('browser', q) > 0) or (Pos('term', q) > 0) then SelectCategoryByName('Default Applications')
  else if (Pos('about', q) > 0) or (Pos('sys', q) > 0) or (Pos('info', q) > 0) then SelectCategoryByName('About');
end;

procedure TConfigSamaWindow.UpdateThemeIcons();
var
  w: TFtWidget;
begin
  if FImgWifiPurr <> nil then FImgWifiPurr.LoadSVGString(FtApp.GetIconSvg('wlan', FtApp.DarkMode));
  if FImgLockPurr <> nil then FImgLockPurr.LoadSVGString(FtApp.GetIconSvg('lock', FtApp.DarkMode));
  if FImgWifiMeow <> nil then FImgWifiMeow.LoadSVGString(FtApp.GetIconSvg('wlan', FtApp.DarkMode));
  if FImgLockMeow <> nil then FImgLockMeow.LoadSVGString(FtApp.GetIconSvg('lock', FtApp.DarkMode));
  if FImgWifiVirgin <> nil then FImgWifiVirgin.LoadSVGString(FtApp.GetIconSvg('wlan', FtApp.DarkMode));
  if FImgLockVirgin <> nil then FImgLockVirgin.LoadSVGString(FtApp.GetIconSvg('lock', FtApp.DarkMode));
  if FImgWifiVM <> nil then FImgWifiVM.LoadSVGString(FtApp.GetIconSvg('wlan', FtApp.DarkMode));
  if FImgLockVM <> nil then FImgLockVM.LoadSVGString(FtApp.GetIconSvg('lock', FtApp.DarkMode));
  if FImgWired <> nil then FImgWired.LoadSVGString(FtApp.GetIconSvg('wired', FtApp.DarkMode));
  if FBtnPurrInfo <> nil then FBtnPurrInfo.SetIconSVG(FtApp.GetIconSvg('info-accent', FtApp.DarkMode));

  w := FindWidget('imgBrightnessLow');
  if w is TFtImage then TFtImage(w).LoadSVGString(FtApp.GetIconSvg('brightness-low', FtApp.DarkMode));
  w := FindWidget('imgBrightnessHigh');
  if w is TFtImage then TFtImage(w).LoadSVGString(FtApp.GetIconSvg('brightness-high', FtApp.DarkMode));
  w := FindWidget('btnRotate0');
  if w is TFtButton then TFtButton(w).SetIconSVG(FtApp.GetIconSvg('rotate-0', FtApp.DarkMode));
  w := FindWidget('btnRotate90');
  if w is TFtButton then TFtButton(w).SetIconSVG(FtApp.GetIconSvg('rotate-90', FtApp.DarkMode));
  w := FindWidget('btnRotate180');
  if w is TFtButton then TFtButton(w).SetIconSVG(FtApp.GetIconSvg('rotate-180', FtApp.DarkMode));
  w := FindWidget('btnRotate270');
  if w is TFtButton then TFtButton(w).SetIconSVG(FtApp.GetIconSvg('rotate-270', FtApp.DarkMode));

  if FCategoryTree <> nil then FCategoryTree.Invalidate();
end;

procedure TConfigSamaWindow.HandleThemeLightClick(Sender: TFtButton);
begin
  if FSwDarkMode <> nil then
  begin
    FSwDarkMode.Checked := False;
    HandleDarkModeToggle(FSwDarkMode, False);
  end;
end;

procedure TConfigSamaWindow.HandleThemeDarkClick(Sender: TFtButton);
begin
  if FSwDarkMode <> nil then
  begin
    FSwDarkMode.Checked := True;
    HandleDarkModeToggle(FSwDarkMode, True);
  end;
end;

procedure TConfigSamaWindow.HandleAccentButtonClick(Sender: TFtButton);
var
  colorName: string;
begin
  if Sender = nil then Exit();
  case Sender.Tag of
    1: colorName := 'Blue';
    2: colorName := 'Purple';
    3: colorName := 'Pink';
    4: colorName := 'Red';
    5: colorName := 'Orange';
    6: colorName := 'Yellow';
    7: colorName := 'Green';
    else colorName := 'Blue';
  end;

  if FSettings <> nil then
  begin
    FSettings.AccentColor := colorName;
    FSettings.Save();
  end;
  if FCmbAccent <> nil then
    FCmbAccent.Text := colorName;
end;

procedure TConfigSamaWindow.HandleDarkModeToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  FSettings.DarkMode := AToggled;
  FSettings.Save();
  FtApp.DarkMode := AToggled;
  UpdateThemeIcons();
  Invalidate();
end;

procedure TConfigSamaWindow.HandleAccentChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.AccentColor := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleWallpaperModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.WallpaperMode := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleChooseWallpaperClick(Sender: TFtButton);
var
  picked: string;
begin
  picked := TFtFileDialog.OpenFile('Select Desktop Wallpaper', GetEnvironmentVariable('HOME'), 'Images (*.png;*.jpg;*.jpeg)|*.png;*.jpg;*.jpeg');
  if picked <> '' then
  begin
    if FTxtWallpaperPath <> nil then
      FTxtWallpaperPath.Text := picked;
    if FSettings <> nil then
    begin
      FSettings.WallpaperPath := picked;
      FSettings.Save();
    end;
  end;
end;

procedure TConfigSamaWindow.HandleWallpaperPresetClick(Sender: TFtButton);
var
  wallName, wallPath: string;
begin
  if FSettings = nil then Exit();
  wallName := LowerCase(Sender.Caption);
  wallPath := '/usr/share/backgrounds/' + wallName + '.jpg';
  if FTxtWallpaperPath <> nil then
    FTxtWallpaperPath.Text := wallPath;
  FSettings.WallpaperPath := wallPath;
  FSettings.Save();
end;

function TConfigSamaWindow.GetSelectedDisplayName(): string;
var
  s: string;
  p: Integer;
  primary: TDisplayOutput;
begin
  if Assigned(FCmbDisplay) and (FCmbDisplay.Text <> '') then
  begin
    s := FCmbDisplay.Text;
    p := Pos(' ', s);
    if p > 0 then
      Result := Copy(s, 1, p - 1)
    else
      Result := s;
  end
  else
  begin
    primary := DisplayService().GetPrimaryOutput();
    Result := primary.Name;
  end;
end;

procedure TConfigSamaWindow.UpdateRotationButtonStates(const ARotation: string);
var
  r: string;
begin
  r := LowerCase(ARotation);
  if Assigned(FBtnRotate0) then
    FBtnRotate0.Flat := (r <> 'normal');
  if Assigned(FBtnRotate90) then
    FBtnRotate90.Flat := (r <> 'left');
  if Assigned(FBtnRotate180) then
    FBtnRotate180.Flat := (r <> 'inverted');
  if Assigned(FBtnRotate270) then
    FBtnRotate270.Flat := (r <> 'right');
end;

procedure TConfigSamaWindow.HandleRotateButtonClick(Sender: TFtButton);
var
  dev, rot: string;
begin
  if Sender = nil then Exit();
  dev := GetSelectedDisplayName();
  case Sender.Tag of
    0: rot := 'normal';
    1: rot := 'left';
    2: rot := 'inverted';
    3: rot := 'right';
    else rot := 'normal';
  end;
  DisplayService().SetRotation(dev, rot);
  RefreshDisplayUI();
end;

procedure TConfigSamaWindow.HandleBrightnessChange(Sender: TFtSlider; AValue: Double);
var
  dev: string;
  pct: Integer;
begin
  if FUpdatingControls then Exit();
  pct := Round(AValue);
  dev := GetSelectedDisplayName();
  DisplayService().SetBrightness(dev, pct);
end;

procedure TConfigSamaWindow.HandleDisplayChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FUpdatingControls then Exit();
  RefreshDisplayUI();
end;

procedure TConfigSamaWindow.HandleResolutionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  dev, resText, sW, sH: string;
  p, pX, w, h: Integer;
  outItem: TDisplayOutput;
  rateItems: TStringList;
  i, j, k: Integer;
begin
  if FUpdatingControls then Exit();
  resText := AText;
  p := Pos('(', resText);
  if p > 0 then
    resText := Trim(Copy(resText, 1, p - 1));

  pX := Pos('×', resText);
  if pX = 0 then pX := Pos('x', resText);
  if pX > 0 then
  begin
    sW := Trim(Copy(resText, 1, pX - 1));
    sH := Trim(Copy(resText, pX + 1, Length(resText)));
    w := StrToIntDef(sW, 1920);
    h := StrToIntDef(sH, 1080);
  end
  else
  begin
    w := 1920;
    h := 1080;
  end;

  if FSettings <> nil then
  begin
    FSettings.Resolution := IntToStr(w) + 'x' + IntToStr(h);
    FSettings.Save();
  end;

  dev := GetSelectedDisplayName();
  outItem := DisplayService().GetOutput(dev);
  if Assigned(FCmbRefreshRate) and (Length(outItem.Modes) > 0) then
  begin
    rateItems := TStringList.Create();
    try
      for i := 0 to High(outItem.Modes) do
      begin
        if (outItem.Modes[i].Width = w) and (outItem.Modes[i].Height = h) then
        begin
          for j := 0 to High(outItem.Modes[i].Rates) do
            rateItems.Add(Format('%.2f Hz', [outItem.Modes[i].Rates[j]]));
          Break;
        end;
      end;
      if rateItems.Count > 0 then
      begin
        FCmbRefreshRate.Clear();
        for k := 0 to rateItems.Count - 1 do
          FCmbRefreshRate.AddItem(rateItems[k]);
        FCmbRefreshRate.SelectedIndex := 0;
      end;
    finally
      rateItems.Free();
    end;
  end;
end;

procedure TConfigSamaWindow.HandleRefreshRateChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, rate: Integer;
  rateStr: string;
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  rateStr := AText;
  p := Pos(' ', rateStr);
  if p > 0 then
    rateStr := Copy(rateStr, 1, p - 1);
  rate := StrToIntDef(rateStr, 60);
  FSettings.RefreshRate := rate;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDisplayApplyClick(Sender: TFtButton);
var
  dev, resText, sW, sH, rateStr: string;
  p, pX, w, h: Integer;
  rateVal: Double;
  fs: TFormatSettings;
begin
  dev := GetSelectedDisplayName();
  if dev = '' then Exit();

  w := 1920;
  h := 1080;
  if Assigned(FCmbResolution) then
  begin
    resText := FCmbResolution.Text;
    p := Pos('(', resText);
    if p > 0 then resText := Trim(Copy(resText, 1, p - 1));
    pX := Pos('×', resText);
    if pX = 0 then pX := Pos('x', resText);
    if pX > 0 then
    begin
      sW := Trim(Copy(resText, 1, pX - 1));
      sH := Trim(Copy(resText, pX + 1, Length(resText)));
      w := StrToIntDef(sW, 1920);
      h := StrToIntDef(sH, 1080);
    end;
  end;

  rateVal := 60.0;
  if Assigned(FCmbRefreshRate) and (FCmbRefreshRate.Text <> '') then
  begin
    rateStr := FCmbRefreshRate.Text;
    p := Pos(' ', rateStr);
    if p > 0 then rateStr := Copy(rateStr, 1, p - 1);
    fs.DecimalSeparator := '.';
    if not TryStrToFloat(rateStr, rateVal, fs) then
    begin
      fs.DecimalSeparator := ',';
      TryStrToFloat(rateStr, rateVal, fs);
    end;
  end;

  if DisplayService().SetMode(dev, w, h, rateVal) then
  begin
    if FSettings <> nil then
    begin
      FSettings.Resolution := IntToStr(w) + 'x' + IntToStr(h);
      FSettings.RefreshRate := Round(rateVal);
      FSettings.Save();
    end;
  end;

  RefreshDisplayUI();
end;

procedure TConfigSamaWindow.RefreshDisplayUI();
var
  outputs: TDisplayOutputArray;
  primary: TDisplayOutput;
  outNames, resItems, rateItems: TStringList;
  i, j, k, selOutIdx, curResIdx, curRateIdx: Integer;
  resLabel, rateLabel, infoStr, selDevName: string;
  foundRes: Boolean;
begin
  outputs := DisplayService().QueryOutputs();
  if Length(outputs) = 0 then Exit();

  selDevName := GetSelectedDisplayName();
  primary := DisplayService().GetOutput(selDevName);
  if primary.Name = '' then
    primary := DisplayService().GetPrimaryOutput();

  FUpdatingControls := True;
  try
    // 1. Populate Display combobox
    if Assigned(FCmbDisplay) then
    begin
      outNames := TStringList.Create();
      try
        selOutIdx := 0;
        for i := 0 to High(outputs) do
        begin
          if outputs[i].IsConnected then
          begin
            if outputs[i].IsPrimary then
              outNames.Add(outputs[i].Name + ' (Primary)')
            else
              outNames.Add(outputs[i].Name);
            if SameText(outputs[i].Name, primary.Name) then
              selOutIdx := outNames.Count - 1;
          end;
        end;
        if outNames.Count = 0 then
          outNames.Add('Default Screen');

        FCmbDisplay.Clear();
        for k := 0 to outNames.Count - 1 do
          FCmbDisplay.AddItem(outNames[k]);
        if (selOutIdx >= 0) and (selOutIdx < FCmbDisplay.ItemCount) then
          FCmbDisplay.SelectedIndex := selOutIdx;
      finally
        outNames.Free();
      end;
    end;

    // 2. Brightness Slider
    if Assigned(FSldBrightness) and (primary.BrightnessPercent > 0) then
      FSldBrightness.Value := primary.BrightnessPercent;

    // 3. Populate Resolutions combobox
    if Assigned(FCmbResolution) then
    begin
      resItems := TStringList.Create();
      try
        curResIdx := -1;
        for i := 0 to High(primary.Modes) do
        begin
          resLabel := IntToStr(primary.Modes[i].Width) + ' × ' + IntToStr(primary.Modes[i].Height);
          if primary.Modes[i].IsPreferred then
            resLabel := resLabel + ' (Preferred)'
          else if (primary.Modes[i].Width = primary.CurrentWidth) and (primary.Modes[i].Height = primary.CurrentHeight) then
            resLabel := resLabel + ' (Current)';

          resItems.Add(resLabel);
          if (primary.Modes[i].Width = primary.CurrentWidth) and (primary.Modes[i].Height = primary.CurrentHeight) and (curResIdx < 0) then
            curResIdx := resItems.Count - 1;
        end;

        if resItems.Count > 0 then
        begin
          FCmbResolution.Clear();
          for k := 0 to resItems.Count - 1 do
            FCmbResolution.AddItem(resItems[k]);
          if (curResIdx >= 0) and (curResIdx < FCmbResolution.ItemCount) then
            FCmbResolution.SelectedIndex := curResIdx
          else
            FCmbResolution.SelectedIndex := 0;
        end;
      finally
        resItems.Free();
      end;
    end;

    // 4. Populate Refresh Rate combobox
    if Assigned(FCmbRefreshRate) then
    begin
      rateItems := TStringList.Create();
      try
        curRateIdx := -1;
        foundRes := False;
        for i := 0 to High(primary.Modes) do
        begin
          if (primary.Modes[i].Width = primary.CurrentWidth) and (primary.Modes[i].Height = primary.CurrentHeight) then
          begin
            foundRes := True;
            for j := 0 to High(primary.Modes[i].Rates) do
            begin
              rateLabel := Format('%.2f Hz', [primary.Modes[i].Rates[j]]);
              rateItems.Add(rateLabel);
              if Abs(primary.Modes[i].Rates[j] - primary.CurrentRate) < 0.05 then
                curRateIdx := rateItems.Count - 1;
            end;
            Break;
          end;
        end;

        if not foundRes or (rateItems.Count = 0) then
        begin
          rateItems.Add('60.00 Hz');
          rateItems.Add('75.00 Hz');
          rateItems.Add('120.00 Hz');
          curRateIdx := 0;
        end;

        FCmbRefreshRate.Clear();
        for k := 0 to rateItems.Count - 1 do
          FCmbRefreshRate.AddItem(rateItems[k]);
        if (curRateIdx >= 0) and (curRateIdx < FCmbRefreshRate.ItemCount) then
          FCmbRefreshRate.SelectedIndex := curRateIdx
        else
          FCmbRefreshRate.SelectedIndex := 0;
      finally
        rateItems.Free();
      end;
    end;

    // 5. Update rotation buttons
    UpdateRotationButtonStates(primary.CurrentRotation);

    // 6. Scale control
    if Assigned(FSegScale) and (FSettings <> nil) then
    begin
      case FSettings.Scale of
        100: FSegScale.SelectedIndex := 0;
        125: FSegScale.SelectedIndex := 1;
        150: FSegScale.SelectedIndex := 2;
        175: FSegScale.SelectedIndex := 3;
        200: FSegScale.SelectedIndex := 4;
        else FSegScale.SelectedIndex := 0;
      end;
    end;

    // 7. Status info label
    if Assigned(FLblDisplayInfo) then
    begin
      infoStr := primary.Name;
      if primary.CurrentWidth > 0 then
        infoStr := infoStr + ' • ' + IntToStr(primary.CurrentWidth) + ' × ' + IntToStr(primary.CurrentHeight);
      if primary.CurrentRate > 0 then
        infoStr := infoStr + Format(' @ %.2f Hz', [primary.CurrentRate]);
      if primary.CurrentRotation <> '' then
        infoStr := infoStr + ' (' + UpCase(primary.CurrentRotation[1]) + Copy(primary.CurrentRotation, 2, Length(primary.CurrentRotation)) + ')';
      FLblDisplayInfo.Text := infoStr;
    end;
  finally
    FUpdatingControls := False;
  end;

  Invalidate();
end;

procedure TConfigSamaWindow.HandleWiredToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls then Exit();
  WiredService().SetWiredEnabled(AToggled);
  RefreshWiredUI();
end;

procedure TConfigSamaWindow.HandleWiredRefresh(Sender: TFtButton);
begin
  RefreshWiredUI();
end;

procedure TConfigSamaWindow.HandleWiredConnectClick(Sender: TFtButton);
var
  primary: TWiredInterface;
begin
  primary := WiredService().GetPrimaryInterface();
  if primary.IsConnected then
    WiredService().Disconnect(primary.Device)
  else
    WiredService().Connect(primary.Device);
  RefreshWiredUI();
end;

procedure TConfigSamaWindow.RefreshWiredUI();
var
  isWiredOn: Boolean;
  primary: TWiredInterface;
  speedStr, ipStr, devTitle: string;
begin
  isWiredOn := WiredService().IsWiredEnabled();
  if Assigned(FSwWired) then
    FSwWired.Checked := isWiredOn;

  if not isWiredOn then
  begin
    if Assigned(FLblWiredStatus) then
      FLblWiredStatus.Text := 'Wired is turned off';
    if Assigned(FContainerWiredDisabled) then
      FContainerWiredDisabled.Visible := True;
    if Assigned(FCardWired) then
      FCardWired.Visible := False;
    Invalidate();
    Exit();
  end;

  if Assigned(FContainerWiredDisabled) then
    FContainerWiredDisabled.Visible := False;
  if Assigned(FCardWired) then
    FCardWired.Visible := True;

  primary := WiredService().GetPrimaryInterface();

  if primary.Device <> '' then
  begin
    devTitle := 'Ethernet (' + primary.Device + ')';
    if primary.ConnectionName <> '' then
      devTitle := primary.ConnectionName + ' (' + primary.Device + ')';

    if Assigned(FLblWiredDevice) then
      FLblWiredDevice.Text := devTitle;

    if primary.IsConnected then
    begin
      if Assigned(FLblWiredStatus) then
        FLblWiredStatus.Text := 'Connected';
      if Assigned(FBtnWiredConnect) then
      begin
        FBtnWiredConnect.Caption := 'Disconnect';
        FBtnWiredConnect.Visible := True;
      end;
    end
    else
    begin
      if primary.Carrier then
      begin
        if Assigned(FLblWiredStatus) then
          FLblWiredStatus.Text := 'Cable plugged in • Disconnected';
        if Assigned(FBtnWiredConnect) then
        begin
          FBtnWiredConnect.Caption := 'Connect';
          FBtnWiredConnect.Visible := True;
        end;
      end
      else
      begin
        if Assigned(FLblWiredStatus) then
          FLblWiredStatus.Text := 'Cable unplugged';
        if Assigned(FBtnWiredConnect) then
          FBtnWiredConnect.Visible := False;
      end;
    end;

    // Speed & Duplex
    if primary.Speed > 0 then
    begin
      speedStr := IntToStr(primary.Speed) + ' Mb/s';
      if primary.Duplex <> '' then
        speedStr := speedStr + ' (' + UpCase(primary.Duplex[1]) + Copy(primary.Duplex, 2, Length(primary.Duplex)) + ' Duplex)';
    end
    else if not primary.Carrier then
      speedStr := 'Cable unplugged'
    else
      speedStr := 'Unknown link speed';

    if Assigned(FLblWiredSpeed) then
      FLblWiredSpeed.Text := speedStr;

    // IPv4 & Gateway
    if primary.IpAddress <> '' then
    begin
      ipStr := primary.IpAddress;
      if primary.Gateway <> '' then
        ipStr := ipStr + ' (Gateway: ' + primary.Gateway + ')';
    end
    else
      ipStr := 'Not assigned';

    if Assigned(FLblWiredIp) then
      FLblWiredIp.Text := ipStr;

    // DNS
    if Assigned(FLblWiredDns) then
    begin
      if primary.Dns <> '' then
        FLblWiredDns.Text := primary.Dns
      else
        FLblWiredDns.Text := 'Not assigned';
    end;

    // MAC
    if Assigned(FLblWiredMac) then
    begin
      if primary.HwAddr <> '' then
        FLblWiredMac.Text := primary.HwAddr
      else
        FLblWiredMac.Text := 'Not available';
    end;
  end
  else
  begin
    if Assigned(FLblWiredStatus) then
      FLblWiredStatus.Text := 'No wired network adapter detected';
    if Assigned(FLblWiredDevice) then
      FLblWiredDevice.Text := 'No Ethernet interface';
    if Assigned(FLblWiredSpeed) then
      FLblWiredSpeed.Text := 'Not available';
    if Assigned(FLblWiredIp) then
      FLblWiredIp.Text := 'Not available';
    if Assigned(FLblWiredDns) then
      FLblWiredDns.Text := 'Not available';
    if Assigned(FLblWiredMac) then
      FLblWiredMac.Text := 'Not available';
    if Assigned(FBtnWiredConnect) then
      FBtnWiredConnect.Visible := False;
  end;

  Invalidate();
end;

procedure TConfigSamaWindow.HandleScaleChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, scaleVal: Integer;
  scaleStr: string;
begin
  if FSettings = nil then Exit();
  scaleStr := AText;
  p := Pos('%', scaleStr);
  if p > 0 then
    scaleStr := Copy(scaleStr, 1, p - 1);
  scaleVal := StrToIntDef(scaleStr, 100);
  FSettings.Scale := scaleVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleSegmentScaleSelect(Sender: TFtSegmentedControl; AIndex: Integer; const AText: string);
var
  p, scaleVal: Integer;
  scaleStr: string;
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  scaleStr := AText;
  p := Pos('%', scaleStr);
  if p > 0 then
    scaleStr := Copy(scaleStr, 1, p - 1);
  scaleVal := StrToIntDef(scaleStr, 100);
  FSettings.Scale := scaleVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleNightLightToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.NightLight := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockPositionChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DockPosition := AText;
  if Assigned(FSegDockPosition) then
  begin
    if SameText(AText, 'Left') then
      FSegDockPosition.SelectedIndex := 0
    else if SameText(AText, 'Right') then
      FSegDockPosition.SelectedIndex := 2
    else
      FSegDockPosition.SelectedIndex := 1;
  end;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleSegmentDockPositionSelect(Sender: TFtSegmentedControl; AIndex: Integer; const AText: string);
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  case AIndex of
    0: FSettings.DockPosition := 'Left';
    1: FSettings.DockPosition := 'Bottom';
    2: FSettings.DockPosition := 'Right';
  end;
  if Assigned(FCmbDockPosition) then
    FCmbDockPosition.Text := FSettings.DockPosition;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDisplayLanguageChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
end;

procedure TConfigSamaWindow.HandleRegionalFormatsChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
end;

procedure TConfigSamaWindow.HandleDockIconSizeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, sizeVal: Integer;
  sizeStr: string;
begin
  if FSettings = nil then Exit();
  sizeStr := AText;
  p := Pos(' ', sizeStr);
  if p > 0 then
    sizeStr := Copy(sizeStr, 1, p - 1);
  sizeVal := StrToIntDef(sizeStr, 48);
  FSettings.DockIconSize := sizeVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockAutoHideToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.DockAutoHide := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleDockMarginChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  p, marginVal: Integer;
  mStr: string;
begin
  if FSettings = nil then Exit();
  mStr := AText;
  p := Pos(' ', mStr);
  if p > 0 then
    mStr := Copy(mStr, 1, p - 1);
  marginVal := StrToIntDef(mStr, 3);
  FSettings.DockMargin := marginVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleShowDesktopToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.ShowDesktopButton := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleClock24hToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  if AToggled then
    FSettings.ClockFormat := '24h'
  else
    FSettings.ClockFormat := '12h';
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleOutputDeviceChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  outputs: TSoundDeviceArray;
begin
  if FUpdatingControls or (Sender = nil) then Exit();
  outputs := SoundService().GetOutputDevices();
  if (AIndex >= 0) and (AIndex < Length(outputs)) then
  begin
    SoundService().SetDefaultOutputDevice(outputs[AIndex].ID);
    if FSettings <> nil then
    begin
      FSettings.OutputDevice := outputs[AIndex].Name;
      FSettings.Save();
    end;
  end;
end;

procedure TConfigSamaWindow.HandleVolumeChange(Sender: TFtSlider; AValue: Double);
var
  vol: Integer;
begin
  if FUpdatingControls then Exit();
  vol := Round(AValue);
  SoundService().SetOutputVolume(vol);
  if Assigned(FLblVolumePercent) then
    FLblVolumePercent.Text := IntToStr(vol) + '%';
  if FSettings <> nil then
  begin
    FSettings.OutputVolume := vol;
    FSettings.Save();
  end;
end;

procedure TConfigSamaWindow.HandleMuteToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls then Exit();
  SoundService().SetOutputMuted(AToggled);
  if FSettings <> nil then
  begin
    FSettings.Muted := AToggled;
    FSettings.Save();
  end;
end;

procedure TConfigSamaWindow.HandleTestSoundClick(Sender: TFtButton);
begin
  SoundService().PlayTestSound();
end;

procedure TConfigSamaWindow.HandleInputDeviceChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  inputs: TSoundDeviceArray;
begin
  if FUpdatingControls or (Sender = nil) then Exit();
  inputs := SoundService().GetInputDevices();
  if (AIndex >= 0) and (AIndex < Length(inputs)) then
  begin
    SoundService().SetDefaultInputDevice(inputs[AIndex].ID);
    if FSettings <> nil then
    begin
      FSettings.InputDevice := inputs[AIndex].Name;
      FSettings.Save();
    end;
  end;
end;

procedure TConfigSamaWindow.HandleInputVolumeChange(Sender: TFtSlider; AValue: Double);
var
  vol: Integer;
begin
  if FUpdatingControls then Exit();
  vol := Round(AValue);
  SoundService().SetInputVolume(vol);
  if Assigned(FLblInputVolumePercent) then
    FLblInputVolumePercent.Text := IntToStr(vol) + '%';
  if FSettings <> nil then
  begin
    FSettings.InputVolume := vol;
    FSettings.Save();
  end;
end;

procedure TConfigSamaWindow.HandleInputMuteToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls then Exit();
  SoundService().SetInputMuted(AToggled);
  if FSettings <> nil then
  begin
    FSettings.InputMuted := AToggled;
    FSettings.Save();
  end;
end;

procedure TConfigSamaWindow.HandleSoundEffectsToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls then Exit();
  SoundService().SetSoundEffectsEnabled(AToggled);
  if FSettings <> nil then
  begin
    FSettings.SoundEffects := AToggled;
    FSettings.Save();
  end;
end;

procedure TConfigSamaWindow.RefreshSoundUI();
var
  outputs, inputs: TSoundDeviceArray;
  i, defOutIdx, defInIdx, outVol, inVol: Integer;
begin
  FUpdatingControls := True;
  try
    // Outputs
    outputs := SoundService().GetOutputDevices();
    if Assigned(FCmbOutputDevice) then
    begin
      FCmbOutputDevice.Clear();
      defOutIdx := 0;
      for i := 0 to High(outputs) do
      begin
        FCmbOutputDevice.AddItem(outputs[i].Name);
        if outputs[i].IsDefault then
          defOutIdx := i;
      end;
      if FCmbOutputDevice.ItemCount > 0 then
        FCmbOutputDevice.SelectedIndex := defOutIdx;
    end;

    outVol := SoundService().GetOutputVolume();
    if Assigned(FSlVolume) then
      FSlVolume.Value := outVol;
    if Assigned(FLblVolumePercent) then
      FLblVolumePercent.Text := IntToStr(outVol) + '%';
    if Assigned(FSwMute) then
      FSwMute.Checked := SoundService().IsOutputMuted();

    // Inputs
    inputs := SoundService().GetInputDevices();
    if Assigned(FCmbInputDevice) then
    begin
      FCmbInputDevice.Clear();
      defInIdx := 0;
      for i := 0 to High(inputs) do
      begin
        FCmbInputDevice.AddItem(inputs[i].Name);
        if inputs[i].IsDefault then
          defInIdx := i;
      end;
      if FCmbInputDevice.ItemCount > 0 then
        FCmbInputDevice.SelectedIndex := defInIdx;
    end;

    inVol := SoundService().GetInputVolume();
    if Assigned(FSlInputVolume) then
      FSlInputVolume.Value := inVol;
    if Assigned(FLblInputVolumePercent) then
      FLblInputVolumePercent.Text := IntToStr(inVol) + '%';
    if Assigned(FSwInputMute) then
      FSwInputMute.Checked := SoundService().IsInputMuted();

    // Sound Effects
    if Assigned(FSwSoundEffects) then
      FSwSoundEffects.Checked := SoundService().AreSoundEffectsEnabled();
  finally
    FUpdatingControls := False;
  end;
  Invalidate();
end;

procedure TConfigSamaWindow.HandlePowerModeChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  PowerService().SetPowerMode(AText);
  FSettings.PowerMode := AText;
  FSettings.Save();
  if Assigned(FSegPowerMode) then
  begin
    if SameText(AText, 'Power Saver') then
      FSegPowerMode.SelectedIndex := 0
    else if SameText(AText, 'Performance') then
      FSegPowerMode.SelectedIndex := 2
    else
      FSegPowerMode.SelectedIndex := 1;
  end;
end;

procedure TConfigSamaWindow.HandleSegmentPowerModeSelect(Sender: TFtSegmentedControl; AIndex: Integer; const AText: string);
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  PowerService().SetPowerMode(AText);
  FSettings.PowerMode := AText;
  FSettings.Save();
  if Assigned(FCmbPowerMode) then
    FCmbPowerMode.Text := AText;
end;

procedure TConfigSamaWindow.HandleScreenBlankChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
var
  delayVal: Integer;
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  if Pos('Never', AText) > 0 then delayVal := 0
  else if Pos('5 ', AText) > 0 then delayVal := 5
  else if Pos('10 ', AText) > 0 then delayVal := 10
  else if Pos('15 ', AText) > 0 then delayVal := 15
  else if Pos('30 ', AText) > 0 then delayVal := 30
  else if Pos('1 hour', AText) > 0 then delayVal := 60
  else delayVal := 10;

  PowerService().SetScreenBlankDelay(delayVal);
  FSettings.ScreenBlankDelay := delayVal;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleAutoSuspendToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls or (FSettings = nil) then Exit();
  PowerService().SetAutoSuspendEnabled(AToggled);
  FSettings.AutoSuspend := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.RefreshPowerUI();
var
  pct: Integer;
  st, pmode: string;
  delayMins, selIdx: Integer;
begin
  FUpdatingControls := True;
  try
    pct := PowerService().GetBatteryPercentage();
    if Assigned(FLblBatteryPercent) then
      FLblBatteryPercent.Text := IntToStr(pct) + '%';

    st := PowerService().GetBatteryStatus() + ' • ' + PowerService().GetTimeRemaining();
    if Assigned(FLblBatteryRemaining) then
      FLblBatteryRemaining.Text := st;

    pmode := PowerService().GetPowerMode();
    if Assigned(FSegPowerMode) then
    begin
      if SameText(pmode, 'Power Saver') then
        FSegPowerMode.SelectedIndex := 0
      else if SameText(pmode, 'Performance') then
        FSegPowerMode.SelectedIndex := 2
      else
        FSegPowerMode.SelectedIndex := 1;
    end;
    if Assigned(FCmbPowerMode) then
      FCmbPowerMode.Text := pmode;

    delayMins := PowerService().GetScreenBlankDelay();
    if Assigned(FCmbScreenBlank) then
    begin
      case delayMins of
        0: selIdx := 0;
        5: selIdx := 1;
        10: selIdx := 2;
        15: selIdx := 3;
        30: selIdx := 4;
        60: selIdx := 5;
        else selIdx := 2;
      end;
      if (selIdx >= 0) and (selIdx < FCmbScreenBlank.ItemCount) then
        FCmbScreenBlank.SelectedIndex := selIdx;
    end;

    if Assigned(FSwAutoSuspend) then
      FSwAutoSuspend.Checked := PowerService().IsAutoSuspendEnabled();

    if Assigned(FLblMaxCapacity) then
      FLblMaxCapacity.Text := '100%';
  finally
    FUpdatingControls := False;
  end;
  Invalidate();
end;

procedure TConfigSamaWindow.HandleBluetoothToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FUpdatingControls then Exit();
  BluetoothService().SetBluetoothEnabled(AToggled);
  if FSettings <> nil then
  begin
    FSettings.BluetoothEnabled := AToggled;
    FSettings.Save();
  end;
  RefreshBluetoothUI();
end;

procedure TConfigSamaWindow.HandleBluetoothScanClick(Sender: TFtButton);
begin
  BluetoothService().StartScan();
  RefreshBluetoothUI();
end;

procedure TConfigSamaWindow.HandleBluetoothConnectClick(Sender: TFtButton);
var
  devs: TBluetoothDeviceArray;
  idx: Integer;
begin
  if Sender = nil then Exit();
  idx := Sender.Tag;
  devs := BluetoothService().GetDevices();
  if (idx >= 0) and (idx < Length(devs)) then
  begin
    if devs[idx].Connected then
      BluetoothService().Disconnect(devs[idx].Address)
    else
      BluetoothService().Connect(devs[idx].Address);
  end;
  RefreshBluetoothUI();
end;

procedure TConfigSamaWindow.RefreshBluetoothUI();
var
  btEnabled: Boolean;
  devs: TBluetoothDeviceArray;
  statusStr: string;
begin
  btEnabled := BluetoothService().IsBluetoothEnabled();

  if Assigned(FSwBluetooth) then
    FSwBluetooth.Checked := btEnabled;

  if not btEnabled then
  begin
    if Assigned(FLblBluetoothStatus) then
      FLblBluetoothStatus.Text := 'Bluetooth is turned off';
    if Assigned(FCardBluetoothDevices) then
      FCardBluetoothDevices.Visible := False;
    if Assigned(FContainerBluetoothDisabled) then
      FContainerBluetoothDisabled.Visible := True;
    Invalidate();
    Exit();
  end;

  if Assigned(FLblBluetoothStatus) then
    FLblBluetoothStatus.Text := 'Visible and available for pairing';
  if Assigned(FContainerBluetoothDisabled) then
    FContainerBluetoothDisabled.Visible := False;
  if Assigned(FCardBluetoothDevices) then
    FCardBluetoothDevices.Visible := True;

  devs := BluetoothService().GetDevices();

  // Row 0
  if Length(devs) > 0 then
  begin
    if Assigned(FLblBtName0) then FLblBtName0.Text := devs[0].Name;
    if devs[0].Connected then
    begin
      statusStr := 'Connected';
      if devs[0].Battery >= 0 then
        statusStr := statusStr + ' • ' + IntToStr(devs[0].Battery) + '% Battery';
      if Assigned(FBtnBtConnect0) then FBtnBtConnect0.Caption := 'Disconnect';
    end
    else if devs[0].Paired then
    begin
      statusStr := 'Paired';
      if devs[0].Battery >= 0 then
        statusStr := statusStr + ' • ' + IntToStr(devs[0].Battery) + '% Battery';
      if Assigned(FBtnBtConnect0) then FBtnBtConnect0.Caption := 'Connect';
    end
    else
    begin
      statusStr := 'Ready to pair';
      if Assigned(FBtnBtConnect0) then FBtnBtConnect0.Caption := 'Pair';
    end;
    if Assigned(FLblBtStatus0) then FLblBtStatus0.Text := statusStr;
    if Assigned(FRowBtDev0) then FRowBtDev0.Visible := True;
  end;

  // Row 1
  if Length(devs) > 1 then
  begin
    if Assigned(FLblBtName1) then FLblBtName1.Text := devs[1].Name;
    if devs[1].Connected then
    begin
      statusStr := 'Connected';
      if devs[1].Battery >= 0 then
        statusStr := statusStr + ' • ' + IntToStr(devs[1].Battery) + '% Battery';
      if Assigned(FBtnBtConnect1) then FBtnBtConnect1.Caption := 'Disconnect';
    end
    else if devs[1].Paired then
    begin
      statusStr := 'Paired';
      if devs[1].Battery >= 0 then
        statusStr := statusStr + ' • ' + IntToStr(devs[1].Battery) + '% Battery';
      if Assigned(FBtnBtConnect1) then FBtnBtConnect1.Caption := 'Connect';
    end
    else
    begin
      statusStr := 'Ready to pair';
      if Assigned(FBtnBtConnect1) then FBtnBtConnect1.Caption := 'Pair';
    end;
    if Assigned(FLblBtStatus1) then FLblBtStatus1.Text := statusStr;
    if Assigned(FRowBtDev1) then FRowBtDev1.Visible := True;
  end;

  // Row 2
  if Length(devs) > 2 then
  begin
    if Assigned(FLblBtName2) then FLblBtName2.Text := devs[2].Name;
    if devs[2].Connected then
    begin
      statusStr := 'Connected';
      if devs[2].Battery >= 0 then
        statusStr := statusStr + ' • ' + IntToStr(devs[2].Battery) + '% Battery';
      if Assigned(FBtnBtConnect2) then FBtnBtConnect2.Caption := 'Disconnect';
    end
    else if devs[2].Paired then
    begin
      statusStr := 'Paired';
      if devs[2].Battery >= 0 then
        statusStr := statusStr + ' • ' + IntToStr(devs[2].Battery) + '% Battery';
      if Assigned(FBtnBtConnect2) then FBtnBtConnect2.Caption := 'Connect';
    end
    else
    begin
      statusStr := 'Ready to pair';
      if Assigned(FBtnBtConnect2) then FBtnBtConnect2.Caption := 'Pair';
    end;
    if Assigned(FLblBtStatus2) then FLblBtStatus2.Text := statusStr;
    if Assigned(FRowBtDev2) then FRowBtDev2.Visible := True;
  end;

  Invalidate();
end;

procedure TConfigSamaWindow.RefreshAppearanceUI();
begin
  FUpdatingControls := True;
  try
    if Assigned(FSwDarkMode) then
      FSwDarkMode.Checked := FSettings.DarkMode;
    if Assigned(FCmbAccent) then
      FCmbAccent.Text := FSettings.AccentColor;
    if Assigned(FBtnStandardFont) then
      FBtnStandardFont.Caption := FSettings.StandardFont;
    if Assigned(FBtnMonospaceFont) then
      FBtnMonospaceFont.Caption := FSettings.MonospaceFont;
  finally
    FUpdatingControls := False;
  end;
  Invalidate();
end;

procedure TConfigSamaWindow.HandleStandardFontClick(Sender: TFtButton);
var
  cur: string;
begin
  if FSettings = nil then Exit();
  cur := FSettings.StandardFont;
  if SameText(cur, 'Inter 11') then cur := 'Cantarell 11'
  else if SameText(cur, 'Cantarell 11') then cur := 'Noto Sans 11'
  else if SameText(cur, 'Noto Sans 11') then cur := 'Roboto 11'
  else if SameText(cur, 'Roboto 11') then cur := 'Sans 11'
  else cur := 'Inter 11';

  FSettings.StandardFont := cur;
  FSettings.Save();
  if Assigned(FBtnStandardFont) then
    FBtnStandardFont.Caption := cur;
  Invalidate();
end;

procedure TConfigSamaWindow.HandleMonospaceFontClick(Sender: TFtButton);
var
  cur: string;
begin
  if FSettings = nil then Exit();
  cur := FSettings.MonospaceFont;
  if SameText(cur, 'JetBrains Mono 10') then cur := 'Fira Code 10'
  else if SameText(cur, 'Fira Code 10') then cur := 'Source Code Pro 10'
  else if SameText(cur, 'Source Code Pro 10') then cur := 'Monospace 10'
  else cur := 'JetBrains Mono 10';

  FSettings.MonospaceFont := cur;
  FSettings.Save();
  if Assigned(FBtnMonospaceFont) then
    FBtnMonospaceFont.Caption := cur;
  Invalidate();
end;

procedure TConfigSamaWindow.CycleStandardFont();
begin
  HandleStandardFontClick(FBtnStandardFont);
end;

procedure TConfigSamaWindow.CycleMonospaceFont();
begin
  HandleMonospaceFontClick(FBtnMonospaceFont);
end;

procedure TConfigSamaWindow.HandlePrimaryBtnChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.PrimaryButton := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandlePointerSpeedChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.PointerSpeed := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleNaturalScrollToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.NaturalScrolling := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleTapToClickToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.TapToClick := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleKeyboardLayoutChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.KeyboardLayout := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleKeyDelayChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.KeyRepeatDelay := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleKeyRateChange(Sender: TFtSlider; AValue: Double);
begin
  if FSettings = nil then Exit();
  FSettings.KeyRepeatRate := Round(AValue);
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleSuperLauncherToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  if FSettings = nil then Exit();
  FSettings.SuperKeyLauncher := AToggled;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleBrowserChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultBrowser := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleFileManagerChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultFileManager := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleTerminalChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultTerminal := AText;
  FSettings.Save();
end;

procedure TConfigSamaWindow.HandleEditorChange(Sender: TFtComboBox; AIndex: Integer; const AText: string);
begin
  if FSettings = nil then Exit();
  FSettings.DefaultTextEditor := AText;
  FSettings.Save();
end;

// ── WLAN Service & Dialog Handlers ──

procedure TConfigSamaWindow.HandlePasswordPromptConnect(Sender: TFtButton);
begin
  FPwdSubmitted := True;
  if Assigned(FPwdDialog) then
  begin
    FPwdDialog.ModalResult := Integer(ftmrOk);
    FPwdDialog.Hide();
  end;
end;

procedure TConfigSamaWindow.HandlePasswordPromptCancel(Sender: TFtButton);
begin
  FPwdSubmitted := False;
  if Assigned(FPwdDialog) then
  begin
    FPwdDialog.ModalResult := Integer(ftmrCancel);
    FPwdDialog.Hide();
  end;
end;

procedure TConfigSamaWindow.HandleWlanToggle(Sender: TFtSwitch; AToggled: Boolean);
begin
  WlanService().SetWifiEnabled(AToggled);
  RefreshWlanUI(False);
end;

procedure TConfigSamaWindow.HandleWlanRescan(Sender: TFtButton);
begin
  RefreshWlanUI(True);
end;

procedure TConfigSamaWindow.HandleConnectedDetails(Sender: TFtButton);
var
  det: TWlanConnectionDetails;
begin
  det := WlanService().GetConnectionDetails();
  if det.Ssid <> '' then
    ShowNetworkDetailsDialog(det.Ssid);
end;

procedure TConfigSamaWindow.HandleConnectedDisconnect(Sender: TFtButton);
begin
  WlanService().Disconnect();
  RefreshWlanUI(False);
end;

procedure TConfigSamaWindow.HandleRowConnectClick(Sender: TFtButton);
var
  idx: Integer;
  net: TWlanNetwork;
begin
  if Sender = nil then Exit();
  idx := Sender.Tag;
  if (idx < 0) or (idx > 5) then Exit();

  net := FWlanRows[idx].Network;
  if net.Ssid = '' then Exit();

  if net.IsConnected then
  begin
    ShowNetworkDetailsDialog(net.Ssid);
    Exit();
  end;

  if net.IsSaved or (net.Security = '') then
  begin
    WlanService().Connect(net.Ssid);
    RefreshWlanUI(False);
  end
  else
  begin
    PromptPasswordAndConnect(net.Ssid);
  end;
end;

procedure TConfigSamaWindow.RefreshWlanUI(AFreshScan: Boolean = False);
var
  wifiOn: Boolean;
  nets: TWlanNetworkArray;
  details: TWlanConnectionDetails;
  i, count: Integer;
begin
  wifiOn := WlanService().IsWifiEnabled();
  if Assigned(FSwWlan) then
    FSwWlan.Checked := wifiOn;

  if not wifiOn then
  begin
    if Assigned(FLblWlanStatus) then
      FLblWlanStatus.Text := 'Wi-Fi is turned off';
    if Assigned(FContainerWlanDisabled) then
      FContainerWlanDisabled.Visible := True;
    if Assigned(FCardWlanConnected) then
      FCardWlanConnected.Visible := False;
    if Assigned(FCardWlanAvailable) then
      FCardWlanAvailable.Visible := False;
    Invalidate();
    Exit();
  end;

  if Assigned(FContainerWlanDisabled) then
    FContainerWlanDisabled.Visible := False;

  nets := WlanService().ScanNetworks(AFreshScan);
  details := WlanService().GetConnectionDetails();

  if details.Ssid <> '' then
  begin
    if Assigned(FLblWlanStatus) then
      FLblWlanStatus.Text := 'Connected to ' + details.Ssid;

    if Assigned(FCardWlanConnected) then
    begin
      FCardWlanConnected.Visible := True;
      if Assigned(FLblConnSsid) then
        FLblConnSsid.Text := details.Ssid;
      if Assigned(FLblConnDetails) then
      begin
        if details.IpAddress <> '' then
          FLblConnDetails.Text := 'Connected • IPv4: ' + details.IpAddress
        else
          FLblConnDetails.Text := 'Connected';
      end;
      if Assigned(FImgConnCheck) then
        FImgConnCheck.Visible := True;
      if Assigned(FBtnConnDetails) then
        FBtnConnDetails.Visible := True;
      if Assigned(FBtnConnDisconnect) then
        FBtnConnDisconnect.Visible := True;
    end;
  end
  else
  begin
    if Assigned(FLblWlanStatus) then
      FLblWlanStatus.Text := 'Disconnected';

    if Assigned(FCardWlanConnected) then
    begin
      FCardWlanConnected.Visible := True;
      if Assigned(FLblConnSsid) then
        FLblConnSsid.Text := 'Not Connected';
      if Assigned(FLblConnDetails) then
        FLblConnDetails.Text := 'Select a wireless network below to connect';
      if Assigned(FImgConnCheck) then
        FImgConnCheck.Visible := False;
      if Assigned(FBtnConnDetails) then
        FBtnConnDetails.Visible := False;
      if Assigned(FBtnConnDisconnect) then
        FBtnConnDisconnect.Visible := False;
    end;
  end;

  if Assigned(FCardWlanAvailable) then
    FCardWlanAvailable.Visible := True;

  if Assigned(FLblScanStatus) then
    FLblScanStatus.Text := IntToStr(Length(nets)) + ' networks visible';

  count := Length(nets);
  for i := 0 to 5 do
  begin
    if i < count then
    begin
      FWlanRows[i].Network := nets[i];
      if Assigned(FWlanRows[i].Row) then
        FWlanRows[i].Row.Visible := True;
      if Assigned(FWlanRows[i].LblSsid) then
        FWlanRows[i].LblSsid.Text := nets[i].Ssid;
      if Assigned(FWlanRows[i].LblSignal) then
        FWlanRows[i].LblSignal.Text := IntToStr(nets[i].Signal) + '%';
      if Assigned(FWlanRows[i].ImgLock) then
        FWlanRows[i].ImgLock.Visible := (nets[i].Security <> '');
      if Assigned(FWlanRows[i].BtnConnect) then
      begin
        if nets[i].IsConnected then
          FWlanRows[i].BtnConnect.Caption := 'Connected'
        else if nets[i].IsSaved then
          FWlanRows[i].BtnConnect.Caption := 'Connect'
        else
          FWlanRows[i].BtnConnect.Caption := 'Connect';
      end;
      if Assigned(FWlanRows[i].Divider) then
        FWlanRows[i].Divider.Visible := (i < 5);
    end
    else
    begin
      if Assigned(FWlanRows[i].Row) then
        FWlanRows[i].Row.Visible := False;
      if Assigned(FWlanRows[i].Divider) then
        FWlanRows[i].Divider.Visible := False;
    end;
  end;

  Invalidate();
end;

procedure TConfigSamaWindow.PromptPasswordAndConnect(const ASsid: string);
var
  lblTitle, lblInstr: TFtLabel;
  btnCancel, btnConnect: TFtButton;
  pw: string;
begin
  FPwdSubmitted := False;
  FPwdDialog := TFtWindow.Create(380, 190, 'Authentication Required');
  try
    FPwdDialog.ExtendedClientArea := False;

    lblTitle := TFtLabel.Create(FPwdDialog, 20, 16, 340, 24, 'Authentication Required');
    lblTitle.Selectable := False;

    lblInstr := TFtLabel.Create(FPwdDialog, 20, 42, 340, 22, 'Enter the password for "' + ASsid + '"');
    lblInstr.Selectable := False;

    FPwdEntry := TFtEntry.Create(FPwdDialog, 20, 74, 340, 32);
    FPwdEntry.Placeholder := 'Password';

    btnCancel := TFtButton.Create(FPwdDialog, 180, 130, 80, 32, 'Cancel');
    btnCancel.OnClick := @HandlePasswordPromptCancel;

    btnConnect := TFtButton.Create(FPwdDialog, 270, 130, 90, 32, 'Connect');
    btnConnect.OnClick := @HandlePasswordPromptConnect;

    FPwdDialog.ShowModal();

    if FPwdSubmitted and (FPwdEntry.Text <> '') then
    begin
      pw := FPwdEntry.Text;
      if WlanService().Connect(ASsid, pw) then
        RefreshWlanUI(False)
      else
        TFtMessageDialog.ShowError('Connection Failed', 'Could not connect to ' + ASsid,
                                   'Please verify the password and try again.');
    end;
  finally
    FPwdDialog.Free();
    FPwdDialog := nil;
    FPwdEntry := nil;
  end;
end;

procedure TConfigSamaWindow.ShowNetworkDetailsDialog(const ASsid: string);
var
  det: TWlanConnectionDetails;
  msg: string;
begin
  det := WlanService().GetConnectionDetails();
  msg := 'SSID: ' + ASsid + LineEnding;
  if det.IpAddress <> '' then
    msg := msg + 'IPv4 Address: ' + det.IpAddress + LineEnding;
  if det.Gateway <> '' then
    msg := msg + 'Gateway: ' + det.Gateway + LineEnding;
  if det.Dns <> '' then
    msg := msg + 'DNS: ' + det.Dns + LineEnding;
  if det.HwAddr <> '' then
    msg := msg + 'Hardware MAC: ' + det.HwAddr + LineEnding;
  if det.Security <> '' then
    msg := msg + 'Security: ' + det.Security + LineEnding;
  if det.Signal > 0 then
    msg := msg + 'Signal Strength: ' + IntToStr(det.Signal) + '%' + LineEnding;

  TFtMessageDialog.ShowInfo('Network Details', ASsid, msg);
end;

end.

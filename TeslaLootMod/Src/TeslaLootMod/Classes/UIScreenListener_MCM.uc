class UIScreenListener_MCM extends UIScreenListener config(TLM_NullConfig);

`include(TeslaLootMod/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(TeslaLootMod/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool AMMOUPGRADEWARNING_CHECKBOX_VALUE;
var config int CONFIG_VERSION;

var localized string TabLabel;
var localized string GeneralSettings;
var localized string AmmoUpgradeWarning;
var localized string AmmoUpgradeWarningToolTip;
var localized string PageTitle;

event OnInit(UIScreen Screen)
{
	// Everything out here runs on every UIScreen. Not great but necessary.
	if (MCM_API(Screen) != none)
	{
		// Everything in here runs only when you need to touch MCM.
		`MCM_API_Register(Screen, ClientModCallback);
	}
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;
	
	LoadSavedSettings();
	
	Page = ConfigAPI.NewSettingsPage(default.TabLabel);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	
	Group = Page.AddGroup('Group1', default.GeneralSettings);
	
	Group.AddCheckbox('checkbox', default.AmmoUpgradeWarning, default.AmmoUpgradeWarningToolTip, AMMOUPGRADEWARNING_CHECKBOX_VALUE, CheckboxSaveHandler);
	
	Page.ShowSettings();
}

`MCM_CH_VersionChecker(class'TeslaLootMod_Defaults'.default.CFG_VERSION,CONFIG_VERSION)

simulated function LoadSavedSettings()
{
	AMMOUPGRADEWARNING_CHECKBOX_VALUE = `MCM_CH_GetValue(class'TeslaLootMod_Defaults'.default.AMMOUPGRADEWARNING_SETTING,AMMOUPGRADEWARNING_CHECKBOX_VALUE);
}

`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandler, AMMOUPGRADEWARNING_CHECKBOX_VALUE);

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
	self.SaveConfig();
}

defaultproperties
{
	ScreenClass = none;
}

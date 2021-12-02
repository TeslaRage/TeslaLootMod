class UIAlert_TLM extends UIAlert;

simulated function BuildAlert()
{
	BindLibraryItem();

	BuildTLMItemRewardedAlert();	

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();	
}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch ( eAlertName )
	{	
	case 'eAlert_TLMItemRewarded': return 'Alert_ItemAvailable';
	default:
		return '';
	}
}

simulated function BuildTLMItemRewardedAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2ItemTemplate ItemTemplate;	
	local XComGameState_Item Item;
	local X2ItemTemplateManager TemplateManager;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local int ItemObjectID;
	local string ImageUponResearchCompletion;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));

	ItemObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'ItemObjectID');
	ImageUponResearchCompletion = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'ImageUponResearchCompletion');

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemObjectID));

	kInfo.strTitle = m_strNewItemReceived;
	kInfo.strName = Item.Nickname;
	
	WUTemplates = Item.GetMyWeaponUpgradeTemplates();
	
	foreach WUTemplates(WUTemplate)
	{
		kInfo.strBody $= WUTemplate.GetItemFriendlyName() $"\n";
		kInfo.strBody $= WUTemplate.GetItemBriefSummary() $"\n\n";
	}	
	
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	
	if (ImageUponResearchCompletion != "")
		kInfo.strImage = ImageUponResearchCompletion;

	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);	

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}
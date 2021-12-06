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
	local X2ItemTemplateManager TemplateManager;
	local string ImageUponResearchCompletion;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));
	
	ImageUponResearchCompletion = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'ImageUponResearchCompletion');	

	kInfo.strTitle = m_strNewItemReceived;
	kInfo.strName = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Nickname');
	kInfo.strBody = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'WeaponInfo');	
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	
	if (ImageUponResearchCompletion != "")
		kInfo.strImage = ImageUponResearchCompletion;

	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);	

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}
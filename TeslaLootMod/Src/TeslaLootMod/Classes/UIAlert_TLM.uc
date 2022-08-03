class UIAlert_TLM extends UIAlert;

simulated function BuildAlert()
{
	BindLibraryItem();

	switch ( eAlertName )
	{
		case 'eAlert_TLMItemRewarded': 
			BuildTLMItemRewardedAlert();
			break;
		case 'eAlert_TLMGeneric': 
			BuildTLMGenericAlert();
			break;
	}

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();	
}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch ( eAlertName )
	{	
	case 'eAlert_TLMItemRewarded':
		return 'Alert_ItemAvailable';
	case 'eAlert_TLMGeneric':
		return 'Alert_XComGeneric';
	default:
		return 'Alert_ItemAvailable';
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

simulated function BuildTLMGenericAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Title'));	// Title
	LibraryPanel.MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Message')); // Body
	LibraryPanel.MC.QueueString("");		// Button 0
	LibraryPanel.MC.QueueString(m_strOK);	// Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

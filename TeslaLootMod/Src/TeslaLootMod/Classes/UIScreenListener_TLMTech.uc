class UIScreenListener_TLMTech extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIAlert AlertScreen;
	local XComGameState_Tech TechState;
	local XComHQPresentationLayer HQPres;
	local UIChooseClass_TLM ChooseItemScreen;
	local UIChooseClass_TLMSalvage ChooseSalvageScreen;
	
	AlertScreen = UIAlert(Screen);
	if (AlertScreen != none && AlertScreen.eAlertName == 'eAlert_ProvingGroundProjectComplete')
	{
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertScreen.DisplayPropertySet, 'TechRef')));

		if (TechState.GetMyTemplate().IsA('X2TechTemplate_TLM'))
		{
			HQPres = `HQPRES;
			ChooseItemScreen = HQPres.Spawn(class'UIChooseClass_TLM', HQPres);
			ChooseItemScreen.Tech = TechState;
			HQPres.ScreenStack.Push(ChooseItemScreen);
		}
		else if (TechState.GetMyTemplateName() == 'TLM_Salvage')
		{
			HQPres = `HQPRES;
			ChooseSalvageScreen = HQPres.Spawn(class'UIChooseClass_TLMSalvage', HQPres);
			ChooseSalvageScreen.Tech = TechState;
			HQPres.ScreenStack.Push(ChooseSalvageScreen);
		}
	}
}

defaultproperties
{
	ScreenClass = class'UIAlert';
}
class UIScreenListener_TLMTech extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIAlert AlertScreen;
	local XComGameState_Tech TechState;
	local XComHQPresentationLayer HQPres;
	local UIChooseClass_TLM ChooseItemScreen;
	
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
	}
}

defaultproperties
{
	ScreenClass = class'UIAlert';
}
class X2StrategyElement_TLM extends X2StrategyElement config(TLM);

var config array<TechData> UnlockLootBoxTechs;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Techs;
	local TechData UnlockLootBoxTech;

	foreach default.UnlockLootBoxTechs(UnlockLootBoxTech)
	{
		Techs.AddItem(CreateUnlockLockboxTemplate(UnlockLootBoxTech));
	}	

	return Techs;
}

static function X2DataTemplate CreateUnlockLockboxTemplate(TechData UnlockLootBoxTech)
{
	local X2TechTemplate_TLM Template;	

	`CREATE_X2TEMPLATE(class'X2TechTemplate_TLM', Template, UnlockLootBoxTech.TemplateName);

	if (class'X2Helper_TLM'.static.IsModLoaded(UnlockLootBoxTech.AltImage.DLC))
	{
		Template.strImage = UnlockLootBoxTech.AltImage.AltstrImage;
	}
	else
	{
		Template.strImage = UnlockLootBoxTech.Image;
	}

	Template.SortingTier = UnlockLootBoxTech.SortingTier;
	Template.ResearchCompletedFn = UnlockLootBoxCompleted;

	Template.Requirements.RequiredEngineeringScore = 10;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;

	Template.bRepeatable = true;
	Template.bProvingGround = true;

	return Template;
}

static function UnlockLootBoxCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{	
	class'X2Helper_TLM'.static.FindAndMakeTechInstant(NewGameState, TechState);

	// If this save game has the old tech, then this needs to be updated
	// Else the popup won't show and UIScreenListener_TLMTech won't spawn the new UI
	TechState.ItemRewards.Length = 0;
	TechState.bSeenResearchCompleteScreen = false;
}

static function UIItemReceived(XComGameState NewGameState, XComGameState_Item Item, X2BaseWeaponDeckTemplate BWTemplate)
{
	local DynamicPropertySet PropertySet;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local string WeaponInfo;	
	
	WUTemplates = Item.GetMyWeaponUpgradeTemplates();

	WeaponInfo = Item.Nickname $"\n";
	foreach WUTemplates(WUTemplate)
	{
		WeaponInfo $= WUTemplate.GetItemFriendlyName() $"\n";
		WeaponInfo $= WUTemplate.GetItemBriefSummary() $"\n";
	}

	BuildUIAlert(PropertySet, 'eAlert_TLMItemRewarded', None, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', Item.GetMyTemplate().DataName);	
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'ImageUponResearchCompletion', BWTemplate.GetImage(Item.GetMyTemplate().DataName));
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'WeaponInfo', WeaponInfo);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Nickname', Item.Nickname);
	QueueDynamicPopup(PropertySet, NewGameState);
}

static function BuildUIAlert(
	out DynamicPropertySet PropertySet, 
	Name AlertName, 
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction, 
	Name EventToTrigger, 
	string SoundToPlay,
	bool bImmediateDisplay = true)
{
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_TLM', AlertName, CallbackFunction, bImmediateDisplay, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', EventToTrigger);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', SoundToPlay);
}

static function QueueDynamicPopup(const out DynamicPropertySet PopupInfo, optional XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bLocalNewGameState;

	if( PopupInfo.bDisplayImmediate )
	{
		`PRESBASE.DisplayDynamicPopupImmediate(PopupInfo);
		return;
	}

	if( NewGameState == None )
	{
		bLocalNewGameState = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Queued UI Alert" @ PopupInfo.PrimaryRoutingKey @ PopupInfo.SecondaryRoutingKey);
	}
	else
	{
		bLocalNewGameState = false;
	}

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.QueuedDynamicPopups.AddItem(PopupInfo);

	if( bLocalNewGameState )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	if( PopupInfo.bDisplayImmediate )
	{
		`PRESBASE.DisplayQueuedDynamicPopups();
	}
}

// Not used - but sad to delete so leave it here just in case it can be useful later
// Background: This was initially made to prevent weapons with small clipsize like Hunter Rifles
// 				from getting Rapid Fire/Hail of Bullets as those abilities need clip > 2.
// 				Decided to give bonus clip size to those Legendary Upgrades instead.
static function bool CanWeaponAffordAmmo(X2WeaponUpgradeTemplate WUTemplate, XComGameState_Item Weapon)
{
	local X2AbilityTemplateManager AbilityMan;	
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityCost Cost;
	local X2AbilityCost_Ammo AmmoCost;
	local name AbilityName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();	

	foreach WUTemplate.BonusAbilities(AbilityName)
	{
		AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);		

		foreach AbilityTemplate.AbilityCosts(Cost)
		{
			AmmoCost = X2AbilityCost_Ammo(Cost);
			if (AmmoCost == none) continue;

			if (AmmoCost.iAmmo > Weapon.GetClipSize())
			{
				return false;
			}
		}
	}

	return true;
}
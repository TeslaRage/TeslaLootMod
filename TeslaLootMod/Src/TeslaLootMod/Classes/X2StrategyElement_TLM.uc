class X2StrategyElement_TLM extends X2StrategyElement config(TLM);

var config array<TechData> UnlockLootBoxTechs;

var localized array<String> RandomNickNames;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Techs;
	local TechData UnlockLootBoxTech;

	foreach default.UnlockLootBoxTechs(UnlockLootBoxTech)
	{
		Techs.AddItem(CreateUnlockLockboxTemplate(UnlockLootBoxTech.TemplateName));
	}	

	return Techs;
}

static function X2DataTemplate CreateUnlockLockboxTemplate(name TemplateName)
{
	local X2TechTemplate_TLM Template;	

	`CREATE_X2TEMPLATE(class'X2TechTemplate_TLM', Template, TemplateName);
	
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Storage_Module";	
	Template.SortingTier = 2;
	Template.ResearchCompletedFn = GenerateItem;

	Template.Requirements.RequiredEngineeringScore = 10;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;

	Template.bRepeatable = true;
	Template.bProvingGround = true;

	return Template;
}

static function GenerateItem(XComGameState NewGameState, XComGameState_Tech TechState)
{			  
	local XComGameState_Item Weapon;   
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_ItemData Data;	
	local X2WeaponTemplate WTemplate;
	local X2BaseWeaponDeckTemplate BWTemplate;	

	XComHQ = `XCOMHQ;	
	
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));	
	GetBaseWeapon(BWTemplate, WTemplate);
	Weapon = WTemplate.CreateInstanceFromTemplate(NewGameState);

	if (Weapon == none)
	{
		`LOG("TLM ERROR: Failed to get base weapon");		
	}

	ApplyWeaponUpgrades(Weapon, TechState);	

	Data = XComGameState_ItemData(NewGameState.CreateNewStateObject(class'XComGameState_ItemData'));
	Data.NumUpgradeSlots = 0;
	Weapon.AddComponentObject(Data);	
	
	XComHQ.PutItemInInventory(NewGameState, Weapon);
	`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', Weapon, Weapon, NewGameState);

	TechState.ItemRewards.Length = 0; 						// Reset the item rewards array in case the tech is repeatable
	TechState.ItemRewards.AddItem(Weapon.GetMyTemplate());	// Needed for UI Alert display info
	TechState.bSeenResearchCompleteScreen = false; 			// Reset the research report for techs that are repeatable

	UIItemReceived(NewGameState, Weapon, BWTemplate);
}

static function GetBaseWeapon(out X2BaseWeaponDeckTemplate BWTemplate, out X2WeaponTemplate WTemplate)
{		
	local X2ItemTemplateManager ItemTemplateMan;	
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local X2CardManager CardMan;	
	local X2BaseWeaponDeckTemplateManager BWMan;	
	local int Weight, Idx;
	local string strWeapon, CardLabel;
	local array<string> CardLabels;
	local array<name> ItemNames;
	local name ItemTemplateName;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;	
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CardMan = class'X2CardManager'.static.GetCardManager();
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	
	BWTemplate = BWMan.DetermineBaseWeaponDeck();

	if (BWTemplate == none)
		`LOG("TLM ERROR: Unable to determine base weapon deck template");

	ItemNames = BWTemplate.GetBaseItems();	

	foreach ItemNames(ItemTemplateName)
	{
		WTemplate = X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(ItemTemplateName));
		if (WTemplate == none) continue;

		Weight = 0.0;
		foreach XComHQ.Crew(UnitRef)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (Unit == none || !Unit.IsSoldier() || Unit.GetSoldierRank() == 0) continue;
			
			if (Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(WTemplate)) Weight++;
		}

		if (CardLabels.Find(string(WTemplate.DataName)) == INDEX_NONE)
		{
			CardMan.AddCardToDeck(BWTemplate.DataName, string(WTemplate.DataName), float(Weight));
		}
	}

	CardLabels.Length = 0;
	CardMan.GetAllCardsInDeck(BWTemplate.DataName, CardLabels);
	
	foreach CardLabels(CardLabel)
	{
		Idx = ItemNames.Find(name(CardLabel));
		if (Idx == INDEX_NONE)
		{			
			CardMan.RemoveCardFromDeck(BWTemplate.DataName, CardLabel);
		}
	}

	CardMan.SelectNextCardFromDeck(BWTemplate.DataName, strWeapon);
	CardMan.MarkCardUsed(BWTemplate.DataName, strWeapon);

	WTemplate = X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(name(strWeapon)));
}

static function ApplyWeaponUpgrades(XComGameState_Item Item, XComGameState_Tech Tech)
{	
	local X2ItemTemplateManager ItemMan;	
	local X2UpgradeDeckTemplateManager UpgradeDeckMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local RarityDeckData Deck;
	local X2RarityTemplate RarityTemplate;
	local array<RarityDeckData> Decks;		
	
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	
	UpgradeDeckMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();

	Item.NickName = default.RandomNickNames[`SYNC_RAND_STATIC(default.RandomNickNames.Length)];	
	RarityTemplate = X2ItemTemplate_LootBox(ItemMan.FindItemTemplate(X2TechTemplate_TLM(Tech.GetMyTemplate()).LootBoxToUse)).RollRarity(Item);
	Decks = RarityTemplate.GetDecksToRoll();	

	foreach Decks(Deck)
	{	
		UDTemplate = UpgradeDeckMan.GetUpgradeDeckTemplate(Deck.UpgradeDeckName);
		if (UDTemplate == none) continue;

		UDTemplate.RollUpgrades(Item, Deck.Quantity);
	}

	RarityTemplate.ApplyColorToString(Item.Nickname);
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
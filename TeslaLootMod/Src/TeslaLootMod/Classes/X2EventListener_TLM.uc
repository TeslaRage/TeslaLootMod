class X2EventListener_TLM extends X2EventListener config (TLM);

var localized string strSlotLocked;
var config bool bAllowRemoveUpgrade;
var config array<int> UpgradeSellTier;

var UIArmory_WeaponUpgrade ScreenChange;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateStrategyListener());
	Templates.AddItem(CreateTacticalListener());

	return Templates;
}

static final function CHEventListenerTemplate CreateStrategyListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_TLM_Strategy');

	Template.RegisterInStrategy = true;

	Template.AddCHEvent('OverrideNumUpgradeSlots', OverrideNumUpgradeSlots, ELD_Immediate);
	// Template.AddCHEvent('OverrideNumUpgradeSlots', OverrideNumUpgradeSlots_OpenSlots, ELD_OnStateSubmitted, 60);
	Template.AddCHEvent('UIArmory_WeaponUpgrade_SlotsUpdated', UIArmory_WeaponUpgrade_SlotsUpdated, ELD_Immediate);
	Template.AddCHEvent('UIArmory_WeaponUpgrade_SlotsUpdated', UIArmory_WeaponUpgrade_SlotsUpdated_GiveColor, ELD_OnStateSubmitted);
	Template.AddCHEvent('InfluenceBuyPrices', InfluenceBuyPrices, ELD_Immediate);

	return Template; 
}

static final function CHEventListenerTemplate CreateTacticalListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_TLM_Tactical');

	Template.RegisterInTactical = true;

	Template.AddCHEvent('OnGetItemRange', OnGetItemRange, ELD_Immediate);

	return Template; 
}

static function EventListenerReturn OverrideNumUpgradeSlots(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
	local XComLWTuple OverrideTuple;
	local XComGameState_Item ItemState;
	local XComGameState_ItemData Data;

	OverrideTuple = XComLWTuple(EventData);
	ItemState = XComGameState_Item(EventSource);

	if (ItemState == none) return ELR_NoInterrupt;	

	// Check if this is our weapon
	Data = XComGameState_ItemData(ItemState.FindComponentObject(class'XComGameState_ItemData'));
	if (Data == none) return ELR_NoInterrupt;

	OverrideTuple.Data[0].i = Data.NumUpgradeSlots;

	return ELR_NoInterrupt;
}

// Unfortunately buggy - but kept as reference
// static function EventListenerReturn OverrideNumUpgradeSlots_OpenSlots(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
// {	
// 	local XComGameState_Item ItemState;
// 	local XComGameState_ItemData Data;
// 	local XComGameState NewGameState;	
// 	local bool bUpdated;	
	
// 	ItemState = XComGameState_Item(EventSource);	
// 	if (ItemState == none) return ELR_NoInterrupt;	

// 	// Check if this is our weapon
// 	Data = XComGameState_ItemData(ItemState.FindComponentObject(class'XComGameState_ItemData'));
// 	if (Data == none) return ELR_NoInterrupt;
	
// 	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update TLM item state");
// 	Data = XComGameState_ItemData(NewGameState.ModifyStateObject(class'XComGameState_ItemData', Data.ObjectID));

// 	if (default.bAllowRemoveUpgrade && Data.NumUpgradeSlots == 0)
// 	{
// 		Data.NumUpgradeSlots = ItemState.GetMyWeaponUpgradeCount();
// 		bUpdated = true;
// 	}

// 	if (!default.bAllowRemoveUpgrade && Data.NumUpgradeSlots != 0)
// 	{
// 		Data.NumUpgradeSlots = 0;
// 		bUpdated = true;
// 	}
	
// 	if (bUpdated)
// 		`GAMERULES.SubmitGameState(NewGameState);
// 	else
// 		`XCOMHISTORY.CleanupPendingGameState(NewGameState);

// 	return ELR_NoInterrupt;
// }

static function EventListenerReturn UIArmory_WeaponUpgrade_SlotsUpdated(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{	
	local XComGameState_Item Item;
	local XComGameState_ItemData Data;
	local UIArmory_WeaponUpgrade Screen;
	local array<X2WeaponUpgradeTemplate> EquippedUpgrades;
	local UIList SlotsList;
	local int i, NumUpgradeSlots;

	Screen = UIArmory_WeaponUpgrade(EventSource);
	if (Screen == none) return ELR_NoInterrupt;

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Screen.WeaponRef.ObjectID));
	if (Item == none) return ELR_NoInterrupt;

	Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));
	if (Data == none) return ELR_NoInterrupt;

	// Override error message "REQUIRES CONTINENT BONUS"
	SlotsList = UIList(EventData);
	EquippedUpgrades = Item.GetMyWeaponUpgradeTemplates();
	NumUpgradeSlots = Item.GetNumUpgradeSlots();

	for (i = 0; i < EquippedUpgrades.Length; ++i)
	{
		if (i > NumUpgradeSlots - 1)
		{
			UIArmory_WeaponUpgradeItem(SlotsList.GetItem(i)).SetDisabled(false);
			UIArmory_WeaponUpgradeItem(SlotsList.GetItem(i)).SetDisabled(true, class'UIUtilities_Text'.static.GetColoredText(default.strSlotLocked, eUIState_Bad));
		}
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn UIArmory_WeaponUpgrade_SlotsUpdated_GiveColor(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local UIArmory_WeaponUpgrade Screen;
	local XComGameState_ItemData Data;
	local XComGameState_Item Item;
	local XComGameState NewGameState;
	local X2RarityTemplateManager RMan;
	local X2RarityTemplate RarityTemplate;

	// Get screen, so we can get WeaponRef
	Screen = UIArmory_WeaponUpgrade(EventSource);
	if (Screen == none) return ELR_NoInterrupt;

	// Get item state
	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Screen.WeaponRef.ObjectID));
	if (Item == none || Item.Nickname == "") return ELR_NoInterrupt;

	// Get TLM item state, so we only do this for our items
	Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));
	if (Data == none) return ELR_NoInterrupt;	

	// Get Rarity Template
	RMan = class'X2RarityTemplateManager'.static.GetRarityTemplateManager();
	RarityTemplate = RMan.GetRarityTemplate(Data.RarityName);
	if (RarityTemplate == none) return ELR_NoInterrupt;
	
	// Update nick
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Give color to item nick");

	Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
	RarityTemplate.ApplyColorToString(Item.Nickname);

	`GAMERULES.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnGetItemRange(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple OverrideTuple;
	local XComGameState_Item Item;	
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local name AbilityName;
	local int Index;

	OverrideTuple = XComLWTuple(EventData);
	if(OverrideTuple == none) return ELR_NoInterrupt;

	Item = XComGameState_Item(EventSource);
	if (Item == none) return ELR_NoInterrupt;

	WUTemplates = Item.GetMyWeaponUpgradeTemplates();
	if (WUTemplates.Length <= 0) return ELR_NoInterrupt;

	foreach WUTemplates(WUTemplate)
	{		
		foreach WUTemplate.BonusAbilities(AbilityName)
		{
			Index = class'X2Ability_TLM'.default.AbilityGivesGRange.Find('AbilityName', AbilityName);
			if (Index == INDEX_NONE) continue;

			OverrideTuple.Data[1].i = class'X2Ability_TLM'.default.AbilityGivesGRange[Index].GrenadeRangeBonus;
			return ELR_NoInterrupt;
		}
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn InfluenceBuyPrices(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{	
	local XComLWTuple OverrideTuple;
	local XComGameState_Item Item;
	local XComGameState_BlackMarket BlackMarket;
	local XComGameStateHistory History;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local bool bLog;
	local array<int> ItemObjectIDs;
	local int i, WUPrice;

	bLog = class'X2DownloadableContentInfo_TeslaLootMod'.default.bLog;

	// Get info we need
	OverrideTuple = XComLWTuple(EventData);
	if(OverrideTuple == none) return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	ItemObjectIDs = OverrideTuple.Data[0].ai;

	BlackMarket = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	if(BlackMarket == none) return ELR_NoInterrupt; // Impossible to happen unless the game is broken

	for (i = 0; i < ItemObjectIDs.Length; i++)
	{
		Item = XComGameState_Item(History.GetGameStateForObjectID(ItemObjectIDs[i]));
		if (Item == none) continue;

		// Only interested with items that has upgrades
		if (Item.GetMyWeaponUpgradeCount() > 0)
		{
			WUTemplates = Item.GetMyWeaponUpgradeTemplates();

			`LOG("Item: " $Item.GetMyTemplateName() $"|| " $ItemObjectIDs[i], bLog, 'TLMDEBUG');
			`LOG("Before: " $OverrideTuple.Data[1].ai[i], bLog, 'TLMDEBUG');
			foreach WUTemplates(WUTemplate)
			{
				WUPrice = default.UpgradeSellTier[WUTemplate.Tier];
				WUPrice = WUPrice == 0 ? 1 : WUPrice;

				if(BlackMarket.InterestTemplates.Find(WUTemplate.DataName) != INDEX_NONE)
				{
					WUPrice *= `ScaleStrategyArrayInt(BlackMarket.default.InterestPriceMultiplier);
				}

				OverrideTuple.Data[1].ai[i] += WUPrice;
				`LOG("WUPrice: " $WUPrice, bLog, 'TLMDEBUG');
			}
			`LOG("After: " $OverrideTuple.Data[1].ai[i], bLog, 'TLMDEBUG');
		}
	}

	return ELR_NoInterrupt;
}
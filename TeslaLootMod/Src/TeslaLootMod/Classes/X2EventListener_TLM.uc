class X2EventListener_TLM extends X2EventListener config (TLM);

var localized string strSlotLocked;
var localized string strAmmoEquipped, strAmmoEquippedMessage, strAmmoUpgradeExistMessage;
var config bool bAllowRemoveUpgrade;

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
	Template.AddCHEvent('ItemAddedToSlot', ItemAddedToSlot_RemoveAmmo, ELD_Immediate);

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

static function EventListenerReturn ItemAddedToSlot_RemoveAmmo(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item, AmmoItem;
	local XComGameState_Unit Unit;
	local array<string> WeaponNames, AmmoUpgradeNames;
	local string tmpMessage, AmmoName, AmmoUpgradeName;
	local bool bWeaponHasAmmoUpgrade, bLog;
	local int i;

	bLog = class'X2DownloadableContentInfo_TeslaLootMod'.default.bLog;

	`LOG("ItemAddedToSlot_RemoveAmmo", bLog, 'TLMDEBUG');

	// Get the info we need
	Item = XComGameState_Item(EventData);
	Unit = XComGameState_Unit(EventSource);
	if (Item == none || Unit == none) return ELR_NoInterrupt;

	// Scenario #1: Equipping a weapon when a utility ammo is already equipped
	if (Item.GetMyWeaponUpgradeCount() > 0)
	{
		WUTemplates = Item.GetMyWeaponUpgradeTemplates();
		foreach WUTemplates(WUTemplate)
		{
			if (WUTemplate.IsA('X2WeaponUpgradeTemplate_TLMAmmo'))
			{
				bWeaponHasAmmoUpgrade = true;
				AmmoUpgradeName = WUTemplate.GetItemFriendlyName();
				break;
			}
		}
	}

	if (Item.GetMyTemplate().IsA('X2AmmoTemplate'))
	{
		// Scenario #2: Equipping an ammo utility item when a weapon is already equipped
		AmmoItem = Item;
	}
	else
	{
		// Scenario #1
		Items = Unit.GetAllInventoryItems();
		foreach Items(AmmoItem)
		{
			if(AmmoItem.GetMyTemplate().IsA('X2AmmoTemplate'))
			{
				break;
			}
		}
	}

	`LOG("bWeaponHasAmmoUpgrade: " $bWeaponHasAmmoUpgrade, bLog, 'TLMDEBUG');
	`LOG("HasItemOfTemplateClass: " $Unit.HasItemOfTemplateClass(class'X2AmmoTemplate'), bLog, 'TLMDEBUG');
	`LOG("UnitHasAmmoUpgrade: " $class'X2Helper_TLM'.static.UnitHasAmmoUpgrade(Unit), bLog, 'TLMDEBUG');
	`LOG("X2AmmoTemplate: " $Item.GetMyTemplate().IsA('X2AmmoTemplate'), bLog, 'TLMDEBUG');

	// Used in Scenario #1 and #2
	AmmoName = AmmoItem == none ? "AmmoItemNone" : AmmoItem.GetMyTemplate().GetItemFriendlyName();

	// Scenario #1
	if (bWeaponHasAmmoUpgrade && Unit.HasItemOfTemplateClass(class'X2AmmoTemplate'))
	{
		`LOG("Show message ammo wont take effect on weapons with ammo upgrade", bLog, 'TLMDEBUG');

		tmpMessage = Repl(default.strAmmoEquippedMessage, "<WEAPON_NAME>", Item.Nickname != "" ? Item.Nickname : Item.GetMyTemplate().GetItemFriendlyName());
		tmpMessage = Repl(tmpMessage, "<AMMO_NAME>", AmmoName);
		tmpMessage = Repl(tmpMessage, "<AMMOUPGRADE_NAME>", AmmoUpgradeName);

		class'X2StrategyElement_TLM'.static.UITLMGenericAlert(NewGameState, default.strAmmoEquipped, tmpMessage);
		return ELR_NoInterrupt;
	}

	// Scenario #2
	if (class'X2Helper_TLM'.static.UnitHasAmmoUpgrade(Unit, WeaponNames, AmmoUpgradeNames) && Item.GetMyTemplate().IsA('X2AmmoTemplate'))
	{
		`LOG("Show message ammo wont take effect on weapons with ammo upgrade", bLog, 'TLMDEBUG');

		for (i = 0; i < WeaponNames.Length; i++)
		{
			tmpMessage = Repl(default.strAmmoUpgradeExistMessage, "<AMMO_NAME>", AmmoName);
			tmpMessage = Repl(tmpMessage, "<WEAPON_NAME>", WeaponNames[i]);
			tmpMessage = Repl(tmpMessage, "<AMMOUPGRADE_NAME>", AmmoUpgradeNames[i]);
			class'X2StrategyElement_TLM'.static.UITLMGenericAlert(NewGameState, default.strAmmoEquipped, tmpMessage);
		}

		return ELR_NoInterrupt;
	}

	// Not applicable to us
	return ELR_NoInterrupt;
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
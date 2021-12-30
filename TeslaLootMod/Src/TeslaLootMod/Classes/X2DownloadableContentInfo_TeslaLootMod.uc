class X2DownloadableContentInfo_TeslaLootMod extends X2DownloadableContentInfo;

var config (TLM) array<LootTable> LootEntry;
var config (TLM) string strTier0Color;
var config (TLM) string strTier1Color;
var config (TLM) string strTier2Color;
var config (TLM) string strTier3Color;

var localized array<String> RandomWeaponNickNames;
var localized array<String> RandomArmorNickNames;
var localized string strHasAmmoAlreadyEquipped;
var localized string strWeaponHasAmmoUpgrade;
var localized string strRounds;
var localized string strPlus;

// =============
// DLC HOOKS
// =============
static event OnPostTemplatesCreated()
{
	class'X2Helper_TLM'.static.AddLootTables();
	class'X2Helper_TLM'.static.UpdateWeaponUpgrade();
	class'X2Helper_TLM'.static.SetDelegatesToUpgradeDecks();
}

static event OnLoadedSavedGameToStrategy()
{
	class'X2Helper_TLM'.static.CreateTechsMidCampaign();
}

static event OnLoadedSavedGameToTactical()
{
	class'X2Helper_TLM'.static.CreateTechsMidCampaign();
}

static function bool CanAddItemToInventory_CH_Improved(
	out int bCanAddItem,						// out value for XComGameState_Unit
	const EInventorySlot Slot,					// Inventory Slot you're trying to equip the Item into
	const X2ItemTemplate ItemTemplate,			// Item Template of the Item you're trying to equip
	int Quantity, 
	XComGameState_Unit UnitState,				// Unit State of the Unit you're trying to equip the Item on
	optional XComGameState CheckGameState, 
	optional out string DisabledReason,			// out value for the UIArmory_Loadout
	optional XComGameState_Item ItemState)		// Item State of the Item we're trying to equip
{	
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;	
	local X2AmmoTemplate AmmoTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local array<XComGameState_Item> InventoryItems;
	local XComGameState_Item InventoryItem;
	local bool bFailedAmmoEquip, bFailedWeaponEquip;
	local bool OverrideNormalBehavior;
	local bool DoNotOverrideNormalBehavior;
	local X2UpgradeDeckTemplateManager UDMan;
	local X2UpgradeDeckTemplate UDTemplate;

	// Prepare return values to make it easier for us to read the code.
	OverrideNormalBehavior = CheckGameState != none;
	DoNotOverrideNormalBehavior = CheckGameState == none;
	
	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	UDTemplate = UDMan.GetUpgradeDeckTemplate('AmmoDeck');

	// 1st scenario: Prevent weapon from being equipped if it has ammo upgrade and unit has ammo already equipped
	// Interested when weapon is attempted to be equipped
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);

	if (WeaponTemplate != none)
	{
		// Get its upgrade templates
		WUTemplates = ItemState.GetMyWeaponUpgradeTemplates();

		foreach WUTemplates(WUTemplate)
		{
			// Check if this upgrade is an ammo upgrade and unit has Ammo in inventory			
			if (UDTemplate.Upgrades.Find('UpgradeName', WUTemplate.DataName) != INDEX_NONE)
			{
				if (UnitState.HasItemOfTemplateClass(class'X2AmmoTemplate'))
				{
					bFailedWeaponEquip = true;
					break;
				}
			}
		}
	}

	// 2nd scenario: Prevent ammo utility item from being equipped if unit already has weapon with ammo upgrade
	// Interested if ammo is being equipped
	AmmoTemplate = X2AmmoTemplate(ItemTemplate);

	if (AmmoTemplate != none)
	{
		// Get all items in unit inventory
		InventoryItems = UnitState.GetAllInventoryItems();

		foreach InventoryItems(InventoryItem)
		{
			// Just grab the upgrades
			WUTemplates = InventoryItem.GetMyWeaponUpgradeTemplates();

			foreach WUTemplates(WUTemplate)
			{
				// If the upgrade is ammo upgrade
				if (UDTemplate.Upgrades.Find('UpgradeName', WUTemplate.DataName) != INDEX_NONE)
				{
					bFailedAmmoEquip = true;
					break;
				}
			}
			if (bFailedAmmoEquip) break;
		}
	}

	if (!bFailedWeaponEquip && !bFailedAmmoEquip) return DoNotOverrideNormalBehavior;	
	
	// Build string message
	if (bFailedWeaponEquip)
	{
		DisabledReason = default.strHasAmmoAlreadyEquipped;
	}
	else if (bFailedAmmoEquip)
	{
		DisabledReason = default.strWeaponHasAmmoUpgrade;
	}

	// Override to disallow the item from being equipped
	bCanAddItem = 0;

	// Return the override value. This will force the game to actually use our out values we have just set.
	return OverrideNormalBehavior;
}

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_TLM')
	{
		class'X2Helper_TLM'.static.CallUIAlert_TLM(PropertySet);
		return true;
	}

	return false;
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;
	local int i;

	Type = name(InString);

	switch(Type)
	{
	case 'RapidFireCharges':
		OutString = string(class'X2Ability_TLM'.default.RapidFireCharges);
		return true;
	case 'RapidFireAimPenalty':
		OutString = string(class'X2Ability_TLM'.default.RapidFireAimPenalty * -1);
		return true;
	case 'RapidFireCooldown':
		OutString = string(class'X2Ability_TLM'.default.RapidFireCooldown);
		return true;
	case 'HailOfBulletsCharges':
		OutString = string(class'X2Ability_TLM'.default.HailOfBulletsCharges);
		return true;
	case 'HailOfBulletsCooldown':
		OutString = string(class'X2Ability_TLM'.default.HailOfBulletsCooldown);
		return true;
	case 'KillZoneCharges':
		OutString = string(class'X2Ability_TLM'.default.KillZoneCharges);
		return true;
	case 'KillZoneCooldown':
		OutString = string(class'X2Ability_TLM'.default.KillZoneCooldown);
		return true;
	case 'FaceoffCharges':
		OutString = string(class'X2Ability_TLM'.default.FaceoffCharges);
		return true;
	case 'FaceoffCooldown':
		OutString = string(class'X2Ability_TLM'.default.FaceoffCooldown);
		return true;
	case 'BonusDamageAdventSoldier':
		OutString = string(class'X2Ability_TLM'.default.BonusDamageAdventSoldier);
		return true;
	case 'RapidFireClipSizeBonus':		
		i = class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades.Find('UpgradeName', 'TLMUpgrade_RapidFire');
		if (i != INDEX_NONE)
		{
			OutString = string(class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades[i].ClipSizeBonus);
			return true;
		}
		break;
	case 'HailofBulletsClipSizeBonus':
		i = class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades.Find('UpgradeName', 'TLMUpgrade_HailOfBullets');
		if (i != INDEX_NONE)
		{
			OutString = string(class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades[i].ClipSizeBonus);
			return true;
		}
		break;
	case 'KillZoneClipSizeBonus':
		i = class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades.Find('UpgradeName', 'TLMUpgrade_KillZone');
		if (i != INDEX_NONE)
		{
			OutString = string(class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades[i].ClipSizeBonus);
			return true;
		}
		break;
	case 'BonusDamageAlien':
		OutString = string(class'X2Ability_TLM'.default.BonusDamageAlien);
		return true;
	}
	return false;
}

// =============
// CONSOLE COMMANDS
// =============

exec function TLM_UpdateSlotCount()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;	
	local StateObjectReference ItemRef, UnitRef;
	local XComGameState NewGameState;
	local bool bUpdated;	

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Update items' slot count");

	// Update Data.NumUpgradeSlots for all items in XCOM HQ inventory
	foreach XComHQ.Inventory(ItemRef)
	{
		if (class'X2Helper_TLM'.static.UpdateSlotCount(ItemRef, NewGameState)) bUpdated = true;
	}

	// Update Data.NumUpgradeSlots for all items held in crew's inventory
	foreach XComHQ.Crew(UnitRef)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit == none) continue;

		foreach Unit.InventoryItems(ItemRef)
		{			
			if (class'X2Helper_TLM'.static.UpdateSlotCount(ItemRef, NewGameState)) bUpdated = true;
		}
	}

	if (bUpdated)
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		class'Helpers'.static.OutputMsg("No item was updated");
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

exec function TLM_GiveNickName(string Nickname, string HexColor)
{
	local XComGameState NewGameState;
	local UIArmory_WeaponUpgrade Armory_WeaponUpgrade;
	local XComGameState_Item Item;

	Armory_WeaponUpgrade = UIArmory_WeaponUpgrade(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory_WeaponUpgrade'));

	if (Armory_WeaponUpgrade == none)
	{
		class'Helpers'.static.OutputMsg("Need to be in item upgrade screen");
		return;
	}

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateforObjectID(Armory_WeaponUpgrade.WeaponRef.ObjectID));

	if (Item == none)
	{
		class'Helpers'.static.OutputMsg("No item selected");
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Update items' slot count");

	Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
	Item.Nickname = "<font color='" $HexColor $"'>" $Nickname $"</font>";

	`GAMERULES.SubmitGameState(NewGameState);

	class'Helpers'.static.OutputMsg("Item nickname updated to " $Item.Nickname);
}

exec function TLM_UpdateRarity(name RarityName)
{
	local XComGameState NewGameState;
	local UIArmory_WeaponUpgrade Armory_WeaponUpgrade;
	local XComGameState_Item Item;
	local XComGameState_ItemData Data;

	Armory_WeaponUpgrade = UIArmory_WeaponUpgrade(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory_WeaponUpgrade'));

	if (Armory_WeaponUpgrade == none)
	{
		class'Helpers'.static.OutputMsg("Need to be in item upgrade screen");
		return;
	}

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateforObjectID(Armory_WeaponUpgrade.WeaponRef.ObjectID));

	if (Item == none)
	{
		class'Helpers'.static.OutputMsg("No item selected");
		return;
	}

	Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));

	if (Data == none)
	{
		class'Helpers'.static.OutputMsg("Not a TLM item");
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Update item's rarity");

	Data = XComGameState_ItemData(NewGameState.ModifyStateObject(class'XComGameState_ItemData', Data.ObjectID));
	Data.RarityName = RarityName;

	`GAMERULES.SubmitGameState(NewGameState);

	class'Helpers'.static.OutputMsg("Item rarity updated to " $RarityName $". This has no gameplay changes just nick color when renaming.");
}
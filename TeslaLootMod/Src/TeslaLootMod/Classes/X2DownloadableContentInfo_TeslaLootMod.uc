class X2DownloadableContentInfo_TeslaLootMod extends X2DownloadableContentInfo;

struct PoolRestrictionData
{
	var ETRPoolType PoolType;
	var array<name> AllowedWeaponCats;
	var array<name> DisallowedWeaponCats;
};

var config (TLM) array<LootTable> LootEntry;
var config (TLM) array<PoolRestrictionData> PoolRestrictions;

var localized string strHasAmmoAlreadyEquipped;
var localized string strWeaponHasAmmoUpgrade;
var localized string strTier0Color;
var localized string strTier1Color;
var localized string strTier2Color;

// =============
// DLC HOOKS
// =============
static event OnPostTemplatesCreated()
{
	AddLootTables();
	UpdateWeaponUpgrade();
}

static event OnLoadedSavedGameToStrategy()
{
	CreateTechsMidCampaign();
}

static event OnLoadedSavedGameToTactical()
{
	CreateTechsMidCampaign();
}

static function bool CanWeaponApplyUpgrade(XComGameState_Item WeaponState, X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local PoolRestrictionData PoolRestriction;
	local ETRPoolType PoolType;	

	// Determine which pool is this upgrade from
	if (class'X2StrategyElement_TLM'.default.RandomAdjustmentUpgrades.Find(UpgradeTemplate.DataName) != INDEX_NONE)
		PoolType = ePool_Refinement;
	else if(class'X2StrategyElement_TLM'.default.RandomBaseUpgrades.Find(UpgradeTemplate.DataName) != INDEX_NONE)
		PoolType = ePool_Base;
	else if(class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades.Find(UpgradeTemplate.DataName) != INDEX_NONE)
		PoolType = ePool_Ammo;
	else if(class'X2StrategyElement_TLM'.default.RandomBaseMeleeUpgrades.Find(UpgradeTemplate.DataName) != INDEX_NONE)
		PoolType = ePool_Melee;	

	foreach default.PoolRestrictions(PoolRestriction)
	{
		if (PoolRestriction.PoolType != PoolType) continue;

		switch (PoolRestriction.PoolType)
		{
			case ePool_Refinement:
				return CanWeaponCatApplyUpgrade(X2WeaponTemplate(WeaponState.GetMyTemplate()).WeaponCat,
												UpgradeTemplate.DataName,
												PoolRestriction,
												class'X2StrategyElement_TLM'.default.RandomAdjustmentUpgrades);

				break;
			case ePool_Base:
				return CanWeaponCatApplyUpgrade(X2WeaponTemplate(WeaponState.GetMyTemplate()).WeaponCat,
												UpgradeTemplate.DataName,
												PoolRestriction,
												class'X2StrategyElement_TLM'.default.RandomBaseUpgrades);

				break;
			case ePool_Ammo:
				return CanWeaponCatApplyUpgrade(X2WeaponTemplate(WeaponState.GetMyTemplate()).WeaponCat,
												UpgradeTemplate.DataName,
												PoolRestriction,
												class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades);

				break;
		}
	}
	
	return true;
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

	// Prepare return values to make it easier for us to read the code.
	OverrideNormalBehavior = CheckGameState != none;
	DoNotOverrideNormalBehavior = CheckGameState == none;
	
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
			if (class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades.Find(WUTemplate.DataName) != INDEX_NONE)
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
				if (class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades.Find(WUTemplate.DataName) != INDEX_NONE)
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

	//  set the out value for XComGameState_Unit, letting the game know that this armor CANNOT be equipped on this soldier
	bCanAddItem = 0;

	//  return the override value. This will force the game to actually use our out values we have just set.
	return OverrideNormalBehavior;
}

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_TLM')
	{
		CallUIAlert_TLM(PropertySet);
		return true;
	}

	return false;
}

// =============
// HELPERS
// =============
static function CallUIAlert_TLM(const out DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_TLM Alert;

	Pres = `HQPRES;

	Alert = Pres.Spawn(class'UIAlert_TLM', Pres);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	Pres.ScreenStack.Push(Alert);
}

static function AddLootTables()
{
	local X2LootTableManager	LootManager;
	local LootTable				LootBag;
	local LootTableEntry		Entry;
	
	LootManager = X2LootTableManager(class'Engine'.static.FindClassDefaultObject("X2LootTableManager"));

	foreach default.LootEntry(LootBag)
	{
		if ( LootManager.default.LootTables.Find('TableName', LootBag.TableName) != INDEX_NONE )
		{
			foreach LootBag.Loots(Entry)
			{
				class'X2LootTableManager'.static.AddEntryStatic(LootBag.TableName, Entry, false);
			}
		}	
	}
}

static function bool CanWeaponCatApplyUpgrade(name WeaponCat, name UpgradeName, PoolRestrictionData PoolRestriction, array<name> UpgradePool)
{
	if (PoolRestriction.AllowedWeaponCats.Find(WeaponCat) != INDEX_NONE
		&& UpgradePool.Find(UpgradeName) != INDEX_NONE)
	{		
		return true;
	}

	if (PoolRestriction.DisallowedWeaponCats.Find(WeaponCat) != INDEX_NONE
		&& UpgradePool.Find(UpgradeName) != INDEX_NONE)
	{	
		return false;
	}

	return true;
}

static function CreateTechsMidCampaign()
{
	local XComGameState_Tech Tech;
	local X2TechTemplate TechTemplate;
	local XComGameState NewGameState;
	local bool bTechExists;

	bTechExists = false;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
	{
		if (Tech.GetMyTemplateName() == 'UnlockLockbox')
		{
			bTechExists = true;
			break;
		}
	}

	if (!bTechExists)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Create tech mid campaign");
		TechTemplate = X2TechTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('UnlockLockbox'));

		Tech = XComGameState_Tech(NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate));
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

static function UpdateWeaponUpgrade()
{
	local X2ItemTemplateManager ItemTemplateMan;
	local X2AbilityTemplateManager AbilityMan;
	local array<X2DataTemplate> DataTemplates;
	local X2DataTemplate DataTemplate;
	local WeaponAdjustmentData Adjustment;
	local X2WeaponUpgradeTemplate WUTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect Effect;
	local X2Effect_TLMEffects TLMEffect;
	local string ItemName, strColor;
	local name AbilityName;

	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	foreach class'X2Item_TLMUpgrades'.default.WeaponAdjustmentUpgrades(Adjustment)
	{
		ItemName = "TLMUpgrade_" $Adjustment.AdjustmentName;
		ItemTemplateMan.FindDataTemplateAllDifficulties(name(ItemName), DataTemplates);

		foreach DataTemplates(DataTemplate)
		{
			WUTemplate = X2WeaponUpgradeTemplate(DataTemplate);
			if (WUTemplate == none) continue;

			foreach WUTemplate.BonusAbilities(AbilityName)
			{
				AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);
				if (AbilityTemplate == none) continue;

				foreach AbilityTemplate.AbilityTargetEffects(Effect)
				{
					TLMEffect = X2Effect_TLMEffects(Effect);
					if (TLMEffect == none) continue;

					WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMDAMAGE", TLMEffect.FlatBonusDamage < 0 ? TLMEffect.FlatBonusDamage * -1 : TLMEffect.FlatBonusDamage);
					WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMCRITDAMAGE", TLMEffect.CritDamage < 0 ? TLMEffect.CritDamage * -1 : TLMEffect.CritDamage);
					WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMPIERCE", TLMEffect.Pierce < 0 ? TLMEffect.Pierce * -1 : TLMEffect.Pierce);
					WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMSHRED", TLMEffect.Shred < 0 ? TLMEffect.Shred * -1 : TLMEffect.Shred);
				}
			}

			switch (WUTemplate.Tier)
			{
				case 0:
					strColor = default.strTier0Color;
					break;
				case 1:
					strColor = default.strTier1Color;
					break;
				case 2:
					strColor = default.strTier2Color;
					break;	
			}

			if (strColor != "")
				WUTemplate.FriendlyName = "<font='" $strColor $"'>" $WUTemplate.FriendlyName $"</font>";
		}
	}	

}
class X2DownloadableContentInfo_TeslaLootMod extends X2DownloadableContentInfo;

var config (TLM) array<LootTable> LootEntry;

var localized string strHasAmmoAlreadyEquipped;
var localized string strWeaponHasAmmoUpgrade;
var localized string strTier0Color;
var localized string strTier1Color;
var localized string strTier2Color;
var localized string strTier3Color;

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
			if (class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades.Find('UpgradeName', WUTemplate.DataName) != INDEX_NONE)
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
				if (class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades.Find('UpgradeName', WUTemplate.DataName) != INDEX_NONE)
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
		CallUIAlert_TLM(PropertySet);
		return true;
	}

	return false;
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;

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
	local array<name> WUNames;
	local string ItemName, strColor;
	local name AbilityName, WUName;

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
		}
	}

	CollectUpgradeNames(WUNames, class'X2StrategyElement_TLM'.default.RandomAdjustmentUpgrades);
	CollectUpgradeNames(WUNames, class'X2StrategyElement_TLM'.default.RandomBaseUpgrades);	
	CollectUpgradeNames(WUNames, class'X2StrategyElement_TLM'.default.RandomAmmoUpgrades);		
	CollectUpgradeNames(WUNames, class'X2StrategyElement_TLM'.default.RandomLegendaryUpgrades);	

	foreach WUNames(WUName)
	{		
		ItemTemplateMan.FindDataTemplateAllDifficulties(WUName, DataTemplates);

		foreach DataTemplates(DataTemplate)
		{
			WUTemplate = X2WeaponUpgradeTemplate(DataTemplate);
			if (WUTemplate == none) continue;

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
				case 3:
					strColor = default.strTier3Color;
					break;
			}

			if (strColor != "")
				WUTemplate.FriendlyName = "<font color='" $strColor $"'>" $WUTemplate.FriendlyName $"</font>";
		}
	}
}

static function AppendArrays(out array<name> ArrayA, array<name> ArrayB)
{
	local name ArrayContent;

	foreach ArrayB(ArrayContent)
	{
		ArrayA.AddItem(ArrayContent);
	}
}

static function CollectUpgradeNames(out array<name> WUNames, array<UpgradePoolData> UpgradePool)
{
	local UpgradePoolData UpgradeData;

	foreach UpgradePool(UpgradeData)
	{
		WUNames.AddItem(UpgradeData.UpgradeName);
	}
}
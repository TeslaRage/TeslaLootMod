class X2UpgradeDeckTemplate extends X2DataTemplate config(TLM);

var localized string FriendlyName;

var config ItemCatData AllowedItemCat;
var config array<name> AllowedCats;
var config array<name> RequiredAbilitiesOnEquipment;
var config array<UpgradeDeckData> Upgrades;

var Delegate<ModifyNickNameDelegate> ModifyNickNameFn;

delegate string ModifyNickNameDelegate(array<X2WeaponUpgradeTemplate> AppliedUpgrades, XComGameState_Item Item);

function RollUpgrades(XComGameState_Item Item, int Quantity, optional bool bApplyNick = true)
{
	local UpgradeDeckData Upgrade;
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<X2WeaponUpgradeTemplate> WUTemplates, AppliedUpgrades;
	local X2ItemTemplateManager ItemMan;
	local array<ItemWeightData> ItemWeights;
	local ItemWeightData ItemWeight;
	local int Applied, Idx;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	Idx = 0;
	foreach Upgrades(Upgrade)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemMan.FindItemTemplate(Upgrade.UpgradeName));

		// Maybe because required mod like melee upgrades is not installed
		if (WUTemplate == none) continue;

		if (!CanApplyUpgrade(WUTemplate, Item, Upgrade)) continue;
		
		WUTemplates.AddItem(WUTemplate);
		ItemWeight.Index = Idx;
		ItemWeight.Weight = Upgrade.Weight;
		ItemWeights.AddItem(ItemWeight);
		Idx++;
	}

	// Pick upgrades and apply
	while (WUTemplates.Length > 0 && Applied < Quantity)
	{
		Idx = class'X2Helper_TLM'.static.GetWeightBasedIndex(ItemWeights);
		if (Idx < 0) continue;

		WUTemplate = WUTemplates[Idx];
		
		if (WUTemplate.CanApplyUpgradeToWeapon(Item, Item.GetMyWeaponUpgradeCount())
			&& Item.CanWeaponApplyUpgrade(WUTemplate))
		{
			Item.ApplyWeaponUpgradeTemplate(WUTemplate);
			AppliedUpgrades.AddItem(WUTemplate);
			WUTemplates.Remove(Idx, 1);
			ItemWeights.Remove(Idx, 1);
			Applied++;
		}
		else
		{
			WUTemplates.Remove(Idx, 1);
			ItemWeights.Remove(Idx, 1);
		}
	}

	ValidateItem(Item);

	if (ModifyNickNameFn != none && bApplyNick)
	{
		Item.NickName = ModifyNickNameFn(AppliedUpgrades, Item);
	}
}

function bool CanApplyUpgrade(X2WeaponUpgradeTemplate WUTemplate, XComGameState_Item Item, UpgradeDeckData Upgrade)
{
	local X2EquipmentTemplate EqTemplate;
	local name AbilityName;
	local bool bRequiredAbilityFound;
	local bool bLog;

	bLog = class'X2DownloadableContentInfo_TeslaLootMod'.default.bLog;

	`LOG(Item.GetMyTemplateName() @"against" @WUTemplate.DataName, bLog, 'TLMDEBUG');

	// Go through the basic validation first
	if (!WUTemplate.CanApplyUpgradeToWeapon(Item, Item.GetMyWeaponUpgradeCount()))
	{
		`LOG("Failed CanApplyUpgradeToWeapon", bLog, 'TLMDEBUG');
		return false;
	}

	if (!Item.CanWeaponApplyUpgrade(WUTemplate))
	{
		`LOG("Failed CanWeaponApplyUpgrade", bLog, 'TLMDEBUG');
		return false;
	}

	// Does this upgrade have valid abilities?
	if (HasInvalidAbilities(WUTemplate, Upgrade))
	{
		`LOG("Failed HasInvalidAbilities", bLog, 'TLMDEBUG');
		return false;
	}

	// Need to check UpgradeDeckData's AllowedWeaponCats and DisallowedWeaponCats
	// Custom upgrades already check this via delegate CanApplyTLMUpgradeToWeapon
	// so this manual check is meant for upgrades from other mods including base game's
	if (Upgrade.AllowedWeaponCats.Length > 0
		&& Upgrade.AllowedWeaponCats.Find(Item.GetWeaponCategory()) == INDEX_NONE)
	{
		`LOG("Failed AllowedWeaponCats", bLog, 'TLMDEBUG');
		return false;
	}
	else if (Upgrade.DisallowedWeaponCats.Find(Item.GetWeaponCategory()) != INDEX_NONE)
	{
		`LOG("Failed DisallowedWeaponCats", bLog, 'TLMDEBUG');
		return false;
	}

	// Checks to make sure that the item has required ability before any upgrade from this
	// deck can be applied. This is useful in cases where a weapon with built in ammo effect
	// is part of the base item deck.
	EqTemplate = X2EquipmentTemplate(Item.GetMyTemplate());

	if (EqTemplate != none && RequiredAbilitiesOnEquipment.Length > 0)
	{
		foreach EqTemplate.Abilities(AbilityName)
		{
			if (RequiredAbilitiesOnEquipment.Find(AbilityName) != INDEX_NONE)
			{
				bRequiredAbilityFound = true;
				break;
			}
		}

		if (!bRequiredAbilityFound)
		{
			`LOG("Failed bRequiredAbilityFound", bLog, 'TLMDEBUG');
			return false;
		}
	}

	// If we reach here, it means the upgrade is good for this item
	return true;
}

static function bool HasInvalidAbilities(X2WeaponUpgradeTemplate WUTemplate, UpgradeDeckData Upgrade)
{
	local X2AbilityTemplateManager AbilityMan;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach WUTemplate.BonusAbilities(AbilityName)
	{
		AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate == none) return true;
	}

	// Issue #16
	// If bMustHaveAbility is true, then the upgrade must have ability to be considered valid
	if (Upgrade.bMustHaveAbility && WUTemplate.BonusAbilities.Length == 0)
	{
		return true;
	}

	return false;
}

function array<X2WeaponUpgradeTemplate> GetUpgradeTemplates()
{
	local X2ItemTemplateManager ItemMan;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local UpgradeDeckData Upgrade;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach Upgrades(Upgrade)
	{
		UpgradeTemplate = X2WeaponUpgradeTemplate(ItemMan.FindItemTemplate(Upgrade.UpgradeName));
		if (UpgradeTemplate == none) continue;
		UpgradeTemplates.AddItem(UpgradeTemplate);
	}

	return UpgradeTemplates;
}

function array<name> GetUpgradeTemplateNames()
{
	local array<name> UpgradeTemplateNames;	
	local UpgradeDeckData Upgrade;

	foreach Upgrades(Upgrade)
	{	
		UpgradeTemplateNames.AddItem(Upgrade.UpgradeName);
	}

	return UpgradeTemplateNames;
}

function bool ValidateTemplate (out string strError)
{
	if (!super.ValidateTemplate(strError))
	{
		return false;
	}

	if (Upgrades.Length == 0)
	{
		strError = "Upgrades is empty so items will not get any weapon upgrades";
		return false;
	}

	return true;
}

function ValidateItem(XComGameState_Item Item)
{
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local X2WeaponTemplate WTemplate;
	local int i, ClipSize;
	local bool bReapply;

	// If the upgrades attached has caused the weapon to have clip size of less than 1,
	// remove the upgrade from the weapon. This also means the weapon will end up with less
	// upgrades than anticipated.

	WTemplate = X2WeaponTemplate(Item.GetMyTemplate());

	if (WTemplate != none && WTemplate.iClipSize > 0 && Item.GetClipSize() < 1)
	{
		ClipSize = Item.GetClipSize();

		WUTemplates = Item.GetMyWeaponUpgradeTemplates();

		// Filter weapon upgrades, only saving the ones we need to reapply
		for (i = 0; i < WUTemplates.Length; i++)
		{
			if (WUTemplates[i].ClipSizeBonus < 0)
			{
				ClipSize += (WUTemplates[i].ClipSizeBonus * -1);
				WUTemplates.Remove(i, 1);
				i--;
				bReapply = true;

				if (ClipSize > 0) break;

				continue;
			}
		}

		// Reapply as needed
		if (bReapply)
		{
			Item.WipeUpgradeTemplates();

			foreach WUTemplates(WUTemplate)
			{
				Item.ApplyWeaponUpgradeTemplate(WUTemplate);
			}
		}
	}
}
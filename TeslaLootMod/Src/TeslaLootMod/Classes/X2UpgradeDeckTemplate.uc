class X2UpgradeDeckTemplate extends X2DataTemplate config(TLM);

var config array<UpgradeDeckData> Upgrades;

var Delegate<ModifyNickNameDelegate> ModifyNickNameFn;

delegate string ModifyNickNameDelegate(array<X2WeaponUpgradeTemplate> AppliedUpgrades, XComGameState_Item Item);

function RollUpgrades(out XComGameState_Item Item, int Quantity)
{
	local UpgradeDeckData Upgrade;
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<X2WeaponUpgradeTemplate> WUTemplates, AppliedUpgrades;
	local X2ItemTemplateManager ItemMan;
	local int Applied, Idx;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach Upgrades(Upgrade)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemMan.FindItemTemplate(Upgrade.UpgradeName));

		// Maybe because required mod like melee upgrades is not installed
		if (WUTemplate == none) continue;

		// Go through the basic validation first
		if (!WUTemplate.CanApplyUpgradeToWeapon(Item, Item.GetMyWeaponUpgradeCount())
			&& !Item.CanWeaponApplyUpgrade(WUTemplate))
			continue;

		// If configured as allowed, then we include into pool
		if (Upgrade.AllowedWeaponCats.Find(X2WeaponTemplate(Item.GetMyTemplate()).WeaponCat) != INDEX_NONE)
		{
			WUTemplates.AddItem(WUTemplate);
			continue;
		}
		else if (Upgrade.AllowedWeaponCats.Length > 0)		
			continue;

		// If configured as disallowed, then we don't include into pool
		if (Upgrade.DisallowedWeaponCats.Find(X2WeaponTemplate(Item.GetMyTemplate()).WeaponCat) != INDEX_NONE)
			continue;

		// Does this upgrade have valid abilities?
		if (HasInvalidAbilities(WUTemplate))
			continue;

		// If we reach here, it means the upgrade is meant for all weapon categories
		WUTemplates.AddItem(WUTemplate);
	}

	// Pick upgrades and apply
	while (WUTemplates.Length > 0 && Applied < Quantity)
	{
		Idx = `SYNC_RAND_STATIC(WUTemplates.Length);
		WUTemplate = WUTemplates[Idx];
		
		if (WUTemplate.CanApplyUpgradeToWeapon(Item, Item.GetMyWeaponUpgradeCount())
			&& Item.CanWeaponApplyUpgrade(WUTemplate))
		{
			Item.ApplyWeaponUpgradeTemplate(WUTemplate);
			AppliedUpgrades.AddItem(WUTemplate);
			WUTemplates.Remove(Idx, 1);
			Applied++;
		}
		else
		{
			WUTemplates.Remove(Idx, 1);
		}		
	}

	if (ModifyNickNameFn != none)
	{
		Item.NickName = ModifyNickNameFn(AppliedUpgrades, Item);
	}
}

static function bool HasInvalidAbilities(X2WeaponUpgradeTemplate WUTemplate)
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

	return false;
}
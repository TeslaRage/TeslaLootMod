class X2UpgradeDeckTemplate extends X2DataTemplate config(TLM);

var config array<UpgradeDeckData> Upgrades;

var Delegate<ModifyNickNameDelegate> ModifyNickNameFn;

delegate string ModifyNickNameDelegate(array<X2WeaponUpgradeTemplate> AppliedUpgrades, XComGameState_Item Item);

function RollUpgrades(XComGameState_Item Item, int Quantity)
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

		if (!CanApplyUpgrade(WUTemplate, Item, Upgrade)) continue;
		
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

function bool CanApplyUpgrade(X2WeaponUpgradeTemplate WUTemplate, XComGameState_Item Item, UpgradeDeckData Upgrade)
{
	// Go through the basic validation first
	if (!WUTemplate.CanApplyUpgradeToWeapon(Item, Item.GetMyWeaponUpgradeCount()))
		return false;

	if (!Item.CanWeaponApplyUpgrade(WUTemplate))
		return false;

	// If not configured as allowed cat, say no.
	if (Upgrade.AllowedWeaponCats.Length > 0
		&& Upgrade.AllowedWeaponCats.Find(X2WeaponTemplate(Item.GetMyTemplate()).WeaponCat) == INDEX_NONE)
	{
		return false;
	}

	// If configured as disallowed, say no.
	if (Upgrade.DisallowedWeaponCats.Find(X2WeaponTemplate(Item.GetMyTemplate()).WeaponCat) != INDEX_NONE)
		return false;

	// Does this upgrade have valid abilities?
	if (HasInvalidAbilities(WUTemplate))
		return false;

	// If we reach here, it means the upgrade is good for this item
	return true;
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
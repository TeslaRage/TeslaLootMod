class X2Item_TLMUpgrades extends X2Item_DefaultUpgrades config (TLM);

var config array<AbilityUpgradeData> AbilityWeaponUpgrades;
var config array<PatchWeaponUpgradesData> PatchWeaponUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local AmmoConversionData AmmoConversion;	
	local AbilityUpgradeData AbilityWeaponUpgrade;
	local string AbilityName;

	// Ammo Upgrades
	foreach class'X2Ability_TLM'.default.ConvertAmmo(AmmoConversion)
	{
		if ((class'X2Helper_TLM'.static.IsModLoaded(AmmoConversion.DLC) && AmmoConversion.DLC != '')
			|| AmmoConversion.DLC == '')
		{
			AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;
			Items.AddItem(AmmoUpgrade(name(AbilityName), AmmoConversion));
		}
	}

	// Ability to Weapon Upgrade Conversion
	foreach default.AbilityWeaponUpgrades(AbilityWeaponUpgrade)
	{
		Items.AddItem(AbilityUpgrade(AbilityWeaponUpgrade));
	}	

	return Items;
}

// HELPERS
static function X2DataTemplate AmmoUpgrade(name AbilityName, AmmoConversionData AmmoConversion)
{
	local X2WeaponUpgradeTemplate_TLMAmmo Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate_TLMAmmo', Template, AmmoConversion.UpgradeName);

	Template.BonusAbilities.AddItem(AbilityName);
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = AmmoConversion.Image;
	Template.AmmoTemplateName = AmmoConversion.Ammo;

	Template.ClipSizeBonus = AmmoConversion.ClipSizeBonus;
	Template.AdjustClipSizeFn = TLMUpgradeAdjustClipSize;

	Template.CanApplyUpgradeToWeaponFn = CanApplyTLMUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = AmmoConversion.Tier;

	// Upgrade icons are set up in OPTC
	
	return Template;
}

static function X2DataTemplate AbilityUpgrade(AbilityUpgradeData AbilityWeaponUpgrade)
{
	local X2WeaponUpgradeTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, AbilityWeaponUpgrade.UpgradeName);

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = AbilityWeaponUpgrade.strImage;

	Template.BonusAbilities.AddItem(AbilityWeaponUpgrade.AbilityName);

	if (AbilityWeaponUpgrade.ClipSizeBonus != 0)
	{
		Template.ClipSizeBonus = AbilityWeaponUpgrade.ClipSizeBonus;
		Template.AdjustClipSizeFn = TLMUpgradeAdjustClipSize;
	}	

	Template.CanApplyUpgradeToWeaponFn = CanApplyTLMUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = AbilityWeaponUpgrade.Tier;

	// Mutual exclusive setup is done in OPTC group by weapon upgrade deck
	// or if this list from config is not blank
	if (AbilityWeaponUpgrade.MutuallyExclusiveUpgrades.Length != 0)
	{
		Template.MutuallyExclusiveUpgrades = AbilityWeaponUpgrade.MutuallyExclusiveUpgrades;
	}

	// Upgrade icons are set up in OPTC

	return Template;
}

// DELEGATES
// This needs its own custom delegate to prevent it from getting empowered upgrade continent/resistance faction card bonus
static function bool TLMUpgradeAdjustClipSize(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, const int CurrentClipSize, out int AdjustedClipSize)
{
	AdjustedClipSize = CurrentClipSize + UpgradeTemplate.ClipSizeBonus;
	return true;
}

static function bool CanApplyTLMUpgradeToWeapon(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, int SlotIndex)
{
	local array<X2WeaponUpgradeTemplate> AttachedUpgradeTemplates;
	local X2WeaponUpgradeTemplate AttachedUpgrade;
	local X2UpgradeDeckTemplateManager UDMan;
	local array<X2UpgradeDeckTemplate> UDTemplates;
	local UpgradeDeckData Upgrade;	
	local name WeaponCat;
	local int iSlot, Index;

	// Check upgrade deck setup
	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	UDTemplates = UDMan.GetUpgradeDecksByUpgradeName(UpgradeTemplate.DataName, true);
	
	if (UDTemplates.Length != 0)
	{
		WeaponCat = X2WeaponTemplate(Weapon.GetMyTemplate()).WeaponCat;

		if (UDTemplates[0].AllowedCats.Length > 0
			&& UDTemplates[0].AllowedCats.Find(WeaponCat) == INDEX_NONE)
		{
			return false;
		}

		Index = UDTemplates[0].Upgrades.Find('UpgradeName', UpgradeTemplate.DataName);
		if (Index != INDEX_NONE)
		{
			Upgrade = UDTemplates[0].Upgrades[Index];

			if (Upgrade.AllowedWeaponCats.Length > 0
				&& Upgrade.AllowedWeaponCats.Find(WeaponCat) == INDEX_NONE)
			{
				return false;
			}
			else if (Upgrade.DisallowedWeaponCats.Find(WeaponCat) != INDEX_NONE)
			{
				return false;
			}
		}
	}
	
	// The rest of this check was copied from CanApplyUpgradeToWeapon delegate from base game
	AttachedUpgradeTemplates = Weapon.GetMyWeaponUpgradeTemplates();

	foreach AttachedUpgradeTemplates(AttachedUpgrade, iSlot)
	{
		// Slot Index indicates the upgrade slot the player intends to replace with this new upgrade
		if (iSlot == SlotIndex)
		{
			// The exact upgrade already equipped in a slot cannot be equipped again
			// This allows different versions of the same upgrade type to be swapped into the slot
			if (AttachedUpgrade == UpgradeTemplate)
			{
				return false;
			}
		}
		else if (UpgradeTemplate.MutuallyExclusiveUpgrades.Find(AttachedUpgrade.DataName) != INDEX_NONE)
		{
			// If the new upgrade is mutually exclusive with any of the other currently equipped upgrades, it is not allowed
			return false;
		}
	}

	return true;
}
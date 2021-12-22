class X2Item_TLMUpgrades extends X2Item_DefaultUpgrades config (TLM);

var config array<AbilityUpgradeData> AbilityWeaponUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local AmmoConversionData AmmoConversion;	
	local AbilityUpgradeData AbilityWeaponUpgrade;
	local string AbilityName;

	// Ammo Upgrades
	foreach class'X2Ability_TLM'.default.ConvertAmmo(AmmoConversion)
	{
		AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;		
		Items.AddItem(AmmoUpgrade(name(AbilityName), AmmoConversion));
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

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
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

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = AbilityWeaponUpgrade.Tier;

	// Mutual exclusive setup is done in OPTC group by weapon upgrade deck
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
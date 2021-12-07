class X2Item_TLMUpgrades extends X2Item_DefaultUpgrades config (TLM);

var config array<name> ClipSizeModifyingUpgrades;
var config array<WeaponAdjustmentData> WeaponAdjustmentUpgrades;
var config int AmmoUpgradeClipSizePenalty;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local AmmoConversionData AmmoConversion;
	local WeaponAdjustmentData Adjustment;
	local string ItemName, AbilityName;

	// Ammo Upgrades
	foreach class'X2Ability_TLM'.default.ConvertAmmo(AmmoConversion)
	{
		ItemName = "TLMUpgrade_" $AmmoConversion.Ammo;
		AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;		
		Items.AddItem(AmmoUpgrade(name(ItemName), name(AbilityName), AmmoConversion));
	}

	// Weapon Refinement Upgrades
	foreach default.WeaponAdjustmentUpgrades(Adjustment)
	{
		ItemName = "TLMUpgrade_" $Adjustment.AdjustmentName;
		Items.AddItem(AdjustmentUpgrade(name(ItemName), Adjustment));
	}

	// Legendary upgrades
	Items.AddItem(Legendary_RapidFire());
	Items.AddItem(Legendary_HailOfBullets());
	Items.AddItem(Legendary_KillZone());

	return Items;
}

// HELPERS
static function X2DataTemplate AmmoUpgrade(name WeaponUpgradeName, name AbilityName, AmmoConversionData AmmoConversion)
{
	local X2WeaponUpgradeTemplate_TLMAmmo Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate_TLMAmmo', Template, WeaponUpgradeName);

	Template.BonusAbilities.AddItem(AbilityName);
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = AmmoConversion.Image;
	Template.AmmoTemplateName = AmmoConversion.Ammo;

	Template.ClipSizeBonus = -default.AmmoUpgradeClipSizePenalty;
	Template.AdjustClipSizeFn = AmmoUpgradeAdjustClipSize;

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 2; // This influences the color in the popup

	if (AmmoConversion.MEWithClipSizeMods)
		Template.MutuallyExclusiveUpgrades = default.ClipSizeModifyingUpgrades;

	SetUpgradeIcons(Template);
	
	return Template;
}

static function SetUpgradeIcons(out X2WeaponUpgradeTemplate_TLMAmmo Template)
{
	local BaseWeaponDeckData DeckedBaseWeapon;

	foreach class'X2StrategyElement_TLM'.default.DeckedBaseWeapons(DeckedBaseWeapon)
	{
		Template.AddUpgradeAttachment('', '', "", "", DeckedBaseWeapon.BaseWeapon, , "", Template.strImage, "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	}	
}

static function X2DataTemplate AdjustmentUpgrade(name WeaponUpgradeName, WeaponAdjustmentData Adjustment)
{
	local X2WeaponUpgradeTemplate Template;
	local string AbilityName;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, WeaponUpgradeName);	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Power_Cell";

	AbilityName = "TLMAbility_" $Adjustment.AdjustmentName;
	Template.BonusAbilities.AddItem(name(AbilityName));

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = Adjustment.Tier;

	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_heat_sink");
	
	return Template;
}

static function SetUpgradeIcons_AdjustmentUpgrade(out X2WeaponUpgradeTemplate Template, string Icon)
{
	local BaseWeaponDeckData DeckedBaseWeapon;

	foreach class'X2StrategyElement_TLM'.default.DeckedBaseWeapons(DeckedBaseWeapon)
	{
		Template.AddUpgradeAttachment('', '', "", "", DeckedBaseWeapon.BaseWeapon, , "", Template.strImage, Icon);
	}
}

static function X2DataTemplate Legendary_RapidFire()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'TLMUpgrade_RapidFire');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";
	
	Template.BonusAbilities.AddItem('TLMAbility_RapidFire');

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	SetUpLegendaryMutualExclusives(Template);
	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_PerkIcons.UIPerk_rapidfire"); // Fine to reuse this

	return Template;
}

static function X2DataTemplate Legendary_HailOfBullets()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'TLMUpgrade_HailOfBullets');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";
	
	Template.BonusAbilities.AddItem('TLMAbility_HailOfBullets');

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	SetUpLegendaryMutualExclusives(Template);
	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_PerkIcons.UIPerk_hailofbullets"); // Fine to reuse this

	return Template;
}

static function X2DataTemplate Legendary_KillZone()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'TLMUpgrade_KillZone');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";
	
	Template.BonusAbilities.AddItem('TLMAbility_KillZone');

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	SetUpLegendaryMutualExclusives(Template);
	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_PerkIcons.UIPerk_killzone"); // Fine to reuse this

	return Template;
}

static function SetUpLegendaryMutualExclusives(out X2WeaponUpgradeTemplate Template)
{
	local UpgradePoolData LegendaryUpgrade;

	foreach class'X2StrategyElement_TLM'.default.RandomLegendaryUpgrades(LegendaryUpgrade)
	{
		Template.MutuallyExclusiveUpgrades.AddItem(LegendaryUpgrade.UpgradeName);
	}
}

// DELEGATES
// This needs its own custom delegate to prevent it from getting empowered upgrade continent/resistance faction card bonus
static function bool AmmoUpgradeAdjustClipSize(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, const int CurrentClipSize, out int AdjustedClipSize)
{
	AdjustedClipSize = CurrentClipSize + UpgradeTemplate.ClipSizeBonus;
	return true;
}
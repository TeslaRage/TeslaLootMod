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
		Items.AddItem(AmmoUpgrade(name(ItemName), AmmoConversion.Ammo, name(AbilityName), AmmoConversion.Image, AmmoConversion.MEWithClipSizeMods));
	}

	// Weapon Refinement Upgrades
	foreach default.WeaponAdjustmentUpgrades(Adjustment)
	{
		ItemName = "TLMUpgrade_" $Adjustment.AdjustmentName;
		Items.AddItem(AdjustmentUpgrade(name(ItemName), Adjustment));
	}

	return Items;
}

// HELPERS
static function X2DataTemplate AmmoUpgrade(name WeaponUpgradeName, name AmmoTemplateName, name AbilityName, string Image, bool MEWithClipSizeMods)
{
	local X2WeaponUpgradeTemplate_TLMAmmo Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate_TLMAmmo', Template, WeaponUpgradeName);

	Template.BonusAbilities.AddItem(AbilityName);
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = Image;
	Template.AmmoTemplateName = AmmoTemplateName;

	Template.ClipSizeBonus = -default.AmmoUpgradeClipSizePenalty;
	Template.AdjustClipSizeFn = AmmoUpgradeAdjustClipSize;

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;

	if (MEWithClipSizeMods)
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

	SetUpgradeIcons_AdjustmentUpgrade(Template);
	
	return Template;
}

static function SetUpgradeIcons_AdjustmentUpgrade(out X2WeaponUpgradeTemplate Template)
{
	local BaseWeaponDeckData DeckedBaseWeapon;

	foreach class'X2StrategyElement_TLM'.default.DeckedBaseWeapons(DeckedBaseWeapon)
	{
		Template.AddUpgradeAttachment('', '', "", "", DeckedBaseWeapon.BaseWeapon, , "", Template.strImage, "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_heat_sink");
	}
}

// DELEGATES
// This needs its own custom delegate to prevent it from getting empowered upgrade continent/resistance faction card bonus
static function bool AmmoUpgradeAdjustClipSize(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, const int CurrentClipSize, out int AdjustedClipSize)
{
	AdjustedClipSize = CurrentClipSize + UpgradeTemplate.ClipSizeBonus;
	return true;
}
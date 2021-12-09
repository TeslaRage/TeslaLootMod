class X2Item_TLMUpgrades extends X2Item_DefaultUpgrades config (TLM);

var config array<WeaponAdjustmentData> WeaponAdjustmentUpgrades;
var config int AmmoUpgradeClipSizePenalty;
var config int RapidFireClipSizeBonus;
var config int HailofBulletsClipSizeBonus;
var config array<AbilityUpgradeData> AbilityWeaponUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local AmmoConversionData AmmoConversion;
	local WeaponAdjustmentData Adjustment;
	local AbilityUpgradeData AbilityWeaponUpgrade;
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
	Items.AddItem(Legendary_Faceoff());
	Items.AddItem(Legendary_AdventSoldierKiller());
	Items.AddItem(Legendary_AlienKiller());

	// Ability to Weapon Upgrade Conversion
	foreach default.AbilityWeaponUpgrades(AbilityWeaponUpgrade)
	{
		Items.AddItem(AbilityUpgrade(AbilityWeaponUpgrade));
	}	

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
	Template.AdjustClipSizeFn = TLMUpgradeAdjustClipSize;

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 2; // This influences the color in the popup

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

	// Ability needs 2 ammo so +1 (with ammo upgrade clip size penalty taken into consideration)
	Template.ClipSizeBonus = default.RapidFireClipSizeBonus;
	Template.AdjustClipSizeFn = TLMUpgradeAdjustClipSize;

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

	// Ability needs 3 ammo so +2 (with ammo upgrade clip size penalty taken into consideration)
	Template.ClipSizeBonus = default.HailofBulletsClipSizeBonus;
	Template.AdjustClipSizeFn = TLMUpgradeAdjustClipSize;

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

static function X2DataTemplate Legendary_Faceoff()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'TLMUpgrade_Faceoff');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";
	
	Template.BonusAbilities.AddItem('TLMAbility_Faceoff');

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	SetUpLegendaryMutualExclusives(Template);
	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_PerkIcons.UIPerk_faceoff"); // Fine to reuse this

	return Template;
}

static function X2DataTemplate Legendary_AdventSoldierKiller()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'TLMUpgrade_AdventSoldierKiller');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";
	
	Template.BonusAbilities.AddItem('TLMAbility_AdventSoldierKiller');

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	SetUpLegendaryMutualExclusives(Template);
	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_PerkIcons.UIPerk_hunter"); // Fine to reuse this

	return Template;
}

static function X2DataTemplate Legendary_AlienKiller()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'TLMUpgrade_AlienKiller');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";
	
	Template.BonusAbilities.AddItem('TLMAbility_AlienKiller');

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	SetUpLegendaryMutualExclusives(Template);
	SetUpgradeIcons_AdjustmentUpgrade(Template, "img:///UILibrary_PerkIcons.UIPerk_hunter"); // Fine to reuse this

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

static function X2DataTemplate AbilityUpgrade(AbilityUpgradeData AbilityWeaponUpgrade)
{
	local X2WeaponUpgradeTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, AbilityWeaponUpgrade.UpgradeName);

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Power_Cell";

	Template.BonusAbilities.AddItem(AbilityWeaponUpgrade.AbilityName);

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
	Template.Tier = 3;

	// Mutual exclusive setup?
	SetUpgradeIcons_AdjustmentUpgrade(Template, AbilityWeaponUpgrade.Icon);

	return Template;
}

// DELEGATES
// This needs its own custom delegate to prevent it from getting empowered upgrade continent/resistance faction card bonus
static function bool TLMUpgradeAdjustClipSize(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, const int CurrentClipSize, out int AdjustedClipSize)
{
	AdjustedClipSize = CurrentClipSize + UpgradeTemplate.ClipSizeBonus;
	return true;
}
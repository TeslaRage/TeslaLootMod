class X2Item_TLMUpgrades extends X2Item_DefaultUpgrades config (TLM);

var config array<name> ClipSizeModifyingUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local AmmoConversionData AmmoConversion;
	local string ItemName, AbilityName;

	foreach class'X2Ability_TLM'.default.ConvertAmmo(AmmoConversion)
	{
		ItemName = "TLMUpgrade_" $AmmoConversion.Ammo;
		AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;
		Items.AddItem(AmmoUpgrade(name(ItemName), AmmoConversion.Ammo, name(AbilityName), AmmoConversion.Image, AmmoConversion.MEWithClipSizeMods));
	}

	Items.AddItem(FineTuning());

	return Items;
}

static function X2DataTemplate AmmoUpgrade(name WeaponUpgradeName, name AmmoTemplateName, name AbilityName, string Image, bool MEWithClipSizeMods)
{
	local X2WeaponUpgradeTemplate_TLMAmmo Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate_TLMAmmo', Template, WeaponUpgradeName);

	Template.BonusAbilities.AddItem(AbilityName);
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = Image;
	Template.AmmoTemplateName = AmmoTemplateName;

	Template.ClipSizeBonus = -1;
	Template.AdjustClipSizeFn = AdjustClipSize;
	Template.GetBonusAmountFn = GetClipSizeBonusAmount;

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

static function X2DataTemplate FineTuning()
{
	local X2WeaponUpgradeTemplate Template;	

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FineTuning');	
		
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "";	

	Template.CHBonusDamage.Damage = 1;
	Template.AddCHDamageModifierFn = AddCHDamageModifier;	

	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;
	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;

	// SetUpgradeIcons(Template);
	
	return Template;
}

	// var() int Damage;           //  base damage amount	
	// var() int PlusOne;          //  chance from 0-100 that one bonus damage will be added
	// var() int Crit;             //  additional damage dealt on a critical hit
	// var() int Pierce;           //  armor piercing value
	// var() int Rupture;          //  permanent extra damage the target will take
	// var() int Shred;            //  permanent armor penetration value

	// Finetuned Damage
	// Momentum Damage
	// Critter
	// Armor Piercer
	// Weakness
	// Shredder

static function bool AddCHDamageModifier(X2WeaponUpgradeTemplate UpgradeTemplate, out int StatMod, name StatType)
{
	switch (StatType)
	{
		case 'Damage':
			StatMod = 1;
			break;
	}

	return true;
}
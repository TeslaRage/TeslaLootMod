class TLM_DataStructures extends Object;

struct TechData
{
	var name TemplateName;
};

struct LootBoxRarityData
{
	var name RarityName;
	var int Chance;
};

struct LootBoxData
{
	var name LootBoxName;
};

struct UpgradeDeckData
{
	var name UpgradeName;
	var array<name> AllowedWeaponCats;
	var array<name> DisallowedWeaponCats;
};

struct AmmoConversionData
{
	var name Ammo;	
	var string Image;
};

struct WeaponAdjustmentData
{
	var name AdjustmentName;
	var int Tier;
	var int Damage;
	var int Crit;
	var int Pierce;
	var int Shred;
};

struct AbilityUpgradeData
{
	var name UpgradeName;
	var name AbilityName;	
};

struct BaseItemData{
	var name TemplateName;
	var name ForcedRarity;
	var string Image;
	var StrategyRequirement Requirements;	
};

struct RarityDeckData
{
	var name UpgradeDeckName;
	var int Quantity;
	var int Chance;

	structdefaultproperties{
		Chance = 100;
	}
};
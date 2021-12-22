class TLM_DataStructures extends Object;

struct TechData
{
	var name TemplateName;
	var int SortingTier;
	var string Image;
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
	var name UpgradeName;
	var int ClipSizeBonus;
	var int Tier;
	var string Image;
};

struct RefinementUpgradeAbilityData
{
	var name AbilityName;	
	var int Damage;
	var int Crit;
	var int Pierce;
	var int Shred;
};

struct AbilityUpgradeData
{
	var name UpgradeName;
	var name AbilityName;
	var string strImage;
	var int ClipSizeBonus;
	var int Tier;
};

struct BaseItemData{
	var name TemplateName;
	var int Weight;
	var name ForcedRarity;
	var string Image;

	structdefaultproperties{
		Weight = 3;
	}
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

struct ItemCatData
{
	var name AllowedItemCat;

	structdefaultproperties{
		AllowedItemCat = "weapon";
	}
};
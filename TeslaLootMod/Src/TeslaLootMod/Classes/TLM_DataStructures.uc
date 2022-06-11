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
	var int Weight;							// Must be a number greater than 0. Default is 5.
	var bool bMustHaveAbility;				// Set to True if TLM needs to check that this upgrade must have an ability
	var array<name> AllowedWeaponCats;
	var array<name> DisallowedWeaponCats;

	structdefaultproperties{
		Weight = 5;
	}
};

struct AmmoConversionData
{
	var name Ammo;
	var name DLC;
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
	var float CritDamageMultiplier;
	var int MobilityDivisor;
	var int DamagePerMobilityDivisor;
};

struct AbilityUpgradeData
{
	var name UpgradeName;
	var name AbilityName;
	var string strImage;
	var int ClipSizeBonus;
	var int Tier;
	var array<name> MutuallyExclusiveUpgrades;
};

struct BaseItemData{
	var name TemplateName;
	var int Weight;							// Must be a number greater than 0. Default is 5.
	var name ForcedRarity;
	var string Image;

	structdefaultproperties{
		Weight = 5;
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

struct PatchItemData
{
	var name ItemTemplateName;
	var name Rarity;
	var bool ApplyNick;

	structdefaultproperties{
		ApplyNick = true;
	}
};

struct AbilityGivesGRangeData
{
	var name AbilityName;
	var int GrenadeRangeBonus;
};

struct AbilityGivesGRadiusData
{
	var name AbilityName;
	var float GrenadeRadiusBonus;
};

struct RuptureAbilitiesData
{
	var name AbilityName;
	var int RuptureValue;
	var int ApplyChance;
};

struct PatchWeaponUpgradesData
{
	var name UpgradeName;
	var array<name> MutuallyExclusiveUpgrades;
	var name AttachmentsDonorTemplate;
};

struct SprintReloadAbilitiesData
{
	var name AbilityName;
	var int Charges;
};

struct ReflexStockAbilitiesData
{
	var name AbilityName;
	var int AimBonusPerVisibleEnemy;
	var int MaxAimBonus;
};

struct FocusScopeAbilitiesData
{
	var name AbilityName;
	var int SingleOutAimBonus;
	var int SingleOutCritChanceBonus;
};

struct FrontLoadAbilitiesData
{
	var name AbilityName;
	var int FullAmmoDamageModifier;
	var int NotFullAmmoDamageModifier;
};

struct RepeaterAltAbilitiesData
{
	var name AbilityName;
	var int BonusDamageWhenEffected;
	var array<name> EffectsToApplyBonusDamage;
};

struct DecksForAutoIconsAndMEData
{
	var name UpgradeDeckTemplateName;
	var bool SetMutualExclusives;
};

struct ItemWeightData
{
	var int Index;
	var int Weight;
};
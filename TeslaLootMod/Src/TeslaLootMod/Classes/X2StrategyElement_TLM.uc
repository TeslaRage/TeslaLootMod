class X2StrategyElement_TLM extends X2StrategyElement config(TLM);

struct ForceLevelData
{
	var int MinFL;
	var int MaxFL;
    var name DataName;
};

var config array<name> arrRandomBaseWeapons;
var config array<ForceLevelData> arrWeaponTechForceLevel;
var config array<ForceLevelData> arrWeaponUpgradeForceLevel;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Techs;

    Techs.AddItem(CreateUnlockLockboxTemplate());

    return Techs;
}

static function X2DataTemplate CreateUnlockLockboxTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'UnlockLockbox');
	Template.PointsToComplete = 360;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Advent_Datapad";
	Template.bAutopsy = true;    
	Template.bCheckForceInstant = true;
    Template.bRepeatable = true;
	Template.SortingTier = 2;
    Template.ResearchCompletedFn = UnlockLockboxCompleted;

	Template.Requirements.RequiredItems.AddItem('LockBox');
	Template.Requirements.RequiredScienceScore = 10;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'LockboxKey';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'LockboxKey';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function UnlockLockboxCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{              
    local XComGameState_Item Weapon;   
    local XComGameState_HeadquartersXCom XComHQ;

    XComHQ = `XCOMHQ;	
    
    XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
    Weapon = GetBaseWeapon().CreateInstanceFromTemplate(NewGameState);

    if (Weapon == none)
    {
        `LOG("Failed to get base weapon");        
    }

    ApplyWeaponUpgrades(Weapon);
    Weapon.Nickname = "TLM Weapon :D";
    XComHQ.PutItemInInventory(NewGameState, Weapon);
}

static function X2WeaponTemplate GetBaseWeapon()
{
    local array<X2WeaponTemplate> PotentialWeapons; 
    local XComGameState_HeadquartersAlien AlienHQ;
    local X2ItemTemplateManager ItemTemplateMan;
    local ForceLevelData WeaponTechForceLevel;
    local X2WeaponTemplate WTemplate;
    local name RandomBaseWeapon;

    AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
    ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();  

    foreach default.arrWeaponTechForceLevel(WeaponTechForceLevel)
    {
        if (AlienHQ.ForceLevel < WeaponTechForceLevel.MinFL || AlienHQ.ForceLevel > WeaponTechForceLevel.MaxFL) continue;

        foreach default.arrRandomBaseWeapons(RandomBaseWeapon)
        {
            WTemplate = X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(RandomBaseWeapon));
            if (WTemplate == none) continue;
            if (WTemplate.WeaponTech != WeaponTechForceLevel.DataName) continue;
            PotentialWeapons.AddItem(WTemplate);
        }    
    }

    return PotentialWeapons[`SYNC_RAND_STATIC(PotentialWeapons.Length)];
}

static function ApplyWeaponUpgrades(out XComGameState_Item Weapon)
{
    local ForceLevelData WeaponUpgradeForceLevel;
    local XComGameState_HeadquartersAlien AlienHQ;
    local X2ItemTemplateManager ItemTemplateMan;
    local X2WeaponUpgradeTemplate WUTemplate;
    local array<X2WeaponUpgradeTemplate> PotentialWeaponUpgrades;

    AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
    ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();  

    foreach default.arrWeaponUpgradeForceLevel(WeaponUpgradeForceLevel)
    {
        if (AlienHQ.ForceLevel < WeaponUpgradeForceLevel.MinFL || AlienHQ.ForceLevel > WeaponUpgradeForceLevel.MaxFL) continue;

        WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(WeaponUpgradeForceLevel.DataName));
        if (WUTemplate == none) continue;

        PotentialWeaponUpgrades.AddItem(WUTemplate);
    }

    Weapon.ApplyWeaponUpgradeTemplate(PotentialWeaponUpgrades[`SYNC_RAND_STATIC(PotentialWeaponUpgrades.Length)]);
}
class X2StrategyElement_TLM extends X2StrategyElement config(TLM);

struct ForceLevelDeckData
{
	var int MinFL;
	var int MaxFL;
	var name Deck;
};

struct RarityData
{
	var name Rarity;
	var int Chance;
	var int NumOfBaseUpgrades;
	var int NumOfAmmoUpgrades;
	var string Color;
};

var config array<name> RandomBaseUpgrades;
var config array<name> RandomAmmoUpgrades;
var config array<RarityData> Rarity;
var config array<ForceLevelDeckData> BaseWeaponDecks;
var config array<BaseWeaponDeckData> DeckedBaseWeapons;

var localized array<String> RandomNickNames;
var localized string strRounds;

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
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Storage_Module";
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
	local XComGameState_ItemData Data;
	local RarityData SelectedRarity;
	local int Idx;
	local string NickAmmo;

	XComHQ = `XCOMHQ;	
	
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	Weapon = GetBaseWeapon().CreateInstanceFromTemplate(NewGameState);

	if (Weapon == none)
	{
		`LOG("Failed to get base weapon");		
	}

	ApplyWeaponUpgrades(Weapon, SelectedRarity, NickAmmo);
	GenerateNickName(Weapon, SelectedRarity, NickAmmo);
	
	XComHQ.PutItemInInventory(NewGameState, Weapon);

	Data = XComGameState_ItemData(NewGameState.CreateNewStateObject(class'XComGameState_ItemData'));
	Data.NumUpgradeSlots = 0;
	Weapon.AddComponentObject(Data);

	Idx = default.DeckedBaseWeapons.Find('BaseWeapon', Weapon.GetMyTemplate().DataName);
	`LOG("default.DeckedBaseWeapons[Idx].Image: " $default.DeckedBaseWeapons[Idx].Image);
	UIItemReceived(Weapon.GetMyTemplate(), Weapon.ObjectID, default.DeckedBaseWeapons[Idx].Image);
}

static function X2WeaponTemplate GetBaseWeapon()
{	
	local XComGameState_HeadquartersAlien AlienHQ;
	local X2ItemTemplateManager ItemTemplateMan;
	local X2WeaponTemplate WTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local X2CardManager CardMan;
	local ForceLevelDeckData BaseWeaponDeck;
	local BaseWeaponDeckData DeckedBaseWeapon;
	local name DeckToUse;
	local int Weight;
	local string strWeapon;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CardMan = class'X2CardManager'.static.GetCardManager();

	foreach default.BaseWeaponDecks(BaseWeaponDeck)
	{
		if (AlienHQ.ForceLevel < BaseWeaponDeck.MinFL || AlienHQ.ForceLevel > BaseWeaponDeck.MaxFL) continue;

		DeckToUse = BaseWeaponDeck.Deck;
	}

	foreach default.DeckedBaseWeapons(DeckedBaseWeapon)
	{
		if (DeckedBaseWeapon.Deck != DeckToUse) continue;

		WTemplate = X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(DeckedBaseWeapon.BaseWeapon));
		if (WTemplate == none) continue;

		Weight = 0.0;
		foreach XComHQ.Crew(UnitRef)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (Unit == none || !Unit.IsSoldier() || Unit.GetSoldierRank() == 0) continue;
			
			if (Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(WTemplate)) Weight++;
		}

		if (Weight == 0) Weight = 1;		
		CardMan.AddCardToDeck(DeckToUse, string(WTemplate.DataName), float(Weight));
	}

	CardMan.SelectNextCardFromDeck(DeckToUse, strWeapon);

	return X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(name(strWeapon)));
}

static function ApplyWeaponUpgrades(out XComGameState_Item Weapon, out RarityData SelectedRarity, out string NickAmmo)
{
	local X2ItemTemplateManager ItemTemplateMan;
	local X2WeaponUpgradeTemplate WUTemplate;
	local RarityData RarityStruct, ItemRarity;	
	local int Applied, Safety, Random, CurrentTotal;

	Random = `SYNC_RAND_STATIC(100);
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();  

	default.Rarity.Sort(SortByChanceDesc);   
	
	foreach default.Rarity(RarityStruct)
	{		
		CurrentTotal += RarityStruct.Chance;
		if (Random < CurrentTotal) 
        {
            ItemRarity = RarityStruct;
            break;
        }
	}

	// Just in case total chance is not 100
	if (CurrentTotal < 100)
	{
		ItemRarity = default.Rarity[0];
	}

	SelectedRarity = ItemRarity;

	Applied = 0;
	Safety = 0;
	while (Applied < ItemRarity.NumOfBaseUpgrades && Safety <= ItemRarity.NumOfBaseUpgrades + 10)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(default.RandomBaseUpgrades[`SYNC_RAND_STATIC(default.RandomBaseUpgrades.Length)]));
		if (WUTemplate == none) continue;

		// Using GetMyWeaponUpgradeCount() to get next "empty" slot
		if (WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount()))
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			Applied++;
		}
		
		Safety++;		
	}

	Applied = 0;
	Safety = 0;
	while (Applied < ItemRarity.NumOfAmmoUpgrades && Safety <= ItemRarity.NumOfAmmoUpgrades + 10)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(default.RandomAmmoUpgrades[`SYNC_RAND_STATIC(default.RandomAmmoUpgrades.Length)]));
		if (WUTemplate == none) continue;

		// Using GetMyWeaponUpgradeCount() to get next "empty" slot
		if (WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount()))
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			Applied++;
			NickAmmo = WUTemplate.GetItemFriendlyName();
			NickAmmo -= default.strRounds;
		}
		
		Safety++;		
	}
}

static function GenerateNickName(out XComGameState_Item Weapon, RarityData SelectedRarity, string NickAmmo)
{
	Weapon.Nickname = "<font color='" $SelectedRarity.Color $"'>" $NickAmmo $default.RandomNickNames[`SYNC_RAND_STATIC(default.RandomNickNames.Length)] $"</font>";
}

function int SortByChanceDesc(RarityData RarityA, RarityData RarityB)
{
	local int ChanceA, ChanceB;

	ChanceA = RarityA.Chance;
	ChanceB = RarityB.Chance;

	if (ChanceA < ChanceB)
	{
		return -1;
	}
	else if (ChanceA > ChanceB)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

static function UIItemReceived(X2ItemTemplate ItemTemplate, int ItemObjectID, string ImageUponResearchCompletion)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_TLMItemRewarded', None, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', ItemTemplate.DataName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'ItemObjectID', ItemObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'ImageUponResearchCompletion', ImageUponResearchCompletion);
	QueueDynamicPopup(PropertySet);
}

static function BuildUIAlert(
	out DynamicPropertySet PropertySet, 
	Name AlertName, 
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction, 
	Name EventToTrigger, 
	string SoundToPlay,
	bool bImmediateDisplay = true)
{
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_TLM', AlertName, CallbackFunction, bImmediateDisplay, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', EventToTrigger);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', SoundToPlay);
}

static function QueueDynamicPopup(const out DynamicPropertySet PopupInfo, optional XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bLocalNewGameState;

	if( PopupInfo.bDisplayImmediate )
	{
		`PRESBASE.DisplayDynamicPopupImmediate(PopupInfo);
		return;
	}

	if( NewGameState == None )
	{
		bLocalNewGameState = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Queued UI Alert" @ PopupInfo.PrimaryRoutingKey @ PopupInfo.SecondaryRoutingKey);
	}
	else
	{
		bLocalNewGameState = false;
	}

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.QueuedDynamicPopups.AddItem(PopupInfo);

	if( bLocalNewGameState )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	if( PopupInfo.bDisplayImmediate )
	{
		`PRESBASE.DisplayQueuedDynamicPopups();
	}
}
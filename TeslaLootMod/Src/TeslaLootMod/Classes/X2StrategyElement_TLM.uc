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
	var bool LegendaryUpgrade;
	var string Color;
};

var config int NumOfTimesToForceInstant;
var config int ChanceForAdjustmentUpgrade;
var config array<LegendaryUpgradeData> RandomLegendaryUpgrades;
var config array<name> RandomAdjustmentUpgrades;
var config array<name> RandomBaseUpgrades;
var config array<name> RandomAmmoUpgrades;
var config array<name> RandomBaseMeleeUpgrades;
var config array<RarityData> Rarity;
var config array<ForceLevelDeckData> BaseWeaponDecks;
var config array<BaseWeaponDeckData> DeckedBaseWeapons;

var localized array<String> RandomNickNames;
var localized string strRounds;
var localized string strPlus;

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
	Template.SortingTier = 2;
	Template.ResearchCompletedFn = UnlockLockboxCompleted;

	Template.Requirements.RequiredItems.AddItem('LockBox');
	Template.Requirements.RequiredEngineeringScore = 10;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;

	Template.bRepeatable = true;
	Template.bProvingGround = true;

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
	local string NickAmmo, NickAdjustment;

	XComHQ = `XCOMHQ;	
	
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	Weapon = GetBaseWeapon().CreateInstanceFromTemplate(NewGameState);

	if (Weapon == none)
	{
		`LOG("Failed to get base weapon");		
	}

	ApplyWeaponUpgrades(Weapon, SelectedRarity, NickAmmo, NickAdjustment);
	GenerateNickName(Weapon, SelectedRarity, NickAmmo, NickAdjustment);

	Data = XComGameState_ItemData(NewGameState.CreateNewStateObject(class'XComGameState_ItemData'));
	Data.NumUpgradeSlots = 0;
	Weapon.AddComponentObject(Data);	
	
	XComHQ.PutItemInInventory(NewGameState, Weapon);
	`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', Weapon, Weapon, NewGameState);

	TechState.ItemRewards.Length = 0; 						// Reset the item rewards array in case the tech is repeatable
	TechState.ItemRewards.AddItem(Weapon.GetMyTemplate());  // Needed for UI Alert display info
	TechState.bSeenResearchCompleteScreen = false; 			// Reset the research report for techs that are repeatable

	if (!TechState.IsInstant() && TechState.TimesResearched >= default.NumOfTimesToForceInstant)
	{
		TechState.bForceInstant = true; 
	}

	UIItemReceived(NewGameState, Weapon);
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
	local int Weight, Idx;
	local string strWeapon, CardLabel;
	local array<string> CardLabels;

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

	CardMan.GetAllCardsInDeck(DeckToUse, CardLabels);

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

		if (CardLabels.Find(string(WTemplate.DataName)) == INDEX_NONE)
		{
			CardMan.AddCardToDeck(DeckToUse, string(WTemplate.DataName), float(Weight));
		}
	}

	CardLabels.Length = 0;
	CardMan.GetAllCardsInDeck(DeckToUse, CardLabels);
	
	foreach CardLabels(CardLabel)
	{
		Idx = default.DeckedBaseWeapons.Find('BaseWeapon', name(CardLabel));
		if (Idx != INDEX_NONE)
		{
			if (default.DeckedBaseWeapons[Idx].Deck != DeckToUse)
				CardMan.RemoveCardFromDeck(DeckToUse, CardLabel);
		}
		else
		{
			CardMan.RemoveCardFromDeck(DeckToUse, CardLabel);
		}
	}

	CardMan.SelectNextCardFromDeck(DeckToUse, strWeapon);
	CardMan.MarkCardUsed(DeckToUse, strWeapon);

	return X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(name(strWeapon)));
}

static function ApplyWeaponUpgrades(out XComGameState_Item Weapon, out RarityData SelectedRarity, out string NickAmmo, out string NickAdjustment)
{
	local X2ItemTemplateManager ItemTemplateMan;
	local X2WeaponUpgradeTemplate WUTemplate;	
	local RarityData RarityStruct, ItemRarity;
	local LegendaryUpgradeData LegendaryUpgrade;
	local array<name> FilteredUpgrades;
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

	if (SelectedRarity.LegendaryUpgrade)
	{		
		foreach default.RandomLegendaryUpgrades(LegendaryUpgrade)
		{
			if (LegendaryUpgrade.AllowedWeaponCats.Find(X2WeaponTemplate(Weapon.GetMyTemplate()).WeaponCat) != INDEX_NONE)
			{
				FilteredUpgrades.AddItem(LegendaryUpgrade.UpgradeName);
			}
		}		
		
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(FilteredUpgrades[`SYNC_RAND_STATIC(FilteredUpgrades.Length)]));

		if (WUTemplate != none)
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
		}
	}

	if (`SYNC_RAND_STATIC(100) < default.ChanceForAdjustmentUpgrade)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(default.RandomAdjustmentUpgrades[`SYNC_RAND_STATIC(default.RandomAdjustmentUpgrades.Length)]));

		if (WUTemplate != none)
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			NickAdjustment = default.strPlus;
		}
	}

	Applied = 0;
	Safety = 0;
	while (Applied < SelectedRarity.NumOfBaseUpgrades && Safety <= SelectedRarity.NumOfBaseUpgrades + 100)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(default.RandomBaseUpgrades[`SYNC_RAND_STATIC(default.RandomBaseUpgrades.Length)]));
		if (WUTemplate == none) continue;

		// Using GetMyWeaponUpgradeCount() to get next "empty" slot
		if (WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount())
			&& Weapon.CanWeaponApplyUpgrade(WUTemplate))
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			Applied++;
		}
		
		Safety++;		
	}

	Applied = 0;
	Safety = 0;
	while (Applied < SelectedRarity.NumOfAmmoUpgrades && Safety <= SelectedRarity.NumOfAmmoUpgrades + 100)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(default.RandomAmmoUpgrades[`SYNC_RAND_STATIC(default.RandomAmmoUpgrades.Length)]));
		if (WUTemplate == none) continue;

		// Using GetMyWeaponUpgradeCount() to get next "empty" slot
		if (WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount())
			&& Weapon.CanWeaponApplyUpgrade(WUTemplate))
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			Applied++;
			NickAmmo = WUTemplate.GetItemFriendlyName();
			NickAmmo -= default.strRounds;
		}
		
		Safety++;		
	}

	Applied = 0;
	Safety = 0;
	while (Applied < SelectedRarity.NumOfBaseUpgrades && Safety <= SelectedRarity.NumOfBaseUpgrades + 100)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(default.RandomBaseMeleeUpgrades[`SYNC_RAND_STATIC(default.RandomBaseMeleeUpgrades.Length)]));
		if (WUTemplate == none) continue;

		// Using GetMyWeaponUpgradeCount() to get next "empty" slot
		if (WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount())
			&& Weapon.CanWeaponApplyUpgrade(WUTemplate))
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			Applied++;
		}
		
		Safety++;		
	}	
}

static function GenerateNickName(out XComGameState_Item Weapon, RarityData SelectedRarity, string NickAmmo, string NickAdjustment)
{
	Weapon.Nickname = "<font color='" $SelectedRarity.Color $"'>" $NickAmmo $default.RandomNickNames[`SYNC_RAND_STATIC(default.RandomNickNames.Length)] $NickAdjustment $"</font>";
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

static function UIItemReceived(XComGameState NewGameState, XComGameState_Item Item)
{
	local DynamicPropertySet PropertySet;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local string WeaponInfo;
	local int Idx;

	Idx = default.DeckedBaseWeapons.Find('BaseWeapon', Item.GetMyTemplate().DataName);
	WUTemplates = Item.GetMyWeaponUpgradeTemplates();

	WeaponInfo = Item.Nickname $"\n";
	foreach WUTemplates(WUTemplate)
	{
		WeaponInfo $= WUTemplate.GetItemFriendlyName() $"\n";
		WeaponInfo $= WUTemplate.GetItemBriefSummary() $"\n";
	}

	BuildUIAlert(PropertySet, 'eAlert_TLMItemRewarded', None, '', "Geoscape_ItemComplete");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', Item.GetMyTemplate().DataName);	
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'ImageUponResearchCompletion', default.DeckedBaseWeapons[Idx].Image);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'WeaponInfo', WeaponInfo);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'Nickname', Item.Nickname);
	QueueDynamicPopup(PropertySet, NewGameState);
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
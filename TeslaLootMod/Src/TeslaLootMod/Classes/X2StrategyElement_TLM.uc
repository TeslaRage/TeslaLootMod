class X2StrategyElement_TLM extends X2StrategyElement config(TLM);

struct DeckData
{
	var int Tier;
	var name Deck;
	var name UnlockTech;
};

struct RarityData
{
	var name RarityName;
	var int Chance;
	var int NumOfBaseUpgrades;
	var bool AllowAmmoUpgrade;
	var bool LegendaryUpgrade;
	var string Color;
};

var config array<name> RequiredTechsForLockbox;
var config int NumOfTimesToForceInstant;
var config int ChanceForAdjustmentUpgrade;
var config array<UpgradePoolData> RandomLegendaryUpgrades;
var config array<UpgradePoolData> RandomAdjustmentUpgrades;
var config array<UpgradePoolData> RandomBaseUpgrades;
var config array<UpgradePoolData> RandomAmmoUpgrades;
var config array<RarityData> Rarity;
var config array<DeckData> BaseWeaponDecks;
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
	Template.Requirements.RequiredTechs = default.RequiredTechsForLockbox;
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
	local X2ItemTemplateManager ItemTemplateMan;
	local X2WeaponTemplate WTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local X2CardManager CardMan;
	local DeckData BaseWeaponDeck;
	local BaseWeaponDeckData DeckedBaseWeapon;
	local name DeckToUse;
	local int Weight, Idx;
	local string strWeapon, CardLabel;
	local array<string> CardLabels;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;	
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CardMan = class'X2CardManager'.static.GetCardManager();

	default.BaseWeaponDecks.Sort(SortByTierDesc);

	foreach default.BaseWeaponDecks(BaseWeaponDeck)
	{		
		if (!XComHQ.IsTechResearched(BaseWeaponDeck.UnlockTech)) continue;

		DeckToUse = BaseWeaponDeck.Deck;
		break;
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
	local array<X2WeaponUpgradeTemplate> WUTemplates, BaseWUTemplates;
	local RarityData RarityStruct, ItemRarity;
	local int RarityRoll, CurrentTotal, Idx, NumOfMissingUpgrades;
	local bool bLegendaryUpgradeApplied, bAmmoUpgradeApplied; 

	RarityRoll = `SYNC_RAND_STATIC(100);
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();  

	default.Rarity.Sort(SortByChanceDesc);   
	
	foreach default.Rarity(RarityStruct)
	{		
		CurrentTotal += RarityStruct.Chance;
		if (RarityRoll < CurrentTotal) 
        {
            ItemRarity = RarityStruct;
            break;
        }
	}

	// Just in case total chance is not 100
	if (CurrentTotal < 100 && ItemRarity.RarityName == '')
	{
		ItemRarity = default.Rarity[0];
	}
	
	CheckForForcedRarity(ItemRarity, Weapon);
	SelectedRarity = ItemRarity;

	// If we rolled Legendary, then grab the Legendary Upgrade
	if (SelectedRarity.LegendaryUpgrade)
	{
		WUTemplates = BuildUpgradePool(Weapon, ItemTemplateMan, default.RandomLegendaryUpgrades);
		WUTemplate = WUTemplates[`SYNC_RAND_STATIC(WUTemplates.Length)];		
		if (WUTemplate != none)
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			bLegendaryUpgradeApplied = true;
		}			
	}	

	// Roll for Refinement Upgrade
	if (`SYNC_RAND_STATIC(100) < default.ChanceForAdjustmentUpgrade)
	{
		WUTemplates = BuildUpgradePool(Weapon, ItemTemplateMan, default.RandomAdjustmentUpgrades);
		WUTemplate = WUTemplates[`SYNC_RAND_STATIC(WUTemplates.Length)];
		if (WUTemplate != none)
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
		NickAdjustment = default.strPlus;
	}

	// Roll for base upgrades
	WUTemplates = BuildUpgradePool(Weapon, ItemTemplateMan, default.RandomBaseUpgrades);	
	ApplyBaseUpgrade(WUTemplates, Weapon, SelectedRarity.NumOfBaseUpgrades);
	
	// Save the base upgrade pool for later
	BaseWUTemplates = WUTemplates;

	// Roll for ammo upgrade
	if (SelectedRarity.AllowAmmoUpgrade)
	{
		WUTemplates = BuildUpgradePool(Weapon, ItemTemplateMan, default.RandomAmmoUpgrades);
		if (WUTemplates.Length > 0)
		{
			Idx = `SYNC_RAND_STATIC(WUTemplates.Length);
			WUTemplate = WUTemplates[Idx];

			if (WUTemplate != none
				&& WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount())
				&& Weapon.CanWeaponApplyUpgrade(WUTemplate))
			{
				Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
				NickAmmo = WUTemplate.GetItemFriendlyNamePlural(); // Cheating - the usual GetItemFriendlyName() has been colored
				NickAmmo -= default.strRounds;
				bAmmoUpgradeApplied = true;
			}
		}
	}

	// Final checks: based on rarity has this item gotten all the upgrades it deserves	
	NumOfMissingUpgrades += (SelectedRarity.AllowAmmoUpgrade && !bAmmoUpgradeApplied) ? 1 : 0;
	NumOfMissingUpgrades += (SelectedRarity.LegendaryUpgrade && !bLegendaryUpgradeApplied) ? 1 : 0;

	// If non-satisfactory, we patch up by giving more base upgrades (if we have not run out of any yet)
	if (NumOfMissingUpgrades > 0)
	{
		ApplyBaseUpgrade(BaseWUTemplates, Weapon, NumOfMissingUpgrades);
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

function int SortByTierDesc(DeckData DeckA, DeckData DeckB)
{
	local int TierA, TierB;

	TierA = DeckA.Tier;
	TierB = DeckB.Tier;

	if (TierA < TierB)
	{
		return -1;
	}
	else if (TierA > TierB)
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

static function array<X2WeaponUpgradeTemplate> BuildUpgradePool(XComGameState_Item Weapon, X2ItemTemplateManager ItemTemplateMan, array<UpgradePoolData> ConfiguredPool)
{
	local X2WeaponUpgradeTemplate WUTemplate;
	local UpgradePoolData PoolData;
	local array<X2WeaponUpgradeTemplate> WUTemplates;	

	foreach ConfiguredPool(PoolData)
	{
		WUTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(PoolData.UpgradeName));

		// Maybe because required mod like melee upgrades is not installed
		if (WUTemplate == none) continue;

		// Go through the basic validation first
		if (!WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount())
			&& !Weapon.CanWeaponApplyUpgrade(WUTemplate))
			continue;

		// If configured as allowed, then we include into pool
		if (PoolData.AllowedWeaponCats.Find(X2WeaponTemplate(Weapon.GetMyTemplate()).WeaponCat) != INDEX_NONE)
		{
			WUTemplates.AddItem(WUTemplate);
			continue;
		}
		else if (PoolData.AllowedWeaponCats.Length > 0)		
			continue;

		// If configured as disallowed, then we don't include into pool
		if (PoolData.DisallowedWeaponCats.Find(X2WeaponTemplate(Weapon.GetMyTemplate()).WeaponCat) != INDEX_NONE)
			continue;

		// Does this upgrade have valid abilities?
		if (HasInvalidAbilities(WUTemplate))
			continue;

		// If we reach here, it means the upgrade is meant for all weapon categories
		WUTemplates.AddItem(WUTemplate);
	}

	return WUTemplates;
}

// Not used - but sad to delete so leave it here just in case it can be useful later
// Background: This was initially made to prevent weapons with small clipsize like Hunter Rifles
// 				from getting Rapid Fire/Hail of Bullets as those abilities need clip > 2.
// 				Decided to give bonus clip size to those Legendary Upgrades instead.
static function bool CanWeaponAffordAmmo(X2WeaponUpgradeTemplate WUTemplate, XComGameState_Item Weapon)
{
	local X2AbilityTemplateManager AbilityMan;	
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityCost Cost;
	local X2AbilityCost_Ammo AmmoCost;
	local name AbilityName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();	

	foreach WUTemplate.BonusAbilities(AbilityName)
	{
		AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);		

		foreach AbilityTemplate.AbilityCosts(Cost)
		{
			AmmoCost = X2AbilityCost_Ammo(Cost);
			if (AmmoCost == none) continue;

			if (AmmoCost.iAmmo > Weapon.GetClipSize())
			{
				return false;
			}
		}
	}

	return true;
}

static function ApplyBaseUpgrade(out array<X2WeaponUpgradeTemplate> WUTemplates, out XComGameState_Item Weapon, int NumOfBaseUpgradesToApply)
{
	local X2WeaponUpgradeTemplate WUTemplate;
	local int Applied, Idx;
	
	while (Applied < NumOfBaseUpgradesToApply && WUTemplates.Length > 0)
	{
		Idx = `SYNC_RAND_STATIC(WUTemplates.Length);
		WUTemplate = WUTemplates[Idx];

		if (WUTemplate != none 
			&& WUTemplate.CanApplyUpgradeToWeapon(Weapon, Weapon.GetMyWeaponUpgradeCount())
			&& Weapon.CanWeaponApplyUpgrade(WUTemplate))
		{
			Weapon.ApplyWeaponUpgradeTemplate(WUTemplate);
			WUTemplates.Remove(Idx, 1);
			Applied++;
		}
		else
		{
			WUTemplates.Remove(Idx, 1);
		}
	}
}

static function bool HasInvalidAbilities(X2WeaponUpgradeTemplate WUTemplate)
{
	local X2AbilityTemplateManager AbilityMan;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach WUTemplate.BonusAbilities(AbilityName)
	{
		AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate == none) return true;
	}

	return false;
}

static function CheckForForcedRarity(out RarityData SelectedRarity, XComGameState_Item Weapon)
{
	local int Idx, Idx2;

	Idx = default.DeckedBaseWeapons.Find('BaseWeapon', Weapon.GetMyTemplateName());

	if (Idx != INDEX_NONE && default.DeckedBaseWeapons[Idx].ForcedRarity != '')
	{
		Idx2 = default.Rarity.Find('RarityName', default.DeckedBaseWeapons[Idx].ForcedRarity);

		if (Idx2 != INDEX_NONE)
		{
			SelectedRarity = default.Rarity[Idx2];
		}
	}	
}
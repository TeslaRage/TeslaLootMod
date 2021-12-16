class X2DownloadableContentInfo_TeslaLootMod extends X2DownloadableContentInfo;

var config (TLM) array<LootTable> LootEntry;
var config (TLM) string strTier0Color;
var config (TLM) string strTier1Color;
var config (TLM) string strTier2Color;
var config (TLM) string strTier3Color;

var localized array<String> RandomWeaponNickNames;
var localized array<String> RandomArmorNickNames;
var localized string strHasAmmoAlreadyEquipped;
var localized string strWeaponHasAmmoUpgrade;
var localized string strRounds;
var localized string strPlus;

// =============
// DLC HOOKS
// =============
static event OnPostTemplatesCreated()
{
	AddLootTables();
	UpdateWeaponUpgrade();
	SetDelegatesToUpgradeDecks();
}

static event OnLoadedSavedGameToStrategy()
{
	CreateTechsMidCampaign();
}

static event OnLoadedSavedGameToTactical()
{
	CreateTechsMidCampaign();
}

static function bool CanAddItemToInventory_CH_Improved(
	out int bCanAddItem,						// out value for XComGameState_Unit
	const EInventorySlot Slot,					// Inventory Slot you're trying to equip the Item into
	const X2ItemTemplate ItemTemplate,			// Item Template of the Item you're trying to equip
	int Quantity, 
	XComGameState_Unit UnitState,				// Unit State of the Unit you're trying to equip the Item on
	optional XComGameState CheckGameState, 
	optional out string DisabledReason,			// out value for the UIArmory_Loadout
	optional XComGameState_Item ItemState)		// Item State of the Item we're trying to equip
{	
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;	
	local X2AmmoTemplate AmmoTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local array<XComGameState_Item> InventoryItems;
	local XComGameState_Item InventoryItem;
	local bool bFailedAmmoEquip, bFailedWeaponEquip;
	local bool OverrideNormalBehavior;
	local bool DoNotOverrideNormalBehavior;
	local X2UpgradeDeckTemplateManager UDMan;
	local X2UpgradeDeckTemplate UDTemplate;

	// Prepare return values to make it easier for us to read the code.
	OverrideNormalBehavior = CheckGameState != none;
	DoNotOverrideNormalBehavior = CheckGameState == none;
	
	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	UDTemplate = UDMan.GetUpgradeDeckTemplate('AmmoDeck');

	// 1st scenario: Prevent weapon from being equipped if it has ammo upgrade and unit has ammo already equipped
	// Interested when weapon is attempted to be equipped
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);

	if (WeaponTemplate != none)
	{
		// Get its upgrade templates
		WUTemplates = ItemState.GetMyWeaponUpgradeTemplates();

		foreach WUTemplates(WUTemplate)
		{
			// Check if this upgrade is an ammo upgrade and unit has Ammo in inventory			
			if (UDTemplate.Upgrades.Find('UpgradeName', WUTemplate.DataName) != INDEX_NONE)
			{
				if (UnitState.HasItemOfTemplateClass(class'X2AmmoTemplate'))
				{
					bFailedWeaponEquip = true;
					break;
				}
			}
		}
	}

	// 2nd scenario: Prevent ammo utility item from being equipped if unit already has weapon with ammo upgrade
	// Interested if ammo is being equipped
	AmmoTemplate = X2AmmoTemplate(ItemTemplate);

	if (AmmoTemplate != none)
	{
		// Get all items in unit inventory
		InventoryItems = UnitState.GetAllInventoryItems();

		foreach InventoryItems(InventoryItem)
		{
			// Just grab the upgrades
			WUTemplates = InventoryItem.GetMyWeaponUpgradeTemplates();

			foreach WUTemplates(WUTemplate)
			{
				// If the upgrade is ammo upgrade
				if (UDTemplate.Upgrades.Find('UpgradeName', WUTemplate.DataName) != INDEX_NONE)
				{
					bFailedAmmoEquip = true;
					break;
				}
			}
			if (bFailedAmmoEquip) break;
		}
	}

	if (!bFailedWeaponEquip && !bFailedAmmoEquip) return DoNotOverrideNormalBehavior;	
	
	// Build string message
	if (bFailedWeaponEquip)
	{
		DisabledReason = default.strHasAmmoAlreadyEquipped;
	}
	else if (bFailedAmmoEquip)
	{
		DisabledReason = default.strWeaponHasAmmoUpgrade;
	}

	// Override to disallow the item from being equipped
	bCanAddItem = 0;

	// Return the override value. This will force the game to actually use our out values we have just set.
	return OverrideNormalBehavior;
}

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_TLM')
	{
		CallUIAlert_TLM(PropertySet);
		return true;
	}

	return false;
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;
	local int i;

	Type = name(InString);

	switch(Type)
	{
	case 'RapidFireCharges':
		OutString = string(class'X2Ability_TLM'.default.RapidFireCharges);
		return true;
	case 'RapidFireAimPenalty':
		OutString = string(class'X2Ability_TLM'.default.RapidFireAimPenalty * -1);
		return true;
	case 'RapidFireCooldown':
		OutString = string(class'X2Ability_TLM'.default.RapidFireCooldown);
		return true;
	case 'HailOfBulletsCharges':
		OutString = string(class'X2Ability_TLM'.default.HailOfBulletsCharges);
		return true;
	case 'HailOfBulletsCooldown':
		OutString = string(class'X2Ability_TLM'.default.HailOfBulletsCooldown);
		return true;
	case 'KillZoneCharges':
		OutString = string(class'X2Ability_TLM'.default.KillZoneCharges);
		return true;
	case 'KillZoneCooldown':
		OutString = string(class'X2Ability_TLM'.default.KillZoneCooldown);
		return true;
	case 'FaceoffCharges':
		OutString = string(class'X2Ability_TLM'.default.FaceoffCharges);
		return true;
	case 'FaceoffCooldown':
		OutString = string(class'X2Ability_TLM'.default.FaceoffCooldown);
		return true;
	case 'BonusDamageAdventSoldier':
		OutString = string(class'X2Ability_TLM'.default.BonusDamageAdventSoldier);
		return true;
	case 'RapidFireClipSizeBonus':		
		i = class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades.Find('UpgradeName', 'TLMUpgrade_RapidFire');
		if (i != INDEX_NONE)
		{
			OutString = string(class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades[i].ClipSizeBonus);
			return true;
		}
		break;
	case 'HailofBulletsClipSizeBonus':
		i = class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades.Find('UpgradeName', 'TLMUpgrade_HailOfBullets');
		if (i != INDEX_NONE)
		{
			OutString = string(class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades[i].ClipSizeBonus);
			return true;
		}
		break;
	case 'KillZoneClipSizeBonus':
		i = class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades.Find('UpgradeName', 'TLMUpgrade_KillZone');
		if (i != INDEX_NONE)
		{
			OutString = string(class'X2Item_TLMUpgrades'.default.AbilityWeaponUpgrades[i].ClipSizeBonus);
			return true;
		}
		break;
	case 'BonusDamageAlien':
		OutString = string(class'X2Ability_TLM'.default.BonusDamageAlien);
		return true;
	}
	return false;
}

// =============
// HELPERS
// =============
static function CallUIAlert_TLM(const out DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_TLM Alert;

	Pres = `HQPRES;

	Alert = Pres.Spawn(class'UIAlert_TLM', Pres);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	Pres.ScreenStack.Push(Alert);
}

static function AddLootTables()
{
	local X2LootTableManager	LootManager;
	local LootTable				LootBag;
	local LootTableEntry		Entry;
	
	LootManager = X2LootTableManager(class'Engine'.static.FindClassDefaultObject("X2LootTableManager"));

	foreach default.LootEntry(LootBag)
	{
		if ( LootManager.default.LootTables.Find('TableName', LootBag.TableName) != INDEX_NONE )
		{
			foreach LootBag.Loots(Entry)
			{
				class'X2LootTableManager'.static.AddEntryStatic(LootBag.TableName, Entry, false);
			}
		}	
	}
}

static function CreateTechsMidCampaign()
{
	local X2StrategyElementTemplateManager StratMan;
	local XComGameState_Tech Tech;
	local X2TechTemplate TechTemplate;
	local XComGameState NewGameState;
	local TechData UnlockLootBoxTech;	
	local array<name> TechsToCreate;
	local name TechName;	

	foreach class'X2StrategyElement_TLM'.default.UnlockLootBoxTechs(UnlockLootBoxTech)
	{
		TechsToCreate.AddItem(UnlockLootBoxTech.TemplateName);
	}
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', Tech)
	{		
		TechsToCreate.RemoveItem(Tech.GetMyTemplateName());
	}

	if (TechsToCreate.Length > 0)
	{
		StratMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Create tech mid campaign");

		foreach TechsToCreate(TechName)
		{
			TechTemplate = X2TechTemplate(StratMan.FindStrategyElementTemplate(TechName));
			Tech = XComGameState_Tech(NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate));
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}
}

static function UpdateWeaponUpgrade()
{	
	local X2AbilityTemplateManager AbilityMan;
	local X2UpgradeDeckTemplateManager UDMan;	
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2UpgradeDeckTemplate UDTemplate;
	local X2Effect Effect;
	local X2Effect_TLMEffects TLMEffect;	
	local string strColor;
	local name AbilityName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();	
	
	UDTemplate = UDMan.GetUpgradeDeckTemplate('RefnDeck');
	WUTemplates = UDTemplate.GetUpgradeTemplates();

	// Localization update for refinement upgrades
	foreach WUTemplates(WUTemplate)
	{
		foreach WUTemplate.BonusAbilities(AbilityName)
		{
			AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);
			if (AbilityTemplate == none) continue;

			foreach AbilityTemplate.AbilityTargetEffects(Effect)
			{
				TLMEffect = X2Effect_TLMEffects(Effect);
				if (TLMEffect == none) continue;

				WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMDAMAGE", TLMEffect.FlatBonusDamage < 0 ? TLMEffect.FlatBonusDamage * -1 : TLMEffect.FlatBonusDamage);
				WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMCRITDAMAGE", TLMEffect.CritDamage < 0 ? TLMEffect.CritDamage * -1 : TLMEffect.CritDamage);
				WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMPIERCE", TLMEffect.Pierce < 0 ? TLMEffect.Pierce * -1 : TLMEffect.Pierce);
				WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMSHRED", TLMEffect.Shred < 0 ? TLMEffect.Shred * -1 : TLMEffect.Shred);
			}
		}
	}	

	// Template coloring contest
	WUTemplates = UDMan.GetAllUpgradeTemplates();		
	
	foreach WUTemplates(WUTemplate)
	{		
		switch (WUTemplate.Tier)
		{
			case 0:
				strColor = default.strTier0Color;
				break;
			case 1:
				strColor = default.strTier1Color;
				break;
			case 2:
				strColor = default.strTier2Color;
				break;
			case 3:
				strColor = default.strTier3Color;
				break;
		}

		if (strColor != "")
			WUTemplate.FriendlyName = "<font color='" $strColor $"'>" $WUTemplate.FriendlyName $"</font>";
	}

	// Setting up of upgrade icons and mutual exclusives
	SetUpUpgradeIconsAndME('LegoDeck');
	SetUpUpgradeIconsAndME('RefnDeck');
	SetUpUpgradeIconsAndME('AmmoDeck');
}

static function SetUpUpgradeIconsAndME(name UpgradeDeckTemplateName)
{
	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2UpgradeDeckTemplateManager UDMan;
	local X2AbilityTemplateManager ABilityMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local array<name> ItemTemplateNames, WUTemplateNames;	
	local name AbilityName, ItemTemplateName;
	local string IconString;

	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	ItemTemplateNames = BWMan.GetAllItemTemplateNames();

	UDTemplate = UDMan.GetUpgradeDeckTemplate(UpgradeDeckTemplateName);
	if (UDTemplate != none)
	{
		WUTemplates = UDTemplate.GetUpgradeTemplates();
		WUTemplateNames = UDTemplate.GetUpgradeTemplateNames();

		foreach WUTemplates(WUTemplate)
		{
			// Get an ability from the weapon upgrade
			foreach WUTemplate.BonusAbilities(AbilityName)
			{
				AbilityTemplate = AbilityMan.FindAbilityTemplate(AbilityName);
				break;
			}
			
			// If we managed to get an ability, use the ability's icon
			if (AbilityTemplate != none)
			{
				IconString = AbilityTemplate.IconImage;
			}

			// If there is no icon due to no ability or ability has no icon, we give default icon
			if (IconString == "")
			{
				IconString = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip";
			}

			// Sets up the attachment icon and items that its applicable to
			foreach ItemTemplateNames(ItemTemplateName)
			{
				WUTemplate.AddUpgradeAttachment('', '', "", "", ItemTemplateName, , "", WUTemplate.strImage, IconString);
			}
			
			// Sets up the mutual exclusive
			WUTemplate.MutuallyExclusiveUpgrades = WUTemplateNames;			
		}
	}
}

static function AppendArrays(out array<name> ArrayA, array<name> ArrayB)
{
	local name ArrayContent;

	foreach ArrayB(ArrayContent)
	{
		ArrayA.AddItem(ArrayContent);
	}
}

static function SetDelegatesToUpgradeDecks()
{
	local X2UpgradeDeckTemplateManager UDMan;
	local X2UpgradeDeckTemplate UDTemplate;

	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	UDTemplate = UDMan.GetUpgradeDeckTemplate('AmmoDeck');

	if (UDTemplate != none)
	{
		UDTemplate.ModifyNickNameFn = ModifyAmmoNick;
	}

	UDTemplate = UDMan.GetUpgradeDeckTemplate('RefnDeck');

	if (UDTemplate != none)
	{
		UDTemplate.ModifyNickNameFn = ModifyRefnNick;
	}
}

static function XComGameState_Item GenerateTLMItem(XComGameState NewGameState, XComGameState_Tech Tech, out X2BaseWeaponDeckTemplate BWTemplate)
{
	local X2ItemTemplateManager ItemMan;
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_ItemData Data;
	local X2RarityTemplate RarityTemplate;
	
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	
	RarityTemplate = X2ItemTemplate_LootBox(ItemMan.FindItemTemplate(X2TechTemplate_TLM(Tech.GetMyTemplate()).LootBoxToUse)).RollRarity();

	GetBaseItem(BWTemplate, ItemTemplate, RarityTemplate, NewGameState);
	Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

	if (Item == none)
	{
		`LOG("TLM ERROR: Failed to get base weapon");		
	}

	ApplyUpgrades(Item, Tech, RarityTemplate);

	Data = XComGameState_ItemData(NewGameState.CreateNewStateObject(class'XComGameState_ItemData'));
	Data.NumUpgradeSlots = 0;
	Item.AddComponentObject(Data);

	return Item;
}

static function GetBaseItem(out X2BaseWeaponDeckTemplate BWTemplate, out X2ItemTemplate ItemTemplate, X2RarityTemplate RarityTemplate, XComGameState NewGameState)
{		
	local X2ItemTemplateManager ItemTemplateMan;	
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local X2CardManager CardMan;	
	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2WeaponTemplate WeaponTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local int Weight, Idx;
	local string strItem, CardLabel;
	local array<string> CardLabels;
	local array<name> ItemNames;
	local name ItemTemplateName;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;	
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CardMan = class'X2CardManager'.static.GetCardManager();
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	
	BWTemplate = BWMan.DetermineBaseWeaponDeck();

	if (BWTemplate == none)
		`LOG("TLM ERROR: Unable to determine base weapon deck template");

	ItemNames = BWTemplate.GetBaseItems(RarityTemplate, NewGameState);	

	foreach ItemNames(ItemTemplateName)
	{
		WeaponTemplate = X2WeaponTemplate(ItemTemplateMan.FindItemTemplate(ItemTemplateName));
		if (WeaponTemplate == none) continue;

		Weight = 0.0;
		foreach XComHQ.Crew(UnitRef)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (Unit == none || !Unit.IsSoldier() || Unit.GetSoldierRank() == 0) continue;
			
			if (Unit.GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate)) Weight++;
		}

		if (CardLabels.Find(string(WeaponTemplate.DataName)) == INDEX_NONE)
		{
			CardMan.AddCardToDeck(BWTemplate.DataName, string(WeaponTemplate.DataName), float(Weight));
		}
	}

	foreach ItemNames(ItemTemplateName)
	{
		ArmorTemplate = X2ArmorTemplate(ItemTemplateMan.FindItemTemplate(ItemTemplateName));
		if (ArmorTemplate == none) continue;

		Weight = 0.0;
		foreach XComHQ.Crew(UnitRef)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (Unit == none || !Unit.IsSoldier() || Unit.GetSoldierRank() == 0) continue;
			
			if (Unit.GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate)) Weight++;
		}

		if (CardLabels.Find(string(ArmorTemplate.DataName)) == INDEX_NONE)
		{
			CardMan.AddCardToDeck(BWTemplate.DataName, string(ArmorTemplate.DataName), float(Weight));
		}
	}

	CardLabels.Length = 0;
	CardMan.GetAllCardsInDeck(BWTemplate.DataName, CardLabels);
	
	foreach CardLabels(CardLabel)
	{
		Idx = ItemNames.Find(name(CardLabel));
		if (Idx == INDEX_NONE)
		{			
			CardMan.RemoveCardFromDeck(BWTemplate.DataName, CardLabel);
		}
	}

	CardMan.SelectNextCardFromDeck(BWTemplate.DataName, strItem);
	// CardMan.MarkCardUsed(BWTemplate.DataName, strItem); // Need to test further

	ItemTemplate = ItemTemplateMan.FindItemTemplate(name(strItem));
}

static function ApplyUpgrades(XComGameState_Item Item, XComGameState_Tech Tech, X2RarityTemplate RarityTemplate)
{		
	local X2UpgradeDeckTemplateManager UpgradeDeckMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local RarityDeckData Deck;	
	local array<RarityDeckData> Decks;	
	
	UpgradeDeckMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();

	Item.NickName = GetInitialNickName(Item);
	Decks = RarityTemplate.GetDecksToRoll();	

	foreach Decks(Deck)
	{	
		UDTemplate = UpgradeDeckMan.GetUpgradeDeckTemplate(Deck.UpgradeDeckName);
		if (UDTemplate == none) continue;

		UDTemplate.RollUpgrades(Item, Deck.Quantity);
	}

	RarityTemplate.ApplyColorToString(Item.Nickname);
}

static function FindAndMakeTechInstant(XComGameState NewGameState, XComGameState_Tech Tech)
{	
	local XComGameState_Tech TechFromHistory;
	local bool bFoundInstantVersion;
	
	// Look for the instant version of the tech from history
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', TechFromHistory)
	{	
		if (TechFromHistory.GetMyTemplate().Requirements.RequiredTechs.Find(Tech.GetMyTemplateName()) != INDEX_NONE)
		{
			bFoundInstantVersion = true;
			break;
		}
	}

	// If there is one, then we force it to instant
	if (bFoundInstantVersion)
	{
		TechFromHistory = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechFromHistory.ObjectID));
		TechFromHistory.bForceInstant = true;
	}
}

static function string GetInitialNickName(XComGameState_Item Item)
{
	if (X2WeaponTemplate(Item.GetMyTemplate()) != none)
	{
		return default.RandomWeaponNickNames[`SYNC_RAND_STATIC(default.RandomWeaponNickNames.Length)];
	}
	else if (X2ArmorTemplate(Item.GetMyTemplate()) != none)
	{
		// For the moment we share the same pool
		return default.RandomWeaponNickNames[`SYNC_RAND_STATIC(default.RandomWeaponNickNames.Length)];
	}

	return "";
}

// =============
// DELEGATES
// =============
static function string ModifyAmmoNick(array<X2WeaponUpgradeTemplate> AppliedUpgrades, XComGameState_Item Item)
{
	local X2WeaponUpgradeTemplate WUTemplate;
	local string Temp;

	foreach AppliedUpgrades(WUTemplate)
	{
		// We only want to do this for ammo upgrades
		if (X2WeaponUpgradeTemplate_TLMAmmo(WUTemplate) == none) continue;

		Temp = WUTemplate.GetItemFriendlyNamePlural();
		Temp -= default.strRounds;
		break; // 1 is enough
	}	
	
	return Temp $Item.Nickname;
}

static function string ModifyRefnNick(array<X2WeaponUpgradeTemplate> AppliedUpgrades, XComGameState_Item Item)
{	
	return Item.Nickname $default.strPlus;
}
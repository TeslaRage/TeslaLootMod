class X2Helper_TLM extends Object config(TLM) abstract;

static function bool IsModLoaded(name DLCName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for(Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--)  
    {
        if(EventManager.GetDLCNames(Index) == DLCName)  
        {
            return true;
        }
    }
    return false;
}

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

	foreach class'X2DownloadableContentInfo_TeslaLootMod'.default.LootEntry(LootBag)
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
				strColor = class'X2DownloadableContentInfo_TeslaLootMod'.default.strTier0Color;
				break;
			case 1:
				strColor = class'X2DownloadableContentInfo_TeslaLootMod'.default.strTier1Color;
				break;
			case 2:
				strColor = class'X2DownloadableContentInfo_TeslaLootMod'.default.strTier2Color;
				break;
			case 3:
				strColor = class'X2DownloadableContentInfo_TeslaLootMod'.default.strTier3Color;
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
	local X2RarityTemplate RarityTemplate;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	
	RarityTemplate = X2ItemTemplate_LootBox(ItemMan.FindItemTemplate(X2TechTemplate_TLM(Tech.GetMyTemplate()).LootBoxToUse)).RollRarity();

	GetBaseItem(BWTemplate, ItemTemplate, RarityTemplate, NewGameState);
	Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);	

	if (Item == none)
	{
		`LOG("TLM ERROR: Failed to get base weapon");
		return Item; // Blank item i.e. get nothing when tech completes	
	}
	
	ApplyUpgrades(Item, RarityTemplate);
	CreateTLMItemState(NewGameState, Item, RarityTemplate.DataName);

	return Item;
}

static function CreateTLMItemState(XComGameState NewGameState, XComGameState_Item Item, name RarityName)
{
	local XComGameState_ItemData Data;

	Data = XComGameState_ItemData(NewGameState.CreateNewStateObject(class'XComGameState_ItemData'));
		
	if (class'X2EventListener_TLM'.default.bAllowRemoveUpgrade)
	{
		Data.NumUpgradeSlots = Item.GetMyWeaponUpgradeCount();
	}
	else
	{
		Data.NumUpgradeSlots = 0;
	}

	Data.RarityName = RarityName;
	Item.AddComponentObject(Data);
}

static function GetBaseItem(out X2BaseWeaponDeckTemplate BWTemplate, out X2ItemTemplate ItemTemplate, X2RarityTemplate RarityTemplate, XComGameState NewGameState)
{		
	local X2ItemTemplateManager ItemTemplateMan;	
	local X2CardManager CardMan;	
	local X2BaseWeaponDeckTemplateManager BWMan;
	local BaseItemData QualifiedBaseItem;
	local array<BaseItemData> QualifiedBaseItems;	
	local string strItem, CardLabel;
	local array<string> CardLabels;	
	local int Idx;

	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CardMan = class'X2CardManager'.static.GetCardManager();
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	
	BWTemplate = BWMan.DetermineBaseWeaponDeck();

	if (BWTemplate == none)
		`LOG("TLM ERROR: Unable to determine base weapon deck template");

	QualifiedBaseItems = BWTemplate.GetBaseItems(RarityTemplate, NewGameState);	
	CardMan.GetAllCardsInDeck(BWTemplate.DataName, CardLabels);

	foreach QualifiedBaseItems(QualifiedBaseItem)
	{
		strItem = string(QualifiedBaseItem.TemplateName);		

		if (CardLabels.Find(strItem) == INDEX_NONE)
		{
			CardLabels.AddItem(strItem);
			CardMan.AddCardToDeck(BWTemplate.DataName, strItem, float(QualifiedBaseItem.Weight));
		}
	}

	CardLabels.Length = 0;
	CardMan.GetAllCardsInDeck(BWTemplate.DataName, CardLabels);
	
	foreach CardLabels(CardLabel)
	{
		Idx = QualifiedBaseItems.Find('TemplateName', name(CardLabel));
		if (Idx == INDEX_NONE)
		{			
			CardMan.RemoveCardFromDeck(BWTemplate.DataName, CardLabel);
		}
	}

	// This also marks the card as "used" so `MarkCardUsed` is not needed
	CardMan.SelectNextCardFromDeck(BWTemplate.DataName, strItem);	

	ItemTemplate = ItemTemplateMan.FindItemTemplate(name(strItem));
}

static function ApplyUpgrades(XComGameState_Item Item, X2RarityTemplate RarityTemplate)
{		
	local X2UpgradeDeckTemplateManager UpgradeDeckMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local RarityDeckData Deck;	
	local array<RarityDeckData> Decks;	

	UpgradeDeckMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();

	Item.NickName = GetInitialNickName(Item);
	Decks = RarityTemplate.GetDecksToRoll(Item);	

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
		return class'X2DownloadableContentInfo_TeslaLootMod'.default.RandomWeaponNickNames[`SYNC_RAND_STATIC(class'X2DownloadableContentInfo_TeslaLootMod'.default.RandomWeaponNickNames.Length)];
	}
	else if (X2ArmorTemplate(Item.GetMyTemplate()) != none)
	{
		// For the moment we share the same pool
		return class'X2DownloadableContentInfo_TeslaLootMod'.default.RandomWeaponNickNames[`SYNC_RAND_STATIC(class'X2DownloadableContentInfo_TeslaLootMod'.default.RandomWeaponNickNames.Length)];
	}

	return "";
}

static function bool UpdateSlotCount(StateObjectReference ItemRef, XComGameState NewGameState)
{
	local XComGameState_Item Item;
	local XComGameState_ItemData Data;

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
	if (Item == none) return false;

	Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));
	if (Data == none) return false;

	Data = XComGameState_ItemData(NewGameState.ModifyStateObject(class'XComGameState_ItemData', Data.ObjectID));
	Data.NumUpgradeSlots = class'X2EventListener_TLM'.default.bAllowRemoveUpgrade ? Item.GetMyWeaponUpgradeCount() : 0;

	class'Helpers'.static.OutputMsg("Updated" @Item.GetMyTemplateName() @Item.Nickname @Data.NumUpgradeSlots @"slots");

	return true;
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
		Temp -= class'X2DownloadableContentInfo_TeslaLootMod'.default.strRounds;
		break; // 1 is enough
	}	
	
	return Temp $Item.Nickname;
}

static function string ModifyRefnNick(array<X2WeaponUpgradeTemplate> AppliedUpgrades, XComGameState_Item Item)
{	
	return Item.Nickname $class'X2DownloadableContentInfo_TeslaLootMod'.default.strPlus;
}
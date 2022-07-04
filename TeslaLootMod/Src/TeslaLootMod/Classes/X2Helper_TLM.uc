class X2Helper_TLM extends Object config(TLM) abstract;

static function bool IsModLoaded(name DLCName)
{
	local XComOnlineEventMgr EventManager;
	local int Index;

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

	if (class'X2DownloadableContentInfo_TeslaLootMod'.default.bUpgradesDropAsLoot)
	{
		foreach class'X2DownloadableContentInfo_TeslaLootMod'.default.LootEntryAlt(LootBag)
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
	else
	{
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
	local DecksForAutoIconsAndMEData DeckForAutoIconsAndME;	
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
				WUTemplate.BriefSummary = Repl(WUTemplate.BriefSummary, "%TLMCRITMULT", TLMEffect.CritDamageMultiplier < 0 ? int(TLMEffect.CritDamageMultiplier * -100): int(TLMEffect.CritDamageMultiplier * 100));
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

		// Only if coloring is configured, and only when the upgrade has not been colored
		if (strColor != "" && InStr(WUTemplate.FriendlyName, "</font>") == INDEX_NONE)
			WUTemplate.FriendlyName = "<font color='" $strColor $"'>" $WUTemplate.FriendlyName $"</font>";
	}

	// Setting up of upgrade icons and mutual exclusives
	foreach class'X2DownloadableContentInfo_TeslaLootMod_Last'.default.DecksForAutoIconsAndME(DeckForAutoIconsAndME)
	{
		SetUpUpgradeIconsAndME(DeckForAutoIconsAndME.UpgradeDeckTemplateName, DeckForAutoIconsAndME.SetMutualExclusives);
	}
}

static function SetUpUpgradeIconsAndME(name UpgradeDeckTemplateName, bool SetMutualExclusives)
{
	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2UpgradeDeckTemplateManager UDMan;
	local X2AbilityTemplateManager ABilityMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local WeaponAttachment WAttachment;
	local array<name> ItemTemplateNames, WUTemplateNames;	
	local name AbilityName, ItemTemplateName;
	local string IconString;

	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	ItemTemplateNames = BWMan.GetAllItemTemplateNames();
	AppendPatchedItems(ItemTemplateNames);

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

			// If no ability icon, then we try to grab from the upgrade template
			// This works fine for base game upgrades or upgrades that have been properly set up with
			// IconString for other weapons. This is not super accurate, but better than nothing
			if (IconString == "")
			{
				foreach WUTemplate.UpgradeAttachments(WAttachment)
				{
					if (WAttachment.InventoryCategoryIcon != "")
					{	
						IconString = WAttachment.InventoryCategoryIcon;
						break;
					}
				}
			}

			// If still no icon, then we give it a default one
			if (IconString == "")
			{
				IconString = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip";
			}

			foreach ItemTemplateNames(ItemTemplateName)
			{
				if (WUTemplate.UpgradeAttachments.Find('ApplyToWeaponTemplate', ItemTemplateName) == INDEX_NONE)
				{
					WUTemplate.AddUpgradeAttachment('', '', "", "", ItemTemplateName, , "", WUTemplate.strImage, IconString);
				}
			}
			
			// Sets up the mutual exclusive
			if (SetMutualExclusives)
			{
				WUTemplate.MutuallyExclusiveUpgrades = WUTemplateNames;
			}
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

static function XComGameState_Item GenerateTLMItem(XComGameState NewGameState, XComGameState_Tech Tech, out X2BaseWeaponDeckTemplate BWTemplate, optional name Category, optional X2RarityTemplate RarityTemplate)
{
	local X2ItemTemplateManager ItemMan;
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;	
	// local X2RarityTemplate RarityTemplate;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (RarityTemplate == none)
	{
		RarityTemplate = X2ItemTemplate_LootBox(ItemMan.FindItemTemplate(X2TechTemplate_TLM(Tech.GetMyTemplate()).LootBoxToUse)).RollRarity();
	}

	GetBaseItem(BWTemplate, ItemTemplate, RarityTemplate, NewGameState, Category);
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

static function GetBaseItem(out X2BaseWeaponDeckTemplate BWTemplate, out X2ItemTemplate ItemTemplate, X2RarityTemplate RarityTemplate, XComGameState NewGameState, optional name Category)
{		
	local X2ItemTemplateManager ItemTemplateMan;
	local X2BaseWeaponDeckTemplateManager BWMan;
	local array<BaseItemData> QualifiedBaseItems;
	local array<ItemWeightData> ItemWeights;
	local ItemWeightData ItemWeight;
	local name ItemTemplateName;
	local int i;

	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	
	BWTemplate = BWMan.DetermineBaseWeaponDeck();

	if (BWTemplate == none)
		`LOG("TLM ERROR: Unable to determine base weapon deck template");

	QualifiedBaseItems = BWTemplate.GetBaseItems(RarityTemplate, NewGameState, Category);

	for (i = 0; i < QualifiedBaseItems.Length; i++)
	{
		ItemWeight.Index = i;
		ItemWeight.Weight = QualifiedBaseItems[i].Weight;
		ItemWeights.AddItem(ItemWeight);
	}

	i = GetWeightBasedIndex(ItemWeights);
	if (i < 0)
	{
		ItemTemplateName = QualifiedBaseItems[`SYNC_RAND_STATIC(QualifiedBaseItems.Length)].TemplateName;
	}
	else
	{
		ItemTemplateName = QualifiedBaseItems[i].TemplateName;
	}

	ItemTemplate = ItemTemplateMan.FindItemTemplate(ItemTemplateName);
}

static function ApplyUpgrades(XComGameState_Item Item, X2RarityTemplate RarityTemplate, optional bool bApplyNick = true)
{		
	local X2UpgradeDeckTemplateManager UpgradeDeckMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local RarityDeckData Deck;	
	local array<RarityDeckData> Decks;	

	UpgradeDeckMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();

	if (bApplyNick)
	{
		Item.NickName = GetInitialNickName(Item);
	}
	
	Decks = RarityTemplate.GetDecksToRoll(Item);	

	foreach Decks(Deck)
	{
		UDTemplate = UpgradeDeckMan.GetUpgradeDeckTemplate(Deck.UpgradeDeckName);
		if (UDTemplate == none) continue;

		UDTemplate.RollUpgrades(Item, Deck.Quantity, bApplyNick);
	}

	if (bApplyNick)
	{
		RarityTemplate.ApplyColorToString(Item.Nickname);
	}
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

static function ApplyTLMTreatmentToItems()
{
	local X2ItemTemplateManager ItemMan;
	local PatchItemData PatchItem;
	local array<X2DataTemplate> DataTemplates;
	local X2DataTemplate DataTemplate;
	local X2ItemTemplate ItemTemplate;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach class'X2DownloadableContentInfo_TeslaLootMod_Last'.default.PatchItems(PatchItem)
	{
		ItemMan.FindDataTemplateAllDifficulties(PatchItem.ItemTemplateName, DataTemplates);

		foreach DataTemplates(DataTemplate)
		{
			ItemTemplate = X2ItemTemplate(DataTemplate);
			if (ItemTemplate == none) continue;

			ItemTemplate.OnAcquiredFn = OnItemAcquired_TLM;
		}
	}
}

static function AppendPatchedItems(out array<name> ItemTemplateNames)
{
	local PatchItemData PatchItem;

	foreach class'X2DownloadableContentInfo_TeslaLootMod_Last'.default.PatchItems(PatchItem)
	{
		ItemTemplateNames.AddItem(PatchItem.ItemTemplateName);
	}
}

// Heavily inspired by Proficiency Class Pack Air Burst Grenades ability
static function AddAbilityBonusRadius()
{
	local X2AbilityTemplateManager AbilityTemplateMgr;
	local array<X2AbilityTemplate> AbilityTemplateArray;
	local X2AbilityTemplate AbilityTemplate;
	local AbilityGivesGRadiusData AbilityBonusRadius;
	local name AbilityName;

	AbilityTemplateMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach class'X2Ability_TLM'.default.GrenadeLaunchAbilities(AbilityName)
	{
		AbilityTemplateMgr.FindAbilityTemplateAllDifficulties(AbilityName, AbilityTemplateArray);

		foreach class'X2Ability_TLM'.default.AbilityGivesGRadius(AbilityBonusRadius)
		{
			foreach AbilityTemplateArray(AbilityTemplate)
			{
				X2AbilityMultiTarget_Radius(AbilityTemplate.AbilityMultiTargetStyle).AddAbilityBonusRadius(AbilityBonusRadius.AbilityName, AbilityBonusRadius.GrenadeRadiusBonus);
			}
		}
	}	
}

static function PatchStandardShot()
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_ApplyWeaponDamage RuptureEffect;
	local X2Condition_AbilityProperty OwnerAbilityCondition;
	local RuptureAbilitiesData RuptureAbility;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('StandardShot');
	if (AbilityTemplate == none) return;

	foreach class'X2Ability_TLM'.default.RuptureAbilities(RuptureAbility)
	{
		RuptureEffect = new class'X2Effect_ApplyWeaponDamage';
		RuptureEffect.bIgnoreBaseDamage = true;
		RuptureEffect.EffectDamageValue.Rupture = RuptureAbility.RuptureValue;
		RuptureEffect.ApplyChance = RuptureAbility.ApplyChance;

		OwnerAbilityCondition = new class'X2Condition_AbilityProperty';
		OwnerAbilityCondition.OwnerHasSoldierAbilities.AddItem(RuptureAbility.AbilityName);
		RuptureEffect.TargetConditions.AddItem(OwnerAbilityCondition);
		AbilityTemplate.AddTargetEffect(RuptureEffect);
	}
}

static function PatchWeaponUpgrades()
{
	local X2ItemTemplateManager ItemTemplateMan;
	local array<X2DataTemplate> DataTemplates;
	local X2DataTemplate DataTemplate;
	local X2WeaponUpgradeTemplate WUTemplate, DonorTemplate;
	local PatchWeaponUpgradesData PatchWeaponUpgrade;
	local name WUTemplateName;

	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	foreach class'X2Item_TLMUpgrades'.default.PatchWeaponUpgrades(PatchWeaponUpgrade)
	{
		ItemTemplateMan.FindDataTemplateAllDifficulties(PatchWeaponUpgrade.UpgradeName, DataTemplates);

		foreach DataTemplates(DataTemplate)
		{
			WUTemplate = X2WeaponUpgradeTemplate(DataTemplate);
			if (WUTemplate == none) continue;

			foreach PatchWeaponUpgrade.MutuallyExclusiveUpgrades(WUTemplateName)
			{
				WUTemplate.MutuallyExclusiveUpgrades.AddItem(WUTemplateName);
			}

			if (PatchWeaponUpgrade.AttachmentsDonorTemplate != '')
			{
				DonorTemplate = X2WeaponUpgradeTemplate(ItemTemplateMan.FindItemTemplate(PatchWeaponUpgrade.AttachmentsDonorTemplate));
				if (DonorTemplate != none)
				{
					WUTemplate.UpgradeAttachments = DonorTemplate.UpgradeAttachments;
				}
			}
		}
	}
}

static function int GetWeightBasedIndex(array<ItemWeightData> ItemWeights)
{
	local int Rand, i, TotalWeight;	

	// Calculate total weight
	for (i = 0; i < ItemWeights.Length; i++)
	{
		// We cannot have 0 or less than that
		if (ItemWeights[i].Weight <= 0)
		{
			ItemWeights[i].Weight = 1;
		}
		TotalWeight += ItemWeights[i].Weight;
	}

	Rand = `SYNC_RAND_STATIC(TotalWeight);

	for (i = 0; i < ItemWeights.Length; i++)
	{
		if (Rand < ItemWeights[i].Weight)
		{
			return ItemWeights[i].Index;
		}
		else
		{
			Rand -= ItemWeights[i].Weight;
		}
	}

	// Should not reach here
	`RedScreen("GetWeightBasedIndex() failed to return a proper index");
	return -1;
}

static function array<XComGameState_Item> GetTLMItemsByCategory(name Category)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local StateObjectReference ItemRef, UnitRef;
	local XComGameState_Item Item;
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> Items;
	local array<TopItemsData> TopItems;
	local TopItemsData TopItem;
	local int i;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	foreach XComHQ.Inventory(ItemRef)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
		if (Item == none) continue;

		if (!IsATLMItem(Item)) continue;

		if (GetTLMItemCategory(Item) == Category)
		{
			// Items.AddItem(Item);
			TopItem.Item = Item;
			TopItem.Tier = Item.GetMyTemplate().Tier;
			TopItems.AddItem(TopItem);
		}
	}

	foreach XComHQ.Crew(UnitRef)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit == none) continue;

		foreach Unit.InventoryItems(ItemRef)
		{
			Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
			if (Item == none) continue;

			if (!IsATLMItem(Item)) continue;

			if (GetTLMItemCategory(Item) == Category)
			{
				// Items.AddItem(Item);
				TopItem.Item = Item;
				TopItem.Tier = Item.GetMyTemplate().Tier;
				TopItems.AddItem(TopItem);
			}
		}
	}

	// `LOG("Category: " $Category $"==================================", true, 'TLMDEBUG');
	// `LOG("Before sort:", true, 'TLMDEBUG');
	// foreach TopItems(TopItem)
	// {
	// 	`LOG(TopItem.Item.GetMyTemplate().DataName $"|" $TopItem.Tier, true, 'TLMDEBUG');
	// }

	TopItems.Sort(SortByTier);

	// `LOG("After sort:", true, 'TLMDEBUG');
	// foreach TopItems(TopItem)
	// {
	// 	`LOG(TopItem.Item.GetMyTemplate().DataName $"|" $TopItem.Tier, true, 'TLMDEBUG');
	// }

	i = 0;
	foreach TopItems(TopItem)
	{
		if (i >= 3) break;

		Items.AddItem(TopItem.Item);
		i++;
	}

	return Items;
}

static function bool IsATLMItem(XComGameState_Item Item)
{
	local XComGameState_ItemData Data;

	Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));
	if (Data != none) return true;

	return false;
}

static function name GetTLMItemCategory(XComGameState_Item Item)
{
	local X2WeaponTemplate WTemplate;

	if (Item.GetMyTemplate().IsA('X2WeaponTemplate'))
	{
		WTemplate = X2WeaponTemplate(Item.GetMyTemplate());
		if (WTemplate != none)
		{
			return WTemplate.WeaponCat;
		}
	}
	else
	{
		return Item.GetMyTemplate().ItemCat;
	}

	return '';
}

simulated function int SortByTier(TopItemsData A, TopItemsData B)
{
	local int TierA, TierB;

	TierA = A.Tier;
	TierB = B.Tier;

	if (TierA > TierB)
	{
		return 1;
	}
	else if (TierA < TierB)
	{
		return -1;
	}

	return 0;
}

static function string GetWeaponUpgradesAsStr(XComGameState_Item Item, string Separator)
{
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local array<string> ItemsFriendlyNames;
	local int i;
	local string strWeaponUpgrades;

	if (Item != none)
	{
		if (Item.GetMyWeaponUpgradeCount() > 0)
		{
			WUTemplates = Item.GetMyWeaponUpgradeTemplates();

			for (i = 0; i < WUTemplates.Length; i++)
			{
				ItemsFriendlyNames.AddItem(WUTemplates[i].GetItemFriendlyName());
			}
			
			class'Object'.static.JoinArray(ItemsFriendlyNames, strWeaponUpgrades, Separator);
		}
	}
	return strWeaponUpgrades;
}

// TODO: Finish this up
static function GetSoldiersCanEquipCat(name Category)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	foreach XComHQ.Crew(UnitRef)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit == none) continue;

		// if (Unit.CanAddItemToInventory())
	}
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

static function bool OnItemAcquired_TLM(XComGameState NewGameState, XComGameState_Item ItemState)
{	
	local X2RarityTemplate RarityTemplate;
	local X2RarityTemplateManager RMan;
	local bool bApplyNick;
	local name RarityName;
	local int Index;

	RMan = class'X2RarityTemplateManager'.static.GetRarityTemplateManager();

	// Get Rarity Template
	Index = class'X2DownloadableContentInfo_TeslaLootMod_Last'.default.PatchItems.Find('ItemTemplateName', ItemState.GetMyTemplateName());
	if (Index == INDEX_NONE) return false;

	RarityName = class'X2DownloadableContentInfo_TeslaLootMod_Last'.default.PatchItems[Index].Rarity;
	bApplyNick = class'X2DownloadableContentInfo_TeslaLootMod_Last'.default.PatchItems[Index].ApplyNick;

	RarityTemplate = RMan.GetRarityTemplate(RarityName);
	if (RarityTemplate == none) return false;

	// Apply TLM treatment
	ApplyUpgrades(ItemState, RarityTemplate, bApplyNick);
	CreateTLMItemState(NewGameState, ItemState, RarityTemplate.DataName);

	return true;
}
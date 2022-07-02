class X2BaseWeaponDeckTemplate extends X2DataTemplate config(TLM);

var config int Tier;
var config StrategyRequirement Requirements;
var config array<BaseItemData> BaseItems;

function array<BaseItemData> GetBaseItems(X2RarityTemplate RarityTemplate, XComGameState NewGameState, optional name Category)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemMan;
	local BaseItemData BaseItem;
	local array<BaseItemData> QualifiedBaseItems;
	local X2ItemTemplate ItemTemplate, SchematicTemplate;
	local StrategyRequirement ItemRequirements;
	local X2WeaponTemplate WeaponTemplate;
	local name ForcedRarityName;	

	XComHQ = `XCOMHQ;
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	

	foreach BaseItems(BaseItem)
	{	
		ItemTemplate = ItemMan.FindItemTemplate(BaseItem.TemplateName);
		if (ItemTemplate == none) continue;

		// Filter by category
		if (Category != '')
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);
			if (WeaponTemplate != none)
			{
				if (WeaponTemplate.WeaponCat != Category) continue;
			}
			else
			{
				if (ItemTemplate.ItemCat != Category) continue;
			}
		}

		// Requirement wise, we only want to check RequiredTechs
		ItemRequirements.RequiredTechs = ItemTemplate.Requirements.RequiredTechs;

		// Individually built items requirement check
		if (!XComHQ.MeetsAllStrategyRequirements(ItemRequirements))
		{
			continue;
		}

		// Pipu still playing with schematics requirement check
		if (ItemTemplate.CreatorTemplateName != '')
		{
			SchematicTemplate = ItemMan.FindItemTemplate(ItemTemplate.CreatorTemplateName);
			if (SchematicTemplate != none)
			{
				// Requirement wise, we only want to check RequiredTechs
				ItemRequirements.RequiredTechs = SchematicTemplate.Requirements.RequiredTechs;

				if (!XComHQ.MeetsAllStrategyRequirements(ItemRequirements))
				{
					continue;
				}
			}
		}

		ForcedRarityName = GetForcedRarity(ItemTemplate.DataName);
		if (ForcedRarityName != '' && ForcedRarityName != RarityTemplate.DataName) continue;
		
		if (!CanItemGetAnyUpgrades(ItemTemplate, RarityTemplate, NewGameState)) continue;
		
		QualifiedBaseItems.AddItem(BaseItem);
	}

	return QualifiedBaseItems;
}

function bool CanItemGetAnyUpgrades(X2ItemTemplate ItemTemplate, X2RarityTemplate RarityTemplate, XComGameState NewGameState)
{
	local XComGameState_Item Item;	
	local array<RarityDeckData> UpgradeDecks;
	local RarityDeckData UpgradeDeck;
	local X2UpgradeDeckTemplateManager UDMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local X2ItemTemplateManager ItemMan;
	local UpgradeDeckData Upgrade;
	local X2WeaponUpgradeTemplate WUTemplate;

	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	// This is a temporary item state to test apply upgrades
	Item = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	UpgradeDecks = RarityTemplate.GetDecksToRoll(Item);

	foreach UpgradeDecks(UpgradeDeck)
	{
		// If the deck has a chance of less than 100, potentially the item will not get any upgrades. So we skip this deck.
		if (UpgradeDeck.Chance < 100) continue;

		// Get the upgrade deck template (which contains all the upgrades)
		UDTemplate = UDMan.GetUpgradeDeckTemplate(UpgradeDeck.UpgradeDeckName);
		foreach UDTemplate.Upgrades(Upgrade)
		{
			// Get weapon upgrade template, so that we can test apply it to the item
			WUTemplate = X2WeaponUpgradeTemplate(ItemMan.FindItemTemplate(Upgrade.UpgradeName));
			if (WUTemplate == none) continue;

			// Test the upgrade on this item
			if (UDTemplate.CanApplyUpgrade(WUTemplate, Item, Upgrade))
			{
				NewGameState.PurgeGameStateForObjectID(Item.ObjectID);
				return true;
			}
		}
	}

	NewGameState.PurgeGameStateForObjectID(Item.ObjectID);
	return false;
}

function string GetImage(name TemplateName)
{
	local int Idx;

	Idx = BaseItems.Find('TemplateName', TemplateName);

	if (Idx != INDEX_NONE)
	{
		return BaseItems[Idx].Image;
	}	

	return "";
}

function name GetForcedRarity(name TemplateName)
{
	local int Idx;

	Idx = BaseItems.Find('TemplateName', TemplateName);

	if (Idx != INDEX_NONE)
	{
		return BaseItems[Idx].ForcedRarity;
	}

	return '';
}

function bool ValidateTemplate (out string strError)
{
	if (!super.ValidateTemplate(strError))
	{
		return false;
	}

	if (BaseItems.Length == 0)
	{
		strError = "BaseItems is empty so no item can be chosen during item generation";
		return false;
	}

	return true;
}
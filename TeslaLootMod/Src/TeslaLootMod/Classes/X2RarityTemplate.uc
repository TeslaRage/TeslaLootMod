class X2RarityTemplate extends X2DataTemplate config(TLM);

var localized string FriendlyName;

var config int Tier;
var config array<RarityDeckData> Decks;
var config string RarityColor;
var config string RarityIcon;

function array<RarityDeckData> GetDecksToRoll(X2ItemTemplate ItemTemplate, optional bool bIgnoreChance)
{
	local X2UpgradeDeckTemplateManager UDMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local X2WeaponTemplate WTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local RarityDeckData Deck;
	local array<RarityDeckData> UpgradeDecks;

	UDMan = class'X2UpgradeDeckTemplateManager'.static.GetUpgradeDeckTemplateManager();

	foreach Decks(Deck)
	{
		// Get upgrade deck template for checks
		UDTemplate = UDMan.GetUpgradeDeckTemplate(Deck.UpgradeDeckName);
		if (UDTemplate == none) continue;

		// First check if `ItemCat` matches
		if (UDTemplate.AllowedItemCat.AllowedItemCat != ItemTemplate.ItemCat) continue;

		// Now we check for `WeaponCat` or `ArmorCat`
		WTemplate = X2WeaponTemplate(ItemTemplate);

		if (WTemplate != none)
		{
			if (UDTemplate.AllowedCats.Length > 0 && UDTemplate.AllowedCats.Find(WTemplate.WeaponCat) == INDEX_NONE)
			{
				continue;
			}
		}
		else
		{
			// If not a weapon, then it can only be an armor template
			ArmorTemplate = X2ArmorTemplate(ItemTemplate);
			if (ArmorTemplate == none) continue;
			
			if (UDTemplate.AllowedCats.Length > 0 && UDTemplate.AllowedCats.Find(ArmorTemplate.ArmorCat) == INDEX_NONE)
			{
				continue;
			}
		}		

		// Possibility of getting the deck
		if (bIgnoreChance || `SYNC_RAND_STATIC(100) < Deck.Chance)
		{
			UpgradeDecks.AddItem(Deck);
		}
	}

	return UpgradeDecks;
}

function ApplyColorToString(out string ColoredString)
{	
	ColoredString = "<font color='" $RarityColor $"'>" $ColoredString $"</font>";
}

function bool ValidateTemplate (out string strError)
{
	if (!super.ValidateTemplate(strError))
	{
		return false;
	}

	if (Decks.Length == 0)
	{
		strError = "Decks is empty so items with this rarity will not get any weapon upgrades";
		return false;
	}

	return true;
}

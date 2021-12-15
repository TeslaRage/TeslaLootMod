class X2RarityTemplate extends X2DataTemplate config(TLM);

var config int Tier;
var config array<RarityDeckData> Decks;
var config string RarityColor;

function array<RarityDeckData> GetDecksToRoll()
{
	local RarityDeckData Deck;
	local array<RarityDeckData> UpgradeDecks;

	foreach Decks(Deck)
	{
		if (`SYNC_RAND_STATIC(100) < Deck.Chance)
			UpgradeDecks.AddItem(Deck);
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
class X2RarityTemplate extends X2DataTemplate config(TLM);

struct RarityDeckData
{
	var name UpgradeDeckName;
	var int Quantity;
	var int Chance;

	structdefaultproperties{
		Chance = 100;
	}
};

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
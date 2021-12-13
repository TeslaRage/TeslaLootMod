class X2ItemTemplate_LootBox extends X2ItemTemplate config (TLM);

var config array<LootBoxRarityData> Rarities;

function X2RarityTemplate RollRarity()
{	
	local X2RarityTemplate RarityTemplate, LowestTierRarityTemplate;		
	local LootBoxRarityData Rarity;
	local X2RarityTemplateManager RMan;
	local int CurrentTotal, RarityRoll;	
	
	RMan = class'X2RarityTemplateManager'.static.GetRarityTemplateManager();
	RarityRoll = `SYNC_RAND_STATIC(100);

	foreach Rarities(Rarity)
	{
		RarityTemplate = RMan.GetRarityTemplate(Rarity.RarityName);
		if (RarityTemplate == none) continue;

		if (LowestTierRarityTemplate == none)
			LowestTierRarityTemplate = RarityTemplate;
		else if (RarityTemplate.Tier < LowestTierRarityTemplate.Tier)
			LowestTierRarityTemplate = RarityTemplate;

		CurrentTotal += Rarity.Chance;
		if (RarityRoll < CurrentTotal)		
			break;		
	}

	if (RarityTemplate == none)
	{
		`REDSCREEN("Unable to determine Rarity, so the lowest tier one was chosen");
		RarityTemplate = LowestTierRarityTemplate;
	}		

	return RarityTemplate;
}
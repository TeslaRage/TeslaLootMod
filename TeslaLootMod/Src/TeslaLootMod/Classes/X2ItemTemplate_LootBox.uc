class X2ItemTemplate_LootBox extends X2ItemTemplate config (TLM);

var config array<LootBoxRarityData> Rarities;

function X2RarityTemplate RollRarity(XComGameState_Item Item)
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

	CheckForForcedRarity(RarityTemplate, Item);	

	return RarityTemplate;
}

private function CheckForForcedRarity(out X2RarityTemplate SelectedRarity, XComGameState_Item Item)
{
	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local X2RarityTemplateManager RMan;
	local X2RarityTemplate RarityTemplate;
	local array<X2RarityTemplate> RarityTemplates;
	local name ForcedRarityName;

	RMan = class'X2RarityTemplateManager'.static.GetRarityTemplateManager();
	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	BWTemplate = BWMan.DetermineBaseWeaponDeck();
	ForcedRarityName = BWTemplate.GetForcedRarity(Item.GetMyTemplateName());
	RarityTemplates = RMan.GetAllRarityTemplates();

	if (ForcedRarityName != '')
	{
		foreach RarityTemplates(RarityTemplate)
		{
			if (RarityTemplate.DataName == ForcedRarityName)
			{
				SelectedRarity = RarityTemplate;
				break;
			}				
		}
	}
}
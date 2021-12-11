class X2RarityTemplateManager extends X2DataTemplateManager;

static function X2RarityTemplateManager GetRarityTemplateManager()
{
    return X2RarityTemplateManager(class'Engine'.static.GetTemplateManager(class'X2RarityTemplateManager'));
}

function X2RarityTemplate GetRarityTemplate(name TemplateName)
{
	local X2RarityTemplate Template;

	Template = X2RarityTemplate(FindDataTemplate(TemplateName));

	return Template;
}

function X2RarityTemplate RollRarity(XComGameState_Item Item)
{
	local X2DataTemplate DataTemplate;
	local X2RarityTemplate RarityTemplate, LowestTierRarityTemplate;	
	local int CurrentTotal, RarityRoll;
	local bool bChosenRarityTemplate;
	
	RarityRoll = `SYNC_RAND_STATIC(100);

	foreach IterateTemplates(DataTemplate)
	{
		RarityTemplate = X2RarityTemplate(DataTemplate);		
		if (RarityTemplate == none) continue;
		
		if (LowestTierRarityTemplate == none) LowestTierRarityTemplate = RarityTemplate;
		if (RarityTemplate.Tier < LowestTierRarityTemplate.Tier) LowestTierRarityTemplate = RarityTemplate;

		CurrentTotal += RarityTemplate.Chance;
		if (RarityRoll < CurrentTotal) 
        {
			bChosenRarityTemplate = true;
            break; // This is the chosen Rarity Template
        }
	}

	if (CurrentTotal < 100 && !bChosenRarityTemplate) RarityTemplate = LowestTierRarityTemplate;

	CheckForForcedRarity(RarityTemplate, Item);		

	return RarityTemplate;
}

function CheckForForcedRarity(out X2RarityTemplate SelectedRarity, XComGameState_Item Item)
{
	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local X2RarityTemplate RarityTemplate;
	local array<X2RarityTemplate> RarityTemplates;
	local name ForcedRarityName;

	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	BWTemplate = BWMan.DetermineBaseWeaponDeck();
	ForcedRarityName = BWTemplate.GetForcedRarity(Item.GetMyTemplateName());
	RarityTemplates = GetAllRarityTemplates();

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

function array<X2RarityTemplate> GetAllRarityTemplates()
{
	local X2RarityTemplate RarityTemplate;
	local array<X2RarityTemplate> RarityTemplates;
	local X2DataTemplate DataTemplate;

	foreach IterateTemplates(DataTemplate)
	{
		RarityTemplate = X2RarityTemplate(DataTemplate);
		if (RarityTemplate == none) continue;

		RarityTemplates.AddItem(RarityTemplate);
	}

	return RarityTemplates;
}

defaultProperties
{
	TemplateDefinitionClass=class'X2RaritySet'
	ManagedTemplateClass=class'X2RarityTemplate'
}
class X2BaseWeaponDeckTemplateManager extends X2DataTemplateManager;

static function X2BaseWeaponDeckTemplateManager GetBaseWeaponDeckTemplateManager()
{
    return X2BaseWeaponDeckTemplateManager(class'Engine'.static.GetTemplateManager(class'X2BaseWeaponDeckTemplateManager'));
}

function X2BaseWeaponDeckTemplate GetBaseWeaponDeckTemplate(name TemplateName)
{
	local X2BaseWeaponDeckTemplate Template;

	Template = X2BaseWeaponDeckTemplate(FindDataTemplate(TemplateName));

	return Template;
}

function X2BaseWeaponDeckTemplate DetermineBaseWeaponDeck()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2DataTemplate DataTemplate;
	local X2BaseWeaponDeckTemplate BWTemplate, ChosenBWTemplate;	

	XComHQ = `XCOMHQ;

	foreach IterateTemplates(DataTemplate)
	{
		BWTemplate = X2BaseWeaponDeckTemplate(DataTemplate);
		if (BWTemplate == none) continue;
		
		if (XComHQ.MeetsAllStrategyRequirements(BWTemplate.Requirements))
		{
			if (ChosenBWTemplate == none) ChosenBWTemplate = BWTemplate;
			else if (ChosenBWTemplate.Tier < BWTemplate.Tier) ChosenBWTemplate = BWTemplate;
		}			
	}

	return ChosenBWTemplate;
}

function array<name> GetAllItemTemplateNames()
{
	local X2DataTemplate DataTemplate;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local BaseItemData BaseItem;
	local array<name> ItemTemplateNames, BaseItemTemplateNames;

	foreach IterateTemplates(DataTemplate)
	{
		BWTemplate = X2BaseWeaponDeckTemplate(DataTemplate);
		if (BWTemplate == none) continue;

		foreach BWTemplate.BaseItems(BaseItem)
		{
			BaseItemTemplateNames.AddItem(BaseItem.TemplateName);
		}

		class'X2Helper_TLM'.static.AppendArrays(ItemTemplateNames, BaseItemTemplateNames);
	}

	return ItemTemplateNames;
}

defaultProperties
{
	TemplateDefinitionClass=class'X2BaseWeaponDeckSet'
	ManagedTemplateClass=class'X2BaseWeaponDeckTemplate'
}
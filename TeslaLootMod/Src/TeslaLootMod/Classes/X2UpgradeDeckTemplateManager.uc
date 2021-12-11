class X2UpgradeDeckTemplateManager extends X2DataTemplateManager;

static function X2UpgradeDeckTemplateManager GetUpgradeDeckTemplateManager()
{
    return X2UpgradeDeckTemplateManager(class'Engine'.static.GetTemplateManager(class'X2UpgradeDeckTemplateManager'));
}

function X2UpgradeDeckTemplate GetUpgradeDeckTemplate(name TemplateName)
{
	local X2UpgradeDeckTemplate Template;

	Template = X2UpgradeDeckTemplate(FindDataTemplate(TemplateName));

	return Template;
}

function array<X2WeaponUpgradeTemplate> GetAllUpgradeTemplates()
{
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local X2DataTemplate DataTemplate, DataTemplate2;
	local array<X2DataTemplate> DataTemplates;
	local X2ItemTemplateManager ItemMan;
	local X2UpgradeDeckTemplate UDTemplate;
	local UpgradeDeckData Upgrade;

	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach IterateTemplates(DataTemplate)
	{
		UDTemplate = X2UpgradeDeckTemplate(DataTemplate);
		if (UDTemplate == none) continue;

		foreach UDTemplate.Upgrades(Upgrade)
		{
			ItemMan.FindDataTemplateAllDifficulties(Upgrade.UpgradeName, DataTemplates);

			foreach DataTemplates(DataTemplate2)
			{
				WUTemplate = X2WeaponUpgradeTemplate(DataTemplate2);
				if (WUTemplate == none) continue;

				WUTemplates.AddItem(WUTemplate);
			}
		}
		
	}

	return WUTemplates;
}

function array<X2UpgradeDeckTemplate> GetUpgradeDecksByUpgradeName(name WeaponUpgradeName)
{
	local X2UpgradeDeckTemplate UDTemplate;
	local array<X2UpgradeDeckTemplate> UDTemplates;
	local X2DataTemplate DataTemplate;

	foreach IterateTemplates(DataTemplate)
	{
		UDTemplate = X2UpgradeDeckTemplate(DataTemplate);
		if (UDTemplate == none) continue;

		if (UDTemplate.Upgrades.Find('UpgradeName', WeaponUpgradeName) != INDEX_NONE)
		{
			UDTemplates.AddItem(UDTemplate);
		}
	}

	return UDTemplates;
}

defaultProperties
{
	TemplateDefinitionClass=class'X2UpgradeDeckSet'
	ManagedTemplateClass=class'X2UpgradeDeckTemplate'
}
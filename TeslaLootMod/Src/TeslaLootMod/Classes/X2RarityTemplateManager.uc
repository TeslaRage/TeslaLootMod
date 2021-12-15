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
class X2UpgradeDeckSet extends X2DataSet config (TLM);

var config array<name> UpgradeDecks;

static function array<X2DataTemplate> CreateTemplates ()
{
	local array<X2DataTemplate> Templates;	
	local name TemplateName;
	
	foreach default.UpgradeDecks(TemplateName)
	{
		Templates.AddItem(CreateTemplateUpgradeDeck(TemplateName));
	}

	return Templates;
}

static function X2UpgradeDeckTemplate CreateTemplateUpgradeDeck (name TemplateName)
{
	local X2UpgradeDeckTemplate Template;

	`CREATE_X2TEMPLATE(class'X2UpgradeDeckTemplate', Template, TemplateName);	

	return Template;
}
class X2RaritySet extends X2DataSet config(TLM);

var config array<name> Rarity;

static function array<X2DataTemplate> CreateTemplates ()
{
	local array<X2DataTemplate> Templates;	
	local name TemplateName;
	
	foreach default.Rarity(TemplateName)
	{
		Templates.AddItem(CreateTemplateRarity(TemplateName));
	}

	return Templates;
}

static function X2RarityTemplate CreateTemplateRarity (name TemplateName)
{
	local X2RarityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2RarityTemplate', Template, TemplateName);	

	return Template;
}
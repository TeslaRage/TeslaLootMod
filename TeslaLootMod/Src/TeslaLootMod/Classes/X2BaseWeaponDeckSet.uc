class X2BaseWeaponDeckSet extends X2DataSet config (TLM);

var config array<name> BaseWeaponDecks;

static function array<X2DataTemplate> CreateTemplates ()
{
	local array<X2DataTemplate> Templates;	
	local name TemplateName;
	
	foreach default.BaseWeaponDecks(TemplateName)
	{
		Templates.AddItem(CreateTemplateBaseWeaponDeck(TemplateName));
	}

	return Templates;
}

static function X2BaseWeaponDeckTemplate CreateTemplateBaseWeaponDeck (name TemplateName)
{
	local X2BaseWeaponDeckTemplate Template;

	`CREATE_X2TEMPLATE(class'X2BaseWeaponDeckTemplate', Template, TemplateName);	

	return Template;
}
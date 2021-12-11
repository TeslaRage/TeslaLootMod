class X2BaseWeaponDeckTemplate extends X2DataTemplate config(TLM);

struct BaseItemData{
	var name TemplateName;
	var name RequiredTech;
	var name ForcedRarity;
	var string Image;
};

var config int Tier;
var config array<name> TechsToUnlock;
var config array<BaseItemData> BaseItems;

function array<name> GetBaseItems()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemMan;
	local BaseItemData BaseItem;
	local X2ItemTemplate ItemTemplate;
	local array<name> BaseItemsTemplateNames;

	XComHQ = `XCOMHQ;
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach BaseItems(BaseItem)
	{
		if (!XComHQ.IsTechResearched(BaseItem.RequiredTech) && BaseItem.RequiredTech != '') continue;
		
		ItemTemplate = ItemMan.FindItemTemplate(BaseItem.TemplateName);
		if (ItemTemplate == none) continue;

		BaseItemsTemplateNames.AddItem(BaseItem.TemplateName);
	}

	return BaseItemsTemplateNames;
}

function string GetImage(name TemplateName)
{
	local int Idx;

	Idx = BaseItems.Find('TemplateName', TemplateName);
	if (Idx == INDEX_NONE) return "";

	return BaseItems[Idx].Image;
}

function name GetForcedRarity(name TemplateName)
{
	local int Idx;

	Idx = BaseItems.Find('TemplateName', TemplateName);
	if (Idx == INDEX_NONE) return '';

	return BaseItems[Idx].ForcedRarity;
}
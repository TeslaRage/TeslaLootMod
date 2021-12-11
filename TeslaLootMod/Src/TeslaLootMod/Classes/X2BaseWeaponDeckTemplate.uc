class X2BaseWeaponDeckTemplate extends X2DataTemplate config(TLM);

struct BaseItemData{
	var name TemplateName;
	var name ForcedRarity;
	var string Image;
	var StrategyRequirement Requirements;	
};

var config int Tier;
var config StrategyRequirement Requirements;
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
		if (!XComHQ.MeetsAllStrategyRequirements(BaseItem.Requirements)) continue;
		
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
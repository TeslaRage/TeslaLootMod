class X2BaseWeaponDeckTemplate extends X2DataTemplate config(TLM);

var config int Tier;
var config StrategyRequirement Requirements;
var config array<BaseItemData> BaseItems;

function array<name> GetBaseItems(X2RarityTemplate RarityTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemMan;
	local BaseItemData BaseItem;
	local X2ItemTemplate ItemTemplate;
	local name ForcedRarityName;
	local array<name> BaseItemsTemplateNames;

	XComHQ = `XCOMHQ;
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach BaseItems(BaseItem)
	{		
		if (!XComHQ.MeetsAllStrategyRequirements(BaseItem.Requirements)) continue;
		
		ItemTemplate = ItemMan.FindItemTemplate(BaseItem.TemplateName);
		if (ItemTemplate == none) continue;

		ForcedRarityName = GetForcedRarity(ItemTemplate.DataName);
		if (ForcedRarityName != '' && ForcedRarityName != RarityTemplate.DataName) continue;
		
		BaseItemsTemplateNames.AddItem(BaseItem.TemplateName);
	}

	return BaseItemsTemplateNames;
}

function string GetImage(name TemplateName)
{
	local int Idx;

	Idx = BaseItems.Find('TemplateName', TemplateName);

	if (Idx != INDEX_NONE)
	{
		return BaseItems[Idx].Image;
	}	

	return "";
}

function name GetForcedRarity(name TemplateName)
{
	local int Idx;

	Idx = BaseItems.Find('TemplateName', TemplateName);

	if (Idx != INDEX_NONE)
	{
		return BaseItems[Idx].ForcedRarity;
	}

	return '';
}
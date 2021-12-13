class X2BaseWeaponDeckTemplate extends X2DataTemplate config(TLM);

var config int Tier;
var config StrategyRequirement Requirements;
var config array<BaseItemData> BaseItems;

function array<name> GetBaseItems(X2RarityTemplate RarityTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemMan;
	local BaseItemData BaseItem;
	local X2ItemTemplate ItemTemplate, SchematicTemplate;	
	local name ForcedRarityName;
	local array<name> BaseItemsTemplateNames;

	XComHQ = `XCOMHQ;
	ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	

	foreach BaseItems(BaseItem)
	{	
		ItemTemplate = ItemMan.FindItemTemplate(BaseItem.TemplateName);
		if (ItemTemplate == none) continue;

		// Individually built items requirement check
		if (!XComHQ.MeetsAllStrategyRequirements(ItemTemplate.Requirements))
		{
			continue;
		}

		// Pipu still playing with schematics requirement check
		if (ItemTemplate.CreatorTemplateName != '')
		{
			SchematicTemplate = ItemMan.FindItemTemplate(ItemTemplate.CreatorTemplateName);
			if (SchematicTemplate != none)
			{
				if (!XComHQ.MeetsAllStrategyRequirements(SchematicTemplate.Requirements))
				{
					continue;
				}
			}
		}

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

function bool ValidateTemplate (out string strError)
{
	if (!super.ValidateTemplate(strError))
	{
		return false;
	}

	if (BaseItems.Length == 0)
	{
		strError = "BaseItems is empty so no item can be chosen during item generation";
		// return false;
	}

	return true;
}
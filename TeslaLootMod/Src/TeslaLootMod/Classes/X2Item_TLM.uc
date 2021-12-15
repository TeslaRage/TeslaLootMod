class X2Item_TLM extends X2Item_DefaultResources config(TLM);

var config array<LootBoxData> LootBoxes;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Resources;
	local LootBoxData LootBox;

	foreach default.LootBoxes(LootBox)
	{
		Resources.AddItem(CreateLockBox(LootBox.LootBoxName));
	}
    Resources.AddItem(CreateLockboxKey());

   	return Resources;
}

static function X2DataTemplate CreateLockboxKey()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'LockboxKey');
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Supplies";
	Template.strInventoryImage = "img:///UILibrary_XPACK_StrategyImages.Invx_Supplies";
	Template.ItemCat = 'resource';

	return Template;
}

static function X2DataTemplate CreateLockBox(name TemplateName)
{
	local X2ItemTemplate_LootBox Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate_LootBox', Template, TemplateName);

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventDatapad';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Storage_Module";
	Template.ItemCat = 'utility';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.TradingPostValue = 40;

	return Template;
}
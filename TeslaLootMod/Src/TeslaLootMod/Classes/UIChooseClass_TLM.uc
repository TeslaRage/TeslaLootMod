//----------------------------------------------------------------------------
//  FILE:    UIChooseClass_TLM.uc by TeslaRage && RustyDios
//
//	Created:	xx/xx/22	00:00
//	Updated:	02/07/22	10:30
//
//  PURPOSE: Custom Loot Panel item Menu for Tesla Loot Mod
//
//----------------------------------------------------------------------------

class UIChooseClass_TLM extends UIScreen config (TLM);

var XComGameState_Tech Tech;
var X2RarityTemplate RarityTemplate;
var XComGameState TempGameState;

var config int NumOfCategoriesToChooseFrom;
var config array<CatEnumData> CatToEnum;
var array<name> SelectedCategories;

var init localized string CatLabels[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;
var init localized string CatDescriptions[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;
var init localized string CatImages[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;

var localized string m_strTitle, m_strSubTitleTitle;
var localized string m_strInventoryLabel, m_strEmptyListTitle;
var localized string m_strTopObtained, m_strEquippedOn, m_strAvailable;

var XComGameStateHistory History;
var XComGameState_HeadquartersXCom XComHQ;
var name DisplayTag, CameraTag;

var UIPanel ScreenContainer, ListContainer, SplitLine;
var UIBGBox ScreenBG;
var UIX2PanelHeader TitleHeader;

var UIList List;
//var UIListItemString_TLM ListItem;

var array<Commodity>	arrItems;
var int					iSelectedItem;
var bool 				bSelectFirstAvailable;
var name 				InventoryListName;

// Set this to specify how long camera transition should take for this screen
var float OverrideInterpTime;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	INIT SCREEN
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);

	BuildScreen();
	UpdateNavHelp();

	GetItems();
	PopulateData();

	//select first selection
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	Navigator.SetSelected(List);
	List.Navigator.SetSelected(List);
	List.SetSelectedIndex(0);

	if( bIsIn3D )
	{
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	BUILD NEW SCREEN ELEMENTS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function BuildScreen()
{
	local int MyX, MyY, MyW, MyH;

	MyX = 430;  MyY = 150;  MyW = 1065;  MyH = 750;

	//box to hold all the elements
	ScreenContainer = Spawn(class'UIPanel', self);
	ScreenContainer.InitPanel();

	//large background
	ScreenBG = Spawn(class'UIBGBox', ScreenContainer);
	ScreenBG.bAnimateOnInit = false;
	ScreenBG.InitPanel('BG1', class'UIUtilities_Controls'.const.MC_X2Background);
	ScreenBG.SetSize(MyW, MyH);
	ScreenBG.SetPosition(MyX, MyY);

	//main title
	TitleHeader = Spawn(class'UIX2PanelHeader', ScreenContainer);
	TitleHeader.InitPanelHeader('TitleHeader', m_strTitle, m_strSubTitleTitle);
	TitleHeader.SetHeaderWidth(MyW -10);
	TitleHeader.SetPosition(MyX +5, MyY +5);
	if( m_strTitle == "" && m_strSubTitleTitle == "" )
	{
		TitleHeader.Hide();
	}

	//setup a 'linebreak'
	SplitLine = Spawn(class'UIPanel', ScreenContainer);
	SplitLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
    SplitLine.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );
    SplitLine.SetAlpha( 15 );
	SplitLine.SetSize( MyW -10, 2 );
    SplitLine.SetPosition(MyX +5, MyY +46);

	//box to hold the list
	ListContainer = Spawn(class'UIPanel', self);
	ListContainer.InitPanel('InventoryContainer');
	ListContainer.SetPosition(MyX +5, MyY +15);

	//the list
	List = Spawn(class'UIList', ListContainer);
	List.bAnimateOnInit = false;
	List.bCenterNoScroll = true;
	List.ScrollbarPadding = -10;
	List.InitList(InventoryListName,,,,,true);	//true = List.bIsHorizontal = true;
	List.OnItemClicked = OnItemChoiceMade;
	List.OnSelectionChanged = SelectedItemChanged;
	List.bStickyHighlight = true;
	List.SetSize(MyW -20, MyH -86);
	List.ShrinkToFit();
	List.SetPosition(15, 50);

	// send mouse scroll events to the list
	ScreenBG.ProcessMouseEvents(List.OnChildMouseEvent);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	POPULATE DATA FIELDS OF COMMODITY ITEMS -- FILL LIST
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function PopulateData()
{
	local UIListItemString_TLM ListItem;
	local Commodity Template;
	local int i;

	List.ClearItems();
	List.bSelectFirstAvailable = false;
	
	//for each item in the list spawn a new item card
	for(i = 0; i < arrItems.Length; i++)
	{
		Template = arrItems[i];
	
		ListItem = UIListItemString_TLM(List.GetItem(i));
		if (ListItem == none)
		{
			ListItem = Spawn(class'UIListItemString_TLM', List.ItemContainer);
			ListItem.InitTLMListItem('' ,Template.Title, Template.Image, Template.Desc);
		}

		//colour entry based on rarity template
		if (RarityTemplate.RarityColor != "")
		{
			ListItem.SetCustomColor(Repl(RarityTemplate.RarityColor,"#",""), 22);
		}
		
		ListItem.SetImage(Template.Image);
		ListItem.SetText( Template.Desc );
		ListItem.SetTitle(Template.Title); //set title also sets realized state, as in: we're all done
	}

	//cull the list from the backend whilst list items is more than current abilities
	while (List.GetItemCount() > arrItems.Length)
	{
		List.GetItem(List.GetItemCount() - 1).Remove();
	}

	OnListItemsRealized();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	UPDATE LIST ELEMENTS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function OnListItemsRealized()
{
	local UIListItemString_TLM ListItem;
	local int i;

	for (i = 0 ; i < List.GetItemCount() ; i++)
	{
		ListItem = UIListItemString_TLM(List.GetItem(i));
		if(!ListItem.bSizeRealized) { return; }
	}

	List.RealizeItems();
	List.RealizeList();

	//now the list is sorted move the scrollbar (if it exists) to be clickable
	if (List.Scrollbar != none)
	{
		List.Scrollbar.MoveToHighestDepth();
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	CONSTRUCT ITEMS TO LIST COMMODITIES
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function GetItems()
{
	arrItems = ConvertOptionsToCommodities();
}

simulated function array<Commodity> ConvertOptionsToCommodities()
{
	local XComGameState NewGameState;

	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local X2ItemTemplateManager ItemMan;

	local array<BaseItemData> BaseItems;
	local BaseItemData BaseItem;
	local X2ItemTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;

	local array<Commodity> arrCommodoties;
	local Commodity StatsComm;

	local ETLMCatType CatType;
	local array<name> Categories;
	local int i, Idx;

	BWMan = class'X2BaseWeaponDeckTemplateManager'.static.GetBaseWeaponDeckTemplateManager();
	BWTemplate = BWMan.DetermineBaseWeaponDeck();
	
	if (BWTemplate != none)
	{
		ItemMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	
		RarityTemplate = X2ItemTemplate_LootBox(ItemMan.FindItemTemplate(X2TechTemplate_TLM(Tech.GetMyTemplate()).LootBoxToUse)).RollRarity();

		if (RarityTemplate != none)
		{
			// If the setup is to pick up no categories, skip this block
			if (default.NumOfCategoriesToChooseFrom != 0)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Generate Items (TEMP)");
				BaseItems = BWTemplate.GetBaseItems(RarityTemplate, NewGameState);
				`XCOMHISTORY.CleanupPendingGameState(NewGameState);

				foreach BaseItems(BaseItem)
				{
					ItemTemplate = ItemMan.FindItemTemplate(BaseItem.TemplateName);

					if (ItemTemplate == none) continue;

					if (ItemTemplate.ItemCat == 'weapon')
					{
						WeaponTemplate = X2WeaponTemplate(ItemTemplate);

						if (WeaponTemplate != none)
						{
							if (Categories.Find(WeaponTemplate.WeaponCat) == INDEX_NONE)
								Categories.AddItem(WeaponTemplate.WeaponCat);
						}
					}
					else
					{
						if (Categories.Find(ItemTemplate.ItemCat) == INDEX_NONE)
							Categories.AddItem(ItemTemplate.ItemCat);
					}
				}
			}

			// Full random is always the first option
			SelectedCategories.AddItem('TLMRandom');

			// < 0 means show all categories. 0 means just the Random.
			if (default.NumOfCategoriesToChooseFrom < 0)
			{
				for (i = 0; i < Categories.Length; i++)
				{
					SelectedCategories.AddItem(Categories[i]);
				}
			}
			else
			{
				// Init
				i = 0;

				// While we have less categories than we want, add more until either full or no more categories
				while (i < default.NumOfCategoriesToChooseFrom && Categories.Length > 0)
				{
					Idx = `SYNC_RAND_STATIC(Categories.Length);
					SelectedCategories.AddItem(Categories[Idx]);
					Categories.Remove(Idx, 1);
					i++;
				}
			}

			// Convert selected cats into commodity items to return
			for (i = 0; i < SelectedCategories.Length; i++)
			{
				CatType = DetermineECAT(SelectedCategories[i]);
				
				StatsComm.Title = CatType == eCat_Unknown ? string(SelectedCategories[i]) : CatLabels[CatType];
				StatsComm.Image = "img:///" $ CatImages[CatType];
				StatsComm.Desc = CatDescriptions[CatType] $AppendAdditionalInfo(SelectedCategories[i]);
				arrCommodoties.AddItem(StatsComm);
			}
		}
	}

	return arrCommodoties;
}

simulated function string AppendAdditionalInfo(name Category)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local XComGameState_Unit Unit;
	local string AdditionalInfo, ItemIcon;

	// Start build of details of items we currently own
	Items = Class'X2Helper_TLM'.static.GetTLMItemsByCategory(Category);

	if (Items.Length > 0)
	{
		ItemIcon = class'UIUtilities_Text'.static.InjectImage("img:///UILibrary_XPACK_StrategyImages.MissionIcon_SupplyDrop",  20, 20, -5);
		AdditionalInfo @= m_strTopObtained;

		foreach Items(Item)
		{
			// AdditionalInfo @= "<Bullet/>"; // does not show on screen
			// Item template friendly name
			AdditionalInfo $= ItemIcon @Item.GetMyTemplate().GetItemFriendlyName();

			// If item has nickname, show it
			if (Item.Nickname != "")
			{
				AdditionalInfo @= "(" $Item.Nickname $")";
			}

			// Show list of upgrades currently attached
			// if (Item.GetMyWeaponUpgradeCount() > 0)
			// {
			// 	AdditionalInfo @= "- " $class'X2Helper_TLM'.static.GetWeaponUpgradesAsStr(Item, ", ");
			// }

			// If the item is currently equipped on someone, show it
			if (Item.OwnerStateObject.ObjectID != 0)
			{
				Unit = XComGameState_Unit(History.GetGameStateForObjectID(Item.OwnerStateObject.ObjectID));
				if (Unit != none)
				{
					AdditionalInfo @= "[" $m_strEquippedOn @Unit.GetFullName() $"]";
				}
			}
			else
			{
				AdditionalInfo @= m_strAvailable;
			}

			AdditionalInfo $= "\n";
		}
	}

	return AdditionalInfo;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	LIST MANIPULATIONS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIListItemString_TLM ListItem;

	ListItem = UIListItemString_TLM(List.GetItem(ItemIndex));
	
	if( ListItem != none )
	{
		iSelectedItem = ItemIndex;
	}
}

simulated function bool CanAffordItem(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
	{
		return XComHQ.CanAffordCommodity(arrItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

simulated function bool IsItemPurchased(int ItemIndex) { return false; }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	ON SELECTION MADE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

function OnItemChoiceMade(UIList kList, int itemIndex)
{
	local XComGameState NewGameState;
	local XComGameState_Item Item;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local name SelectedCategory;

	XComHQ = `XCOMHQ;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Generate Item for Reward");

	if (itemIndex == 0)
	{
		// Random roll
		SelectedCategory = '';
	}
	else
	{
		SelectedCategory = SelectedCategories[itemIndex];
	}

	Item = class'X2Helper_TLM'.static.GenerateTLMItem(NewGameState, Tech, BWTemplate, SelectedCategory, RarityTemplate);
	
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.PutItemInInventory(NewGameState, Item);
	
	`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', Item, Item, NewGameState);
	
	class'X2StrategyElement_TLM'.static.UIItemReceived(NewGameState, Item, BWTemplate);
	
	`GAMERULES.SubmitGameState(NewGameState);

	OnCancel();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	FIGURE OUT CORRECT CATEGORY OUTPUT BASED ON INPUT
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

function ETLMCatType DetermineECAT(name Category)
{
	local int Idx;

	Idx = default.CatToEnum.Find('Category', Category);

	if (Idx != INDEX_NONE)
	{
		return default.CatToEnum[Idx].CatType;
	}

	return eCat_Unknown;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	SCREEN MANIPULATION
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function OnCancel()
{
	CloseScreen();
	if(bIsIn3D)
		UIMovie_3D(Movie).HideDisplay(DisplayTag);
}

simulated function OnReceiveFocus()
{
	// super.OnReceiveFocus();
	bIsFocused = true;

	if(bHideOnLoseFocus)
		Show();

	if(bIsIn3D)
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, `HQINTERPTIME);	

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	NAV HELP BUTTONS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;

	if(`ISCONTROLLERACTIVE && CanAffordItem(iSelectedItem) && !IsItemPurchased(iSelectedItem))
	{
		NavHelp.AddSelectNavHelp();
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	DEFAULT PROPERTIES
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	Package = "";

	bIsIn3D = false;

	InventoryListName="List";
	OverrideInterpTime = -1;
	bAnimateOnInit = false;
	bSelectFirstAvailable = true;

	InputState = eInputState_Consume;

	bHideOnLoseFocus = false;
	bConsumeMouseEvents = true;	

	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}

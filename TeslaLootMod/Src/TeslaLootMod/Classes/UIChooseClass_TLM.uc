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
var array<name> SelectedCategories;

var init localized string CatLabels[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;
var init localized string CatDescriptions[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;
var init localized string CatImages[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;

var localized string m_strTitle, m_strSubTitleTitle;
var localized string m_strInventoryLabel, m_strEmptyListTitle;

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
	//box to hold all the elements
	ScreenContainer = Spawn(class'UIPanel', self);
	ScreenContainer.InitPanel();

	//large background
	ScreenBG = Spawn(class'UIBGBox', ScreenContainer);
	ScreenBG.bAnimateOnInit = false;
	ScreenBG.InitPanel('BG1', class'UIUtilities_Controls'.const.MC_X2Background);
	ScreenBG.SetSize(1440, 750);
	ScreenBG.SetPosition(250, 150);

	//main title
	TitleHeader = Spawn(class'UIX2PanelHeader', ScreenContainer);
	TitleHeader.InitPanelHeader('TitleHeader', m_strTitle, m_strSubTitleTitle);
	TitleHeader.SetHeaderWidth(1430);
	TitleHeader.SetPosition(255, 155);
	if( m_strTitle == "" && m_strSubTitleTitle == "" )
	{
		TitleHeader.Hide();
	}

	//setup a 'linebreak'
	SplitLine = Spawn(class'UIPanel', ScreenContainer);
	SplitLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
    SplitLine.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );
    SplitLine.SetAlpha( 15 );
	SplitLine.SetSize( 1430, 2 );
    SplitLine.SetPosition(255, 196);

	//box to hold the list
	ListContainer = Spawn(class'UIPanel', self);
	ListContainer.InitPanel('InventoryContainer');
	ListContainer.SetPosition(255, 165);

	//the list
	List = Spawn(class'UIList', ListContainer);
	List.bAnimateOnInit = false;
	List.bCenterNoScroll = true;
	List.ScrollbarPadding = -10;
	List.InitList(InventoryListName,,,,,true);	//true = List.bIsHorizontal = true;
	List.OnItemClicked = OnItemChoiceMade;
	List.OnSelectionChanged = SelectedItemChanged;
	List.bStickyHighlight = true;
	List.SetSize(1400, 664);
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
				StatsComm.Desc = CatDescriptions[CatType];
				arrCommodoties.AddItem(StatsComm);
			}
		}
	}

	return arrCommodoties;
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
	switch (Category)
	{
		case 'rifle': 				return eCat_Rifle; 				break;
		case 'cannon': 				return eCat_Cannon; 			break;
		case 'shotgun': 			return eCat_Shotgun; 			break;
		case 'sniper_rifle': 		return eCat_SniperRifle; 		break;
		case 'grenade_launcher':	return eCat_GrenadeLauncher;	break;
		case 'gremlin': 			return eCat_Gremlin; 			break;
		case 'pistol': 				return eCat_Pistol; 			break;
		case 'psiamp': 				return eCat_PsiAmp; 			break;
		case 'sword': 				return eCat_Sword; 				break;
		case 'vektor_rifle': 		return eCat_VektorRifle; 		break;
		case 'bullpup': 			return eCat_Bullpup; 			break;
		case 'gauntlet': 			return eCat_Gauntlet; 			break;
		case 'sidearm': 			return eCat_Sidearm; 			break;
		case 'wristblade': 			return eCat_Wristblade; 		break;
		case 'sparkrifle': 			return eCat_SparkRifle; 		break;
		case 'smg': 				return eCat_Smg; 				break;
		case 'glaive': 				return eCat_Glaive; 			break;
		case 'chemthrower': 		return eCat_Chemthrower; 		break;
		case 'combatknife': 		return eCat_CombatKnife; 		break;
		case 'shield': 				return eCat_Shield; 			break;
		case 'spark_shield': 		return eCat_SparkShield; 		break;
		case 'canister': 			return eCat_Canister; 			break;
		case 'armor': 				return eCat_Armor; 				break;
		case 'TLMRandom': 			return eCat_Rando; 				break;
		default: 					return eCat_Unknown;
	}
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

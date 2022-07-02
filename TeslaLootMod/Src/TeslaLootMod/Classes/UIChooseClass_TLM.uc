class UIChooseClass_TLM extends UIChooseClass config (TLM);

var XComGameState_Tech Tech;
var array<name> SelectedCategories;
var X2RarityTemplate RarityTemplate;
var XComGameState TempGameState;

var config int NumOfCategoriesToChooseFrom;

var init localized string CatLabels[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;
var init localized string CatDescriptions[ETLMCatType.EnumCount]<BoundEnum=ETLMCatType>;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	Screen = self;
	Movie = InitMovie;
	PC = InitController;

	InitPanel(InitName);

	// Are we displaying in a 3D surface?
	bIsIn3D = Movie.Class == class'UIMovie_3D';
	
	// Setup watch for force hide via cinematics.
	if (PC != none)
	{
		if( Movie.Stack != none && Movie.Stack.bCinematicMode )
			HideForCinematics();
	}
	else
		`warn("UIMovie::BaseInit - PlayerController (PC) == none!");

	Movie.Pres.PlayUISound(eSUISound_MenuOpen);

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);

	BuildScreen();
	UpdateNavHelp();

	// Move and resize list to accommodate label
	List.OnItemDoubleClicked = OnPurchaseClicked;

	SetBuiltLabel("");

	GetItems();

	SetChooseResearchLayout();
	PopulateData();
	UpdateNavHelp(); // bsg-jrebar (4/20/17): Update on Init instead of receive focus

	ItemCard.Hide();
	Navigator.SetSelected(List);
	List.SetSelectedIndex(0);
}

simulated function BuildScreen()
{
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('TitleHeader', m_strTitle, m_strSubTitleTitle);
	TitleHeader.SetHeaderWidth( 580 );
	if( m_strTitle == "" && m_strSubTitleTitle == "" )
		TitleHeader.Hide();

	ListContainer = Spawn(class'UIPanel', self).InitPanel('InventoryContainer');

	ItemCard = Spawn(class'UIItemCard', ListContainer).InitItemCard('ItemCard');

	ListBG = Spawn(class'UIPanel', ListContainer);
	ListBG.InitPanel('InventoryListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList(InventoryListName);
	// List.bIsHorizontal = true;
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	SetCategory(m_strInventoryLabel);
	SetBuiltLabel(m_strTotalLabel);

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	if( bIsIn3D )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);
}

simulated function PopulateData()
{
	local Commodity Template;
	local int i;

	List.ClearItems();
	List.bSelectFirstAvailable = false;
	
	for(i = 0; i < arrItems.Length; i++)
	{
		Template = arrItems[i];
		if(i < m_arrRefs.Length)
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, m_arrRefs[i], GetButtonString(i), m_eStyle, , 126);
		}
		else
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, , GetButtonString(i), m_eStyle, , 126);
		}
	}
}

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local array<Commodity> arrCommodoties;
	local Commodity StatsComm;
	local X2BaseWeaponDeckTemplateManager BWMan;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local X2ItemTemplateManager ItemMan;
	local array<BaseItemData> BaseItems;
	local BaseItemData BaseItem;
	local XComGameState NewGameState;
	local X2ItemTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;
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

			i = 0;
			while (i < default.NumOfCategoriesToChooseFrom && Categories.Length > 0)
			{
				Idx = `SYNC_RAND_STATIC(Categories.Length);
				SelectedCategories.AddItem(Categories[Idx]);
				Categories.Remove(Idx, 1);
				i++;
			}

			SelectedCategories.AddItem('TLMRandom');

			for (i = 0; i < SelectedCategories.Length; i++)
			{
				CatType = DetermineECAT(SelectedCategories[i]);

				StatsComm.Title = (CatType == eCat_Unknown) ? string(SelectedCategories[i]) : CatLabels[CatType];
				StatsComm.Image = "img:///UILibrary_Common.class_rookie";
				StatsComm.Desc = CatDescriptions[CatType];
				arrCommodoties.AddItem(StatsComm);
			}
		}
	}

	return arrCommodoties;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_Item Item;
	local X2BaseWeaponDeckTemplate BWTemplate;
	local name SelectedCategory;

	XComHQ = `XCOMHQ;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Generate Item for Reward");

	if (iOption == SelectedCategories.Length - 1)
	{
		// Legacy roll
		SelectedCategory = '';
	}
	else
	{
		SelectedCategory = SelectedCategories[iOption];
	}

	Item = class'X2Helper_TLM'.static.GenerateTLMItem(NewGameState, Tech, BWTemplate, SelectedCategory, RarityTemplate);
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.PutItemInInventory(NewGameState, Item);
	`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', Item, Item, NewGameState);
	class'X2StrategyElement_TLM'.static.UIItemReceived(NewGameState, Item, BWTemplate);
	`GAMERULES.SubmitGameState(NewGameState);

	return true;
}

function ETLMCatType DetermineECAT(name Category)
{
	switch (Category)
	{
		case 'shotgun': return eCat_Shotgun; break;
		case 'cannon': return eCat_Cannon; break;
		case 'pistol': return eCat_Pistol; break;
		case 'sniper_rifle': return eCat_SniperRifle; break;
		case 'rifle': return eCat_Rifle; break;
		case 'vektor_rifle': return eCat_VektorRifle; break;
		case 'bullpup': return eCat_Bullpup; break;
		case 'sidearm': return eCat_Sidearm; break;
		case 'sparkrifle': return eCat_SparkRifle; break;
		case 'smg': return eCat_Smg; break;
		case 'gremlin': return eCat_Gremlin; break;
		case 'grenade_launcher': return eCat_GrenadeLauncher; break;
		case 'psiamp': return eCat_PsiAmp; break;
		case 'sword': return eCat_Sword; break;
		case 'combatknife': return eCat_CombatKnife; break;
		case 'gauntlet': return eCat_Gauntlet; break;
		case 'wristblade': return eCat_Wristblade; break;
		case 'glaive': return eCat_Glaive; break;
		case 'shield': return eCat_Shield; break;
		case 'spark_shield': return eCat_SparkShield; break;
		case 'armor': return eCat_Armor; break;
		case 'TLMRandom': return eCat_Rando; break;
		default: return eCat_Unknown;
	}
}

//----------------------------------------------------------------
simulated function OnCancel()
{
	// Do nothing
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

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
	// bConsumeMouseEvents = true;	

	// DisplayTag="UIDisplay_Academy"
	// CameraTag="UIDisplay_Academy"
}

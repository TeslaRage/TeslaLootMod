class UIChooseClass_TLM extends UIChooseClass;

var array<XComGameState_Item> m_arrItems;

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local array<Commodity> arrCommodoties;
	local Commodity StatsComm;
    // local StatForConditioning stStatForConditioning;
    local XGParamTag LocTag;
    local XComGameState_Unit UnitState;
	local XComGameState_Item Item;
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local array<string> arrString;
	local string strTemp;
    // local int j;
    
    // UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_UnitRef.ObjectID));

    // LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	
    // foreach default.arrStatForConditioning(stStatForConditioning)
    // {
    //     j = class'XComGameStateContext_HeadquartersOrderCS'.default.arrStatRanges.find('Stat', stStatForConditioning.Stat);

    //     LocTag.StrValue0 = class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[stStatForConditioning.Stat];   
    //     LocTag.StrValue1 = UnitState.GetCombatIntelligenceLabel(); 
    //     LocTag.IntValue0 = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.default.arrComIntBonus[UnitState.ComInt];                
    //     LocTag.IntValue1 = class'XComGameStateContext_HeadquartersOrderCS'.default.arrStatRanges[j].MinBonus;
    //     LocTag.IntValue2 = class'XComGameStateContext_HeadquartersOrderCS'.default.arrStatRanges[j].MaxBonus;

    //     StatsComm.Title = LocTag.StrValue0 @m_strStatTitle;
    //     StatsComm.Image = stStatForConditioning.img;
    //     StatsComm.Desc = `XEXPAND.ExpandString(m_strStatDesc);
    //     StatsComm.OrderHours = class'X2DownloadableContentInfo_WOTC_SoldierConditioning'.static.GetTrainingDays(UnitState) * 24;
     
    //     arrCommodoties.AddItem(StatsComm);
    // } 

	foreach m_arrItems(Item)
	{
		WUTemplates = Item.GetMyWeaponUpgradeTemplates();

		foreach WUTemplates(WUTemplate)
		{
			strTemp = WUTemplate.GetItemFriendlyName() @"-" @WUTemplate.GetItemBriefSummary();
			arrString.AddItem(strTemp);
		}

		JoinArray(arrString, StatsComm.Desc, "\n");

		StatsComm.Title = Item.Nickname;
		StatsComm.Image = "";
		// StatsComm.Desc = "This item has" @Item.GetMyWeaponUpgradeCount @"upgrades";
		StatsComm.OrderHours = 0;
		
		arrCommodoties.AddItem(StatsComm);
	}


	return arrCommodoties;
}

function bool OnClassSelected(int iOption)
{
	// local XComGameState NewGameState;
	// local XComGameState_FacilityXCom FacilityState;
	// local XComGameState_StaffSlot StaffSlotState;	
	// local XComGameState_HeadquartersProjectConditionSoldier ProjectState;
	// local StaffUnitInfo UnitInfo;		
	
	// FacilityState = XComHQ.GetFacilityByName('RecoveryCenter');	
	// StaffSlotState = FacilityState.GetEmptyStaffSlotByTemplate('TR_ConditionSoldierSlot');
	
	// if (StaffSlotState != none)
	// {
	// 	// The Training project is started when the staff slot is filled. Pass in the NewGameState so the project can be found below.
	// 	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Condition Soldier Slot");
	// 	UnitInfo.UnitRef = m_UnitRef;
	// 	StaffSlotState.FillSlot(UnitInfo, NewGameState);
		
	// 	// Find the new Training Project which was just created by filling the staff slot and set the class		
	// 	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectConditionSoldier', ProjectState)
	// 	{			
    //         ProjectState.ConditionStat = default.arrStatForConditioning[iOption].Stat;			
	// 		break;
	// 	}
		
	// 	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	// 	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");		
	// 	RefreshFacility();
	// }
    return true;
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;	

	DisplayTag="UIBlueprint_LootRecovered"
	CameraTag="UIBlueprint_LootRecovered"
}

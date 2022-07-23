class UIChooseClass_TLMSalvage extends UIChooseClass config (TLM);

var array<XComGameState_Item> Items;
var XComGameState_Tech Tech;

var config array<int> SalvageTier;

var localized string m_strAvailableUpgrades, m_strCloseSalvageScreen, m_strCloseRefund;

simulated function array<Commodity> ConvertClassesToCommodities()
{
	local array<Commodity> arrCommodoties;
	local Commodity ClassComm;
	local XComGameState_Item Item;

	Items = class'X2Helper_TLM'.static.GetTLMItems(, true);

	foreach Items(Item)
	{
		ClassComm.Title = Item.GetMyTemplate().GetItemFriendlyName();
		ClassComm.Image = "img:///UILibrary_Common.Objective_RecoverItem";
		ClassComm.Desc = Item.NickName $"\n" $m_strAvailableUpgrades $"\n" $class'X2Helper_TLM'.static.GetWeaponUpgradesAsStr(Item, ", ");
		// ClassComm.OrderHours = Instant

		arrCommodoties.AddItem(ClassComm);
	}

	return arrCommodoties;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_Item Item, Upgrade, Fragment;
	local X2ItemTemplate FragmentTemplate;
	local array<X2WeaponUpgradeTemplate> WUTemplates, WUTemplatesSave;
	local X2WeaponUpgradeTemplate WUTemplate;
	local XComGameState_ItemData Data;
	local XComGameState_Unit Unit;
	local int ChanceToSalvage, ScrapCount, i;

	Item = Items[iOption];

	if (Item != none)
	{
		WUTemplates = Item.GetMyWeaponUpgradeTemplates();

		// Pick which upgrade to "save"
		foreach WUTemplates(WUTemplate)
		{
			ChanceToSalvage = SalvageTier[WUTemplate.Tier] == 0 ? SalvageTier[SalvageTier.Length - 1] : SalvageTier[WUTemplate.Tier];

			if (`SYNC_RAND_STATIC(100) < ChanceToSalvage)
			{
				WUTemplatesSave.AddItem(WUTemplate);
			}
			else
			{
				// 1 scrap per failed salvage
				ScrapCount++;
			}
		}

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Salvage upgrades");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', `XCOMHQ.ObjectID));
		History = `XCOMHISTORY;

		// Put upgrades into HQ
		foreach WUTemplatesSave(WUTemplate)
		{
			Upgrade = WUTemplate.CreateInstanceFromTemplate(NewGameState);
			XComHQ.PutItemInInventory(NewGameState, Upgrade);
			`HQPRES.UIProvingGroundItemReceived(WUTemplate, Tech.GetReference());
		}

		// We want to touch this item
		Item = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));

		// Strip upgrades and remove nickname
		Item.WipeUpgradeTemplates();
		Item.Nickname = "";

		// Remove this item's status as a TLM item
		Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));
		if (Data != none)
		{
			Item.RemoveComponentObject(Data);
			NewGameState.RemoveStateObject(Data.ObjectID);
		}

		// Destroy the item if not finite
		if (!Item.GetMyTemplate().bInfiniteItem)
		{
			// If equipped on a unit, then need to unequip first before destroying it
			if (Item.OwnerStateObject.ObjectID > 0)
			{
				Unit = XComGameState_Unit(History.GetGameStateForObjectID(Item.OwnerStateObject.ObjectID));
				Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
				Unit.RemoveItemFromInventory(Item, NewGameState);
				Unit.ApplyBestGearLoadout(NewGameState);
			}
			else
			{
				XComHQ.RemoveItemFromInventory(NewGameState, Item.GetReference(), 1);
			}

			// 1 scrap per destroyed item
			ScrapCount++;

			NewGameState.RemoveStateObject(Item.ObjectID);
		}

		FragmentTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('WeaponFragment');

		for (i = 0; i < ScrapCount; i++)
		{
			// Give scraps
			Fragment = FragmentTemplate.CreateInstanceFromTemplate(NewGameState);
			XComHQ.PutItemInInventory(NewGameState, Fragment);
			`HQPRES.UIProvingGroundItemReceived(FragmentTemplate, Tech.GetReference());
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}

	return true;
}

simulated function RefundCosts()
{
	local XComGameState NewGameState;
	local StrategyCost TechCost;
	local array<ArtifactCost> CostsToRefund;
	local ArtifactCost Cost;

	TechCost = Tech.GetMyTemplate().Cost;

	CostsToRefund = TechCost.ResourceCosts;

	foreach TechCost.ArtifactCosts(Cost)
	{
		CostsToRefund.AddItem(Cost);
	}

	if (CostsToRefund.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Refund tech costs");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', `XCOMHQ.ObjectID));

		foreach CostsToRefund(Cost)
		{
			XComHQ.AddResource(NewGameState, Cost.ItemTemplateName, Cost.Quantity);
			`HQPRES.UIProvingGroundItemReceived(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(Cost.ItemTemplateName), Tech.GetReference());
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}
}

simulated function DialogCallback(Name eAction, UICallbackData xUserData)
{
	if (eAction == 'eUIAction_Accept')
	{
		RefundCosts();
		CloseScreen();
	}
}

simulated function OnCancel()
{
	local TDialogueBoxData DialogData;
	local UICallbackData_StateObjectReference CallbackData;

	CallbackData = new class'UICallbackData_StateObjectReference';
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = DialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strCloseSalvageScreen;
	DialogData.strText = m_strCloseRefund;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function OnReceiveFocus()
{
	bIsFocused = true;

	if(bHideOnLoseFocus)
		Show();

	UpdateNavHelp();
	if(bIsIn3D)
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, `HQINTERPTIME);

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = false;

	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}

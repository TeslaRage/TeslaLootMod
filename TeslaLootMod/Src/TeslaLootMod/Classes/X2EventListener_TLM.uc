class X2EventListener_TLM extends X2EventListener;

var localized string strSlotLocked;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

    Templates.AddItem(CreateStrategyListener());

    return Templates;
}

static final function CHEventListenerTemplate CreateStrategyListener()
{
    local CHEventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_TLM_Strategy');

    Template.RegisterInStrategy = true;

    Template.AddCHEvent('OverrideNumUpgradeSlots', OverrideNumUpgradeSlots, ELD_Immediate);
    Template.AddCHEvent('UIArmory_WeaponUpgrade_SlotsUpdated', UIArmory_WeaponUpgrade_SlotsUpdated, ELD_Immediate);

    return Template; 
}

static function EventListenerReturn OverrideNumUpgradeSlots(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
    local XComLWTuple OverrideTuple;
    local XComGameState_Item ItemState;
    local XComGameState_ItemData Data;

    OverrideTuple = XComLWTuple(EventData);
    ItemState = XComGameState_Item(EventSource);

    if (ItemState == none) return ELR_NoInterrupt;    

    // Check if this is our weapon
    Data = XComGameState_ItemData(ItemState.FindComponentObject(class'XComGameState_ItemData'));
    if (Data == none) return ELR_NoInterrupt;

    OverrideTuple.Data[0].i = Data.NumUpgradeSlots; 

    return ELR_NoInterrupt;
}

static function EventListenerReturn UIArmory_WeaponUpgrade_SlotsUpdated(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{    
    local XComGameState_Item Item;
    local XComGameState_ItemData Data;
    local UIArmory_WeaponUpgrade Screen;
    local array<X2WeaponUpgradeTemplate> EquippedUpgrades;
    local UIList SlotsList;
    local int i, NumUpgradeSlots;

    Screen = UIArmory_WeaponUpgrade(EventSource);
    if (Screen == none) return ELR_NoInterrupt;

    Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Screen.WeaponRef.ObjectID));
    if (Item == none) return ELR_NoInterrupt;

    Data = XComGameState_ItemData(Item.FindComponentObject(class'XComGameState_ItemData'));
    if (Data == none) return ELR_NoInterrupt;

    // Disable nickname change/update
    // Screen.GetCustomizeItem(0).bDisabled = true; 
    Screen.GetCustomizeItem(0).SetDisabled(true, "Disabled");

    // Override error message "REQUIRES CONTINENT BONUS"
    SlotsList = UIList(EventData);
    EquippedUpgrades = Item.GetMyWeaponUpgradeTemplates();
    NumUpgradeSlots = Item.GetNumUpgradeSlots();

    for (i = 0; i < EquippedUpgrades.Length; ++i)
	{
        if (i > NumUpgradeSlots - 1)
        {
            UIArmory_WeaponUpgradeItem(SlotsList.GetItem(i)).SetDisabled(false);
            UIArmory_WeaponUpgradeItem(SlotsList.GetItem(i)).SetDisabled(true, class'UIUtilities_Text'.static.GetColoredText(default.strSlotLocked, eUIState_Bad));
        }
	}

    return ELR_NoInterrupt;
}
class X2EventListener_TLM extends X2EventListener;

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

    Data = XComGameState_ItemData(ItemState.FindComponentObject(class'XComGameState_ItemData'));
    if (Data == none) return ELR_NoInterrupt;

    OverrideTuple.Data[0].i = Data.NumUpgradeSlots; 

    return ELR_NoInterrupt;
}
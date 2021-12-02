class X2Ability_TLM extends X2Ability config(TLM);

struct AmmoConversionData
{
	var name Ammo;
	var bool MEWithClipSizeMods;
	var string Image;
};

struct BaseWeaponDeckData
{
	var name Deck;	
	var name BaseWeapon;
	var string Image;
};

var config array<AmmoConversionData> ConvertAmmo;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local AmmoConversionData AmmoConversion;
	local string AbilityName;

	foreach default.ConvertAmmo(AmmoConversion)
	{
		AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;
		Templates.AddItem(AmmoAbility(name(AbilityName)));
	}

	return Templates;
}

static function X2DataTemplate AmmoAbility(name AbilityName)
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_UnitPostBeginPlay PostBeginPlayTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	PostBeginPlayTrigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	PostBeginPlayTrigger.Priority -= 10;        // Lower priority to guarantee ammo modifying effects (e.g. Deep Pockets) already run.
	Template.AbilityTriggers.AddItem(PostBeginPlayTrigger);

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = BuiltInAmmo_BuildGameState;
	Template.BuildVisualizationFn = none;

	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	return Template;
}

simulated function XComGameState BuiltInAmmo_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item AmmoState, WeaponState, NewWeaponState;	
	local X2AmmoTemplate AmmoTemplate;	
	local bool FoundAmmo;

    local name AbilityName;
    local X2AbilityTemplateManager AbilityManager;
    local X2AbilityTemplate AbilityTemplate;
    
    local X2WeaponUpgradeTemplate_TLMAmmo WUATemplateName;
    local X2ItemTemplateManager ItemTemplateManager;    
    local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
    local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);
	AbilityContext = XComGameStateContext_Ability(Context);
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	WeaponState = AbilityState.GetSourceWeapon();
	NewWeaponState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', WeaponState.ObjectID));	

	// Start Issue #393
	// Reset weapon's ammo before further modificiations
	NewWeaponState.Ammo = NewWeaponState.GetClipSize();
	// End Issue #393
      
    ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    WeaponUpgradeTemplates = WeaponState.GetMyWeaponUpgradeTemplates();
    foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
    {
        WUATemplateName = X2WeaponUpgradeTemplate_TLMAmmo(WeaponUpgradeTemplate);
        if (WUATemplateName != none){
            AmmoTemplate = X2AmmoTemplate(ItemTemplateManager.FindItemTemplate(WUATemplateName.AmmoTemplateName));
            if (AmmoTemplate != none) break;
        }
    }    

    if (AmmoTemplate != none)
    {
        FoundAmmo = true;
        AmmoState = AmmoTemplate.CreateInstanceFromTemplate(NewGameState);
        foreach AmmoTemplate.Abilities(AbilityName)
        {
            AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
            AbilityTemplate = AbilityManager.FindAbilityTemplate(AbilityName);
            `TACTICALRULES.InitAbilityForUnit(AbilityTemplate, UnitState, NewGameState,AmmoState.GetReference());			
        }
    }

	if (FoundAmmo)
	{
		NewWeaponState.LoadedAmmo = AmmoState.GetReference();		
        NewWeaponState.Ammo += AmmoTemplate.ModClipSize;
	}

	return NewGameState;
}
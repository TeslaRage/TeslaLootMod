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

struct WeaponAdjustmentData
{
	var name AdjustmentName;	
	var int Damage;
	var int Crit;
	var int Pierce;
	var int Shred;
};

var config array<AmmoConversionData> ConvertAmmo;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local AmmoConversionData AmmoConversion;
	local WeaponAdjustmentData WeaponAdjustmentUpgrade;	
	local string AbilityName;

	// Abilities for ammo upgrades are taken from CLAP mod
	foreach default.ConvertAmmo(AmmoConversion)
	{
		AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;
		Templates.AddItem(AmmoAbility(name(AbilityName)));
	}

	// Abilities for Weapon Refinement upgrades
	foreach class'X2Item_TLMUpgrades'.default.WeaponAdjustmentUpgrades(WeaponAdjustmentUpgrade)
	{
		AbilityName = "TLMAbility_" $WeaponAdjustmentUpgrade.AdjustmentName;
		Templates.AddItem(AdjustmentAbility(name(AbilityName), WeaponAdjustmentUpgrade));
	}

	return Templates;
}

static function X2DataTemplate AmmoAbility(name AbilityName)
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_UnitPostBeginPlay PostBeginPlayTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	PostBeginPlayTrigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	PostBeginPlayTrigger.Priority -= 10;		// Lower priority to guarantee ammo modifying effects (e.g. Deep Pockets) already run.
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

static function X2DataTemplate AdjustmentAbility(name AbilityName, WeaponAdjustmentData WeaponAdjustmentUpgrade)
{
	local X2AbilityTemplate Template;	
	local X2Effect_TLMEffects TLMEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);	

	TLMEffect = new class'X2Effect_TLMEffects';
	TLMEffect.BuildPersistentEffect(1, true, false, false);
	TLMEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, false,, Template.AbilitySourceName);
	TLMEffect.FlatBonusDamage = WeaponAdjustmentUpgrade.Damage;
	TLMEffect.CritDamage = WeaponAdjustmentUpgrade.Crit;
	TLMEffect.Pierce = WeaponAdjustmentUpgrade.Pierce;
	TLMEffect.Shred = WeaponAdjustmentUpgrade.Shred;
	TLMEffect.FriendlyName = Template.LocFriendlyName;
	Template.AddTargetEffect(TLMEffect);	

	Template.SetUIStatMarkup(class'XLocalizedData'.default.DamageLabel, , TLMEffect.FlatBonusDamage);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.CriticalDamageLabel, , TLMEffect.CritDamage);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.PierceLabel, , TLMEffect.Pierce);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , TLMEffect.Shred);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}
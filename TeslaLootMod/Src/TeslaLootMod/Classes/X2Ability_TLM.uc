class X2Ability_TLM extends X2Ability config(TLM);

var config array<AmmoConversionData> ConvertAmmo;
var config array<RefinementUpgradeAbilityData> RefinementUpgradeAbilities;
var config array<AbilityGivesGRangeData> AbilityGivesGRange;
var config array<AbilityGivesGRadiusData> AbilityGivesGRadius;
var config array<name> GrenadeLaunchAbilities;
var config array<RuptureAbilitiesData> RuptureAbilities;
var config array<SprintReloadAbilitiesData> SprintReloadAbilities;
var config array<ReflexStockAbilitiesData> ReflexStockAbilities;
var config array<FocusScopeAbilitiesData> FocusScopeAbilities;
var config array<FrontLoadAbilitiesData> FrontLoadAbilities;
var config array<RepeaterAltAbilitiesData> RepeaterAltAbilities;

var config int RapidFireCharges;
var config int RapidFireAimPenalty;
var config int RapidFireCooldown;
var config int HailOfBulletsCharges;
var config int HailOfBulletsCooldown;
var config int KillZoneCharges;
var config int KillZoneCooldown;
var config int FaceoffCharges;
var config int FaceoffCooldown;
var config int BonusDamageAdventSoldier;
var config int BonusDamageAlien;

var localized string strAimBonusPerVisibleEnemy;
var localized string strFriendlyNameSingleOut;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local AmmoConversionData AmmoConversion;
	local array<AmmoConversionData> DistinctConvertAmmo;
	local RefinementUpgradeAbilityData RefinementUpgradeAbility;
	local SprintReloadAbilitiesData SprintReloadAbility;
	local ReflexStockAbilitiesData ReflexStockAbility;
	local FocusScopeAbilitiesData FocusScopeAbility;
	local FrontLoadAbilitiesData FrontLoadAbility;
	local RepeaterAltAbilitiesData RepeaterAltAbility;
	local string AbilityName;

	// Abilities for ammo upgrades are taken from CLAP mod
	DistinctConvertAmmo = MakeDistinct(default.ConvertAmmo);
	foreach DistinctConvertAmmo(AmmoConversion)
	{
		if ((class'X2Helper_TLM'.static.IsModLoaded(AmmoConversion.DLC) && AmmoConversion.DLC != '')
			|| AmmoConversion.DLC == '')
		{
			AbilityName = "TLMAAbility_" $AmmoConversion.Ammo;
			Templates.AddItem(AmmoAbility(name(AbilityName)));
		}
	}

	// Abilities for Weapon Refinement upgrades
	foreach default.RefinementUpgradeAbilities(RefinementUpgradeAbility)
	{		
		Templates.AddItem(RefinementAbility(RefinementUpgradeAbility));
	}

	Templates.AddItem(TLMRapidFire());
	Templates.AddItem(TLMRapidFire2());
	Templates.AddItem(TLMHailOfBullets());
	Templates.AddItem(TLMKillZone());
	Templates.AddItem(TLMFaceoff());
	Templates.AddItem(TLMAdventSoldierKiller());
	Templates.AddItem(TLMAlienKiller());
	Templates.AddItem(TLMPassiveAbility('TLMAbility_GrenadeRangeT1', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_GrenadeRangeT2', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_GrenadeRangeT3', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_GrenadeRadiusT1', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_GrenadeRadiusT2', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_GrenadeRadiusT3', "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_RuptureT1', "img:///UILibrary_PerkIcons.UIPerk_bulletshred"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_RuptureT2', "img:///UILibrary_PerkIcons.UIPerk_bulletshred"));
	Templates.AddItem(TLMPassiveAbility('TLMAbility_RuptureT3', "img:///UILibrary_PerkIcons.UIPerk_bulletshred"));

	foreach default.SprintReloadAbilities(SprintReloadAbility)
	{
		Templates.AddItem(TLMSprintReload(SprintReloadAbility.AbilityName, SprintReloadAbility.Charges));
	}

	foreach default.ReflexStockAbilities(ReflexStockAbility)
	{
		Templates.AddItem(TLMReflexStock(ReflexStockAbility));
	}

	foreach default.FocusScopeAbilities(FocusScopeAbility)
	{
		Templates.AddItem(TLMFocusScope(FocusScopeAbility));
	}

	foreach default.FrontLoadAbilities(FrontLoadAbility)
	{
		Templates.AddItem(TLMFrontLoadMag(FrontLoadAbility));
	}

	foreach default.RepeaterAltAbilities(RepeaterAltAbility)
	{
		Templates.AddItem(TLMRepeaterAlt(RepeaterAltAbility));
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

static function X2DataTemplate RefinementAbility(RefinementUpgradeAbilityData RefinementUpgrade)
{
	local X2AbilityTemplate Template;	
	local X2Effect_TLMEffects TLMEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, RefinementUpgrade.AbilityName);

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
	TLMEffect.FlatBonusDamage = RefinementUpgrade.Damage;
	TLMEffect.CritDamage = RefinementUpgrade.Crit;
	TLMEffect.CritDamageMultiplier = RefinementUpgrade.CritDamageMultiplier;
	TLMEffect.Pierce = RefinementUpgrade.Pierce;
	TLMEffect.Shred = RefinementUpgrade.Shred;	
	TLMEffect.MobilityDivisor = RefinementUpgrade.MobilityDivisor;
	TLMEffect.DamagePerMobilityDivisor = RefinementUpgrade.DamagePerMobilityDivisor;
	TLMEffect.FriendlyName = Template.LocFriendlyName;
	Template.AddTargetEffect(TLMEffect);	

	Template.SetUIStatMarkup(class'XLocalizedData'.default.DamageLabel, , TLMEffect.FlatBonusDamage);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.CriticalDamageLabel, , TLMEffect.CritDamage);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.PierceLabel, , TLMEffect.Pierce);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , TLMEffect.Shred);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}

static function X2AbilityTemplate TLMRapidFire()
{
	local X2AbilityTemplate	Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCost_Ammo AmmoCost;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local X2AbilityCooldown Cooldown;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;	

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMAbility_RapidFire');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 0;
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//  require 2 ammo to be present so that both shots can be taken
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 2;
	AmmoCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(AmmoCost);
	//  actually charge 1 ammo for this shot. the 2nd shot will charge the extra ammo.
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.RapidFireCooldown;
	Template.AbilityCooldown = Cooldown;

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.RapidFireCharges;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.BuiltInHitMod = default.RapidFireAimPenalty;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_rapidfire";
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.AdditionalAbilities.AddItem('TLMRapidFire2');
	Template.PostActivationEvents.AddItem('TLMRapidFire2');

	Template.bCrossClassEligible = false;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static function X2AbilityTemplate TLMRapidFire2()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_Ammo AmmoCost;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local X2AbilityTrigger_EventListener Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMRapidFire2');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.BuiltInHitMod = default.RapidFireAimPenalty;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'TLMRapidFire2';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_OriginalTarget;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_rapidfire";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = SequentialShot_MergeVisualization;
	
	Template.bShowActivation = true;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static function X2AbilityTemplate TLMHailOfBullets()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_Ammo AmmoCost;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local X2AbilityCooldown Cooldown;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMAbility_HailOfBullets');

	Template.AbilityCosts.AddItem(default.WeaponActionTurnEnding);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 3;
	Template.AbilityCosts.AddItem(AmmoCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.HailOfBulletsCooldown;
	Template.AbilityCooldown = Cooldown;

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.HailOfBulletsCharges;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.bGuaranteedHit = true;
	ToHitCalc.bAllowCrit = false;
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hailofbullets";
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.bCrossClassEligible = false;
	Template.CinescriptCameraType = "StandardGunFiring";

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static function X2AbilityTemplate TLMKillZone(bool bDisplayZone=false)
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldown Cooldown;
	local X2AbilityCost_Ammo AmmoCost;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityMultiTarget_Cone ConeMultiTarget;
	local X2Effect_ReserveActionPoints ReservePointsEffect;
	local X2Effect_MarkValidActivationTiles MarkTilesEffect;
	local X2Condition_UnitEffects SuppressedCondition;
	local X2Effect_Persistent KillZoneEffect;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMAbility_KillZone');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.KillZoneCooldown;
	Template.AbilityCooldown = Cooldown;

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.KillZoneCharges;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	ConeMultiTarget = new class'X2AbilityMultiTarget_Cone';
	ConeMultiTarget.bUseWeaponRadius = true;
	ConeMultiTarget.ConeEndDiameter = 32 * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.ConeLength = 60 * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityMultiTargetStyle = ConeMultiTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ReservePointsEffect = new class'X2Effect_ReserveActionPoints';
	ReservePointsEffect.ReserveType = class'X2Ability_SharpshooterAbilitySet'.default.KillZoneReserveType;
	Template.AddShooterEffect(ReservePointsEffect);

	MarkTilesEffect = new class'X2Effect_MarkValidActivationTiles';
	MarkTilesEffect.AbilityToMark = 'KillZoneShot';
	MarkTilesEffect.bVisualizeFlagsOnCursor = bDisplayZone;
	Template.AddShooterEffect(MarkTilesEffect);

	if (bDisplayZone)
	{
		// Add persistent effect on shooter to be able to have a callback on load, 
		// so the pathing pawn is notified to display a flag on Killzone tiles on load.
		KillZoneEffect = new class'X2Effect_Persistent';
		KillZoneEffect.EffectName = 'KillZoneSource';
		KillZoneEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
		Template.AddShooterEffect(KillZoneEffect);
	}

	Template.AdditionalAbilities.AddItem('KillZoneShot');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.TargetingMethod = class'X2TargetingMethod_Cone';
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_killzone";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.Hostility = eHostility_Defensive;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.ActivationSpeech = 'KillZone';
	
	Template.bCrossClassEligible = false;
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	
	return Template;
}

static function X2AbilityTemplate TLMFaceoff()
{
	local X2AbilityTemplate Template;
	local X2AbilityCooldown Cooldown;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local X2AbilityMultiTarget_AllUnits MultiTargetUnits;
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMAbility_Faceoff');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_faceoff";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.FaceoffCooldown;
	Template.AbilityCooldown = Cooldown;

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.FaceoffCharges;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.bOnlyMultiHitWithSuccess = false;
	Template.AbilityToHitCalc = ToHitCalc;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	MultiTargetUnits = new class'X2AbilityMultiTarget_AllUnits';
	MultiTargetUnits.bUseAbilitySourceAsPrimaryTarget = true;
	MultiTargetUnits.bAcceptEnemyUnits = true;
	Template.AbilityMultiTargetStyle = MultiTargetUnits;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	Template.AddMultiTargetEffect(new class'X2Effect_ApplyWeaponDamage');

	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_SharpshooterAbilitySet'.static.Faceoff_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.ActivationSpeech = 'Faceoff';

	return Template;
}

static function X2AbilityTemplate TLMAdventSoldierKiller()
{
	local X2AbilityTemplate Template;
	local X2Effect_TLMEffects TLMEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMAbility_AdventSoldierKiller');	

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
	TLMEffect.BonusDamageAdventSoldier = default.BonusDamageAdventSoldier;
	Template.AddTargetEffect(TLMEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

static function X2AbilityTemplate TLMAlienKiller()
{
	local X2AbilityTemplate Template;
	local X2Effect_TLMEffects TLMEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'TLMAbility_AlienKiller');	

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
	TLMEffect.BonusDamageAlien = default.BonusDamageAlien;
	Template.AddTargetEffect(TLMEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

static function X2AbilityTemplate TLMPassiveAbility(name AbilityName, string AbilityIcon)
{
	local X2AbilityTemplate Template;

	Template = CreatePassiveAbility(AbilityName, AbilityIcon, '', false);

	return Template;
}

static function X2AbilityTemplate TLMSprintReload(name AbilityName, float SprintReloadCharge)
{
	local X2AbilityTemplate Template;
	local X2Effect_SetUnitValue SetInitialValue;
	local X2Effect_TLMAbilityListener AbilityListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_long_watch"; 
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;

	SetInitialValue = new class'X2Effect_SetUnitValue';
	SetInitialValue.UnitName = 'TRSprintReloadCharge';
	SetInitialValue.NewValueToSet = SprintReloadCharge;
	SetInitialValue.CleanupType = eCleanup_BeginTactical;
	Template.AddTargetEffect(SetInitialValue);
	
	AbilityListener = new class'X2Effect_TLMAbilityListener';
	AbilityListener.BuildPersistentEffect(1, true, false);
	AbilityListener.EffectName = 'TRSprintReloadEffect';
	AbilityListener.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false,, Template.AbilitySourceName);
	AbilityListener.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(AbilityListener);	

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate TLMReflexStock (ReflexStockAbilitiesData ReflexStockAbility)
{
	local X2AbilityTemplate Template;
	local X2Effect_TLMEffects ReflexStockEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, ReflexStockAbility.AbilityName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_long_watch"; 
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;

	ReflexStockEffect = new class'X2Effect_TLMEffects';
	ReflexStockEffect.AimBonusPerVisibleEnemy = ReflexStockAbility.AimBonusPerVisibleEnemy;
	ReflexStockEffect.MaxAimBonus = ReflexStockAbility.MaxAimBonus;
	ReflexStockEffect.FriendlyNameAimBonusPerVisibleEnemy = default.strAimBonusPerVisibleEnemy;
	Template.AddTargetEffect(ReflexStockEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate TLMFocusScope (FocusScopeAbilitiesData FocusScopeAbility)
{
	local X2AbilityTemplate Template;
	local X2Effect_TLMEffects FocusScopeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, FocusScopeAbility.AbilityName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_long_watch"; 
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;

	FocusScopeEffect = new class'X2Effect_TLMEffects';
	FocusScopeEffect.SingleOutAimBonus = FocusScopeAbility.SingleOutAimBonus;
	FocusScopeEffect.SingleOutCritChanceBonus = FocusScopeAbility.SingleOutCritChanceBonus;
	FocusScopeEffect.FriendlyNameSingleOut = default.strFriendlyNameSingleOut;
	Template.AddTargetEffect(FocusScopeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate TLMFrontLoadMag (FrontLoadAbilitiesData FrontLoadAbility)
{
	local X2AbilityTemplate Template;
	local X2Effect_TLMEffects FrontLoadEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, FrontLoadAbility.AbilityName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_long_watch"; 
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;

	FrontLoadEffect = new class'X2Effect_TLMEffects';
	FrontLoadEffect.FullAmmoDamageModifier = FrontLoadAbility.FullAmmoDamageModifier;
	FrontLoadEffect.NotFullAmmoDamageModifier = FrontLoadAbility.NotFullAmmoDamageModifier;
	FrontLoadEffect.FriendlyName = Template.LocFriendlyName;
	Template.AddTargetEffect(FrontLoadEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate TLMRepeaterAlt (RepeaterAltAbilitiesData RepeaterAltAbility)
{
	local X2AbilityTemplate Template;
	local X2Effect_TLMEffects RepeaterAltEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, RepeaterAltAbility.AbilityName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_long_watch"; 
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;

	RepeaterAltEffect = new class'X2Effect_TLMEffects';
	RepeaterAltEffect.BonusDamageWhenEffected = RepeaterAltAbility.BonusDamageWhenEffected;
	RepeaterAltEffect.EffectsToApplyBonusDamage = RepeaterAltAbility.EffectsToApplyBonusDamage;
	RepeaterAltEffect.FriendlyName = Template.LocFriendlyName;
	Template.AddTargetEffect(RepeaterAltEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

// HELPERS
static function array<AmmoConversionData> MakeDistinct(array<AmmoConversionData> ConfigAmmoConversion)
{
	local array<AmmoConversionData> DistinctAmmoConversion;
	local AmmoConversionData AmmoConversion;

	foreach ConfigAmmoConversion(AmmoConversion)
	{
		if (DistinctAmmoConversion.Find('Ammo', AmmoConversion.Ammo) == INDEX_NONE)
		{
			DistinctAmmoConversion.AddItem(AmmoConversion);			
		}
	}

	return DistinctAmmoConversion;
}

static function X2AbilityTemplate CreatePassiveAbility(name AbilityName, optional string IconString, optional name IconEffectName = AbilityName, optional bool bDisplayIcon = true)
{	
	local X2AbilityTemplate Template;
	local X2Effect_Persistent IconEffect;	

	`CREATE_X2ABILITY_TEMPLATE (Template, AbilityName);
	Template.IconImage = IconString;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bCrossClassEligible = false;
	Template.bUniqueSource = true;
	Template.bIsPassive = true;

	// Dummy effect to show a passive icon in the tactical UI for the SourceUnit
	IconEffect = new class'X2Effect_Persistent';
	IconEffect.BuildPersistentEffect(1, true, false);
	IconEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, bDisplayIcon,, Template.AbilitySourceName);
	IconEffect.EffectName = IconEffectName;
	Template.AddTargetEffect(IconEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}
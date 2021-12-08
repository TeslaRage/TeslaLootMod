// This class is meant to house basic weapon altering effects
class X2Effect_TLMEffects extends X2Effect_Persistent;

var float DamageMultiplier;
var int FlatBonusDamage;
var int Pierce;
var int Shred;
var int CritChance;
var int CritDamage;
var int BonusDamageAdventSoldier;
var int BonusDamageAlien;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;
	local XComGameState_Item SourceWeapon;
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(TargetDamageable);
	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && DamageMultiplier != 0)
		{
			ExtraDamage = CurrentDamage * DamageMultiplier;
		}

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && FlatBonusDamage != 0)
		{
			ExtraDamage += FlatBonusDamage;
		}

		if (AppliedData.AbilityResultContext.HitResult == eHit_Crit && CritDamage != 0)
		{		
			ExtraDamage += CritDamage;		
		}

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && BonusDamageAdventSoldier != 0)
		{
			if (Unit.GetMyTemplate().bIsAdvent && !Unit.GetMyTemplate().bIsRobotic)
				ExtraDamage += BonusDamageAdventSoldier;
		}

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && BonusDamageAlien != 0)
		{
			if (Unit.GetMyTemplate().bIsAlien && !Unit.GetMyTemplate().bIsRobotic)
				ExtraDamage += BonusDamageAlien;
		}
	}

	return int(ExtraDamage);
}

function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData)
{	
	local XComGameState_Item SourceWeapon;

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		return Pierce;
	}
	return 0;
}

function int GetExtraShredValue(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData)
{
	local XComGameState_Item SourceWeapon;

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		return Shred;
	}
	return 0;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ModInfo;	
	local XComGameState_Item SourceWeapon;

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		if (CritChance != 0)
		{
			ModInfo.ModType = eHit_Crit;
			ModInfo.Reason = FriendlyName;
			ModInfo.Value = CritChance;
			ShotModifiers.AddItem(ModInfo);
		}
	}
}
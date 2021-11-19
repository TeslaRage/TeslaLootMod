class X2Effect_TLMEffects extends X2Effect_Persistent;

var float DamageMultiplier;
var int FlatBonusDamage;
var int Pierce;
var int Shred;
var int CritChance;
var int CritDamage;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;

	if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && DamageMultiplier > 0)
	{
		ExtraDamage = CurrentDamage * DamageMultiplier;
	}

    if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && FlatBonusDamage > 0)
    {
        ExtraDamage += FlatBonusDamage;
    }

    if (AppliedData.AbilityResultContext.HitResult == eHit_Crit && CritDamage > 0)
	{		
        ExtraDamage += CritDamage;		
	}

	return int(ExtraDamage);
}

function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData)
{	
    return Pierce;
}

function int GetExtraShredValue(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData)
{
    return Shred;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ModInfo;	
	
	if (CritChance > 0)
	{
		ModInfo.ModType = eHit_Crit;
		ModInfo.Reason = FriendlyName;
		ModInfo.Value = CritChance;
		ShotModifiers.AddItem(ModInfo);
	}
}
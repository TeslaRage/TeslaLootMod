// This class is meant to house basic weapon altering effects
class X2Effect_TLMEffects extends X2Effect_Persistent;

// Individual properties
var float DamageMultiplier;
var int FlatBonusDamage;
var int Pierce;
var int Shred;
var int CritChance;
var int CritDamage;
var float CritDamageMultiplier;
var int BonusDamageAdventSoldier;
var int BonusDamageAlien;
var int FullAmmoDamageModifier;
var int NotFullAmmoDamageModifier;

// These should be used together
var int MobilityDivisor;
var int DamagePerMobilityDivisor;

// These should be used together
var int AimBonusPerVisibleEnemy;
var int MaxAimBonus;
var string FriendlyNameAimBonusPerVisibleEnemy;

// These should be used together
var int SingleOutAimBonus;
var int SingleOutCritChanceBonus;
var string FriendlyNameSingleOut;

// These should be used together
var int BonusDamageWhenEffected;
var array<name> EffectsToApplyBonusDamage;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;
	local XComGameState_Item SourceWeapon;
	local XComGameState_Unit Unit;
	local XComGameState_Ability AbilityfromEffectState;
	local name QualifiedEffectName;
	local bool bLog;

	bLog = class'X2DownloadableContentInfo_TeslaLootMod'.default.bLog;

	`LOG("IsHitResultHit:" $class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult), bLog, 'TLMDEBUG');
	`LOG("HitResult:" $class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[AppliedData.AbilityResultContext.HitResult], bLog, 'TLMDEBUG');

	Unit = XComGameState_Unit(TargetDamageable);
	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		`LOG("AbilityState: " $AbilityState.GetMyTemplateName() @"Ability from effectstate: " $EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID, bLog, 'TLMDEBUG');
		`LOG("Effectstate: " $EffectState.ObjectID, bLog, 'TLMDEBUG');
		`LOG("BonusDamageWhenEffected: " $BonusDamageWhenEffected, bLog, 'TLMDEBUG');

		AbilityfromEffectState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityfromEffectState != none)
		{
			`LOG("AbilityfromEffectState: " $AbilityfromEffectState.GetMyTemplateName(), bLog, 'TLMDEBUG');
		}

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

		if (AppliedData.AbilityResultContext.HitResult == eHit_Crit && CritDamageMultiplier > 0)
		{			
			ExtraDamage += (CurrentDamage * CritDamageMultiplier);
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

		if (AppliedData.AbilityResultContext.HitResult == eHit_Crit && MobilityDivisor > 0)
		{			
			ExtraDamage += ((Unit.GetCurrentStat(eStat_Mobility) / MobilityDivisor) * DamagePerMobilityDivisor);
		}

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && FullAmmoDamageModifier != 0)
		{
			if (SourceWeapon.Ammo == SourceWeapon.GetClipSize() && SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon)
			{
				ExtraDamage += FullAmmoDamageModifier;
			}			
		}

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && NotFullAmmoDamageModifier != 0)
		{
			if (SourceWeapon.Ammo < SourceWeapon.GetClipSize())
			{
				ExtraDamage += NotFullAmmoDamageModifier;
			}
		}

		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && BonusDamageWhenEffected != 0)
		{
			foreach EffectsToApplyBonusDamage(QualifiedEffectName)
			{
				if (Unit.IsUnitAffectedByEffectName(QualifiedEffectName))
				{
					ExtraDamage += BonusDamageWhenEffected;
					break;
				}
			}
		}
	}

	return round(ExtraDamage);
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
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID
		&& class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult))
	{
		return Shred;
	}
	return 0;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ModInfo;	
	local XComGameState_Item SourceWeapon;
	local int NumOfEnemies, AimBonus;

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

		if (AimBonusPerVisibleEnemy != 0)
		{			
			NumOfEnemies = Attacker.GetNumVisibleEnemyUnits(true, false, false, -1, false, false, false);
			if (NumOfEnemies > 0)
			{
				AimBonus = NumOfEnemies * AimBonusPerVisibleEnemy;
				if (AimBonus > MaxAimBonus) AimBonus = MaxAimBonus;

				ModInfo.ModType = eHit_Success;
				ModInfo.Reason = FriendlyNameAimBonusPerVisibleEnemy == "" ? FriendlyName : FriendlyNameAimBonusPerVisibleEnemy;
				ModInfo.Value = AimBonus;
				ShotModifiers.AddItem(ModInfo);
			}
		}

		if (SingleOutAimBonus != 0)
		{
			NumOfEnemies = Attacker.GetNumVisibleEnemyUnits(true, false, false, -1, false, false, false);
			if (NumOfEnemies == 1)
			{
				ModInfo.ModType = eHit_Success;
				ModInfo.Reason = FriendlyNameSingleOut == "" ? FriendlyName : FriendlyNameSingleOut;
				ModInfo.Value = SingleOutAimBonus;
				ShotModifiers.AddItem(ModInfo);

				ModInfo.ModType = eHit_Crit;
				ModInfo.Reason = FriendlyNameSingleOut == "" ? FriendlyName : FriendlyNameSingleOut;
				ModInfo.Value = SingleOutCritChanceBonus;
				ShotModifiers.AddItem(ModInfo);
			}
		}
	}
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
}

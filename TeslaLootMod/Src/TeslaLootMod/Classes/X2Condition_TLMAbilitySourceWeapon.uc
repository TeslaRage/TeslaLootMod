// Currently not used
class X2Condition_TLMAbilitySourceWeapon extends X2Condition;

var bool bCheckForReloadUpgrade;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameState_Item SourceWeapon;
	local array<name> WUTemplateNames;
	local bool HasReloadUpgrade;
	
	SourceWeapon = kAbility.GetSourceWeapon();
	WUTemplateNames = SourceWeapon.GetMyWeaponUpgradeTemplateNames();

	if (bCheckForReloadUpgrade)
	{
		if (WUTemplateNames.Find('TLMUpgrade_ReloadT1') != INDEX_NONE)
		{
			HasReloadUpgrade = true;
		}

		if (SourceWeapon.Ammo <= 0 && HasReloadUpgrade)
		{
			return 'AA_Success';
		}

		return 'AA_AmmoAlreadyFull';
	}


	return 'AA_Success';
}
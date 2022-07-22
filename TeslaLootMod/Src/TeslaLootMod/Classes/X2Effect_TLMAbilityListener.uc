class X2Effect_TLMAbilityListener extends X2Effect_PersistentStatChange;

var localized string strSprintReload, strChargesLeft;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventMgr;
	local Object ListenerObj;

	EventMgr = `XEVENTMGR;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	ListenerObj = EffectGameState;

	EventMgr.RegisterForEvent(ListenerObj, 'AbilityActivated', GiveMovementActionPoints, ELD_OnStateSubmitted,, UnitState,, EffectGameState);	
}

static function EventListenerReturn GiveMovementActionPoints(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{	
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;
	local UnitValue CurrentFocusValue, NewFocusValue;
	local VisualizationActionMetadata ActionMetadata, EmptyTrack;
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;	
	local array<X2WeaponUpgradeTemplate> WUTemplates;
	local X2WeaponUpgradeTemplate WUTemplate;
	local bool HasSprintReloadAbility;
	local name AbilityName;
	
	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none) return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none) return ELR_NoInterrupt;

	if (AbilityState.GetMyTemplateName() != 'Reload') return ELR_NoInterrupt;

	WUTemplates = UnitState.GetPrimaryWeapon().GetMyWeaponUpgradeTemplates();

	foreach WUTemplates(WUTemplate)
	{
		foreach WUtemplate.BonusAbilities(AbilityName)
		{
			if (class'X2Ability_TLM'.default.SprintReloadAbilities.Find('AbilityName', AbilityName) == INDEX_NONE) continue;

			HasSprintReloadAbility = true;
			break;
		}
		if (HasSprintReloadAbility) break;
	}

	if (HasSprintReloadAbility)
	{
		UnitState.GetUnitValue('TRSprintReloadCharge', CurrentFocusValue);
		if (CurrentFocusValue.fValue < 1) return ELR_NoInterrupt;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TLM: Give movement action point");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		
		NewFocusValue = CurrentFocusValue;
		NewFocusValue.fValue -= 1;

		UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
		UnitState.SetUnitFloatValue('TRSprintReloadCharge', int(NewFocusValue.fValue), eCleanup_BeginTactical);

		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference);
		ActionMetadata.StateObject_NewState = NewGameState.GetGameStateForObjectID(UnitState.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);
		
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, NewGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.strSprintReload $":" @int(NewFocusValue.fValue) @default.strChargesLeft, '', eColor_Good);

		`GAMERULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}
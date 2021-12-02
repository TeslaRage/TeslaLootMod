class X2DownloadableContentInfo_TeslaLootMod extends X2DownloadableContentInfo;

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_TLM')
	{
		CallUIAlert_TLM(PropertySet);
		return true;
	}

	return false;
}

static function CallUIAlert_TLM(const out DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_TLM Alert;

	Pres = `HQPRES;

	Alert = Pres.Spawn(class'UIAlert_TLM', Pres);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	Pres.ScreenStack.Push(Alert);
}
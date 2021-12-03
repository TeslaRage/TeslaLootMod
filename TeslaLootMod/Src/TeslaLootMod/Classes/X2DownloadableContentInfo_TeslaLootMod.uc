class X2DownloadableContentInfo_TeslaLootMod extends X2DownloadableContentInfo;

var config (TLM) array<LootTable> LootEntry;

// =============
// DLC HOOKS
// =============
static event OnPostTemplatesCreated()
{
	AddLootTables();
}

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_TLM')
	{
		CallUIAlert_TLM(PropertySet);
		return true;
	}

	return false;
}

// =============
// HELPERS
// =============
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

static function AddLootTables()
{
	local X2LootTableManager	LootManager;
	local LootTable				LootBag;
	local LootTableEntry		Entry;
	
	LootManager = X2LootTableManager(class'Engine'.static.FindClassDefaultObject("X2LootTableManager"));

	foreach default.LootEntry(LootBag)
	{
		if ( LootManager.default.LootTables.Find('TableName', LootBag.TableName) != INDEX_NONE )
		{
			foreach LootBag.Loots(Entry)
			{
				class'X2LootTableManager'.static.AddEntryStatic(LootBag.TableName, Entry, false);
			}
		}	
	}
}
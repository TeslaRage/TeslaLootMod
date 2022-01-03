class X2DownloadableContentInfo_TeslaLootMod_Last extends X2DownloadableContentInfo;

var config (TLM) array<PatchItemData> PatchItems;

// =============
// DLC HOOKS
// =============
static event OnPostTemplatesCreated()
{
	class'X2Helper_TLM'.static.ApplyTLMTreatmentToItems();
	class'X2Helper_TLM'.static.UpdateWeaponUpgrade();
}
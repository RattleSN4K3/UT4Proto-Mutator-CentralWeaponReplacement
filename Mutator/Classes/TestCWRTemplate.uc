class TestCWRTemplate extends UTMutator
	dependson(TestCentralWeaponReplacement)
	hidedropdown
	abstract;

var array<TemplateInfo> WeaponsToReplace;
var array<TemplateInfo> AmmoToReplace;

event PreBeginPlay()
{
	super.PreBeginPlay();

	if (!IsPendingKill())
	{
		RegisterByArray(WeaponsToReplace, false);
		RegisterByArray(AmmoToReplace, true);
	}
}

private final function RegisterByArray(out array<TemplateInfo> ItemsToReplace, bool bAmmo)
{
	local int i;
	local string path;

	for (i=0; i<ItemsToReplace.Length; i++)
	{
		path = ItemsToReplace[i].NewClassPath;
		if (ItemsToReplace[i].AddPackage) path = class.GetPackageName()$"."$path;

		RegisterWeaponReplacement(self, ItemsToReplace[i].OldClassName, path, bAmmo, ItemsToReplace[i].Options);
	}
}

protected final function bool RegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, bool bAmmo, optional ReplacementOptionsInfo ReplacementOptions)
{
	return class'TestCentralWeaponReplacement'.static.StaticRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo, ReplacementOptions);
}

DefaultProperties
{
}

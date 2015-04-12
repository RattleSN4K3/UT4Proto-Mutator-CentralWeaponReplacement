class TestCWRTemplate extends UTMutator
	dependson(TestCentralWeaponReplacement)
	hidedropdown
	abstract;

struct TemplateInfo
{
	/** class name of the weapon we want to get rid of */
	var name OldClassName;
	/** fully qualified path of the class to replace it with */
	var string NewClassPath;

	/** the options for this item */
	var ReplacementOptionsInfo Options;

	/** Flag. Set when to append the package name (of the current package) to the NewClassPath field */
	var bool AddPackage;
};

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

private final function bool RegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, bool bAmmo, ReplacementOptionsInfo ReplacementOptions)
{
	return class'TestCentralWeaponReplacement'.static.StaticRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo, ReplacementOptions);
}

DefaultProperties
{
}

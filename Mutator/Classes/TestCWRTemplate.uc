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
		RegisterByArray(self, WeaponsToReplace, false);
		RegisterByArray(self, AmmoToReplace, true);
	}
}

event Destroyed()
{
	Unregister(self);
	Super.Destroyed();
}

static private final function bool RegisterByArray(Object Registrar, array<TemplateInfo> ItemsToReplace, bool bAmmo, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local int i;
	local string path;

	for (i=0; i<ItemsToReplace.Length; i++)
	{
		path = ItemsToReplace[i].NewClassPath;
		if (ItemsToReplace[i].AddPackage && Registrar != none) path = (class(Registrar) != none ? Registrar.GetPackageName() : Registrar.Class.GetPackageName())$"."$path;

		if (!RegisterWeaponReplacement(Registrar, ItemsToReplace[i].OldClassName, path, bAmmo, ItemsToReplace[i].Options, bPre, bOnlyCheck, ErrorMessage))
		{
			if (bOnlyCheck)
			{
				return false;
			}
		}
	}

	return true;
}

static protected final function bool RegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, bool bAmmo, optional ReplacementOptionsInfo ReplacementOptions, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	return class'TestCentralWeaponReplacement'.static.StaticRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo, ReplacementOptions, bPre, bOnlyCheck, ErrorMessage);
}

static private final function bool Unregister(Object Registrar, optional bool bPre)
{
	return class'TestCentralWeaponReplacement'.static.StaticUnRegisterWeaponReplacement(Registrar, bPre);
}

//**********************************************************************************
// UI related static interface functions
//**********************************************************************************

// For UI support to check for conflict (called by UI menu)
static function string Localize( string SectionName, string KeyName, string PackageName )
{
	local string ErrorMessage;
	if (KeyName == "" && PackageName == "")
	{
		if (SectionName ~= "IsConflicting")
		{
			return IsConflicting(ErrorMessage) ? "1"$Chr(10)$ErrorMessage : "0";
		}
		else if (SectionName ~= "PreAdd")
		{
			StaticInitialize();
			return "1";
		}
		else if (SectionName ~= "PreRemove")
		{
			StaticDestroy();
			return "1";
		}
	}

	return super.Localize(SectionName, KeyName, PackageName);
}

static protected function bool IsConflicting(optional out string ErrorMessage)
{
	return !RegisterByArray(default.Class, default.WeaponsToReplace, false, true, true, ErrorMessage) ||
		!RegisterByArray(default.Class, default.AmmoToReplace, true, true, true, ErrorMessage);
}

static protected function StaticInitialize()
{
	RegisterByArray(default.Class, default.WeaponsToReplace, false, true);
	RegisterByArray(default.Class, default.AmmoToReplace, true, true);
}

static protected function StaticDestroy()
{
	Unregister(default.Class, true);
}

DefaultProperties
{
}

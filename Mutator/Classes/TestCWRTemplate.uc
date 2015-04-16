class TestCWRTemplate extends UTMutator
	dependson(TestCentralWeaponReplacement)
	hidedropdown
	abstract;

var array<TemplateInfo> WeaponsToReplace;
var array<TemplateInfo> AmmoToReplace;
 
var const bool bAutoDestroy;

event PreBeginPlay()
{
	local array<TemplateDynamicInfo> Replacements;
	local int i;
	local Object Registrar;

	super.PreBeginPlay();

	if (!IsPendingKill())
	{
		Registrar = GetRegistrar();
		RegisterByArray(Registrar, WeaponsToReplace, false);
		RegisterByArray(Registrar, AmmoToReplace, true);

		StaticGetDynamicReplacements(Replacements);
		for (i=0; i<Replacements.Length; i++)
		{
			RegisterByInfo(Registrar, Replacements[i].Template, Replacements[i].bAmmo);
		}

		if (bAutoDestroy)
		{
			Destroy();
		}
	}
}

event Destroyed()
{
	if (!bAutoDestroy)
	{
		Unregister(self);
	}
	Super.Destroyed();
}

protected final function Object GetRegistrar()
{
	return bAutoDestroy ? class : self;
}

static private final function bool RegisterByArray(Object Registrar, array<TemplateInfo> ItemsToReplace, bool bAmmo, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local int i;

	for (i=0; i<ItemsToReplace.Length; i++)
	{
		if (!RegisterByInfo(Registrar, ItemsToReplace[i], bAmmo, bPre, bOnlyCheck, ErrorMessage))
		{
			return false;
		}
	}

	return true;
}

static private final function bool RegisterByInfo(Object Registrar, TemplateInfo item, bool bAmmo, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local string path;

	path = item.NewClassPath;
	if (item.AddPackage && Registrar != none) path = (class(Registrar) != none ? Registrar.GetPackageName() : Registrar.Class.GetPackageName())$"."$path;

	if (!RegisterWeaponReplacement(Registrar, item.OldClassName, path, bAmmo, item.Options, bPre, bOnlyCheck, ErrorMessage))
	{
		if (bOnlyCheck)
		{
			return false;
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

static private final function Update(Object Registrar, bool bBatchOp, optional bool bPre)
{
	class'TestCentralWeaponReplacement'.static.StaticUpdateWeaponReplacement(Registrar, bBatchOp, bPre);
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
			return StaticIsConflicting(ErrorMessage) ? "1"$Chr(10)$ErrorMessage : "0";
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
		else if (SectionName ~= "PreUpdate")
		{
			StaticUpdate();
			return "1";
		}
	}

	return super.Localize(SectionName, KeyName, PackageName);
}

static protected function bool StaticIsConflicting(optional out string ErrorMessage)
{
	local bool bConflicting;
	local array<TemplateDynamicInfo> Replacements;
	local int i;

	bConflicting = bConflicting || !RegisterByArray(default.Class, default.WeaponsToReplace, false, true, true, ErrorMessage);
	bConflicting = bConflicting || !RegisterByArray(default.Class, default.AmmoToReplace, true, true, true, ErrorMessage);

	if (!bConflicting)
	{
		StaticGetDynamicReplacements(Replacements);
		for (i=0; i<Replacements.Length; i++)
		{
			if (!RegisterByInfo(default.Class, Replacements[i].Template, Replacements[i].bAmmo, true, true, ErrorMessage))
			{
				bConflicting = true;
				break;
			}
		}
	}

	return bConflicting;
}

static protected function StaticInitialize()
{
	local array<TemplateDynamicInfo> Replacements;
	local int i;

	RegisterByArray(default.Class, default.WeaponsToReplace, false, true);
	RegisterByArray(default.Class, default.AmmoToReplace, true, true);

	StaticGetDynamicReplacements(Replacements);
	for (i=0; i<Replacements.Length; i++)
	{
		RegisterByInfo(default.Class, Replacements[i].Template, Replacements[i].bAmmo, true);
	}
}

static protected function StaticDestroy()
{
	Unregister(default.Class, true);
}

static private final function StaticUpdate()
{
	Update(default.Class, true, true);
	StaticDestroy();
	StaticInitialize();
	Update(default.Class, false, true);
}

// override for dynamic replacements
static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements);

//**********************************************************************************
// Dynamic static interface functions
//**********************************************************************************

static protected final function TemplateDynamicInfo CreateTemplate(bool bAmmo, coerce name OldClassName, string NewClassPath, optional ReplacementOptionsInfo Options)
{
	local TemplateDynamicInfo item;
	item.bAmmo = bAmmo;
	item.Template.OldClassName = OldClassName;
	item.Template.NewClassPath = NewClassPath;
	item.Template.Options = Options;
	return item;
}

DefaultProperties
{
}

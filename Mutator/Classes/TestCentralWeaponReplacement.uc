class TestCentralWeaponReplacement extends UTMutator
	config(TestCentralWeaponReplacement);

//**********************************************************************************
// Variables
//**********************************************************************************

var() const string ParameterProfile;

// Config
// ------------

var config array<ReplacementInfoEx> DefaultWeaponsToReplace;
var config array<ReplacementInfoEx> DefaultAmmoToReplace;

var config array<ReplacementInfoEx> DefaultHealthToReplace;
var config array<ReplacementInfoEx> DefaultArmorToReplace;
var config array<ReplacementInfoEx> DefaultPowerupsToReplace;
var config array<ReplacementInfoEx> DefaultDeployablesToReplace;
var config array<ReplacementInfoEx> DefaultVehiclesToReplace;
var config array<ReplacementInfoEx> DefaultCustomsToReplace;

// Workflow
// ------------

var string CurrentProfileName;
var TestCWRMapProfile CurrentProfile;

//**********************************************************************************
// Inherited functions
//**********************************************************************************

// Intialize the default replacments
event PreBeginPlay()
{
	local int i;
	super.PreBeginPlay();

	if (!IsPendingKill())
	{
		for (i=0; i<DefaultWeaponsToReplace.Length; i++)
			RegisterReplacement(self, DefaultWeaponsToReplace[i].OldClassName, DefaultWeaponsToReplace[i].NewClassPath, RT_Weapon, DefaultWeaponsToReplace[i].Options);

		for (i=0; i<DefaultAmmoToReplace.Length; i++)
			RegisterReplacement(self, DefaultAmmoToReplace[i].OldClassName, DefaultAmmoToReplace[i].NewClassPath, RT_Ammo, DefaultAmmoToReplace[i].Options);

		for (i=0; i<DefaultHealthToReplace.Length; i++)
			RegisterReplacement(self, DefaultHealthToReplace[i].OldClassName, DefaultHealthToReplace[i].NewClassPath, RT_Health, DefaultHealthToReplace[i].Options);

		for (i=0; i<DefaultArmorToReplace.Length; i++)
			RegisterReplacement(self, DefaultArmorToReplace[i].OldClassName, DefaultArmorToReplace[i].NewClassPath, RT_Armor, DefaultArmorToReplace[i].Options);

		for (i=0; i<DefaultPowerupsToReplace.Length; i++)
			RegisterReplacement(self, DefaultPowerupsToReplace[i].OldClassName, DefaultPowerupsToReplace[i].NewClassPath, RT_Powerup, DefaultPowerupsToReplace[i].Options);

		for (i=0; i<DefaultDeployablesToReplace.Length; i++)
			RegisterReplacement(self, DefaultDeployablesToReplace[i].OldClassName, DefaultDeployablesToReplace[i].NewClassPath, RT_Deployable, DefaultDeployablesToReplace[i].Options);

		for (i=0; i<DefaultVehiclesToReplace.Length; i++)
			RegisterReplacement(self, DefaultVehiclesToReplace[i].OldClassName, DefaultVehiclesToReplace[i].NewClassPath, RT_Vehicle, DefaultVehiclesToReplace[i].Options);

		for (i=0; i<DefaultCustomsToReplace.Length; i++)
			RegisterReplacement(self, DefaultCustomsToReplace[i].OldClassName, DefaultCustomsToReplace[i].NewClassPath, RT_Custom, DefaultCustomsToReplace[i].Options);
	}
}

// used to check for default inventory items to be replaced or
// whether an item should be added to the weapon lockers or the default inventory
function InitMutator(string Options, out string ErrorMessage)
{
	local TestCWRMapProfile MapProvider;

	super.InitMutator(Options, ErrorMessage);

	if (class'GameInfo'.static.HasOption(Options, ParameterProfile))
	{
		CurrentProfileName = class'GameInfo'.static.ParseOption(Options, ParameterProfile);
	}

	if (CurrentProfileName != "" && class'TestCWRMapProfile'.static.GetMapProfileByName(CurrentProfileName, MapProvider))
	{
		CurrentProfile = MapProvider;
		RegisterReplacementArray(CurrentProfile, CurrentProfile.WeaponsToReplace, RT_Weapon);
		RegisterReplacementArray(CurrentProfile, CurrentProfile.AmmoToReplace, RT_Ammo);

		RegisterReplacementArray(CurrentProfile, CurrentProfile.HealthToReplace, RT_Health);
		RegisterReplacementArray(CurrentProfile, CurrentProfile.ArmorToReplace, RT_Armor);
		RegisterReplacementArray(CurrentProfile, CurrentProfile.PowerupsToReplace, RT_Powerup);
		RegisterReplacementArray(CurrentProfile, CurrentProfile.DeployablesToReplace, RT_Deployable);
		RegisterReplacementArray(CurrentProfile, CurrentProfile.VehiclesToReplace, RT_Vehicle);
		RegisterReplacementArray(CurrentProfile, CurrentProfile.CustomsToReplace, RT_Custom);
	}
}

event Destroyed()
{
	Unregister(none);
	Super.Destroyed();
}

//**********************************************************************************
// Interface functions
//**********************************************************************************

static private function bool RegisterReplacement(Object Registrar, name OldClassName, string NewClassPath, EReplacementType ReplacementType, ReplacementOptionsInfo ReplacementOptions, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	return class'TestCWRCore'.static.StaticRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, ReplacementType, ReplacementOptions, bPre, bOnlyCheck, ErrorMessage);
}

static private function RegisterReplacementInfo(Object Registrar, coerce TemplateInfo RepInfo, EReplacementType ReplacementType)
{
	RegisterReplacement(Registrar, RepInfo.OldClassName, RepInfo.NewClassPath, ReplacementType, RepInfo.Options);
}

static private function RegisterReplacementArray(Object Registrar, coerce array<TemplateInfo> Replacements, EReplacementType ReplacementType)
{
	local int i;
	for (i=0; i<Replacements.Length; i++)
	{
		RegisterReplacementInfo(Registrar, Replacements[i], ReplacementType);
	}
}

static private function bool Unregister(Object Registrar, optional bool bPre)
{
	return class'TestCWRCore'.static.StaticUnRegisterWeaponReplacement(Registrar, bPre);
}

static private function Update(Object Registrar, bool bBatchOp, optional bool bPre)
{
	class'TestCWRCore'.static.StaticUpdateWeaponReplacement(Registrar, bBatchOp, bPre);
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
			return InternalStaticIsConflicting(ErrorMessage) ? "1"$Chr(10)$ErrorMessage : "0";
		}
		else if (SectionName ~= "PreAdd")
		{
			InternalStaticInitialize();
			return "1";
		}
		else if (SectionName ~= "PreRemove")
		{
			InternalStaticDestroy();
			return "1";
		}
		else if (SectionName ~= "PreUpdate")
		{
			InternalStaticUpdate();
			return "1";
		}
	}

	return super.Localize(SectionName, KeyName, PackageName);
}

static private function bool InternalStaticIsConflicting(optional out string ErrorMessage)
{
	return !InternalStaticInitialize(true, ErrorMessage);
}

static private function bool InternalStaticInitialize(optional bool bOnlyCheck, optional out string ErrorMessage )
{
	local int i;

	for (i=0; i<default.DefaultWeaponsToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultWeaponsToReplace[i].OldClassName, default.DefaultWeaponsToReplace[i].NewClassPath, RT_Weapon, default.DefaultWeaponsToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultAmmoToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultAmmoToReplace[i].OldClassName, default.DefaultAmmoToReplace[i].NewClassPath, RT_Ammo, default.DefaultAmmoToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultHealthToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultHealthToReplace[i].OldClassName, default.DefaultHealthToReplace[i].NewClassPath, RT_Health, default.DefaultHealthToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultArmorToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultArmorToReplace[i].OldClassName, default.DefaultArmorToReplace[i].NewClassPath, RT_Armor, default.DefaultArmorToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultPowerupsToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultPowerupsToReplace[i].OldClassName, default.DefaultPowerupsToReplace[i].NewClassPath, RT_Powerup, default.DefaultPowerupsToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultDeployablesToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultDeployablesToReplace[i].OldClassName, default.DefaultDeployablesToReplace[i].NewClassPath, RT_Deployable, default.DefaultDeployablesToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultVehiclesToReplace.Length; i++)
		if (!RegisterReplacement(default.class, default.DefaultVehiclesToReplace[i].OldClassName, default.DefaultVehiclesToReplace[i].NewClassPath, RT_Vehicle, default.DefaultVehiclesToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	for (i=0; i<default.DefaultCustomsToReplace.Length; i++)
		if (RegisterReplacement(default.class, default.DefaultCustomsToReplace[i].OldClassName, default.DefaultCustomsToReplace[i].NewClassPath, RT_Custom, default.DefaultCustomsToReplace[i].Options, true, bOnlyCheck, ErrorMessage))
			if (bOnlyCheck) return false;

	return true;
}

static private function InternalStaticDestroy()
{
	Unregister(default.Class, true);
}

static private function InternalStaticUpdate()
{
	Update(default.Class, true);
	InternalStaticDestroy();
	InternalStaticInitialize();
	Update(default.Class, false);
}

//**********************************************************************************
// Helper functions
//**********************************************************************************

static function bool HasMutator(WorldInfo WI, out TestCentralWeaponReplacement OutMut, optional Object IgnoreMutator)
{
	foreach WI.DynamicActors(class'TestCentralWeaponReplacement', OutMut)
	{
		if (IgnoreMutator == none || OutMut != IgnoreMutator)
		{
			break;
		}
	}

	return OutMut != none;
}

//**********************************************************************************
// Static functions
//**********************************************************************************

static function bool GetConfigReplacements(EReplacementType ReplacementType, out array<ReplacementInfoEx> Replacements)
{
	switch (ReplacementType) {
	case RT_Weapon: Replacements = default.DefaultWeaponsToReplace;break;
	case RT_Ammo: Replacements = default.DefaultAmmoToReplace;break;

	case RT_Health: Replacements = default.DefaultHealthToReplace;break;
	case RT_Armor: Replacements = default.DefaultArmorToReplace;break;
	case RT_Powerup: Replacements = default.DefaultPowerupsToReplace;break;
	case RT_Deployable: Replacements = default.DefaultDeployablesToReplace;break;
	case RT_Vehicle: Replacements = default.DefaultVehiclesToReplace;break;
	case RT_Custom: Replacements = default.DefaultCustomsToReplace;break;
	default: return false;
	}

	return true;
}

static function bool SetConfigReplacements(EReplacementType ReplacementType, out array<ReplacementInfoEx> Replacements)
{
	if (ReplacementType == RT_Weapon) default.DefaultWeaponsToReplace = Replacements;
	else if (ReplacementType == RT_Ammo) default.DefaultAmmoToReplace = Replacements;

	else if (ReplacementType == RT_Health) default.DefaultHealthToReplace = Replacements;
	else if (ReplacementType == RT_Armor) default.DefaultArmorToReplace = Replacements;
	else if (ReplacementType == RT_Powerup) default.DefaultPowerupsToReplace = Replacements;
	else if (ReplacementType == RT_Deployable) default.DefaultDeployablesToReplace = Replacements;
	else if (ReplacementType == RT_Vehicle) default.DefaultVehiclesToReplace = Replacements;
	else if (ReplacementType == RT_Custom) default.DefaultCustomsToReplace = Replacements;
	else return false;

	StaticSaveConfig();
	return true;
}

Defaultproperties
{
	GroupNames[0]="WEAPONMOD"

	ParameterProfile="CWRMapProfile"
}
class TestCWR_ConfigWeaponMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigWeapon);

var config name ReplaceWeaponClassName;
var config name ReplaceAmmoClassName;

// Called immediately after gameplay begins.
event PostBeginPlay()
{
	super.PostBeginPlay();

	if (ReplaceWeaponClassName != '')
	{
		RegisterWeaponReplacement(self, ReplaceWeaponClassName, PathName(class'TestCWR_RipperWeapon'), false);
		RegisterWeaponReplacement(self, ReplaceAmmoClassName, PathName(class'TestCWR_RipperAmmo'), true);
	}
}

static protected function bool StaticIsConflicting(optional out string ErrorMessage)
{
	if (!super.StaticIsConflicting() && default.ReplaceWeaponClassName != '')
	{
		return !RegisterWeaponReplacement(default.Class, default.ReplaceWeaponClassName, PathName(class'TestCWR_RipperWeapon'), false,, true, true, ErrorMessage) ||
			!RegisterWeaponReplacement(default.Class, default.ReplaceWeaponClassName, PathName(class'TestCWR_RipperAmmo'), true,, true, true, ErrorMessage);
	}
	
	return false;
}

static protected function StaticInitialize()
{
	super.StaticInitialize();

	if (default.ReplaceWeaponClassName != '')
	{
		RegisterWeaponReplacement(default.Class, default.ReplaceWeaponClassName, PathName(class'TestCWR_RipperWeapon'), false,, true);
		RegisterWeaponReplacement(default.Class, default.ReplaceAmmoClassName, PathName(class'TestCWR_RipperAmmo'), true,, true);
	}
}

DefaultProperties
{
	ReplaceWeaponClassName="UTWeap_BioRifle_Content"
	ReplaceAmmoClassName="UTAmmo_BioRifle_Content"
}


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

DefaultProperties
{
	ReplaceWeaponClassName="UTWeap_BioRifle_Content"
	ReplaceAmmoClassName="UTAmmo_BioRifle_Content"
}


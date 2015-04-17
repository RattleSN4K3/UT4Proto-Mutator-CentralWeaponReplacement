class TestCWR_ConfigWeaponMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigWeapon);

var config name ReplaceWeaponClassName;
var config name ReplaceAmmoClassName;
var config ReplacementOptionsInfo ReplaceWeaponOptions;
var config ReplacementOptionsInfo ReplaceAmmoOptions;

static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements)
{
	if (default.ReplaceWeaponClassName != '')
	{
		Replacements.AddItem(CreateTemplate(RT_Weapon, default.ReplaceWeaponClassName, PathName(class'TestCWR_RipperWeapon'), default.ReplaceWeaponOptions));
		Replacements.AddItem(CreateTemplate(RT_Ammo, default.ReplaceAmmoClassName, PathName(class'TestCWR_RipperAmmo'), default.ReplaceAmmoOptions));
	}
}

DefaultProperties
{
	ReplaceWeaponClassName="UTWeap_BioRifle_Content"
	ReplaceAmmoClassName="UTAmmo_BioRifle_Content"
	ReplaceWeaponOptions=()
	ReplaceAmmoOptions=()
}

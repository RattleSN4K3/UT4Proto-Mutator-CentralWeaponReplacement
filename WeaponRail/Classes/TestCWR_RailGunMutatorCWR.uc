class TestCWR_RailGunMutatorCWR extends UTMutator;

var class<Inventory> ReplaceWeaponClass;
var class<Inventory> WeaponClass;

var class<UTAmmoPickupFactory> ReplaceAmmoClass;
var class<UTAmmoPickupFactory> AmmoClass;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	class'TestCentralWeaponReplacement'.static.StaticRegisterWeaponReplacement(
		self, ReplaceWeaponClass.Name, PathName(WeaponClass), false);
	class'TestCentralWeaponReplacement'.static.StaticRegisterWeaponReplacement(
		self, ReplaceAmmoClass.Name, PathName(AmmoClass), true);
}

DefaultProperties
{
	ReplaceWeaponClass=class'UTWeap_SniperRifle'
	WeaponClass=class'TestCWR_RailGunWeapon'

	ReplaceAmmoClass=class'UTAmmo_SniperRifle'
	AmmoClass=class'TestCWR_RailGunAmmo'
}

class TestCWR_SubclassWeaponMutator extends UTMutator;

var class<UTWeapon> AllWeaponClass;
var class<UTWeapon> NewWeaponClass;

var class<UTAmmoPickupFactory> ReplaceAmmoClass;
var class<UTAmmoPickupFactory> AmmoClass;

function bool CheckReplacement(Actor Other)
{
	local UTWeaponPickupFactory WeaponPickup;
	local UTAmmoPickupFactory AmmoPickup, NewAmmo;

	WeaponPickup = UTWeaponPickupFactory(Other);
	if (WeaponPickup != None && WeaponPickup.WeaponPickupClass != none)
	{
		if (WeaponPickup.WeaponPickupClass != AllWeaponClass && ClassIsChildOf(WeaponPickup.WeaponPickupClass, class'UTWeapon'))
		{
			WeaponPickup.WeaponPickupClass = NewWeaponClass;
			WeaponPickup.InitializePickup();
		}
	}
	else if (UTWeaponLocker(Other) != none)
	{
		return true;
	}
	else if (UTAmmoPickupFactory(Other) != none)
	{
		AmmoPickup = UTAmmoPickupFactory(Other);
		if (ClassIsChildOf(ReplaceAmmoClass, class'UTAmmoPickupFactory'))
		{
			if (AmmoClass == none)
			{
				// replace with nothing
				return false;
			}
			if (AmmoClass.default.bStatic || AmmoClass.default.bNoDelete)
			{
				// transform the current ammo into the desired class
				AmmoPickup.TransformAmmoType(AmmoClass);
				return true;
			}
			else
			{
				// spawn the new ammo, link it to the old, then disable the old one
				NewAmmo = AmmoPickup.Spawn(AmmoClass);
				NewAmmo.OriginalFactory = AmmoPickup;
				AmmoPickup.ReplacementFactory = NewAmmo;
				return false;
			}
		}
	}

	return true;
}

DefaultProperties
{
	AllWeaponClass=class'UTWeap_Redeemer_Content'
	NewWeaponClass=class'TestCWR_SuperDeemerWeapon'

	ReplaceAmmoClass=class'UTAmmoPickupFactory'
	AmmoClass=class'TestCWR_SuperDeemerAmmo'
}

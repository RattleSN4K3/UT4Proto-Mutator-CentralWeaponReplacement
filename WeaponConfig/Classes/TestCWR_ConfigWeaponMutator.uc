class TestCWR_ConfigWeaponMutator extends UTMutator
	config(TestCWR_ConfigWeapon);

var config name ReplaceWeaponClassName;
var config name ReplaceAmmoClassName;

var class<Inventory> WeaponClass;
var class<UTAmmoPickupFactory> AmmoClass;

var bool bReplaceWeapon;
var bool bAddToLocker;
var bool bAddToDefault;

function PostBeginPlay()
{
	local int i;
	local UTGame G;

	// ensure another mutator can replace the weapon
	Super.PostBeginPlay();

	// Make sure the game does not hold a null reference
	G = UTGame(WorldInfo.Game);
	if(G != none)
	{
		for (i=0; i<G.DefaultInventory.Length; i++)
		{
			if (G.DefaultInventory[i].Name == ReplaceWeaponClassName)
			{
				if (i != INDEX_NONE && bReplaceWeapon)
				{
					G.DefaultInventory[i] = WeaponClass;
					break;
				}
			}
		}

		if (i >= G.DefaultInventory.Length && bAddToDefault)
		{
			G.DefaultInventory.AddItem(WeaponClass);
		}
	}

	if (bAddToLocker)
	{
		AddToLocker();
	}
}

function AddToLocker()
{
	local UTWeaponLocker Locker;
	local WeaponEntry ent;

	foreach DynamicActors(class'UTWeaponLocker', Locker)
	{
		ent.WeaponClass = class<UTWeapon>(WeaponClass);
		if (class<UTWeapon>(WeaponClass) != none)
		{
			Locker.MaxDesireability += class<UTWeapon>(WeaponClass).Default.AIRating;

			//if (class<UTWeapon>(WeaponClass).default.PickupFactoryMesh != none)
			//	ent.PickupMesh = class<UTWeapon>(WeaponClass).default.PickupFactoryMesh;
		}

		Locker.Weapons.AddItem(ent);
	}
}

function bool CheckReplacement(Actor Other)
{
	local UTWeaponPickupFactory WeaponPickup;
	local UTWeaponLocker Locker;
	local UTAmmoPickupFactory AmmoPickup, NewAmmo;
	local int i;

	if (!bReplaceWeapon)
		return true;

	WeaponPickup = UTWeaponPickupFactory(Other);
	if (WeaponPickup != None)
	{
		if (WeaponPickup.WeaponPickupClass != None && WeaponPickup.WeaponPickupClass.Name == ReplaceWeaponClassName)
		{
			WeaponPickup.WeaponPickupClass = class<UTWeapon>(WeaponClass);
			WeaponPickup.InitializePickup();
		}
	}
	else
	{
		Locker = UTWeaponLocker(Other);
		if (Locker != None)
		{
			for (i = 0; i < Locker.Weapons.length; i++)
			{
				if (Locker.Weapons[i].WeaponClass != None && Locker.Weapons[i].WeaponClass.Name == ReplaceWeaponClassName)
				{
					Locker.ReplaceWeapon(i, class<UTWeapon>(WeaponClass));
				}
			}
		}
		else
		{
			AmmoPickup = UTAmmoPickupFactory(Other);
			if (AmmoPickup != None && AmmoPickup.Class.Name == ReplaceAmmoClassName)
			{
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
	}

	return true;
}

DefaultProperties
{
	bAddToLocker=false
	bAddToDefault=false
	bReplaceWeapon=true

	WeaponClass=class'TestCWR_RipperWeapon'
	AmmoClass=class'TestCWR_RipperAmmo'

	ReplaceWeaponClassName="UTWeap_BioRifle_Content"
	ReplaceAmmoClassName="UTAmmo_BioRifle_Content"
}

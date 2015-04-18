class TestCWR_NoDeployableMutator extends UTMutator;

var class<Inventory> ReplaceDeployableClass;

function PostBeginPlay()
{
	local int i;
	local UTGame G;

	Super.PostBeginPlay();

	G = UTGame(WorldInfo.Game);
	if(G != none)
	{
		i = G.DefaultInventory.Find(ReplaceDeployableClass);
		if (i != INDEX_NONE)
		{
			G.DefaultInventory.Remove(i, 1);
		}
	}
}

function bool CheckReplacement(Actor Other)
{
	local UTDeployablePickupFactory DeployablePickup;
	local UTWeaponLocker Locker;
	local int i;

	DeployablePickup = UTDeployablePickupFactory(Other);
	if (DeployablePickup != None)
	{
		if (DeployablePickup.DeployablePickupClass != None && DeployablePickup.DeployablePickupClass == ReplaceDeployableClass)
		{
			// remove factory
			return false;
		}
	}
	else
	{
		Locker = UTWeaponLocker(Other);
		if (Locker != None)
		{
			for (i = 0; i < Locker.Weapons.length; i++)
			{
				if (Locker.Weapons[i].WeaponClass != None && Locker.Weapons[i].WeaponClass == ReplaceDeployableClass)
				{
					Locker.ReplaceWeapon(i, none);
				}
			}
		}
	}

	return true;
}

DefaultProperties
{
	ReplaceDeployableClass=class'UTDeployableSpiderMineTrap'
}

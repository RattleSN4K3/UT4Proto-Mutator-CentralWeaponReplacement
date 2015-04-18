class TestCWR_ConfigDeployableMutator extends UTMutator
	config(TestCWR_ConfigDeployable);

var config name ReplaceDeployableClassName;
var class<UTDeployable> NewDeployableClass;

var bool bReplaceDeployable;
var bool bAddToLocker;
var bool bAddToDefault;

function PostBeginPlay()
{
	local int i;
	local UTGame G;

	Super.PostBeginPlay();

	G = UTGame(WorldInfo.Game);
	if(G != none)
	{
		for (i=0; i<G.DefaultInventory.Length; i++)
		{
			if (G.DefaultInventory[i].Name == ReplaceDeployableClassName)
			{
				if (i != INDEX_NONE && bReplaceDeployable)
				{
					G.DefaultInventory[i] = NewDeployableClass;
					break;
				}
			}
		}

		if (NewDeployableClass != none && i >= G.DefaultInventory.Length && bAddToDefault)
		{
			G.DefaultInventory.AddItem(NewDeployableClass);
		}
	}

	if (bAddToLocker)
	{
		AddToLocker(NewDeployableClass);
	}
}

function AddToLocker(class<UTWeapon> WeaponClass)
{
	local UTWeaponLocker Locker;
	local WeaponEntry ent;

	if (WeaponClass == none)
		return;

	foreach DynamicActors(class'UTWeaponLocker', Locker)
	{
		if (Locker.Weapons.Find('WeaponClass', WeaponClass) != INDEX_NONE)
			continue;

		ent.WeaponClass = NewDeployableClass;
		Locker.MaxDesireability += WeaponClass.Default.AIRating;

		Locker.Weapons.AddItem(ent);
	}
}

function bool CheckReplacement(Actor Other)
{
	local UTDeployablePickupFactory DeployablePickup;
	local UTWeaponLocker Locker;
	local int i;

	if (!bReplaceDeployable)
		return true;

	DeployablePickup = UTDeployablePickupFactory(Other);
	if (DeployablePickup != None)
	{
		if (DeployablePickup.DeployablePickupClass != None && DeployablePickup.DeployablePickupClass.Name == ReplaceDeployableClassName)
		{
			DeployablePickup.DeployablePickupClass = NewDeployableClass;
			DeployablePickup.InitializePickup();
		}
	}
	else
	{
		Locker = UTWeaponLocker(Other);
		if (Locker != None)
		{
			for (i = 0; i < Locker.Weapons.length; i++)
			{
				if (Locker.Weapons[i].WeaponClass != None && Locker.Weapons[i].WeaponClass.Name == ReplaceDeployableClassName)
				{
					Locker.ReplaceWeapon(i, NewDeployableClass);
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
	bReplaceDeployable=true

	ReplaceDeployableClassName="UTDeployableSpiderMineTrap"
	NewDeployableClass=class'UTDeployableSlowVolume'
}

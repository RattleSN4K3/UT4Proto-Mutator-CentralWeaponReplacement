class TestCWR_ConfigPowerupMutator extends UTMutator
	config(TestCWR_ConfigPowerup);

var config name ReplacePowerupClassName;
var class<UTPowerupPickupFactory> NewPowerupClass;

var bool bReplacePowerup;
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
			if (G.DefaultInventory[i].Name == ReplacePowerupClassName)
			{
				if (i != INDEX_NONE && bReplacePowerup)
				{
					G.DefaultInventory[i] = NewPowerupClass.default.InventoryType;
					break;
				}
			}
		}

		if (i >= G.DefaultInventory.Length && bAddToDefault && NewPowerupClass != none && NewPowerupClass.default.InventoryType != none)
		{
			G.DefaultInventory.AddItem(NewPowerupClass.default.InventoryType);
		}
	}
}

function bool CheckReplacement(Actor Other)
{
	local UTPowerupPickupFactory PowerupPickup;

	if (UTPowerupPickupFactory(Other) != none)
	{
		PowerupPickup = UTPowerupPickupFactory(Other);
		if (PowerupPickup.IsA(ReplacePowerupClassName) && !ClassIsChildOf(PowerupPickup.Class, NewPowerupClass))
		{
			if (ReplacePowerupClassName != '')
			{
				class'TestCWRCore'.static.SpawnStaticActor(NewPowerupClass, WorldInfo, Other.Owner,, Other.Location, Other.Rotation);
			}

			// remove old factory
			return false;
		}
	}

	return true;
}

DefaultProperties
{
	bAddToDefault=true
	bReplacePowerup=true

	ReplacePowerupClassName="UTPickupFactory_UDamage"
	NewPowerupClass=class'UTPickupFactory_JumpBoots'
}

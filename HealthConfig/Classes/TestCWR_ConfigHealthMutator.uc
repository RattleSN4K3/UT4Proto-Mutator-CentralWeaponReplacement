class TestCWR_ConfigHealthMutator extends UTMutator
	config(TestCWR_ConfigHealth);

var config name ReplaceHealthClassName;
var class<UTHealthPickupFactory> NewHealthClass;

function bool CheckReplacement(Actor Other)
{
	local UTHealthPickupFactory HealthPickup;

	if (UTHealthPickupFactory(Other) != none)
	{
		HealthPickup = UTHealthPickupFactory(Other);
		if (HealthPickup.IsA(ReplaceHealthClassName) && !ClassIsChildOf(HealthPickup.Class, NewHealthClass))
		{
			if (ReplaceHealthClassName != '')
			{
				class'TestCWRCore'.static.SpawnStaticActor(NewHealthClass, WorldInfo, Other.Owner,, Other.Location, Other.Rotation);
			}

			// remove old factory
			return false;
		}
	}

	return true;
}

DefaultProperties
{
	ReplaceHealthClassName="UTPickupFactory_MediumHealth"
	NewHealthClass=class'UTPickupFactory_HealthVial'
}

class TestCWR_ConfigVehicleMutator extends UTMutator
	config(TestCWR_ConfigVehicle);

var config name ReplaceVehicleClassName;
var class<UTVehicleFactory> NewVehicleClass;

function bool CheckReplacement(Actor Other)
{
	local UTVehicleFactory VehiclePickup;

	if (UTVehicleFactory(Other) != none)
	{
		VehiclePickup = UTVehicleFactory(Other);
		if (VehiclePickup.IsA(ReplaceVehicleClassName) && !ClassIsChildOf(VehiclePickup.Class, NewVehicleClass))
		{
			if (ReplaceVehicleClassName != '')
			{
				class'TestCWRCore'.static.SpawnStaticActor(NewVehicleClass, WorldInfo, Other.Owner,, Other.Location, Other.Rotation);
			}

			// remove old factory
			VehiclePickup.VehicleClassPath = "";
			VehiclePickup.VehicleClass = none;
			VehiclePickup.Deactivate();
			return false;
		}
	}

	return true;
}

DefaultProperties
{
	ReplaceVehicleClassName="UTVehicleFactory_Goliath"
	NewVehicleClass=class'UTVehicleFactory_Scorpion'
}

class TestCWR_NoVehicleMutator extends UTMutator;

function bool CheckReplacement(Actor Other)
{
	if (UTVehicleFactory_Goliath(Other) != None)
	{
		// remove factory
		UTVehicleFactory_Goliath(Other).VehicleClassPath = "";
		UTVehicleFactory_Goliath(Other).VehicleClass = none;
		UTVehicleFactory_Goliath(Other).Deactivate();
		return false;
	}

	return true;
}

DefaultProperties
{
}

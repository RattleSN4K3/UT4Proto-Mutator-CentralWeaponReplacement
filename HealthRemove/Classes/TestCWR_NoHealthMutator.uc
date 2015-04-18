class TestCWR_NoHealthMutator extends UTMutator;

function bool CheckReplacement(Actor Other)
{
	if (UTPickupFactory_HealthVial(Other) != None)
	{
		// remove factory
		return false;
	}

	return true;
}

DefaultProperties
{
}

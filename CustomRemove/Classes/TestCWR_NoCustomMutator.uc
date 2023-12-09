class TestCWR_NoCustomMutator extends UTMutator;

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

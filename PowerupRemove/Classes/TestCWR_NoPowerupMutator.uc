class TestCWR_NoPowerupMutator extends UTMutator;

function bool CheckReplacement(Actor Other)
{
	if (UTPickupFactory_JumpBoots(Other) != None)
	{
		// remove factory
		return false;
	}

	return true;
}

DefaultProperties
{
}

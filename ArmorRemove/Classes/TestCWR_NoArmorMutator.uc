class TestCWR_NoArmorMutator extends UTMutator;

function bool CheckReplacement(Actor Other)
{
	if (UTArmorPickup_ShieldBelt(Other) != None)
	{
		// remove factory
		return false;
	}

	return true;
}

DefaultProperties
{
}

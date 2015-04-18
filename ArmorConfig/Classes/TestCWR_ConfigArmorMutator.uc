class TestCWR_ConfigArmorMutator extends UTMutator
	config(TestCWR_ConfigArmor);

var config name ReplaceArmorClassName;
var class<UTArmorPickupFactory> NewArmorClass;

function bool CheckReplacement(Actor Other)
{
	local UTArmorPickupFactory ArmorPickup;

	if (UTArmorPickupFactory(Other) != none)
	{
		ArmorPickup = UTArmorPickupFactory(Other);
		if (ArmorPickup.IsA(ReplaceArmorClassName) && !ClassIsChildOf(ArmorPickup.Class, NewArmorClass))
		{
			if (ReplaceArmorClassName != '')
			{
				class'TestCentralWeaponReplacement'.static.SpawnStaticActor(NewArmorClass, WorldInfo, Other.Owner,, Other.Location, Other.Rotation);
			}

			// remove old factory
			return false;
		}
	}

	return true;
}

DefaultProperties
{
	ReplaceArmorClassName="UTArmorPickup_ShieldBelt"
	NewArmorClass=class'UTArmorPickup_Thighpads'
}

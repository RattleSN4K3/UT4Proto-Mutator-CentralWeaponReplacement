class TestCWR_NoWeaponMutatorCWR extends TestCWRTemplate;

DefaultProperties
{
	WeaponsToReplace.Add((OldClassName="UTWeap_Stinger",NewClassPath=""))
	AmmoToReplace.Add((OldClassName="UTAmmo_Stinger",NewClassPath=""))

	//WeaponsToReplace.Add((OldClassName="UTWeap_SniperRifle",Options=(bReplaceWeapon=false)))
	//AmmoToReplace.Add((OldClassName="UTAmmo_SniperRifle",Options=(bReplaceWeapon=false)))
	//WeaponsToReplace.Add((OldClassName="UTWeapon",NewClassPath="",Options=(bSubclasses=true)))
	//AmmoToReplace.Add((OldClassName="UTAmmoPickupFactory",NewClassPath="",Options=(bSubclasses=true)))

	//WeaponsToReplace.Add((OldClassName="UTWeapon",NewClassPath="UTGame.UTWeap_SniperRifle",Options=(bSubclasses=true)))
	//AmmoToReplace.Add((OldClassName="UTAmmoPickupFactory",NewClassPath="UTGame.UTAmmo_SniperRifle",Options=(bSubclasses=true)))
}

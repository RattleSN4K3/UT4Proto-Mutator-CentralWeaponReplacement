class TestCWR_LightningGunMutatorCWR extends TestCWRTemplate;

DefaultProperties
{
	WeaponsToReplace.Add((OldClassName="UTWeap_SniperRifle",NewClassPath="TestCWR_LightningGunWeapon",AddPackage=true))
	AmmoToReplace.Add((OldClassName="UTAmmo_SniperRifle",NewClassPath="TestCWR_LightningGunAmmo",AddPackage=true))
}

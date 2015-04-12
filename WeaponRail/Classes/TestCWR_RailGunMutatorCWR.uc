class TestCWR_RailGunMutatorCWR extends TestCWRTemplate;

DefaultProperties
{
	WeaponsToReplace.Add((OldClassName="UTWeap_SniperRifle",NewClassPath="TestCWR_RailGunWeapon",AddPackage=true))
	AmmoToReplace.Add((OldClassName="UTAmmo_SniperRifle",NewClassPath="TestCWR_RailGunAmmo",AddPackage=true))
}

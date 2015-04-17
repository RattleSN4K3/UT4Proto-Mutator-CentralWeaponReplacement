class TestCWR_SubclassWeaponMutatorCWR extends TestCWRTemplate;

DefaultProperties
{
	WeaponsToReplace(0)=(OldClassName="UTWeap_Redeemer_Content",Options=(bNoReplaceWeapon=true))
	WeaponsToReplace(1)=(OldClassName="UTWeapon",NewClassPath="TestCWR_SuperDeemerWeapon",AddPackage=true,Options=(bSubClasses=true,bNoDefaultInventory=true))
	AmmoToReplace(0)=(OldClassName="UTAmmoPickupFactory",NewClassPath="TestCWR_SuperDeemerAmmo",AddPackage=true,Options=(bSubClasses=true))
}

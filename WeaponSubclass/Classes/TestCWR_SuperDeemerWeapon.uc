class TestCWR_SuperDeemerWeapon extends UTWeap_Redeemer_Content;

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstance
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=0.0,A=1.0)))
	End Object

	Begin Object Name=FirstPersonMesh
	    Materials(0)=MyMaterialInstance
		Materials(1)=MyMaterialInstance
	End Object

	Begin Object Name=PickupMesh
		Materials(0)=MyMaterialInstance
		Materials(1)=MyMaterialInstance
	End Object

	AttachmentClass=class'TestCWR_SuperDeemerAttachment'

	ItemName="Super Redeemer"
	PickupMessage="Super Redeemer"

	AmmoCount=4
	LockerAmmoCount=4
	MaxAmmoCount=15
	RespawnTime=45.0
	bDelayedSpawn=false

	EquipTime=+1.2
	PutDownTime=+0.8

	WeaponProjectiles(0)=class'TestCWR_SuperDeemerProjectile'
	WeaponProjectiles(1)=class'TestCWR_SuperDeemerProjectile'
	RedRedeemerClass=class'TestCWR_SuperDeemerProjectile'

	WarHeadClass=class'TestCWR_SuperDeemerRemote'
}

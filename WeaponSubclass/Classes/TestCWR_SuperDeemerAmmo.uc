class TestCWR_SuperDeemerAmmo extends UTAmmoPickupFactory;

DefaultProperties
{
	PickupMessage="Super Deemer Ammo"

	AmmoAmount=4
	TargetWeapon=class'TestCWR_SuperDeemerWeapon'
	PickupSound=SoundCue'A_Pickups.Ammo.Cue.A_Pickup_Ammo_Rocket_Cue'
	MaxDesireability=0.6

	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceAmmo
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues(0)=(ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=0.0,A=1.0))
	End Object

	Begin Object Name=AmmoMeshComp
		StaticMesh=StaticMesh'WP_Redeemer.Mesh.S_WP_Redeemer_Missile_Open'
		Materials(0)=MyMaterialInstanceAmmo
		Scale=1.6
		Rotation=(Pitch=16384,Yaw=0,Roll=0)
		Translation=(X=0.0,Y=0.0,Z=11.000000)
	End Object

	Begin Object Name=CollisionCylinder
		CollisionHeight=14.4
	End Object
}

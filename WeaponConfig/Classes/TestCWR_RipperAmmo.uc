class TestCWR_RipperAmmo extends UTAmmoPickupFactory;

DefaultProperties
{
	PickupMessage="Ripper Ammo"

	AmmoAmount=15
	TargetWeapon=class'TestCWR_RipperWeapon'
	PickupSound=SoundCue'A_Pickups.Ammo.Cue.A_Pickup_Ammo_Rocket_Cue'
	MaxDesireability=0.2

	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceAmmo
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues(0)=(ParameterName="Diffuse_01_Color",ParameterValue=(R=0.0,G=1.0,B=0.0,A=1.0))
	End Object

	Begin Object Name=AmmoMeshComp
		StaticMesh=StaticMesh'WP_Translocator.Mesh.S_Translocator_Disk'
		Materials(0)=MyMaterialInstanceAmmo
		Rotation=(Roll=16384)
		//Translation=(X=0.0,Y=0.0,Z=-15.0)
	End Object

	Begin Object Name=CollisionCylinder
		CollisionHeight=14.4
	End Object
}

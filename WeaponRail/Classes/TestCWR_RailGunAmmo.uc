class TestCWR_RailGunAmmo extends UTAmmo_ShockRifle;

DefaultProperties
{
	PickupMessage="RailGun Ammo"

	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceAmmo
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=1.0,B=1.0,A=1.0)))
	End Object

	Begin Object Name=AmmoMeshComp
		Materials(0)=MyMaterialInstanceAmmo
	End Object

	TargetWeapon=class'TestCWR_RailGunWeapon'
}

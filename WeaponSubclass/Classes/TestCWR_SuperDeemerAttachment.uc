class TestCWR_SuperDeemerAttachment extends UTAttachment_Redeemer;

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceAttachment
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=0.0,A=1.0)))
	End Object

	// Weapon SkeletalMesh
	Begin Object Name=SkeletalMeshComponent0
		Materials(0)=MyMaterialInstanceAttachment
	End Object

	WeaponClass=class'TestCWR_SuperDeemerWeapon'
}

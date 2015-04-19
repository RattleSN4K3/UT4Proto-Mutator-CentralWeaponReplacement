class TestCWR_TranslocatorAttachment extends UTAttachment_Translocator;

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceAttachment
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=1.0,A=1.0)))
	End Object

	// Weapon SkeletalMesh
	Begin Object Name=SkeletalMeshComponent0
		Materials(0)=MyMaterialInstanceAttachment
	End Object

	TeamSkins[0]=MyMaterialInstanceAttachment
	TeamSkins[1]=MyMaterialInstanceAttachment

	WeaponClass=class'TestCWR_TranslocatorWeapon'
}

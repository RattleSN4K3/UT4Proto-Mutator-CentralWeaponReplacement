class TestCWR_RailGunWeapon extends UTWeap_ShockRifle;

Defaultproperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstance
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=1.0,B=1.0,A=1.0)))
	End Object

	Begin Object Name=FirstPersonMesh
	    Materials(0)=MyMaterialInstance
	End Object

	Begin Object Name=PickupMesh
		Materials(0)=MyMaterialInstance
	End Object

	AttachmentClass=class'TestCWR_RailGunAttachment'

	ItemName="Rail Gun"
	PickupMessage="Rail Gun"
}
class TestCWR_RailGunAttachment extends UTAttachment_ShockRifle;

simulated function SetSkin(Material NewMaterial)
{
	local int i, Cnt;
	local MaterialInstanceConstant MIC;
	Cnt = Mesh.Materials.Length;
	for ( i=0; i < Cnt || Cnt == 0; i++ )
	{
		Mesh.SetMaterial(i, MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01');
		MIC = Mesh.CreateAndSetMaterialInstanceConstant(i);
		MIC.SetVectorParameterValue('Diffuse_01_Color', MakeLinearColor(1.0, 1.0, 1.0, 1.0));
		if (Cnt == 0) break;
	}
}

DefaultProperties
{
}

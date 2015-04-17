class TestCWR_SuperDeemerRemote extends UTRemoteRedeemer_Content;

simulated state Dying
{

Begin:
	Instigator = self;
	if (Role == ROLE_Authority && !WorldInfo.Game.IsInState('MatchOver'))
	{
		DriverLeave(true);
	}
	PlaySound(RedeemerProjClass.default.ExplosionSound, true);
	RedeemerProjClass.static.RedeemerHurtRadius(0.125, self, InstigatorController);
	Sleep(0.5);
	RedeemerProjClass.static.RedeemerHurtRadius(0.300, self, InstigatorController);
	Sleep(0.2);
	if (Role == ROLE_Authority && !WorldInfo.Game.IsInState('MatchOver'))
	{
		RedeemerProjClass.static.DoKnockdown(Location, WorldInfo, InstigatorController);
	}
	RedeemerProjClass.static.RedeemerHurtRadius(0.8, self, InstigatorController);
	Sleep(0.2);
	RedeemerProjClass.static.RedeemerHurtRadius(1.0, self, InstigatorController);
	if (Role == ROLE_Authority && !WorldInfo.Game.IsInState('MatchOver'))
	{
		Destroy();
	}
}

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceAttachment
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=0.0,A=1.0)))
	End Object

	Begin Object Name=WRocketMesh
		Materials(0)=MyMaterialInstanceAttachment
		Scale=2.0
	End Object

	AirSpeed=1400.0
	RedeemerProjClass=class'TestCWR_SuperDeemerProjectile'
}

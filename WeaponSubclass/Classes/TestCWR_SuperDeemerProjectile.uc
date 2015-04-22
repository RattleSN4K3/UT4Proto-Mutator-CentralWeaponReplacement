class TestCWR_SuperDeemerProjectile extends UTProj_Redeemer;

simulated state Dying
{
Begin:
	RedeemerHurtRadius(0.125, self, InstigatorController);
	Sleep(0.5);
	RedeemerHurtRadius(0.300, self, InstigatorController);
	if (Role == ROLE_Authority)
	{
		DoKnockdown(Location, WorldInfo, InstigatorController);
	}
	Sleep(0.2);
	RedeemerHurtRadius(0.8, self, InstigatorController);
	Sleep(0.2);
	RedeemerHurtRadius(1.0, self, InstigatorController);
	Shutdown();
}

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstanceProjectile
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=0.0,A=1.0)))
	End Object

	Begin Object Name=ProjectileMesh
		Materials(0)=MyMaterialInstanceProjectile
		CullDistance=20000
		Scale=2.0
	End Object

	DistanceExplosionTemplates[0]=(Template=ParticleSystem'WP_Redeemer.Particles.P_WP_Redeemer_Explo_Far',MinDistance=2200.0)
	DistanceExplosionTemplates[1]=(Template=ParticleSystem'WP_Redeemer.Particles.P_WP_Redeemer_Explo_Far',MinDistance=1500.0)
	DistanceExplosionTemplates[2]=(Template=ParticleSystem'WP_Redeemer.Particles.P_WP_Redeemer_Explo_Far',MinDistance=0.0)


	speed=1400.0
	MaxSpeed=1600.0
	Damage=125.0
	DamageRadius=1200.0
	MomentumTransfer=80000
	LifeSpan=30.00
}

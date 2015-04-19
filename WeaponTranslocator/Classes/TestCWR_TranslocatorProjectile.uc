class TestCWR_TranslocatorProjectile extends UTProj_TransDisc_ContentRed;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (Role == ROLE_Authority)
	{
		Translocate();
	}
}

simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	if (Role == ROLE_Authority)
	{
		Translocate();
	}
}

function Translocate()
{
	if (MyTranslocator != None)
	{
		MyTranslocator.CustomFire();
	}
}

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstance
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues(0)=(ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=1.0,A=1.0))
	End Object

	Begin Object Name=ProjectileMesh
		Materials(0)=MyMaterialInstance
	End Object

	Physics=PHYS_Projectile
	TossZ=0
	bBounce=false

	speed=2000.0
	MaxSpeed=2000.0
	LifeSpan=10
}

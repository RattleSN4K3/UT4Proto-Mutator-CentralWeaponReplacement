class TestCWR_RipperProjectile extends UTProjectile;

DefaultProperties
{
	ProjFlightTemplate=ParticleSystem'WP_Translocator.Particles.P_WP_Translocator_Trail_Red'

	// Add the mesh
	Begin Object Class=StaticMeshComponent Name=ProjectileMesh
		StaticMesh=StaticMesh'WP_Translocator.Mesh.S_Translocator_Disk'
		Materials(0)=MaterialInterface'WP_Translocator.Materials.M_WP_Translocator_1PRed_unlit'
		Scale=1

		CastShadow=false
		bAcceptsLights=false
		Translation=(Z=2)
		CollideActors=false
		CullDistance=6000
		BlockRigidBody=false
		BlockActors=false
		bUseAsOccluder=FALSE
	End Object

	Speed=1300.0
	MaxSpeed=1200.0
	Damage=30.0
	MomentumTransfer=15000

	bCollideWorld=true
	bNetTemporary=false
	Physics=PHYS_Falling
	bSwitchToZeroCollision=false

	Begin Object Name=CollisionCylinder
		CollisionRadius=5
		CollisionHeight=2
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		CollideActors=true
	End Object

	bBounce=true
	LifeSpan=6.0
}

class TestCWR_RipperWeapon extends UTWeapon;

var ParticleSystemComponent DiskEffect;

simulated function PostBeginPlay()
{
	local SkeletalMeshComponent SKMesh;

	// Attach the Muzzle Flash
	SKMesh = SkeletalMeshComponent(Mesh);
	super.PostBeginPlay();
	if (  SKMesh != none )
	{
		SKMesh.AttachComponentToSocket(DiskEffect, MuzzleFlashSocket);
	}
}

function ItemRemovedFromInvManager()
{
	Super.ItemRemovedFromInvManager();

	if(DiskEffect != none)
	{
		DiskEffect.DeactivateSystem();
	}
}

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstance
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues(0)=(ParameterName="Diffuse_01_Color",ParameterValue=(R=0.0,G=1.0,B=0.0,A=1.0))
	End Object

	ItemName="Ripper"
	PickupMessage="Ripper"

	Begin Object class=AnimNodeSequence Name=MeshSequenceA
	End Object

	Begin Object Name=FirstPersonMesh
		SkeletalMesh=SkeletalMesh'WP_Translocator.Mesh.SK_WP_Translocator_1P'
		PhysicsAsset=None
		AnimSets(0)=AnimSet'WP_Translocator.Anims.K_WP_Translocator_1P_Base'
		Materials(0)=MaterialInterface'WP_Translocator.Materials.M_Gun_Ark'
		Materials(1)=MyMaterialInstance
		Animations=MeshSequenceA
		Scale=1
		FOV=55.0
	End Object
	AttachmentClass=class'TestCWR_RipperAttachment'

	//EmptyPutDownAnim=weaponputdownempty
	//EmptyEquipAnim=weaponequipempty

	Begin Object Name=PickupMesh
		SkeletalMesh=SkeletalMesh'WP_Translocator.Mesh.SK_WP_Translocator_3p_Mid'
		Materials(0)=MyMaterialInstance
	End Object

	WeaponFireSnd[0]=SoundCue'A_Weapon_Translocator.Translocator.A_Weapon_Translocator_Fire_Cue'
	WeaponFireSnd[1]=SoundCue'A_Weapon_Translocator.Translocator.A_Weapon_Translocator_Teleport_Cue'
	WeaponEquipSnd=SoundCue'A_Weapon_Translocator.Translocator.A_Weapon_Translocator_Raise_Cue'
	WeaponPutDownSnd=SoundCue'A_Weapon_Translocator.Translocator.A_Weapon_Translocator_Lower_Cue'

	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_Projectile
	WeaponProjectiles(0)=class'TestCWR_RipperProjectile'
	WeaponProjectiles(1)=class'TestCWR_RipperProjectile'

	ArmsAnimSet=AnimSet'WP_Translocator.Anims.K_WP_Translocator_1P_Arms'

	WeaponFireAnim(0)=WeaponFire
	WeaponFireAnim(1)=none
	ArmFireAnim(0)=WeaponFire
	ArmFireAnim(1)=none

	CrossHairCoordinates=(U=0,V=0,UL=64,VL=64)
	IconCoordinates=(U=600,V=461,UL=122,VL=54)

	Begin Object Class=ParticleSystemComponent Name=DiskInEffect
		Template=ParticleSystem'WP_Translocator.Particles.P_WP_Translocator_idle'
		DepthPriorityGroup=SDPG_Foreground
		SecondsBeforeInactive=1.0f
	End Object
	DiskEffect=DiskInEffect
	Components.Add(DiskInEffect)
	MuzzleFlashSocket=MuzzleFlash

	MaxDesireability=0.75
	AIRating=+0.5
	CurrentRating=0.55
	bInstantHit=false
	bSplashJump=false
	bRecommendSplashDamage=true
	bSniping=false
	ShouldFireOnRelease(0)=0
	ShouldFireOnRelease(1)=0

	FireInterval(0)=+0.5
	FireInterval(1)=+0.83

	InventoryGroup=3
	GroupWeight=0.5

	QuickPickGroup=1
	QuickPickWeight=0.8

	AmmoCount=15
	LockerAmmoCount=25
	MaxAmmoCount=40
}

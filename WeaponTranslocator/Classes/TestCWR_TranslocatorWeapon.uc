class TestCWR_TranslocatorWeapon extends UTWeap_Translocator_Content;

simulated event float GetPowerPerc();
simulated function ReAddAmmo();
simulated function bool HasAmmo(byte FireModeNum, optional int Amount)
{
	return true;
}

simulated function DrawWeaponCrosshair( Hud HUD )
{
	if ( GetZoomedState() == ZST_NotZoomed )
	{
		return;
	}

	super.DrawWeaponCrosshair(HUD);
}

simulated function EndFire(byte FireModeNum)
{
	local UTPlayerController PC;
	super.EndFire(FireModeNum);

	if (FireModeNum == 1 && WorldInfo.NetMode != NM_DedicatedServer && Instigator != None)
	{
		PC = UTPlayerController(Instigator.Controller);
		if (PC != None && LocalPlayer(PC.Player) != none && FireModeNum < bZoomedFireMode.Length && bZoomedFireMode[FireModeNum] != 0 )
		{
			EndZoom(PC);
		}
	}
}

DefaultProperties
{
	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstance
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues(0)=(ParameterName="Diffuse_01_Color",ParameterValue=(R=1.0,G=0.0,B=1.0,A=1.0))
	End Object

	Begin Object Name=FirstPersonMesh
		Materials(1)=MyMaterialInstance
	End Object
	AttachmentClass=class'TestCWR_TranslocatorAttachment'

	Begin Object Name=PickupMesh
		Materials(0)=MyMaterialInstance
	End Object

	TeamSkins(0)=MyMaterialInstance
	TeamSkins(1)=MyMaterialInstance

	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_Projectile
	WeaponProjectiles(0)=class'TestCWR_TranslocatorProjectile'
	WeaponProjectiles(1)=class'TestCWR_TranslocatorProjectile'

	FiringStatesArray(0)=WeaponFiring
	FiringStatesArray(1)=WeaponFiring

	WeaponFireAnim(0)=WeaponFire
	WeaponFireAnim(1)=WeaponFire
	ArmFireAnim(0)=WeaponFire
	ArmFireAnim(1)=WeaponFire

	FireInterval(0)=+0.25
	FireInterval(1)=+0.40

	ShotCost(0)=0
	ShotCost(1)=0

	AmmoDisplayType=EAWDS_None

	// Zoom
	ZoomedTargetFOV=40.0
	ZoomedRate=200.0
	bZoomedFireMode(1)=1
	bSniping=true


	ItemName="BeamerGun"
	PickupMessage="BeamerGun"
}

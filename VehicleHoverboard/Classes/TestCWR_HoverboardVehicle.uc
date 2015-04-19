class TestCWR_HoverboardVehicle extends UTVehicle_Hoverboard;

Defaultproperties
{
	Seats(0)={(GunClass=class'TestCWR_HoverboardWeapon',
				GunSocket=(FireSocket),
				CameraTag=b_Hips,
				CameraOffset=-200,
				DriverDamageMult=1.0,
				bSeatVisible=true,
				SeatBone=UpperBody,
				SeatOffset=(X=0,Y=0,Z=51))}

	Begin Object Class=MaterialInstanceConstant Name=MyMaterialInstance
		Parent=MaterialInterface'Engine_MI_Shaders.Instances.M_ES_Phong_Opaque_INST_01'
		VectorParameterValues.Add((ParameterName="Diffuse_01_Color",ParameterValue=(R=0.0,G=0.0,B=0.0,A=1.0)))
	End Object

	Begin Object Name=SVehicleMesh
		Materials(0)=MyMaterialInstance
	End Object

	VehiclePositionString="in a FasterBoard"
	VehicleNameString="FasterBoard"

	COMOffset=(x=10.0,y=0.0,z=-5.0)

	AirSpeed=1800
	GroundSpeed=1600.0
	MaxSpeed=2400.0

	bStayUpright=true
	LeanUprightStiffness=5000
	LeanUprightDamping=600


	Begin Object Name=SimObject
		WheelSuspensionStiffness=200.0
		WheelSuspensionDamping=20.0
		WheelSuspensionBias=0.0
		WheelLatExtremumValue=0.7

		MaxThrustForce=350.0
		MaxReverseForce=160.0
		MaxReverseVelocity=300.0
		//LongDamping=0.8 //0.3

		//MaxStrafeForce=150.0
		//LatDamping=0.8 //0.3

		//MaxUphillHelpThrust=150.0
		//UphillHelpThrust=175.0

		//TurnTorqueFactor=800.0
		//SpinTurnTorqueScale=3.5
		//MaxTurnTorque=1000.0
		//TurnDampingSpeedFunc=(Points=((InVal=0,OutVal=0.05),(InVal=300,OutVal=0.11),(InVal=800,OutVal=0.12)))
		//FlyingTowTurnDamping=0.2
		//FlyingTowRelVelDamping=0.2
		//TowRelVelDamping=0.01
	End Object


	//Begin Object Name=HoverWheelFL
	//	BoneOffset=(X=25.0,Y=0.0,Z=-50.0)
	//	WheelRadius=10
	//	SuspensionTravel=30
	//	bPoweredWheel=true
	//	LongSlipFactor=0
	//	LatSlipFactor=100
	//	HandbrakeLongSlipFactor=0
	//	HandbrakeLatSlipFactor=150
	//	SteerFactor=1.0
	//	bHoverWheel=false //true
	//End Object

	//Begin Object Name=HoverWheelRL
	//	BoneOffset=(X=0.0,Y=0,Z=-50.0)
	//	WheelRadius=10
	//	SuspensionTravel=30
	//	bPoweredWheel=true
	//	LongSlipFactor=0
	//	LatSlipFactor=100
	//	HandbrakeLongSlipFactor=0
	//	HandbrakeLatSlipFactor=150
	//	SteerFactor=0.0
	//	bHoverWheel=false //true
	//End Object

	bRotateCameraUnderVehicle=false
	bNoFollowJumpZ=false
}
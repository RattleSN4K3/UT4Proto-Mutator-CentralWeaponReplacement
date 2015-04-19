class TestCWR_HoverboardMutator extends UTMutator;

var class<UTVehicle> ReplaceVehicleClass;
var class<UTVehicle> NewVehicleClass;


/* called by GameInfo.RestartPlayer()
	change the players jumpz, etc. here
*/
function ModifyPlayer(Pawn Other)
{
	local UTPawn UTP;
	super.ModifyPlayer(Other);

	UTP = UTPawn(Other);
	if (UTP != none && UTP.HoverboardClass == ReplaceVehicleClass)
	{
		UTP.HoverboardClass = NewVehicleClass;
	}
}

DefaultProperties
{
	ReplaceVehicleClass=class'UTVehicle_Hoverboard'
	NewVehicleClass=class'TestCWR_HoverboardVehicle'
}

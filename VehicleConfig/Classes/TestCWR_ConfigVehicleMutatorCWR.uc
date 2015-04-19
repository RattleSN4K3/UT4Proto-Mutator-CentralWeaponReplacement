class TestCWR_ConfigVehicleMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigVehicle);

var config name ReplaceVehicleClassName;
var config ReplacementOptionsInfo ReplaceVehicleOptions;

static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements)
{
	if (default.ReplaceVehicleClassName != '')
	{
		Replacements.AddItem(CreateTemplate(RT_Vehicle, default.ReplaceVehicleClassName, PathName(class'UTVehicleFactory_Scorpion'), default.ReplaceVehicleOptions));
	}
}

DefaultProperties
{
	ReplaceVehicleClassName="UTVehicleFactory_Goliath"
	ReplaceVehicleOptions=()
}

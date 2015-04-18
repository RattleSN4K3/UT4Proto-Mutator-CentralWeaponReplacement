class TestCWR_ConfigPowerupMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigPowerup);

var config name ReplacePowerupClassName;
var config ReplacementOptionsInfo ReplacePowerupOptions;

static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements)
{
	if (default.ReplacePowerupClassName != '')
	{
		Replacements.AddItem(CreateTemplate(RT_Powerup, default.ReplacePowerupClassName, PathName(class'UTPickupFactory_JumpBoots'), default.ReplacePowerupOptions));
	}
}

DefaultProperties
{
	ReplacePowerupClassName="UTPickupFactory_UDamage"
	ReplacePowerupOptions=()
}

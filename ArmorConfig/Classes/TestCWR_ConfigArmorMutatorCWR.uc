class TestCWR_ConfigArmorMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigArmor);

var config name ReplaceArmorClassName;
var config ReplacementOptionsInfo ReplaceArmorOptions;

static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements)
{
	if (default.ReplaceArmorClassName != '')
	{
		Replacements.AddItem(CreateTemplate(RT_Armor, default.ReplaceArmorClassName, PathName(class'UTArmorPickup_Thighpads'), default.ReplaceArmorOptions));
	}
}

DefaultProperties
{
	ReplaceArmorClassName="UTArmorPickup_ShieldBelt"
	ReplaceArmorOptions=()
}

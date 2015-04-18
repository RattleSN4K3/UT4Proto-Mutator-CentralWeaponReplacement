class TestCWR_ConfigHealthMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigHealth);

var config name ReplaceHealthClassName;
var config ReplacementOptionsInfo ReplaceHealthOptions;

static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements)
{
	if (default.ReplaceHealthClassName != '')
	{
		Replacements.AddItem(CreateTemplate(RT_Health, default.ReplaceHealthClassName, PathName(class'UTPickupFactory_HealthVial'), default.ReplaceHealthOptions));
	}
}

DefaultProperties
{
	ReplaceHealthClassName="UTPickupFactory_MediumHealth"
	ReplaceHealthOptions=()
}

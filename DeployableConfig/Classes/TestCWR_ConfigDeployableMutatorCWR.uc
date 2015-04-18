class TestCWR_ConfigDeployableMutatorCWR extends TestCWRTemplate
	config(TestCWR_ConfigDeployable);

var config name ReplaceDeployableClassName;
var config ReplacementOptionsInfo ReplaceDeployableOptions;

static function StaticGetDynamicReplacements(out array<TemplateDynamicInfo> Replacements)
{
	if (default.ReplaceDeployableClassName != '')
	{
		Replacements.AddItem(CreateTemplate(RT_Deployable, default.ReplaceDeployableClassName, PathName(class'UTDeployableSlowVolume'), default.ReplaceDeployableOptions));
	}
}

DefaultProperties
{
	ReplaceDeployableClassName="UTDeployableSpiderMineTrap"
	ReplaceDeployableOptions=()
}

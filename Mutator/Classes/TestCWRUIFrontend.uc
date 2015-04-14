class TestCWRUIFrontend extends UTUIFrontEnd_Mutators;

//**********************************************************************************
// Inherited functions
//**********************************************************************************

/** Post initialization event - Setup widget delegates.*/
event PostInitialize()
{
	// force scenetag for proper title
	SceneTag = 'Mutators';

	super.PostInitialize();
}

/** Scene activated event, sets up the title for the scene. */
event SceneActivated(bool bInitialActivation)
{
	Super.SceneActivated(bInitialActivation);

	if (bInitialActivation)
	{
		InitUICheck();
	}
}

/** Called just after this scene is removed from the active scenes array */
event SceneDeactivated()
{
	super.SceneDeactivated();

	CleanupUICheck();
}

/** Modifies the enabled mutator array to enable/disable a mutator. */
function SetMutatorEnabled(int MutatorId, bool bEnabled)
{
	local string ClassPath, s;
	local int cnt;
	local class<Mutator> Mutclass;

	ClassPath = string(GetClassNameFromIndex(MutatorId));

	if (bEnabled)
	{
		if (IsInConflict(ClassPath, s, Mutclass))
		{
			s = Repl("Unable to add `mutator.", "`mutator", class'TestCWRUI'.static.GetMutatorName(Mutclass))$Chr(10)$s;
			DisplayMessageBox(s, class'TestCWRUI'.static.GetMutatorName(class'TestCentralWeaponReplacement'));
			return;
		}
	}

	cnt = EnabledList.Items.length;
	super.SetMutatorEnabled(MutatorId, bEnabled);
	if (cnt != EnabledList.Items.length) PreInit(ClassPath, bEnabled, Mutclass);
}

//**********************************************************************************
// Main CWR functions
//**********************************************************************************

function InitUICheck()
{
	local int i;
	local name n;
	local class<Mutator> mutclass;

	class'TestCentralWeaponReplacement'.static.StaticPreInitialize();

	for (i=0; i<MenuDataStore.EnabledMutators.Length; i++)
	{
		n = GetClassNameFromIndex(MenuDataStore.EnabledMutators[i]);
		if (GetMutatorClass(n, mutclass))
		{
			mutclass.static.Localize("PreAdd", "", "");
		}
	}
}

function CleanupUICheck()
{
	class'TestCentralWeaponReplacement'.static.StaticPreDestroy();
}

//**********************************************************************************
// CWR helper functions
//**********************************************************************************

function bool GetMutatorClass(coerce string ClassPath, out class<Mutator> OutClass)
{
	OutClass = class<Mutator>(DynamicLoadObject(ClassPath, class'Class'));
	return OutClass != none;
}

function bool IsInConflict(string ClassPath, out string ErrorMessage, optional out class<Mutator> OutMutclass)
{
	local string s;
	local array<string> strs;
	if (GetMutatorClass(ClassPath, OutMutclass))
	{
		s = OutMutclass.static.Localize("IsConflicting", "", "");
		ParseStringIntoArray(s, strs, Chr(10), false);
		if (strs.Length > 1 && (strs[0] == "1" || strs[0] ~= "true" || strs[0] ~= "yes"))
		{
			ErrorMessage = strs[1];
			return true;
		}
	}

	return false;
}

function bool PreInit(string ClassPath, bool bAdd, optional class<Mutator> Mutclass)
{
	if (Mutclass != none || GetMutatorClass(ClassPath, mutclass))
	{
		Mutclass.static.Localize(bAdd ? "PreAdd" : "PreRemove", "", "");
		return true;
	}

	return false;
}

DefaultProperties
{
}


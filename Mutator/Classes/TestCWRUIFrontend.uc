class TestCWRUIFrontend extends UTUIFrontEnd_Mutators;

var protected int PendingMutatorId;
var protected string PendingClassPath;

var localized string ErrorMessage;
var localized string ErrorQuery;

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
	local string error, msg, title;
	local class<Mutator> Mutclass;
	local UTUIScene_MessageBox MessageBoxReference;

	PendingMutatorId = INDEX_NONE;
	PendingClassPath = string(GetClassNameFromIndex(MutatorId));

	if (bEnabled)
	{
		if (IsInConflict(PendingClassPath, error, Mutclass))
		{
			PendingMutatorId = MutatorId;

			title = class'TestCWRUI'.static.GetMutatorName(class'TestCentralWeaponReplacement');
			MessageBoxReference = GetMessageBoxScene();

			msg = ErrorMessage;
			msg = Repl(msg, "`query", MessageBoxReference != none ? ErrorQuery : "");
			msg = Repl(msg, "`error", error);
			msg = Repl(msg, "`mutator", class'TestCWRUI'.static.GetMutatorName(Mutclass));
			msg = Repl(msg, "  ", Chr(10));

			if(MessageBoxReference != none)
			{	
				MessageBoxReference.DisplayAcceptCancelBox(msg, title, OnMutator_Add_Confirm);
			}
			else
			{
				DisplayMessageBox(msg, title);
			}
			return;
		}
	}

	SetMutatorEnabledNoCheck(MutatorId, bEnabled);
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

/** Modifies the enabled mutator array to enable/disable a mutator. */
function SetMutatorEnabledNoCheck(int MutatorId, bool bEnabled)
{
	local int cnt;
	
	cnt = EnabledList.Items.length;
	super.SetMutatorEnabled(MutatorId, bEnabled);
	if (cnt != EnabledList.Items.length) PreInit(PendingClassPath, bEnabled);
}

/** Confirmation for adding conflicting mutator. */
function OnMutator_Add_Confirm(UTUIScene_MessageBox MessageBox, int SelectedItem, int PlayerIndex)
{
	if(SelectedItem == 0)
	{
		SetMutatorEnabledNoCheck(PendingMutatorId, true);
	}
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
	ErrorMessage="Unable to add `mutator.  `error`query"
	ErrorQuery="    Do you want to continue enabling the mutator?"
}


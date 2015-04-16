class TestCWRUIFrontend extends UTUIFrontEnd_Mutators;

var protected int PendingEnableMutatorId;
var protected string PendingEnableClassPath;

var protected bool PendingConfigureOpened;
var protected bool PendingConfigurePre, PendingConfigurePost;
var protected int PendingConfigureMutatorId;
var protected string PendingConfigureClassPath;

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
	else if (PendingConfigureOpened && PendingConfigureClassPath != "")
	{
		PreUpdate(PendingConfigureMutatorId, PendingConfigureClassPath);
		PendingConfigureOpened = false;
		PendingConfigureClassPath = "";
	}
}

/** Called just after this scene is removed from the active scenes array */
event SceneDeactivated()
{
	super.SceneDeactivated();

	CleanupUICheck();
}

/**
 * Called when a new scene is opened over this one.  Propagates the values for bRequiresNetwork and bRequiresOnlineService to the new page.
 */
function ChildSceneOpened( UIScene NewTopScene )
{
	if (PendingConfigurePost)
	{
		PendingConfigurePost = false;
		PendingConfigureOpened = true;
	}

	super.ChildSceneOpened(NewTopScene);
}

/** @return Opens the message box scene and returns a reference to it. */
function UTUIScene_MessageBox GetMessageBoxScene(optional UIScene SceneReference = None)
{
	PendingConfigurePre = false;
	return super.GetMessageBoxScene(SceneReference);
}

/** Opens a UI Scene given a reference to a scene to open. */
function UIScene OpenScene(UIScene SceneToOpen, optional bool bSkipAnimation=false, optional delegate<OnSceneActivated> SceneDelegate=None)
{
	if (PendingConfigurePre) PendingConfigurePost = true;
	PendingConfigurePre = false;

	return super.OpenScene(SceneToOpen, bSkipAnimation, SceneDelegate);
}

/** Modifies the enabled mutator array to enable/disable a mutator. */
function SetMutatorEnabled(int MutatorId, bool bEnabled)
{
	local string error;
	local class<Mutator> Mutclass;
	
	PendingEnableMutatorId = INDEX_NONE;
	PendingEnableClassPath = string(GetClassNameFromIndex(MutatorId));

	if (bEnabled)
	{
		if (IsInConflict(PendingEnableClassPath, error, Mutclass))
		{
			PendingEnableMutatorId = MutatorId;
			PrintErrorMessageFor(error, Mutclass);

			return;
		}
	}

	SetMutatorEnabledNoCheck(MutatorId, bEnabled);
}

/** Loads the configuration scene for the currently selected mutator. */
function OnConfigureMutator()
{
	PendingConfigurePre = true;
	PendingConfigureMutatorId = EnabledList.GetCurrentItem();
	PendingConfigureClassPath = string(GetClassNameFromIndex(PendingConfigureMutatorId));

	super.OnConfigureMutator();
	PendingConfigurePre = false;
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
	if (cnt != EnabledList.Items.length) PreInit(PendingEnableClassPath, bEnabled);
}

/** Confirmation for adding conflicting mutator. */
function OnMutator_Add_Confirm(UTUIScene_MessageBox MessageBox, int SelectedItem, int PlayerIndex)
{
	if(SelectedItem == 0)
	{
		SetMutatorEnabledNoCheck(PendingEnableMutatorId, true);
	}
}

function PrintErrorMessageFor(string InError, class<Mutator> Mutclass, optional bool NoQuery)
{
	local string msg, title;
	local UTUIScene_MessageBox MessageBoxReference;

	title = class'TestCWRUI'.static.GetMutatorName(class'TestCentralWeaponReplacement');
	MessageBoxReference = GetMessageBoxScene();
	if (MessageBoxReference == none)
		return;

	msg = ErrorMessage;
	msg = Repl(msg, "`query", NoQuery ? "" : ErrorQuery);
	msg = Repl(msg, "`error", InError);
	msg = Repl(msg, "`mutator", class'TestCWRUI'.static.GetMutatorName(Mutclass));
	msg = Repl(msg, "  ", Chr(10));

	if (NoQuery) MessageBoxReference.Display(msg, title);
	else MessageBoxReference.DisplayAcceptCancelBox(msg, title, OnMutator_Add_Confirm);
}

//**********************************************************************************
// CWR helper functions
//**********************************************************************************

function bool GetMutatorClass(coerce string ClassPath, out class<Mutator> OutClass)
{
	OutClass = class<Mutator>(DynamicLoadObject(ClassPath, class'Class'));
	return OutClass != none;
}

function bool IsInConflict(string ClassPath, out string OutErrorMessage, optional out class<Mutator> OutMutclass)
{
	local string s;
	local array<string> strs;
	if (GetMutatorClass(ClassPath, OutMutclass))
	{
		s = OutMutclass.static.Localize("IsConflicting", "", "");
		ParseStringIntoArray(s, strs, Chr(10), false);
		if (strs.Length > 1 && (strs[0] == "1" || strs[0] ~= "true" || strs[0] ~= "yes"))
		{
			OutErrorMessage = strs[1];
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

function bool PreUpdate(int MutatorId, string ClassPath, optional class<Mutator> Mutclass)
{
	local int i;
	local string OtherClassPath;
	local class<Mutator> OtherMutclass;
	local string msg;

	if (Mutclass != none || GetMutatorClass(ClassPath, mutclass))
	{
		Mutclass.static.Localize("PreUpdate", "", "");

		// check current mutator and if 
		if (IsInConflict(ClassPath, msg))
		{
			PrintErrorMessageFor(msg, Mutclass, true);
		}

		//@TODO: check every following mutator and print multiple error message
		else
		{
			i = EnabledList.Items.Find(MutatorId);
			for (i=i; i<EnabledList.Items.Length; i++)
			{
				OtherClassPath = ""$GetClassNameFromIndex(EnabledList.Items[i]);
				if (IsInConflict(OtherClassPath, msg, OtherMutclass))
				{
					PrintErrorMessageFor(msg, OtherMutclass, true);
					break;
				}
			}
		}

		return true;
	}

	return false;
}

DefaultProperties
{
	ErrorMessage="Unable to add `mutator.    `error`query"
	ErrorQuery="    Do you want to continue enabling the mutator?"
}


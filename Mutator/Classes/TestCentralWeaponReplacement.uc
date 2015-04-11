class TestCentralWeaponReplacement extends UTMutator_WeaponReplacement
	config(TestCentralWeaponReplacement);

const DialogDefaultColor = "<color:R=1,G=1,B=1,A=1>";

//**********************************************************************************
// Structs
//**********************************************************************************

struct ReplacementInfoEx
{
	var Object Registrar;
};

struct ErrorMessageInfo
{
	var Object Conflict;
	var Object Registrar;
	var name ClassName;
	var string NewClassPath;
};

struct HashedMutatorInfo
{
	var string Hash;
	var UTUIDataProvider_Mutator Info;
};

struct HashedWeaponInfo
{
	var string Hash;
	var name ClassName;
	var UTUIDataProvider_Weapon Info;
};

struct HashedAmmoInfo
{
	var string Hash;
	var name ClassName;
	var string Text;
};

//**********************************************************************************
// Variables
//**********************************************************************************

// Config
// ------------

var config array<ReplacementInfo> DefaultWeaponsToReplace;
var config array<ReplacementInfo> DefaultAmmoToReplace;

// Workflow
// ------------

var array<ReplacementInfoEx> WeaponsToReplaceEx;
var array<ReplacementInfoEx> AmmoToReplaceEx;

var array<HashedMutatorInfo> HashedMutators;
var array<HashedWeaponInfo> HashedWeapons;
var array<HashedAmmoInfo> HashedAmmos;

// UI
// ------------

var array<ErrorMessageInfo> ErrorMessages;

var() string DialogNameColor;
var() string DialogGoodColor;
var() string DialogBadColor;

// Localization
// ------------

var localized string MessageErrors;
var localized string MessageClassReplacedBy;
var localized string MessageClassReplacedDefault;
var localized string MessageClassSubstBy;
var localized string MessageClassSubstDefault;
var localized string MessageClassRemovedBy;
var localized string MessageClassRemovedDefault;

//**********************************************************************************
// Inherited functions
//**********************************************************************************

/* Don't call Actor PreBeginPlay() for Mutator
*/
event PreBeginPlay()
{
	local int i;
	super.PreBeginPlay();

	if (!IsPendingKill())
	{
		WeaponsToReplace.Length = 0;
		AmmoToReplace.Length = 0;

		for (i=0; i<DefaultWeaponsToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultWeaponsToReplace[i].OldClassName, DefaultWeaponsToReplace[i].NewClassPath, false);

		for (i=0; i<DefaultAmmoToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultAmmoToReplace[i].OldClassName, DefaultAmmoToReplace[i].NewClassPath, true);
	}
}

// called when gameplay actually starts
function MatchStarting()
{
	local int i;
	local string str;

	super.MatchStarting();

	if (ErrorMessages.Length > 0 && WorldInfo.NetMode != NM_DedicatedServer)
	{
		// init datastore for weapons and mutators
		LoadMutators();
		LoadWeapons();

		for (i=0; i<ErrorMessages.Length; i++)
		{
			if (str != "" || i > 0)
				str $= Chr(10);
			str $= GenerateErrorInfo(ErrorMessages[i]);
		}

		// clear out data
		HashedMutators.Length = 0;
		HashedWeapons.Length = 0;
		HashedAmmos.Length = 0;

		str = Repl(Repl(MessageErrors, "  ", Chr(10)), "`errors", str);
		ShowMessageBox(str, GetHumanReadableName());
	}
}

// Returns the human readable string representation of an object.
simulated function String GetHumanReadableName()
{
	return GetMutatorName(self);
}

//**********************************************************************************
// Interface functions
//**********************************************************************************

function RegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, bool bAmmo)
{
	local int index;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	NewClassPath = TrimRight(NewClassPath);

	if (bAmmo)
	{
		if (IsNewItem(AmmoToReplace, index, OldClassName))
		{
			AddWeaponReplacement(true, Registrar, OldClassName, NewClassPath);
		}
		else if (!(AmmoToReplace[index].NewClassPath ~= NewClassPath))
		{
			AddErrorMessage(AmmoToReplaceEx[index].Registrar, Registrar, OldClassName, NewClassPath);
		}
	}
	else if (IsNewItem(WeaponsToReplace, index, OldClassName))
	{
		AddWeaponReplacement(false, Registrar, OldClassName, NewClassPath);
	}
	else if (!(WeaponsToReplace[index].NewClassPath ~= NewClassPath))
	{
		AddErrorMessage(WeaponsToReplaceEx[index].Registrar, Registrar, OldClassName, NewClassPath);
	}
}

static function bool StaticRegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, bool bAmmo, optional bool bSilent, optional out string ErrorMessage)
{
	local WorldInfo WI;
	local TestCentralWeaponReplacement mut;

	if (Registrar == none)
	{
		ErrorMessage = "No Registrar.";
		return false;
	}

	if (Actor(Registrar) != none)
		WI = Actor(Registrar).WorldInfo;
	if (WI == none)
		WI = class'Engine'.static.GetCurrentWorldInfo();

	if (WI == none)
	{
		ErrorMessage = "No WorldInfo found.";
		return false;
	}

	// try to find an existent gneric mutator
	foreach WI.DynamicActors(class'TestCentralWeaponReplacement', mut)
		break;

	// if not mutator was found, create one
	if (mut == none)
	{
		mut = WI.Spawn(class'TestCentralWeaponReplacement', WI.Game);
		if (WI.Game != none)
		{
			mut.NextMutator = WI.Game.BaseMutator;
			WI.Game.BaseMutator = mut;
		}
	}

	// register the weapon replacement
	mut.RegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo);
	return true;
}

//**********************************************************************************
// Private functions
//**********************************************************************************

private function AddWeaponReplacement(bool bAmmo, Object Registrar, name OldClassName, string NewClassPath)
{
	local int i;
	local ReplacementInfo base;
	local ReplacementInfoEx ex;
	base.OldClassName = OldClassName;
	base.NewClassPath = NewClassPath;
	ex.Registrar = Registrar;

	if (bAmmo)
	{
		i = AmmoToReplace.Length;
		AmmoToReplaceEx.Length = i;
		AmmoToReplace[i] = base;
		AmmoToReplaceEx[i] = ex;
	}
	else
	{
		i = WeaponsToReplace.Length;
		WeaponsToReplaceEx.Length = i;
		WeaponsToReplace[i] = base;
		WeaponsToReplaceEx[i] = ex;
	}
}

private function AddErrorMessage(Object Conflicting, Object Registrar, name OldClassName, string NewClassPath)
{
	local int index;
	index = ErrorMessages.Length;
	ErrorMessages.Add(1);
	ErrorMessages[index].Conflict = Conflicting;
	ErrorMessages[index].Registrar = Registrar;
	ErrorMessages[index].ClassName = OldClassName;
	ErrorMessages[index].NewClassPath = NewClassPath;
}

private function LoadMutators()
{
	local array<UTUIResourceDataProvider> ProviderList;
	local int i;
	local string hash;
	local UTUIDataProvider_Mutator mut;
	local HashedMutatorInfo item;

	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UTUIDataProvider_Mutator', ProviderList);
	for (i=0; i<ProviderList.length; i++)
	{
		mut = UTUIDataProvider_Mutator(ProviderList[i]);
		if (mut == none || !ClassPathValid(mut.ClassName)) continue;

		// don't add duplicate items
		hash = Locs(mut.ClassName);
		if (HashedMutators.Find('Hash', hash) != INDEX_NONE) continue;

		item.Hash = hash;
		item.Info = mut;

		HashedMutators.AddItem(item);
	}
}

private function LoadWeapons()
{
	local array<UTUIResourceDataProvider> ProviderList;
	local int i, index;
	local string hash;
	local UTUIDataProvider_Weapon weapn;
	local HashedWeaponInfo item;
	local HashedAmmoInfo ammo;

	local string str, s1, s2;

	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UTUIDataProvider_Weapon', ProviderList);
	for (i=0; i<ProviderList.length; i++)
	{
		weapn = UTUIDataProvider_Weapon(ProviderList[i]);
		if (weapn == none || !ClassPathValid(weapn.ClassName)) continue;

		// don't add duplicate items
		hash = Locs(weapn.ClassName);
		if (HashedWeapons.Find('Hash', hash) != INDEX_NONE) continue;

		item.Hash = hash;
		item.Info = weapn;
		item.ClassName = name(Mid(weapn.ClassName, Instr(weapn.ClassName, ".")+1));

		HashedWeapons.AddItem(item);

		// Ammo
		if (!ClassPathValid(weapn.AmmoClassPath)) continue;
		hash = Locs(weapn.AmmoClassPath);
		if (HashedAmmos.Find('Hash', hash) != INDEX_NONE) continue;

		index = Instr(weapn.AmmoClassPath, ".");
		s1 = Left(weapn.AmmoClassPath, index);
		s2 = Mid(weapn.AmmoClassPath, index+1);

		str = Localize(s2, "PickupMessage", s1);
		FixFriendlyName(str);

		ammo.Hash = hash;
		ammo.Text = str;
		ammo.ClassName = name(s2);

		HashedAmmos.AddItem(ammo);
	}
}

//**********************************************************************************
// Helper functions
//**********************************************************************************

function bool IsNewItem(out array<ReplacementInfo> items, out int index, name ClassName)
{
	index = items.Find('OldClassName', ClassName);
	return index == INDEX_NONE;
}

private function string GenerateErrorInfo(ErrorMessageInfo err)
{
	local string str;

	if (!ClassPathValid(err.NewClassPath)) // TODO: Check for valid class path and not just for empty string
	{
		str = err.Registrar != none ? MessageClassRemovedBy : MessageClassRemovedDefault;
	}
	else
	{
		str = err.Registrar != none ? MessageClassSubstBy : MessageClassSubstDefault;
		str $= " ";
		str $= err.Conflict != none ? MessageClassReplacedBy : MessageClassReplacedDefault;
	}

	str = Repl(str, "`new", Colorize(GetPickupName(err.NewClassPath, true), DialogNameColor));
	str = Repl(str, "`old", Colorize(GetPickupName(err.ClassName, false), DialogNameColor));
	str = Repl(str, "`already", Colorize(GetObjectFriendlyName(err.Conflict), DialogGoodColor));
	str = Repl(str, "`mutator", Colorize(GetObjectFriendlyName(err.Registrar), DialogBadColor));
	return str;
}

private function string GetPickupName(coerce string Path, bool IsPath)
{
	local int index;
	local string str;
	if (IsPath) index = HashedWeapons.Find('Hash', Locs(Path));
	else index = HashedWeapons.Find('ClassName', name(Path));
	if (index != INDEX_NONE && HashedWeapons[index].Info != none)
	{
		str = HashedWeapons[index].Info.FriendlyName;
	}
	else
	{
		if (IsPath) index = HashedAmmos.Find('Hash', Locs(Path));
		else index = HashedAmmos.Find('ClassName', name(Path));
		if (index != INDEX_NONE)
		{
			str = HashedAmmos[index].Text;
		}
	}

	if (str == "" || Left(str, 1) == "?")
	{
		str = Mid(Path, Instr(Path, ".")+1);
	}

	return str;
}

private function string GetObjectFriendlyName(Object obj, optional string defaultstr)
{
	local int index;
	local string str;

	if (class(Obj) != none)
		str = PathName(Obj);
	else if (Obj != none)
		str = PathName(Obj.Class);
	
	if (str != "")
	{
		index = HashedMutators.Find('Hash', Locs(str));
		if (index != INDEX_NONE && HashedMutators[index].Info != none)
		{
			str = HashedMutators[index].Info.FriendlyName;
		}
	}
	
	if (str == "")
	{
		if (Actor(obj) != none)
			str = Actor(obj).GetHumanReadableName();
		if (str == "" && class<Actor>(obj) != none)
			str = class<Actor>(obj).static.GetLocalString();
		else if (obj != none)
			str = string(obj.Name);
	}
	
	return str != "" ? str : defaultstr;
}

//**********************************************************************************
// Static functions
//**********************************************************************************

static function ShowMessageBox(string message, optional string Title="")
{
	local GameUISceneClient MySceneClient;
	local UIScene OpenedScene;
	MySceneClient = UTGameUISceneClient(class'UIRoot'.static.GetSceneClient());
	if (MySceneClient != none && MySceneClient.OpenScene(class'UTUIScene'.default.MessageBoxScene,, OpenedScene) && UTUIScene_MessageBox(OpenedScene) != none)
	{
		UTUIScene_MessageBox(OpenedScene).Display(message, Title);
	}
}

static function string Colorize(coerce string str, string ColorString)
{
	//<color:/> doesn't work so we need to use another tag with white color
	return "<color:"$ColorString$">"$str$DialogDefaultColor;
}

static function bool ClassPathValid(string classpath)
{
	if (classpath == "" || Len(classpath) > 63 || InStr(classpath, " ") != INDEX_NONE)
		return false;

	return (InStr(classpath, ".") != INDEX_NONE && Right(classpath, 1) != ".");
}

/** Trim the right part of the string */
static simulated function string TrimRight(coerce string sInput, optional coerce string sTrim = " ")
{
	local string sOutput;
	local int l;
	sOutput = sInput;

	l = Len(sTrim);
	while (Right(sOutput, l) == sTrim)
		sOutput = Left(sOutput, Len(sOutput)-1);
	
	return sOutput;
}

/** Fix names which are uppercase */
static function FixFriendlyName(out string FriendlyName)
{
	local string str;
	local array<String> splitname;
	local int i;

	// check for bad string
	if (FriendlyName != "" && Caps(FriendlyName) == FriendlyName)
	{
		// remove the special char from the end of the string
		str = TrimRight(FriendlyName, "!");

		// parse single words into an array
		ParseStringIntoArray(str, splitname, " ", true);
		
		// properly format longer words
		for (i=0; i<splitname.Length;i++)
			if (len(splitname[i]) > 2)
				splitname[i] = Left(splitname[i], 1)$Mid(locs(splitname[i]), 1);

		// join split name
		JoinArray(splitname, str, " ");
		FriendlyName = str;
	}
}

private static function string GetMutatorName(Mutator M)
{
	local Object TempObj;
	local UTUIDataProvider_Mutator DP;
	local string Pack;

	Pack = ""$M.class.GetPackageName();
	
	// Check that the data provider for this mutator exists
	TempObj = new(M.Class.Outer, Pack) Class'Package';
	DP = new(TempObj, string(M.Class)) Class'UTUIDataProvider_Mutator';

	if (DP != none && DP.FriendlyName != "") {
		return DP.FriendlyName;
	} else {
		return ""$M.Class.Name;
	}
}

Defaultproperties
{
	DialogNameColor="R=1.0,G=1.0,B=0.5,A=1.0"
	DialogBadColor="R=1.0,G=0.5,B=0.5,A=1"
	DialogGoodColor="R=0.1328125,G=0.69140625,B=0.296875,A=1"

	MessageErrors="Some errors occurred in replacing weapons:    `errors"
	MessageClassReplacedBy="The mutator `already is already replacing `old."
	MessageClassReplacedDefault="`old is already replaced by the default configuration."
	MessageClassSubstBy="`new cannot be added by `mutator."
	MessageClassSubstDefault="`new cannot be added."
	MessageClassRemovedBy="The mutator `already already removed `old."
	MessageClassRemovedDefault="`old is already removed by the default configuration."
}
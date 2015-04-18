class TestCWRUI extends Object;

//**********************************************************************************
// Constants
//**********************************************************************************

const DialogDefaultColor = "<color:R=1,G=1,B=1,A=1>";

//**********************************************************************************
// Structs
//**********************************************************************************

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

var bool bInitialized;

// Hashed Data
var array<HashedMutatorInfo> HashedMutators;
var array<HashedWeaponInfo> HashedWeapons;
var array<HashedAmmoInfo> HashedAmmos;

// UI
var() string DialogNameColor;
var() string DialogGoodColor;
var() string DialogBadColor;

// Localization
var localized string ProfileTitle;
var localized string MessageErrors;
var localized string MessageClassReplacedBy;
var localized string MessageClassReplacedDefault;
var localized string MessageClassSubstBy;
var localized string MessageClassSubstDefault;
var localized string MessageClassRemovedBy;
var localized string MessageClassRemovedDefault;

//**********************************************************************************
// Basic creation/destruction functions
//**********************************************************************************

// Always use this function to get a reference to the data object
static final function TestCWRUI GetData()
{
	local TestCWRUI data;
	local string ObjectName;

	ObjectName = default.Class.Name$"Obj";
	data = TestCWRUI(FindObject("Transient" $"."$ ObjectName, default.Class));

	// If there is no existing instance of this object class, create one
	if (data == none) data = new(none, ObjectName) default.Class;
	if (!data.bInitialized) data.Init();

	return data;
}

final function Init()
{
	bInitialized = true;
	LoadMutators();
	LoadWeapons();
}

function Kill()
{
	HashedMutators.Length = 0;
	HashedWeapons.Length = 0;
	HashedAmmos.Length = 0;
	bInitialized = false;
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

function string GetErrorMessage(Object Conflicting, Object Registrar, name OldClassName, string NewClassPath)
{
	local ErrorMessageInfo item;

	item.Conflict = Conflicting;
	item.Registrar = Registrar;
	item.ClassName = OldClassName;
	item.NewClassPath = NewClassPath;

	return GenerateErrorInfo(item, false);
}

static function string DumpErrorInfo(ErrorMessageInfo err, optional bool NoPrefix)
{
	local string str;
	if (!ClassPathValid(err.NewClassPath))
	{
		str = err.Registrar != none ? "`old already removed by `already" : "`old already removed by default configuration";
	}
	else
	{
		str = "Unable to add `new";
		if (err.Registrar != none) str $= " (by `mutator)";
		str $= ". ";
		str $= err.Conflict != none ? "`already is already replacing `old" : "`old already replaced by default configuration";
	}

	str = Repl(str, "`new", Mid(err.NewClassPath, Instr(err.NewClassPath, ".")+1));
	str = Repl(str, "`old", err.ClassName);
	str = Repl(str, "`already", StaticGetObjectFriendlyName(err.Conflict, true));
	str = Repl(str, "`mutator", StaticGetObjectFriendlyName(err.Registrar, true));
	if (!NoPrefix) str = "CWR:"@str;
	return str;
}

function string GenerateErrorInfo(ErrorMessageInfo err, optional bool bColorize = true)
{
	local string str;
	if (!ClassPathValid(err.NewClassPath))
	{
		str = err.Registrar != none ? MessageClassRemovedBy : MessageClassRemovedDefault;
	}
	else
	{
		str = err.Registrar != none ? MessageClassSubstBy : MessageClassSubstDefault;
		str $= " ";
		str $= err.Conflict != none ? MessageClassReplacedBy : MessageClassReplacedDefault;
	}
	str = Repl(str, "`new", SubstErrorInfo(GetPickupName(err.NewClassPath, true), bColorize, DialogNameColor));
	str = Repl(str, "`old", SubstErrorInfo(GetPickupName(err.ClassName, false), bColorize, DialogNameColor));
	str = Repl(str, "`already", SubstErrorInfo(GetObjectFriendlyName(err.Conflict), bColorize, DialogGoodColor));
	str = Repl(str, "`mutator", SubstErrorInfo(GetObjectFriendlyName(err.Registrar), bColorize, DialogBadColor));
	return str;
}

private function string SubstErrorInfo(string str, optional bool bColor, optional string ColorString)
{
	return (bColor && ColorString != "") ? Colorize(str, ColorString) : str;
}

private function string GetPickupName(coerce string Path, bool IsPath)
{
	local int index;
	local string str;
	local class cls;
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

	if (IsPath)
	{
		cls = class(DynamicLoadObject(Path, class'class'));
		GetFriendlyNameOfPickupClass(cls, str);
	}

	if (str == "" || Left(str, 1) == "?")
	{
		str = Mid(Path, Instr(Path, ".")+1);
	}

	return str;
}

static private function string StaticGetObjectFriendlyName(Object obj, optional bool NoFriendly, optional string defaultstr)
{
	local string str;
	if (TestCWRMapProfile(Obj) != none)
	{
		if (NoFriendly)
			str = string(TestCWRMapProfile(Obj).Name);
		else
			str = Repl(default.ProfileTitle, "`t", TestCWRMapProfile(Obj).ProfileName);
	}
	
	if (str == "" && !NoFriendly && obj != none)
	{
		GetFriendlyNameOfPickupClass(obj.Class, str);
	}

	if (str == "" && Obj != none)
	{
		str = PathName(class(obj) != none ? Obj : Obj.Class);
		str = Mid(str, InStr(str, ".")+1);
	}
	
	return str != "" ? str : defaultstr;
}

private function string GetObjectFriendlyName(Object obj, optional bool NoFriendly, optional string defaultstr)
{
	local string str;
	local int index;
	if (TestCWRMapProfile(Obj) == none && !NoFriendly && Obj != none)
	{
		index = HashedMutators.Find('Hash', Locs(PathName(class(obj) != none ? Obj : Obj.Class)));
		if (index != INDEX_NONE && HashedMutators[index].Info != none)
		{
			str = HashedMutators[index].Info.FriendlyName;
		}
	}

	return str != "" ? str : StaticGetObjectFriendlyName(obj, NoFriendly, defaultstr);
}

static function bool GetFriendlyNameOfPickupClass(class cls, out string out_propertytext, optional bool bUseDefaultInstead, optional coerce string DefaultStr)
{
	local class<Inventory> Inv;
	local class<UTItemPickupFactory> Fac;
	local class<UTWeaponLocker> Locker;
	local string str;

	Inv = class<Inventory>(cls);
	if (Inv != none)
	{
		str = Inv.default.PickupMessage;
		if (str == "" || str == class'Inventory'.default.PickupMessage)
		{
			str = Inv.default.ItemName;
		}

		if (class<UTDeployable>(cls) != none)
		{
			if (str == class'UTDeployable'.default.ItemName)
			{
				str = "";
			}
		}
		if (class<UTBeamWeapon>(cls) != none)
		{
			if (str == class'UTBeamWeapon'.default.ItemName)
			{
				str = "";
			}
		}
		else if (str != class'Inventory'.default.ItemName && str != class'Weapon'.default.ItemName && str != class'UTWeapon'.default.ItemName)
		{
			FixFriendlyName(str);
			out_propertytext = str;
			return true;
		}
		//@TODO: remove and fix returning value too early
		else if (str == class'GameWeapon'.default.ItemName || str == class'UTWeapon'.default.ItemName)
		{
			FixFriendlyName(str);
			out_propertytext = str;
			return false;
		}
	}

	Fac = class<UTItemPickupFactory>(cls);
	if (Fac != none)
	{
		str = Fac.default.PickupMessage;
	}

	Locker = class<UTWeaponLocker>(cls);
	if (Locker != none)
	{
		str = Locker.default.LockerString;
	}

	if (class<Actor>(cls) != none && str == "")
	{
		str = class<Actor>(cls).static.GetLocalString();
		if (class<Inventory>(cls) != none && str == class'Inventory'.default.PickupMessage)
		{
			str = "";
		}
	}

	if (str != "")
	{
		FixFriendlyName(str);
		out_propertytext = str;
		return true;
	}

	if (bUseDefaultInstead && DefaultStr != "")
	{
		out_propertytext = DefaultStr;
		return true;
	}

	out_propertytext = string(cls.Name);
	return true;
}

//**********************************************************************************
// Static functions
//**********************************************************************************

static function ShowErrorMessage(string errors, optional string Title="")
{
	local string message;
	message = Repl(Repl(default.MessageErrors, "  ", Chr(10)), "`errors", errors);
	ShowMessageBox(message, Title);
}

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

static function string GetMutatorName(class<Mutator> MutClass)
{
	local Object TempObj;
	local UTUIDataProvider_Mutator DP;
	local string Pack;
	
	// Check that the data provider for this mutator exists
	Pack = ""$MutClass.GetPackageName();
	TempObj = new(MutClass.Outer, Pack) Class'Package';
	DP = new(TempObj, string(MutClass)) Class'UTUIDataProvider_Mutator';

	return (DP != none && DP.FriendlyName != "") ? DP.FriendlyName : string(MutClass.Name);
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

static function bool ClassPathValid(string classpath)
{
	if (classpath == "" || Len(classpath) > 63 || InStr(classpath, " ") != INDEX_NONE)
		return false;

	return (InStr(classpath, ".") != INDEX_NONE && Right(classpath, 1) != ".");
}

DefaultProperties
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

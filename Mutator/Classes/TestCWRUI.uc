class TestCWRUI extends Object;

//**********************************************************************************
// Enums
//**********************************************************************************

enum EReplacementType
{
	RT_Weapon,
	RT_Ammo,
	RT_Health,
	RT_Armor,
	RT_Powerup,
	RT_Deployable,
	RT_Vehicle,
	RT_Custom,
};

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

struct SublistInfo
{
	var name Name;
	var name FieldName;
	var string MarkupString;
};

struct DataListMapInfo
{
	var name ListName;
	var EReplacementType Type;
	var name BaseClassName;
	var string BasePrefix;

	// Runtime
	var transient array<SublistInfo> SubLists;
};

struct KnownClassInfo
{
	var EReplacementType Type;
	var string Path;
	var bool bAbstract;
};

//**********************************************************************************
// Variables
//**********************************************************************************

var bool bInitialized;
var bool bAllLoaded;

var UTUIDataStore_StringList StringDataStore;

var() array<DataListMapInfo> DataLists;
var() array<DataListMapInfo> CachedDataLists;

// Hashed Data
var array<HashedMutatorInfo> HashedMutators;
var array<HashedWeaponInfo> HashedWeapons;
var array<HashedAmmoInfo> HashedAmmos;

var array<KnownClassInfo> KnownClasses;

// UI
var() string DialogNameColor;
var() string DialogGoodColor;
var() string DialogBadColor;

// Localization
var localized string ProfileTitle;
var localized string NameSuffixAbstract;

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

public function bool AllLoaded()
{
	return bAllLoaded && CachedDataLists.Length != DataLists.Length;
}

public function bool LoadAll()
{
	local DataStoreClient DSC;
	local int i;
	local array<SublistInfo> SubLists;

	if (AllLoaded())
		return true;

	DSC = class'UIInteraction'.static.GetDataStoreClient();
	if ( DSC == None )
		return false;

	StringDataStore = UTUIDataStore_StringList(DSC.FindDataStore(class'UTUIDataStore_StringList'.default.Tag));
	if ( StringDataStore == None )
	{
		StringDataStore = DSC.CreateDataStore(class'UTUIDataStore_StringList');
		DSC.RegisterDataStore(StringDataStore);
	}

	if ( StringDataStore == None )
		return false;

	CachedDataLists = DataLists;
	for (i=0; i<CachedDataLists.Length; i++)
	{
		SubLists.Length = 0;
		if (InternalLoadList(SubLists, CachedDataLists[i].ListName, CachedDataLists[i].Type))
		{
			CachedDataLists[i].SubLists = SubLists;
		}
	}

	InternalLoadWeapons();
	
	bAllLoaded = true;
	return true;
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
		str = IsDefaultMutator(err.Registrar) ? "`old already removed by default configuration" : "`old already removed by `already";
	}
	else
	{
		str = "Unable to add `new";
		if (!IsDefaultMutator(err.Registrar)) str $= " (by `mutator)";
		str $= ". ";
		str $= IsDefaultMutator(err.Conflict) ? "`old already replaced by default configuration" : "`already is already replacing `old";
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
		str = IsDefaultMutator(err.Registrar) ? MessageClassRemovedDefault : MessageClassRemovedBy;
	}
	else
	{
		str = IsDefaultMutator(err.Registrar) ? MessageClassSubstDefault : MessageClassSubstBy;
		str $= " ";
		str $= IsDefaultMutator(err.Conflict) ? MessageClassReplacedDefault : MessageClassReplacedBy;
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
	
	if (str == "" && !NoFriendly && Obj != none)
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
	if (TestCWRMapProfile(Obj) == none && !NoFriendly)
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
	local class<UTVehicle> Vec;
	local class<UTVehicleWeapon> VecGunClass;
	local string str;

	if (class<PickupFactory>(cls) != none)
	{
		Inv = class<PickupFactory>(cls).default.InventoryType;
	}
	else
	{
		Inv = class<Inventory>(cls);
	}

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

	if (class<UTVehicleFactory>(cls) != none)
	{
		Vec = class<UTVehicle>(DynamicLoadObject(class<UTVehicleFactory>(cls).default.VehicleClassPath, Class'class'));
		if (Vec != none)
		{
			str = Vec.default.VehicleNameString;
			if (str == class'UTVehicle'.default.VehicleNameString)
			{
				if (Vec.default.Seats.Length > 0)
				{
					VecGunClass = Vec.default.Seats[0].GunClass;
				}
				
				if (VecGunClass != none)
				{
					str = VecGunClass.default.ItemName;
				}
				else
				{
					str = "";
				}
			}
		}
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
// Data Lists functions
//**********************************************************************************

public function bool GetMarkup(name ListName, name SubListName, out string OutMarkup)
{
	local int i, j;
	i = CachedDataLists.Find('ListName', ListName);
	if (i != INDEX_NONE)
	{
		j = CachedDataLists[i].SubLists.Find('Name', SubListName);
		if (j != INDEX_NONE)
		{
			OutMarkup = CachedDataLists[i].SubLists[j].MarkupString;
			return true;
		}
	}

	return false;
}

public function bool GetDataStoreValue(name ListName, name FieldName, int StrIndex, out string OutStr)
{
	local int i, j;
	local name n;
	i = CachedDataLists.Find('ListName', ListName);
	if (i != INDEX_NONE)
	{
		j = CachedDataLists[i].SubLists.Find('Name', FieldName);
		if (j != INDEX_NONE)
		{
			n = CachedDataLists[i].SubLists[j].FieldName;
			OutStr = StringDataStore.GetStr(n, StrIndex);
			return true;
		}
	}

	return false;
}

public function bool GetDataStoreIndex(name ListName, name FieldName, coerce string Str, out int OutIndex)
{
	local int i, j;
	local name n;
	i = CachedDataLists.Find('ListName', ListName);
	if (i != INDEX_NONE)
	{
		j = CachedDataLists[i].SubLists.Find('Name', FieldName);
		if (j != INDEX_NONE)
		{
			n = CachedDataLists[i].SubLists[j].FieldName;
			OutIndex = StringDataStore.FindStr(n, Str);
			return true;
		}
	}

	return false;
}

private function InternalLoadWeapons()
{
	local int i;
	local name ListName;
	local name ListNameClasses;
	local name ListNamePaths;
	local string FriendlyName;
	local array<SublistInfo> SubLists;

	ListName = 'WeaponSelection';
	ListNameClasses = name(ListName$"_Class");
	ListNamePaths = name(ListName$"_Path");

	if (StringDataStore.GetFieldIndex('WeaponSelection') == INDEX_None)
	{
		StringDataStore.Empty(ListName, true);
		StringDataStore.Empty(ListNameClasses, true);
		StringDataStore.Empty(ListNamePaths, true);

		// add none entry
		StringDataStore.AddStr(ListName, "", true);
		StringDataStore.AddStr(ListNameClasses, "", true);
		StringDataStore.AddStr(ListNamePaths, "", true);

		for (i=0; i<HashedWeapons.Length; i++)
		{
			FriendlyName = HashedWeapons[i].Info.FriendlyName;
			FriendlyName = class'UTUIScene'.static.TrimWhitespace(FriendlyName);
			if (FriendlyName == "") FriendlyName = ""$HashedWeapons[i].ClassName;
			StringDataStore.AddStr(ListName, FriendlyName, true);
			StringDataStore.AddStr(ListNameClasses, ""$HashedWeapons[i].ClassName, true);
			StringDataStore.AddStr(ListNamePaths, ""$HashedWeapons[i].Info.ClassName, true);
		}
	}

	i = SubLists.Length;
	SubLists.Add(1);
	SubLists[i].Name = '';
	SubLists[i].FieldName = ListName;
	SubLists[i].MarkupString = "<"$StringDataStore.tag$":"$ListName$">";
	
	i = SubLists.Length;
	SubLists.Add(1);
	SubLists[i].FieldName = ListNameClasses;
	SubLists[i].Name = 'Class';
	SubLists[i].MarkupString = "<"$StringDataStore.tag$":"$ListNameClasses$">";

	i = SubLists.Length;
	SubLists.Add(1);
	SubLists[i].FieldName = ListNamePaths;
	SubLists[i].Name = 'Path';
	SubLists[i].MarkupString = "<"$StringDataStore.tag$":"$ListNamePaths$">";

	i = CachedDataLists.Length;
	CachedDataLists.Add(1);
	CachedDataLists[i].ListName = 'WeaponSelection';
	CachedDataLists[i].SubLists = SubLists;
}

private function bool InternalLoadList(out array<SublistInfo> OutSubLists, name ListName, EReplacementType Type)
{
	local int i;
	local string FriendlyName, ClassName;

	local name ListNameClasses;
	local name ListNamePaths;

	ListNameClasses = name(ListName$"_Class");
	ListNamePaths = name(ListName$"_Path");

	if (StringDataStore.GetFieldIndex(ListName) == INDEX_None)
	{
		StringDataStore.Empty(ListName, true);
		StringDataStore.Empty(ListNameClasses, true);
		StringDataStore.Empty(ListNamePaths, true);

		// add none entry
		StringDataStore.AddStr(ListName, "", true);
		StringDataStore.AddStr(ListNameClasses, "", true);
		StringDataStore.AddStr(ListNamePaths, "", true);

		for (i=0; i<KnownClasses.Length; i++)
		{
			if (KnownClasses[i].Type != Type) continue;

			//@TODO: separate abstract classes from list
			//@TODO: add abstract
			if (KnownClasses[i].bAbstract) continue;

			ClassName = Mid(KnownClasses[i].Path, InStr(KnownClasses[i].Path, ".")+1);
			FriendlyName = GetPickupName(KnownClasses[i].Path, true);
			if (KnownClasses[i].bAbstract)
				FriendlyName $= NameSuffixAbstract;

			StringDataStore.AddStr(ListName, FriendlyName, true);
			StringDataStore.AddStr(ListNameClasses, ClassName, true);
			StringDataStore.AddStr(ListNamePaths, KnownClasses[i].Path, true);
		}
	}

	i = OutSubLists.Length;
	OutSubLists.Add(1);
	OutSubLists[i].Name = '';
	OutSubLists[i].FieldName = ListName;
	OutSubLists[i].MarkupString = "<"$StringDataStore.tag$":"$ListName$">";
	
	i = OutSubLists.Length;
	OutSubLists.Add(1);
	OutSubLists[i].Name = 'Class';
	OutSubLists[i].FieldName = ListNameClasses;
	OutSubLists[i].MarkupString = "<"$StringDataStore.tag$":"$ListNameClasses$">";

	i = OutSubLists.Length;
	OutSubLists.Add(1);
	OutSubLists[i].Name = 'Path';
	OutSubLists[i].FieldName = ListNamePaths;
	OutSubLists[i].MarkupString = "<"$StringDataStore.tag$":"$ListNamePaths$">";

	return true;
}

//**********************************************************************************
// Static functions
//**********************************************************************************

static function bool IsDefaultMutator(Object Obj)
{
	return Obj == none || class<TestCentralWeaponReplacement>(Obj) != none || TestCentralWeaponReplacement(Obj) != none;
}

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
	KnownClasses.Add((Type=RT_Health,Path="UTGame.UTHealthPickupFactory",bAbstract=true))
	KnownClasses.Add((Type=RT_Health,Path="UTGame.UTPickupFactory_HealthVial"))
	KnownClasses.Add((Type=RT_Health,Path="UTGame.UTPickupFactory_MediumHealth"))
	KnownClasses.Add((Type=RT_Health,Path="UTGameContent.UTPickupFactory_SuperHealth"))

	KnownClasses.Add((Type=RT_Armor,Path="UTGame.UTArmorPickupFactory",bAbstract=true))
	KnownClasses.Add((Type=RT_Armor,Path="UTGame.UTArmorPickup_Helmet"))
	KnownClasses.Add((Type=RT_Armor,Path="UTGame.UTArmorPickup_Thighpads"))
	KnownClasses.Add((Type=RT_Armor,Path="UTGame.UTArmorPickup_Vest"))
	KnownClasses.Add((Type=RT_Armor,Path="UTGameContent.UTArmorPickup_ShieldBelt"))

	KnownClasses.Add((Type=RT_Powerup,Path="UTGame.UTPowerupPickupFactory",bAbstract=true))
	KnownClasses.Add((Type=RT_Powerup,Path="UTGameContent.UTPickupFactory_Berserk"))
	KnownClasses.Add((Type=RT_Powerup,Path="UTGameContent.UTPickupFactory_Invisibility"))
	KnownClasses.Add((Type=RT_Powerup,Path="UTGameContent.UTPickupFactory_Invulnerability"))
	KnownClasses.Add((Type=RT_Powerup,Path="UTGameContent.UTPickupFactory_JumpBoots"))
	KnownClasses.Add((Type=RT_Powerup,Path="UTGameContent.UTPickupFactory_UDamage"))
	KnownClasses.Add((Type=RT_Powerup,Path="UT3Gold.UTPickupFactory_SlowField"))

	KnownClasses.Add((Type=RT_Deployable,Path="UTGame.UTDeployable",bAbstract=true))
	KnownClasses.Add((Type=RT_Deployable,Path="UTGameContent.UTDeployableEMPMine"))
	KnownClasses.Add((Type=RT_Deployable,Path="UTGameContent.UTDeployableEnergyShield"))
	KnownClasses.Add((Type=RT_Deployable,Path="UTGameContent.UTDeployableShapedCharge"))
	KnownClasses.Add((Type=RT_Deployable,Path="UTGameContent.UTDeployableSlowVolume"))
	KnownClasses.Add((Type=RT_Deployable,Path="UTGameContent.UTDeployableSpiderMineTrap"))
	KnownClasses.Add((Type=RT_Deployable,Path="UTGame.UTDeployableXRayVolumeBase",bAbstract=true))
	KnownClasses.Add((Type=RT_Deployable,Path="UT3Gold.UTDeployableLinkGenerator"))
	KnownClasses.Add((Type=RT_Deployable,Path="UT3Gold.UTDeployableXRayVolume"))

	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Cicada"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_DarkWalker"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Fury"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Goliath"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_HellBender"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Leviathan"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Manta"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Nemesis"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_NightShade"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Paladin"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Raptor"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Scavenger"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Scorpion"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_SPMA"))
	//KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_StealthBender"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Viper"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UT3Gold.UTVehicleFactory_Eradicator"))
	KnownClasses.Add((Type=RT_Vehicle,Path="UT3Gold.UTVehicleFactory_StealthBenderGold"))

	//KnownClasses.Add((Type=RT_Vehicle,Path="UT3Gold.UTVehicleFactory_TrackTurretBase",bAbstract=true))
	//KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_ShieldedTurret_Rocket"))
	//KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_ShieldedTurret_Shock"))
	//KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_ShieldedTurret_Stinger"))
	//KnownClasses.Add((Type=RT_Vehicle,Path="UTGameContent.UTVehicleFactory_Turret"))


	DataLists(0)={(ListName="HealthSelection",Type=RT_Health,BaseClassName="UTHealthPickupFactory",BasePrefix="            ")}
	DataLists(1)={(ListName="ArmorSelection",Type=RT_Armor,BaseClassName="UTArmorPickupFactory",BasePrefix="            ")}
	DataLists(2)={(ListName="PowerupSelection",Type=RT_Powerup,BaseClassName="UTPowerupPickupFactory",BasePrefix="          ")}
	DataLists(3)={(ListName="DeployableSelection",Type=RT_Deployable,BaseClassName="UTDeployable",BasePrefix="            ")}
	DataLists(4)={(ListName="VehicleSelection",Type=RT_Vehicle,BaseClassName="UTVehicleFactory",BasePrefix="      ")}


	DialogNameColor="R=1.0,G=1.0,B=0.5,A=1.0"
	DialogBadColor="R=1.0,G=0.5,B=0.5,A=1"
	DialogGoodColor="R=0.1328125,G=0.69140625,B=0.296875,A=1"

	ProfileTitle="`t-Profile"
	NameSuffixAbstract=" (All)"

	MessageErrors="Some errors occurred in replacing weapons:    `errors"
	MessageClassReplacedBy="The mutator `already is already replacing `old."
	MessageClassReplacedDefault="`old is already replaced by the default configuration."
	MessageClassSubstBy="`new cannot be added by `mutator."
	MessageClassSubstDefault="`new cannot be added."
	MessageClassRemovedBy="The mutator `already already removed `old."
	MessageClassRemovedDefault="`old is already removed by the default configuration."
}

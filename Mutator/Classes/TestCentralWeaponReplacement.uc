class TestCentralWeaponReplacement extends UTMutator
	config(TestCentralWeaponReplacement);

const DialogDefaultColor = "<color:R=1,G=1,B=1,A=1>";

//**********************************************************************************
// Structs
//**********************************************************************************

struct ReplacementIgnoreClassesInfo
{
	/** class name of the weapon we want to get rid of */
	var name ClassName;
	/** Whether to check for subclasses  */
	var bool bSubClasses;

	structdefaultproperties
	{
		bSubClasses=true
	}
};

struct ReplacementOptionsInfo
{
	/** Whether to replace/remove the class name */
	var bool bReplaceWeapon;
	/** Whether to check for subclasses  */
	var bool bSubClasses;
	/** Whether to add the class to the weapon lockers */
	var bool bAddToLocker;
	/** Whether to add the class to the default inventory (on spawn) */
	var bool bAddToDefault;

	/** Whether to prevent replacing default inventory items (to be used with bSubClasses=true) */
	var bool bNoDefaultInventory;

	/** List of classes to ignore in checking for subclasses */
	var array<ReplacementIgnoreClassesInfo> IgnoreSubClasses<EditCondition=bSubClasses>;
	
	structdefaultproperties
	{
		bReplaceWeapon=true
		bSubClasses=false
		bAddToLocker=false
		bAddToDefault=false
		bNoDefaultInventory=false
	}
};

struct ReplacementInfoEx
{
	/** class name of the weapon we want to get rid of */
	var name OldClassName;
	/** fully qualified path of the class to replace it with */
	var string NewClassPath;
	
	/** the options for this item */
	var ReplacementOptionsInfo Options;

	/** the mutator/object which has registered the replacement
	(might be none if set by default configuration) */
	var transient Object Registrar;
};

struct TemplateInfo
{
	/** class name of the weapon we want to get rid of */
	var name OldClassName;
	/** fully qualified path of the class to replace it with */
	var string NewClassPath;

	/** the options for this item */
	var ReplacementOptionsInfo Options;

	/** Flag. Set when to append the package name (of the current package) to the NewClassPath field */
	var bool AddPackage;
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

var() const string ParameterProfile;
var string CurrentProfileName;
var TestCWRMapProfile CurrentProfile;

// Pre Game
// ------------

/** @ignore */
var private transient config array<ReplacementInfoEx> StaticWeaponsToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticAmmoToReplace;

// Config
// ------------

var config array<ReplacementInfoEx> DefaultWeaponsToReplace;
var config array<ReplacementInfoEx> DefaultAmmoToReplace;

// Workflow
// ------------

var array<ReplacementInfoEx> WeaponsToReplace;
var array<ReplacementInfoEx> AmmoToReplace;

var array<HashedMutatorInfo> HashedMutators;
var array<HashedWeaponInfo> HashedWeapons;
var array<HashedAmmoInfo> HashedAmmos;

var array<int> EnforcerIndizes;

// UI
// ------------

var array<ErrorMessageInfo> ErrorMessages;

var() string DialogNameColor;
var() string DialogGoodColor;
var() string DialogBadColor;

// Localization
// ------------

var localized string ProfileTitle;
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
			RegisterWeaponReplacement(none, DefaultWeaponsToReplace[i].OldClassName, DefaultWeaponsToReplace[i].NewClassPath, false, DefaultWeaponsToReplace[i].Options);

		for (i=0; i<DefaultAmmoToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultAmmoToReplace[i].OldClassName, DefaultAmmoToReplace[i].NewClassPath, true, DefaultAmmoToReplace[i].Options);
	}
}

/**
 * This function can be used to parse the command line parameters when a server
 * starts up
 */

function InitMutator(string Options, out string ErrorMessage)
{
	local int i, j;
	local UTGame G;
	local class<UTWeapon> WeaponClass;
	local TestCWRMapProfile MapProvider;

	super.InitMutator(Options, ErrorMessage);

	if (class'GameInfo'.static.HasOption(Options, ParameterProfile))
	{
		CurrentProfileName = class'GameInfo'.static.ParseOption(Options, ParameterProfile);
	}

	if (CurrentProfileName != "" && class'TestCWRMapProfile'.static.GetMapProfileByName(CurrentProfileName, MapProvider))
	{
		CurrentProfile = MapProvider;
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.WeaponsToReplace, false);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.AmmoToReplace, true);
	}

	// Make sure the game does not hold a null reference
	G = UTGame(WorldInfo.Game);
	if(G != none)
	{
		for (j=0; j<WeaponsToReplace.Length; j++)
		{
			if (WeaponsToReplace[j].Options.bReplaceWeapon && !WeaponsToReplace[j].Options.bNoDefaultInventory)
			{
				for (i=0; i<G.DefaultInventory.length; i++)
				{
					if (G.DefaultInventory[i] == None) continue;
					if (!WeaponsToReplace[j].Options.bSubClasses && G.DefaultInventory[i].Name != WeaponsToReplace[j].OldClassName) continue;

					// IsA doesn't work for abstract classes, we need to use the workaround/hackfix
					if (WeaponsToReplace[j].Options.bSubClasses && !IsSubClass(G.DefaultInventory[i], WeaponsToReplace[j].OldClassName)) continue;

					if (!ClassPathValid(WeaponsToReplace[j].NewClassPath))
					{
						// replace with nothing
						G.DefaultInventory.Remove(i, 1);
						i--;
						continue;
					}
					else
					{
						WeaponClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[j].NewClassPath, class'Class'));
						if (WeaponsToReplace[j].Options.bReplaceWeapon)
						{
							G.DefaultInventory[i] = WeaponClass;
						}
					}
				}
			}

			if (WeaponsToReplace[j].Options.bAddToDefault && ClassPathValid(WeaponsToReplace[j].NewClassPath))
			{
				WeaponClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[j].NewClassPath, class'Class'));
				if (WeaponClass != none) G.DefaultInventory.AddItem(WeaponClass);
			}

			if (WeaponsToReplace[j].Options.bAddToLocker)
			{
				WeaponClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[j].NewClassPath, class'Class'));
				AddToLocker(WeaponClass);
			}
		}

		if (G.TranslocatorClass != None)
		{
			j = WeaponsToReplace.Find('OldClassName', G.TranslocatorClass.Name);
			if (j != INDEX_NONE)
			{
				if (WeaponsToReplace[j].NewClassPath == "" || !WeaponsToReplace[j].Options.bReplaceWeapon)
				{
					// replace with nothing
					G.TranslocatorClass = None;
				}
				else
				{
					G.TranslocatorClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[j].NewClassPath, class'Class'));
				}
			}
		}

		EnforcerIndizes.Length = 0;
		for (i=0; i<G.DefaultInventory.length; i++)
		{
			if (IsSubClass(G.DefaultInventory[i], 'UTWeap_Enforcer'))
			{
				EnforcerIndizes.AddItem(i);
			}
		}
	}
}

function bool CheckReplacement(Actor Other)
{
	local UTWeaponPickupFactory WeaponPickup;
	local UTWeaponLocker Locker;
	local UTAmmoPickupFactory AmmoPickup, NewAmmo;
	local int i, Index;
	local class<UTAmmoPickupFactory> NewAmmoClass;

	WeaponPickup = UTWeaponPickupFactory(Other);
	if (WeaponPickup != None)
	{
		if (WeaponPickup.WeaponPickupClass != None)
		{
			if (ShouldBeReplaced(index, WeaponPickup.WeaponPickupClass, false) && WeaponsToReplace[index].Options.bReplaceWeapon)
			{
				if (WeaponsToReplace[index].NewClassPath == "")
				{
					// replace with nothing
					return false;
				}
				WeaponPickup.WeaponPickupClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[index].NewClassPath, class'Class'));
				WeaponPickup.InitializePickup();
			}
		}
	}
	else
	{
		if (UTWeaponLocker(Other) != None)
		{
			Locker = UTWeaponLocker(Other);
			for (i = 0; i < Locker.Weapons.length; i++)
			{
				if (Locker.Weapons[i].WeaponClass != none && ShouldBeReplaced(index, Locker.Weapons[i].WeaponClass, false) && WeaponsToReplace[index].Options.bReplaceWeapon)
				{
					if (WeaponsToReplace[index].NewClassPath == "")
					{
						// replace with nothing
						Locker.ReplaceWeapon(i, None);
					}
					else
					{
						Locker.ReplaceWeapon(i, class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[index].NewClassPath, class'Class')));
					}
				}
			}
		}
		else if (UTAmmoPickupFactory(Other) != none)
		{
			AmmoPickup = UTAmmoPickupFactory(Other);
			if (AmmoPickup.Class != none)
			{
				if (ShouldBeReplaced(index, AmmoPickup.Class, true) && AmmoToReplace[index].Options.bReplaceWeapon)
				{
					if (AmmoToReplace[index].NewClassPath == "")
					{
						// replace with nothing
						return false;
					}
					NewAmmoClass = class<UTAmmoPickupFactory>(DynamicLoadObject(AmmoToReplace[index].NewClassPath, class'Class'));
					if (NewAmmoClass == None)
					{
						// replace with nothing
						return false;
					}
					else if (NewAmmoClass.default.bStatic || NewAmmoClass.default.bNoDelete)
					{
						// transform the current ammo into the desired class
						AmmoPickup.TransformAmmoType(NewAmmoClass);
						return true;
					}
					else
					{
						// spawn the new ammo, link it to the old, then disable the old one
						NewAmmo = AmmoPickup.Spawn(NewAmmoClass);
						NewAmmo.OriginalFactory = AmmoPickup;
						AmmoPickup.ReplacementFactory = NewAmmo;
						return false;
					}
				}
			}
		}

		// remove initial anim for Enforcers (may only work on server/listen player)
		else if (EnforcerIndizes.Length > 1 && UTWeap_Enforcer(Other) != none)
		{
			UTWeap_Enforcer(Other).bLoaded = true;
			UTWeap_Enforcer(Other).EquipTime = UTWeap_Enforcer(Other).ReloadTime;
		}
	}

	return true;
}

/* called by GameInfo.RestartPlayer()
	change the players jumpz, etc. here
*/
function ModifyPlayer(Pawn Other)
{
	local int i, index;
	local UTWeap_Enforcer Enf;
	super.ModifyPlayer(Other);

	// special case for Akimbo (Enforcer only)
	if (EnforcerIndizes.Length > 1 && UTGame(WorldInfo.Game) != none)
	{
		index = EnforcerIndizes[0];
		Enf = UTWeap_Enforcer(Other.FindInventoryType(UTGame(WorldInfo.Game).DefaultInventory[0]));
		if (Enf != none)
		{
			for (i=1; i<EnforcerIndizes.Length; i++)
			{
				index = EnforcerIndizes[i];
				if (index < UTGame(WorldInfo.Game).DefaultInventory.Length)
				{
					if (!Enf.DenyPickupQuery(UTGame(WorldInfo.Game).DefaultInventory[index], none))
					{
						Other.CreateInventory(UTGame(WorldInfo.Game).DefaultInventory[index], false);
					}
				}
			}
		}
	}
}

// called when gameplay actually starts
function MatchStarting()
{
	local int i;
	local string str, s;

	super.MatchStarting();

	if (ErrorMessages.Length > 0)
	{
		// init datastore for weapons and mutators
		LoadMutators();
		LoadWeapons();

		for (i=0; i<ErrorMessages.Length; i++)
		{
			s = DumpErrorInfo(ErrorMessages[i]);
			LogInternal(s);

			if (WorldInfo.NetMode != NM_DedicatedServer)
			{
				WriteToConsole(s);

				if (str != "" || i > 0)
					str $= Chr(10);
				str $= GenerateErrorInfo(ErrorMessages[i]);
			}
		}

		// clear out data
		HashedMutators.Length = 0;
		HashedWeapons.Length = 0;
		HashedAmmos.Length = 0;

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			str = Repl(Repl(MessageErrors, "  ", Chr(10)), "`errors", str);
			ShowMessageBox(str, GetHumanReadableName());
		}
	}
}

// Returns the human readable string representation of an object.
simulated function String GetHumanReadableName()
{
	return GetMutatorName(class);
}

//**********************************************************************************
// Interface functions
//**********************************************************************************

function RegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, bool bAmmo, ReplacementOptionsInfo ReplacementOptions)
{
	local int index;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	NewClassPath = TrimRight(NewClassPath);

	if (bAmmo)
	{
		if (IsNewItem(AmmoToReplace, index, OldClassName))
		{
			AddWeaponReplacement(AmmoToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions);
		}
		else if (!(AmmoToReplace[index].NewClassPath ~= NewClassPath))
		{
			AddErrorMessage(AmmoToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
		}
	}
	else if (IsNewItem(WeaponsToReplace, index, OldClassName))
	{
		AddWeaponReplacement(WeaponsToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions);
	}
	else if (!(WeaponsToReplace[index].NewClassPath ~= NewClassPath))
	{
		AddErrorMessage(WeaponsToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
	}
}

function RegisterWeaponReplacementArray(Object Registrar, array<TemplateInfo> Replacements, bool bAmmo)
{
	local int i;
	for (i=0; i<Replacements.Length; i++)
	{
		RegisterWeaponReplacement(Registrar,
			Replacements[i].OldClassName,
			Replacements[i].NewClassPath,
			bAmmo,
			Replacements[i].Options);
	}
}

function UnRegisterWeaponReplacement(Object Registrar)
{
	local int i;

	for (i=0; i<WeaponsToReplace.Length; i++)
	{
		if (WeaponsToReplace[i].Registrar == Registrar)
		{
			WeaponsToReplace.Remove(i, 1);
			i--;
		}
	}

	for (i=0; i<AmmoToReplace.Length; i++)
	{
		if (AmmoToReplace[i].Registrar == Registrar)
		{
			AmmoToReplace.Remove(i, 1);
			i--;
		}
	}
}

static function bool StaticRegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, bool bAmmo, optional ReplacementOptionsInfo ReplacementOptions, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage, optional bool bSilent)
{
	local WorldInfo WI;
	local TestCentralWeaponReplacement mut;

	if (bPre)
	{
		return StaticPreRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo, ReplacementOptions, bOnlyCheck, ErrorMessage, bSilent);
	}

	if (Registrar == none)
	{
		ErrorMessage = "No Registrar.";
		return false;
	}

	// check for WorldInfo
	if (!EnsureWorld(Registrar, WI))
	{
		ErrorMessage = "No WorldInfo found.";
		return false;
	}

	// spawn/create mutator
	EnsureMutator(WI, mut);

	// register the weapon replacement
	mut.RegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo, ReplacementOptions);
	return true;
}

static function bool StaticUnRegisterWeaponReplacement(Object Registrar, optional bool bPre, optional bool bSilent, optional out string ErrorMessage)
{
	local WorldInfo WI;
	local TestCentralWeaponReplacement mut;

	if (bPre)
	{
		return StaticPreUnRegisterWeaponReplacement(Registrar, bSilent, ErrorMessage);
	}
	
	if (Registrar == none)
	{
		ErrorMessage = "No Registrar.";
		return false;
	}

	// check for WorldInfo
	if (!EnsureWorld(Registrar, WI))
	{
		ErrorMessage = "No WorldInfo found.";
		return false;
	}

	// spawn/create mutator
	EnsureMutator(WI, mut);

	// register the weapon replacement
	mut.UnRegisterWeaponReplacement(Registrar);
}

/** Create/Find the currently spawned mutator
 * @return true if newly created
 */
static function bool EnsureWorld(Object Registrar, out WorldInfo OutWorldInfo)
{
	if (Actor(Registrar) != none)
		OutWorldInfo = Actor(Registrar).WorldInfo;
	if (OutWorldInfo == none)
		OutWorldInfo = class'Engine'.static.GetCurrentWorldInfo();

	return OutWorldInfo != none;
}

/** Create/Find the currently spawned mutator
 * @return true if newly created
 */
static function bool EnsureMutator(WorldInfo WI, out TestCentralWeaponReplacement OutMut)
{
	// try to find an existent gneric mutator
	foreach WI.DynamicActors(class'TestCentralWeaponReplacement', OutMut)
		break;

	// if not mutator was found, create one
	if (OutMut == none)
	{
		OutMut = WI.Spawn(class'TestCentralWeaponReplacement', WI.Game);
		if (WI.Game != none)
		{
			OutMut.NextMutator = WI.Game.BaseMutator;
			WI.Game.BaseMutator = OutMut;
		}

		return true;
	}

	return false;
}

//**********************************************************************************
// Pre-Game/UI Interface functions
//**********************************************************************************

static function StaticPreClearWeapon()
{
	default.StaticWeaponsToReplace.Length = 0;
	default.StaticAmmoToReplace.Length = 0;
}

static function bool StaticPreRegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, bool bAmmo, ReplacementOptionsInfo ReplacementOptions, optional bool bOnlyCheck, optional out string ErrorMessage, optional bool bBatchOp)
{
	local int index;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	NewClassPath = TrimRight(NewClassPath);

	if (bAmmo)
	{
		if (IsNewItem(default.StaticAmmoToReplace, index, OldClassName))
		{
			if (!bOnlyCheck) AddWeaponReplacement(default.StaticAmmoToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions);
			return true;
		}
		else if (!(default.StaticAmmoToReplace[index].NewClassPath ~= NewClassPath))
		{
			ErrorMessage = GetErrorMessage(default.StaticAmmoToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
		}
	}
	else if (IsNewItem(default.StaticWeaponsToReplace, index, OldClassName))
	{
		if (!bOnlyCheck) AddWeaponReplacement(default.StaticWeaponsToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions);
		return true;
	}
	else if (!(default.StaticWeaponsToReplace[index].NewClassPath ~= NewClassPath))
	{
		ErrorMessage = GetErrorMessage(default.StaticWeaponsToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
	}

	return false;
}

static function bool StaticPreUnRegisterWeaponReplacement(Object Registrar, optional bool bSilent, optional out string ErrorMessage)
{
	local int i;
	local bool bAnyRemoved;

	if (Registrar == none)
	{
		ErrorMessage = "No Registrar.";
		return false;
	}

	for (i=0; i<default.StaticWeaponsToReplace.Length; i++)
	{
		if (default.StaticWeaponsToReplace[i].Registrar == Registrar)
		{
			bAnyRemoved = true;
			default.StaticWeaponsToReplace.Remove(i, 1);
			i--;
		}
	}

	for (i=0; i<default.StaticAmmoToReplace.Length; i++)
	{
		if (default.StaticAmmoToReplace[i].Registrar == Registrar)
		{
			bAnyRemoved = true;
			default.StaticAmmoToReplace.Remove(i, 1);
			i--;
		}
	}

	return bAnyRemoved;
}

//**********************************************************************************
// Private functions
//**********************************************************************************

static private function AddWeaponReplacement(out array<ReplacementInfoEx> arr, Object Registrar, name OldClassName, string NewClassPath, ReplacementOptionsInfo ReplacementOptions)
{
	local ReplacementInfoEx item;
	item.OldClassName = OldClassName;
	item.NewClassPath = NewClassPath;
	item.Registrar = Registrar;
	item.Options = ReplacementOptions;

	arr.AddItem(item);
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

static private function string GetErrorMessage(Object Conflicting, Object Registrar, name OldClassName, string NewClassPath)
{
	local ErrorMessageInfo item;
	item.Conflict = Conflicting;
	item.Registrar = Registrar;
	item.ClassName = OldClassName;
	item.NewClassPath = NewClassPath;
	return DumpErrorInfo(item, true); // TODO: use GenerateErrorInfo once datastores are loaded statically
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

function AddToLocker(class<UTWeapon> WeaponClass)
{
	local UTWeaponLocker Locker;
	local WeaponEntry ent;

	if (WeaponClass == none)
		return;

	foreach DynamicActors(class'UTWeaponLocker', Locker)
	{
		ent.WeaponClass = WeaponClass;
		Locker.MaxDesireability += WeaponClass.Default.AIRating;

		//if (WeaponClass.default.PickupFactoryMesh != none)
		//	ent.PickupMesh = WeaponClass.default.PickupFactoryMesh;

		Locker.Weapons.AddItem(ent);
	}
}

function bool ShouldBeReplaced(out int index, class ClassToCheck, bool bAmmo)
{
	local int i;
	if (bAmmo)
	{
		index = AmmoToReplace.Find('OldClassName', ClassToCheck.Name);
		if (index == INDEX_NONE)
		{
			for (i=0; i<AmmoToReplace.Length; i++)
			{
				if (AmmoToReplace[i].Options.bSubClasses && IsSubClass(ClassToCheck, AmmoToReplace[i].OldClassName))
				{
					index = i;
					return true;
				}
			}
		}
	}
	else
	{
		index = WeaponsToReplace.Find('OldClassName', ClassToCheck.Name);
		if (index == INDEX_NONE)
		{
			for (i=0; i<WeaponsToReplace.Length; i++)
			{
				if (WeaponsToReplace[i].Options.bSubClasses && 
					IsSubClass(ClassToCheck, WeaponsToReplace[i].OldClassName) &&
					!IgnoreSubClass(ClassToCheck, WeaponsToReplace[i].Options.IgnoreSubClasses))
				{
					index = i;
					return true;
				}
			}
		}
	}

	return index != INDEX_NONE;
}

//**********************************************************************************
// Helper functions
//**********************************************************************************

static function bool IsNewItem(out array<ReplacementInfoEx> items, out int index, name ClassName)
{
	index = items.Find('OldClassName', ClassName);
	return index == INDEX_NONE;
}

static private function string DumpErrorInfo(ErrorMessageInfo err, optional bool NoPrefix)
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

private function string GenerateErrorInfo(ErrorMessageInfo err, optional bool bColorize = true)
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
	
	if (str == "" && !NoFriendly)
	{
		if (Actor(obj) != none)
			str = Actor(obj).GetHumanReadableName();
		if (str == "" && class<Actor>(obj) != none)
			str = class<Actor>(obj).static.GetLocalString();
		else if (obj != none)
			str = string(obj.Name);
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

static function bool IsSubClass(class ClassToCheck, name ParentClassName)
{
	local Object Obj;
	// get default object which works for abstract classes
	return GetDefaultObject(ClassToCheck, obj) && obj.IsA(ParentClassName);
}

static function bool IgnoreSubClass(class ClassToCheck, array<ReplacementIgnoreClassesInfo> ParentCheck)
{
	local Object Obj;
	local int i;
	
	// get default object which works for abstract classes
	if (ParentCheck.Length > 0 && GetDefaultObject(ClassToCheck, obj))
	{
		for (i=0; i<ParentCheck.Length; i++)
		{
			if ((!ParentCheck[i].bSubClasses && ParentCheck[i].ClassName == ClassToCheck.Name) ||
				(ParentCheck[i].bSubClasses && obj.IsA(ParentCheck[i].ClassName)))
			{
				return true;
			}
		}
	}

	return false;
}

// NOTE: needed for hackfix
static function bool GetDefaultObject(class<Object> cls, out Object obj)
{
	local string path;

	path = GetDefaultPath(cls);
	obj = FindObject(path, cls);
	return (obj != none);
}

// NOTE: needed for hackfix
static function string GetDefaultPath(class<Object> cls)
{
	return cls.GetPackageName() $".Default__"$ cls.Name;
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

static function WriteToConsole(string message)
{
	local GameUISceneClient SceneClient;
	local Console con;

	SceneClient = class'UIRoot'.static.GetSceneClient();
	con = SceneClient.ViewportConsole;
	con.OutputText(message);
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

static function string GetMutatorName(class<Mutator> MutClass)
{
	local Object TempObj;
	local UTUIDataProvider_Mutator DP;
	local string Pack;

	Pack = ""$MutClass.GetPackageName();
	
	// Check that the data provider for this mutator exists
	TempObj = new(MutClass.Outer, Pack) Class'Package';
	DP = new(TempObj, string(MutClass)) Class'UTUIDataProvider_Mutator';

	if (DP != none && DP.FriendlyName != "") {
		return DP.FriendlyName;
	} else {
		return ""$MutClass.Name;
	}
}

Defaultproperties
{
	GroupNames[0]="WEAPONMOD"

	ParameterProfile="CWRMapProfile"

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
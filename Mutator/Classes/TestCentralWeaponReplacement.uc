class TestCentralWeaponReplacement extends UTMutator
	dependson(TestCWRUI)
	config(TestCentralWeaponReplacement);

//**********************************************************************************
// Structs
//**********************************************************************************

struct ReplacementIgnoreClassesInfo
{
	/** class name of the pickup we want to ignore to be replaced */
	var name ClassName;
	/** Whether to check for subclasses  */
	var bool bSubClasses;

	structdefaultproperties
	{
		bSubClasses=true
	}
};

struct ReplacementLockerInfo
{
	/** List of Locker names to add/remove the weapon to/from  */
	var array<name> Names;

	/** List of Locker groups to add/remove the weapon to/from  */
	var array<name> Groups;

	/** List of Locker tag to add/remove the weapon to/from  */
	var array<name> Tags;
};

struct ReplacementOptionsInfo
{
	/** Whether to replace/remove the weapon */
	var bool bReplaceWeapon;
	/** Whether to add the inventory item to the default inventory (on spawn) */
	var bool bAddToDefault;

	/** Whether to check for subclasses  */
	var bool bSubClasses;
	/** Whether to prevent replacing default inventory items (to be used with bSubClasses=true) */
	var bool bNoDefaultInventory<EditCondition=bSubClasses>;
	/** List of classes to ignore in checking for subclasses */
	var array<ReplacementIgnoreClassesInfo> IgnoreSubClasses<EditCondition=bSubClasses>;

	/** Whether to add the weapon to the weapon lockers */
	var bool bAddToLocker;
	/** Options to specify to which Locker the weapon should be added */
	var ReplacementLockerInfo LockerOptions;
	
	structdefaultproperties
	{
		bReplaceWeapon=true
		bAddToDefault=false

		bSubClasses=false
		bNoDefaultInventory=false

		bAddToLocker=false
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

	/** Flag. Set whether to append the package name (of the current package) to the NewClassPath field */
	var bool AddPackage;
};

struct TemplateDynamicInfo
{
	/** Info about the replacement */
	var TemplateInfo Template;

	/** whether the replacement is type of Ammo */
	var bool bAmmo;
};

//**********************************************************************************
// Variables
//**********************************************************************************

var() const string ParameterProfile;

// Pre Game
// ------------

/** @ignore */
var private transient config array<ReplacementInfoEx> StaticWeaponsToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticAmmoToReplace;
/** @ignore */
var private transient config array<name> StaticOrder;
/** @ignore */
var private transient config bool StaticBatchOp;

// Config
// ------------

var config array<ReplacementInfoEx> DefaultWeaponsToReplace;
var config array<ReplacementInfoEx> DefaultAmmoToReplace;

// Workflow
// ------------

var array<ReplacementInfoEx> WeaponsToReplace;
var array<ReplacementInfoEx> AmmoToReplace;

var TestCWRUI DataCache;
var array<ErrorMessageInfo> ErrorMessages;

var array<int> EnforcerIndizes;

var string CurrentProfileName;
var TestCWRMapProfile CurrentProfile;

//**********************************************************************************
// Inherited functions
//**********************************************************************************

// Intialize the default replacments
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

// used to check for default inventory items to be replaced or
// whether an item should be added to the weapon lockers or the default inventory
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
			WeaponClass = none;
			if (ClassPathValid(WeaponsToReplace[j].NewClassPath))
			{
				WeaponClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[j].NewClassPath, class'Class'));
			}

			if (WeaponsToReplace[j].OldClassName != '' && WeaponsToReplace[j].Options.bReplaceWeapon && !WeaponsToReplace[j].Options.bNoDefaultInventory)
			{
				for (i=0; i<G.DefaultInventory.length; i++)
				{
					if (G.DefaultInventory[i] == None) continue;
					if (!WeaponsToReplace[j].Options.bSubClasses && G.DefaultInventory[i].Name != WeaponsToReplace[j].OldClassName) continue;

					// IsA doesn't work for abstract classes, we need to use the workaround/hackfix
					if (WeaponsToReplace[j].Options.bSubClasses && !IsSubClass(G.DefaultInventory[i], WeaponsToReplace[j].OldClassName)) continue;

					if (WeaponClass == none)
					{
						// remove from inventory
						G.DefaultInventory.Remove(i, 1);
					}
					else if (WeaponsToReplace[j].Options.bReplaceWeapon)
					{
						G.DefaultInventory[i] = WeaponClass;
					}
				}
			}

			// add to default inventory by request
			if (WeaponsToReplace[j].Options.bAddToDefault && WeaponClass != none)
			{
				G.DefaultInventory.AddItem(WeaponClass);
			}

			// add to weapon lockers by request
			if (WeaponsToReplace[j].Options.bAddToLocker)
			{
				AddToLocker(WeaponClass, WeaponsToReplace[j].Options.LockerOptions);
			}
		}

		if (G.TranslocatorClass != None)
		{
			j = WeaponsToReplace.Find('OldClassName', G.TranslocatorClass.Name);
			if (j != INDEX_NONE)
			{
				if (WeaponClass == none || !WeaponsToReplace[j].Options.bReplaceWeapon)
				{
					// replace with nothing
					G.TranslocatorClass = None;
				}
				else
				{
					G.TranslocatorClass = WeaponClass;
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

// check for factory and replace/remove their inventory item (if desired)
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
				if (Locker.Weapons[i].WeaponClass != none &&
					ShouldBeReplaced(index, Locker.Weapons[i].WeaponClass, false) &&
					WeaponsToReplace[index].Options.bReplaceWeapon &&
					ShouldBeReplacedLocker(Locker, WeaponsToReplace[index].Options.LockerOptions))
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

// Fix Dual Enforcer
/** called by GameInfo.RestartPlayer() */
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

// print error message on local players or on log
/** called when gameplay actually starts */
function MatchStarting()
{
	local int i;
	local string str, s;
	
	super.MatchStarting();

	if (ErrorMessages.Length > 0)
	{
		// init datastore for weapons and mutators
		DataCache = class'TestCWRUI'.static.GetData();

		for (i=0; i<ErrorMessages.Length; i++)
		{
			s = DataCache.DumpErrorInfo(ErrorMessages[i]);
			LogInternal(s);

			if (WorldInfo.NetMode != NM_DedicatedServer)
			{
				WriteToConsole(s);

				if (str != "" || i > 0) str $= Chr(10);
				str $= DataCache.GenerateErrorInfo(ErrorMessages[i]);
			}
		}

		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			DataCache.ShowErrorMessage(str, GetHumanReadableName());
		}

		// clear out data
		DataCache.Kill();
		DataCache = none;
	}
}

// Returns the human readable string representation of an object.
simulated function String GetHumanReadableName()
{
	return class'TestCWRUI'.static.GetMutatorName(class);
}

//**********************************************************************************
// Interface functions
//**********************************************************************************

function RegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, bool bAmmo, ReplacementOptionsInfo ReplacementOptions)
{
	local int index;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	else NewClassPath = TrimRight(NewClassPath);

	if (bAmmo)
	{
		if (IsNewItem(AmmoToReplace, index, OldClassName))
		{
			AddReplacementToArray(AmmoToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions);
		}
		else if (!(AmmoToReplace[index].NewClassPath ~= NewClassPath))
		{
			AddErrorMessage(AmmoToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
		}
	}
	else if (IsNewItem(WeaponsToReplace, index, OldClassName))
	{
		AddReplacementToArray(WeaponsToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions);
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
	RemoveReplacementFromArray(WeaponsToReplace, Registrar);
	RemoveReplacementFromArray(AmmoToReplace, Registrar);
}

static function bool StaticRegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, bool bAmmo, optional ReplacementOptionsInfo ReplacementOptions, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local WorldInfo WI;
	local TestCentralWeaponReplacement mut;

	if (bPre)
	{
		return StaticPreRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, bAmmo, ReplacementOptions, bOnlyCheck, ErrorMessage);
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

static function bool StaticUnRegisterWeaponReplacement(Object Registrar, optional bool bPre, optional out string ErrorMessage)
{
	local WorldInfo WI;
	local TestCentralWeaponReplacement mut;

	if (bPre)
	{
		return StaticPreUnRegisterWeaponReplacement(Registrar, ErrorMessage);
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
	if (!EnsureMutator(WI, mut, true))
	{
		ErrorMessage = "No Mutator found.";
		return false;
	}

	// unregister the weapon replacement
	mut.UnRegisterWeaponReplacement(Registrar);
	return true;
}

/** Remove registered replacements but keep order */
static function StaticUpdateWeaponReplacement(Object Registrar, bool bBatchOp, optional bool bPre)
{
	if (bPre)
	{
		StaticPreUpdateWeaponReplacement(Registrar, bBatchOp);
		return;
	}

	//@TODO: implement runtime changes update
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
static function bool EnsureMutator(WorldInfo WI, out TestCentralWeaponReplacement OutMut, optional bool NoCreation)
{
	// try to find an existent gneric mutator
	foreach WI.DynamicActors(class'TestCentralWeaponReplacement', OutMut)
		break;

	// if not mutator was found, create one
	if (OutMut == none && !NoCreation)
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

static function StaticPreInitialize()
{
	local TestCentralWeaponReplacement MutatorObj;
	local int i;

	default.StaticWeaponsToReplace.Length = 0;
	default.StaticAmmoToReplace.Length = 0;
	default.StaticOrder.Length = 0;
	default.StaticBatchOp = false;

	if (GetStaticMutator(MutatorObj))
	{
		MutatorObj.DataCache = class'TestCWRUI'.static.GetData();
	}

	for (i=0; i<default.DefaultWeaponsToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.DefaultWeaponsToReplace[i].OldClassName, default.DefaultWeaponsToReplace[i].NewClassPath, false, default.DefaultWeaponsToReplace[i].Options, true);

	for (i=0; i<default.DefaultAmmoToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.DefaultAmmoToReplace[i].OldClassName, default.DefaultAmmoToReplace[i].NewClassPath, true, default.DefaultAmmoToReplace[i].Options, true);
}

static function StaticPreDestroy()
{
	local TestCentralWeaponReplacement MutatorObj;

	default.StaticWeaponsToReplace.Length = 0;
	default.StaticAmmoToReplace.Length = 0;
	default.StaticOrder.Length = 0;
	default.StaticBatchOp = false;

	if (GetStaticMutator(MutatorObj) && MutatorObj.DataCache != none)
	{
		MutatorObj.DataCache.Kill();
		MutatorObj.DataCache = none;
	}
}

static private function bool StaticPreRegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, bool bAmmo, ReplacementOptionsInfo ReplacementOptions, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local int index;
	local name RegistrarName;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	else NewClassPath = TrimRight(NewClassPath);

	RegistrarName = Registrar != none ? Registrar.Name : '';
	if (!bOnlyCheck && default.StaticOrder.Find(RegistrarName) == INDEX_NONE)
	{
		default.StaticOrder.AddItem(RegistrarName);
	}

	if (bAmmo)
	{
		if (IsNewItem(default.StaticAmmoToReplace, index, OldClassName))
		{
			if (!bOnlyCheck)
			{
				if (default.StaticBatchOp) index = StaticPreGetInsertIndex(default.StaticAmmoToReplace, Registrar);
				AddReplacementToArray(default.StaticAmmoToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions, index);
			}
			return true;
		}
		else if (!(default.StaticAmmoToReplace[index].NewClassPath ~= NewClassPath))
		{
			ErrorMessage = class'TestCWRUI'.static.GetData().GetErrorMessage(default.StaticAmmoToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
			return false;
		}
	}
	else if (IsNewItem(default.StaticWeaponsToReplace, index, OldClassName))
	{
		if (!bOnlyCheck)
		{
			if (default.StaticBatchOp) index = StaticPreGetInsertIndex(default.StaticWeaponsToReplace, Registrar);
			AddReplacementToArray(default.StaticWeaponsToReplace, Registrar, OldClassName, NewClassPath, ReplacementOptions, index);
		}
		return true;
	}
	else if (!(default.StaticWeaponsToReplace[index].NewClassPath ~= NewClassPath))
	{
		ErrorMessage = class'TestCWRUI'.static.GetData().GetErrorMessage(default.StaticWeaponsToReplace[index].Registrar, Registrar, OldClassName, NewClassPath);
		return false;
	}

	return true;
}

static private function bool StaticPreUnRegisterWeaponReplacement(Object Registrar, optional out string ErrorMessage)
{
	local bool bAnyRemoved;

	if (Registrar == none)
	{
		ErrorMessage = "No Registrar.";
		return false;
	}

	bAnyRemoved = RemoveReplacementFromArray(default.StaticWeaponsToReplace, Registrar) || bAnyRemoved;
	bAnyRemoved = RemoveReplacementFromArray(default.StaticAmmoToReplace, Registrar) || bAnyRemoved;

	// remove order entry (skip otherwise to keep order for updating)
	if (!default.StaticBatchOp) default.StaticOrder.RemoveItem(Registrar.Name);

	return bAnyRemoved;
}

static private function StaticPreUpdateWeaponReplacement(Object Registrar, bool bBatchOp)
{
	default.StaticBatchOp = bBatchOp;
}

static private function int StaticPreGetInsertIndex(out array<ReplacementInfoEx> arr, Object Registrar)
{
	local int i;
	local name RegistrarName, PreName;
	local bool bFound;
	i = default.StaticOrder.Find(Registrar.Name);
	if (i == 0)
	{
		return 0;
	}
	else if (i > 0)
	{
		PreName = default.StaticOrder[i-1];
		for (i=0; i<arr.Length; i++)
		{
			RegistrarName = arr[i].Registrar != none ? arr[i].Registrar.Name : '';
			if (!bFound && RegistrarName == PreName) bFound = true;
			if (bFound && RegistrarName != PreName) return i;
		}
	}

	return INDEX_NONE;
}

//**********************************************************************************
// Private functions
//**********************************************************************************

static private function AddReplacementToArray(out array<ReplacementInfoEx> arr, Object Registrar, name OldClassName, string NewClassPath, ReplacementOptionsInfo ReplacementOptions, optional int InsertIndex = INDEX_NONE)
{
	local ReplacementInfoEx item;
	item.OldClassName = OldClassName;
	item.NewClassPath = NewClassPath;
	item.Registrar = Registrar;
	item.Options = ReplacementOptions;

	if (InsertIndex == INDEX_NONE || InsertIndex > arr.Length-1) arr.AddItem(item);
	else arr.InsertItem(InsertIndex, item);
}

static private function bool RemoveReplacementFromArray(out array<ReplacementInfoEx> arr, Object Registrar)
{
	local int i;
	local bool bRemoved; 
	for (i=arr.Length-1; i>=0; i--)
	{
		if (arr[i].Registrar == Registrar)
		{
			bRemoved = true;
			arr.Remove(i, 1);
		}
	}

	return bRemoved;
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

function AddToLocker(class<UTWeapon> WeaponClass, ReplacementLockerInfo LockerOptions, optional bool bRemove)
{
	local UTWeaponLocker Locker;
	local WeaponEntry ent;
	local bool bAll;
	local int index;

	if (WeaponClass == none)
		return;

	bAll = LockerOptions.Names.Length == 0 && LockerOptions.Groups.Length == 0 && LockerOptions.Tags.Length == 0;
	foreach DynamicActors(class'UTWeaponLocker', Locker)
	{
		if (bAll || ShouldBeReplacedLocker(Locker, LockerOptions))
		{
			index = Locker.Weapons.Find('WeaponClass', WeaponClass);
			if (bRemove && index != INDEX_NONE)
			{
				Locker.Weapons.Remove(index, 1);
			}
			else if (!bRemove && index == INDEX_NONE)
			{
				ent.WeaponClass = WeaponClass;
				Locker.MaxDesireability += WeaponClass.Default.AIRating;

				Locker.Weapons.AddItem(ent);
			}
		}
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

function bool ShouldBeReplacedLocker(UTWeaponLocker Locker, ReplacementLockerInfo LockerOptions)
{
	if (LockerOptions.Names.Length == 0 && LockerOptions.Groups.Length == 0 && LockerOptions.Tags.Length == 0)
		return true;

	return LockerOptions.Names.Find(Locker.Name) != INDEX_NONE ||
		LockerOptions.Groups.Find(Locker.Group) != INDEX_NONE ||
		LockerOptions.Tags.Find(Locker.Group) != INDEX_NONE;
}

//**********************************************************************************
// Helper functions
//**********************************************************************************

static function bool IsNewItem(out array<ReplacementInfoEx> items, out int index, name ClassName)
{
	index = items.Find('OldClassName', ClassName);
	return index == INDEX_NONE;
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

static function WriteToConsole(string message)
{
	local GameUISceneClient SceneClient;
	local Console con;

	SceneClient = class'UIRoot'.static.GetSceneClient();
	con = SceneClient.ViewportConsole;
	con.OutputText(message);
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

static function bool GetStaticMutator(out TestCentralWeaponReplacement OutMutator)
{
	local Object Obj;
	if (GetDefaultObject(default.Class, Obj) && TestCentralWeaponReplacement(Obj) != none)
	{
		OutMutator = TestCentralWeaponReplacement(Obj);
	}

	return OutMutator != none;
}

Defaultproperties
{
	GroupNames[0]="WEAPONMOD"

	ParameterProfile="CWRMapProfile"
}
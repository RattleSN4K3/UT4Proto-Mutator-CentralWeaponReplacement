class TestCentralWeaponReplacement extends UTMutator
	dependson(TestCWRUI)
	config(TestCentralWeaponReplacement);

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

struct ReplacementSpawnInfo
{
	/** Whether to override the Location of this Actor */
	var bool OverrideLocation;
	/** The Location to use when the location is overridden */
	var Vector Location;
	/** A relative 3D-coordinate value to offset the position */
	var Vector OffsetLocation;	

	/** Whether to override the Rotation of this Actor */
	var bool OverrideRotation;
	/** The Rotation to use when the location is overridden */
	var Rotator Rotation;
	/** A relative 3D-coordinate value to offset the base rotation */
	var Rotator OffsetRotation;

	//var bool OverrideScale;
	//var bool ApplyScale;
	//var float Scale;
	//var Vector Scale3D;	
	//var float OffsetScale;
	//var Vector OffsetScale3D;
};

struct ReplacementOptionsInfo
{
	/** Whether to not replace/remove the weapon */
	var bool bNoReplaceWeapon;
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

	/** Options to specify additional spawning information about translation/rotation/scale etc. when a pickup/vehicle factory is replaced */
	var ReplacementSpawnInfo SpawnOptions;
	
	// struct defaultproperties doesn't work for template mutators default props
	// Note: Don't change anything to a different value than the default one
	structdefaultproperties
	{
		bNoReplaceWeapon=false
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

	structdefaultproperties
	{
		Options=()
	}
};

struct TemplateDynamicInfo
{
	/** Info about the replacement */
	var TemplateInfo Template;

	/** Type of the dynamic template */
	var EReplacementType Type;
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
var private transient config array<ReplacementInfoEx> StaticHealthToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticArmorToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticPowerupsToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticDeployablesToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticVehiclesToReplace;
/** @ignore */
var private transient config array<ReplacementInfoEx> StaticCustomsToReplace;
/** @ignore */
var private transient config array<name> StaticOrder;
/** @ignore */
var private transient config bool StaticBatchOp;

// Config
// ------------

var config array<ReplacementInfoEx> DefaultWeaponsToReplace;
var config array<ReplacementInfoEx> DefaultAmmoToReplace;

var config array<ReplacementInfoEx> DefaultHealthToReplace;
var config array<ReplacementInfoEx> DefaultArmorToReplace;
var config array<ReplacementInfoEx> DefaultPowerupsToReplace;
var config array<ReplacementInfoEx> DefaultDeployablesToReplace;
var config array<ReplacementInfoEx> DefaultVehiclesToReplace;
var config array<ReplacementInfoEx> DefaultCustomsToReplace;

// Workflow
// ------------

var array<ReplacementInfoEx> WeaponsToReplace;
var array<ReplacementInfoEx> AmmoToReplace;

var array<ReplacementInfoEx> HealthToReplace;
var array<ReplacementInfoEx> ArmorToReplace;
var array<ReplacementInfoEx> PowerupsToReplace;
var array<ReplacementInfoEx> DeployablesToReplace;
var array<ReplacementInfoEx> VehiclesToReplace;
var array<ReplacementInfoEx> CustomsToReplace;


var TestCWRUI DataCache;
var array<ErrorMessageInfo> ErrorMessages;

var array<int> EnforcerIndizes;

/** Flag. Set when hoverboard is is going to be placed on each spawn of a player */
var bool bReplaceHoverboard;
var class<UTVehicle> HoverboardClass;

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

		HealthToReplace.Length = 0;
		ArmorToReplace.Length = 0;
		PowerupsToReplace.Length = 0;
		DeployablesToReplace.Length = 0;
		VehiclesToReplace.Length = 0;
		CustomsToReplace.Length = 0;

		for (i=0; i<DefaultWeaponsToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultWeaponsToReplace[i].OldClassName, DefaultWeaponsToReplace[i].NewClassPath, RT_Weapon, DefaultWeaponsToReplace[i].Options);

		for (i=0; i<DefaultAmmoToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultAmmoToReplace[i].OldClassName, DefaultAmmoToReplace[i].NewClassPath, RT_Ammo, DefaultAmmoToReplace[i].Options);

		for (i=0; i<DefaultHealthToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultHealthToReplace[i].OldClassName, DefaultHealthToReplace[i].NewClassPath, RT_Health, DefaultHealthToReplace[i].Options);

		for (i=0; i<DefaultArmorToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultArmorToReplace[i].OldClassName, DefaultArmorToReplace[i].NewClassPath, RT_Armor, DefaultArmorToReplace[i].Options);

		for (i=0; i<DefaultPowerupsToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultPowerupsToReplace[i].OldClassName, DefaultPowerupsToReplace[i].NewClassPath, RT_Powerup, DefaultPowerupsToReplace[i].Options);

		for (i=0; i<DefaultDeployablesToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultDeployablesToReplace[i].OldClassName, DefaultDeployablesToReplace[i].NewClassPath, RT_Deployable, DefaultDeployablesToReplace[i].Options);

		for (i=0; i<DefaultVehiclesToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultVehiclesToReplace[i].OldClassName, DefaultVehiclesToReplace[i].NewClassPath, RT_Vehicle, DefaultVehiclesToReplace[i].Options);

		for (i=0; i<DefaultCustomsToReplace.Length; i++)
			RegisterWeaponReplacement(none, DefaultCustomsToReplace[i].OldClassName, DefaultCustomsToReplace[i].NewClassPath, RT_Custom, DefaultCustomsToReplace[i].Options);
	}
}

// used to check for default inventory items to be replaced or
// whether an item should be added to the weapon lockers or the default inventory
function InitMutator(string Options, out string ErrorMessage)
{
	local int i, j;
	local UTGame G;
	local class<Inventory> InventoryClass;
	local TestCWRMapProfile MapProvider;
	local class NewClass;

	super.InitMutator(Options, ErrorMessage);

	if (class'GameInfo'.static.HasOption(Options, ParameterProfile))
	{
		CurrentProfileName = class'GameInfo'.static.ParseOption(Options, ParameterProfile);
	}

	if (CurrentProfileName != "" && class'TestCWRMapProfile'.static.GetMapProfileByName(CurrentProfileName, MapProvider))
	{
		CurrentProfile = MapProvider;
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.WeaponsToReplace, RT_Weapon);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.AmmoToReplace, RT_Ammo);

		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.HealthToReplace, RT_Health);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.ArmorToReplace, RT_Armor);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.PowerupsToReplace, RT_Powerup);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.DeployablesToReplace, RT_Deployable);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.VehiclesToReplace, RT_Vehicle);
		RegisterWeaponReplacementArray(CurrentProfile, CurrentProfile.CustomsToReplace, RT_Custom);
	}

	// Make sure the game does not hold a null reference
	G = UTGame(WorldInfo.Game);
	if(G != none)
	{
		for (j=0; j<WeaponsToReplace.Length; j++)
		{
			InventoryClass = none;
			if (ClassPathValid(WeaponsToReplace[j].NewClassPath))
			{
				InventoryClass = class<Inventory>(DynamicLoadObject(WeaponsToReplace[j].NewClassPath, class'Class'));
			}

			if (WeaponsToReplace[j].OldClassName != '' && !WeaponsToReplace[j].Options.bNoReplaceWeapon && !WeaponsToReplace[j].Options.bNoDefaultInventory)
			{
				for (i=0; i<G.DefaultInventory.length; i++)
				{
					if (G.DefaultInventory[i] == None) continue;
					if (!WeaponsToReplace[j].Options.bSubClasses && G.DefaultInventory[i].Name != WeaponsToReplace[j].OldClassName) continue;

					// IsA doesn't work for abstract classes, we need to use the workaround/hackfix
					if (WeaponsToReplace[j].Options.bSubClasses && !IsSubClass(G.DefaultInventory[i], WeaponsToReplace[j].OldClassName)) continue;

					if (InventoryClass == none)
					{
						// remove from inventory
						G.DefaultInventory.Remove(i, 1);
					}
					else if (!WeaponsToReplace[j].Options.bNoReplaceWeapon)
					{
						G.DefaultInventory[i] = InventoryClass;
					}
				}
			}

			// add to default inventory by request
			if (WeaponsToReplace[j].Options.bAddToDefault && InventoryClass != none)
			{
				G.DefaultInventory.AddItem(InventoryClass);
			}

			// add to weapon lockers by request
			if (WeaponsToReplace[j].Options.bAddToLocker)
			{
				AddToLocker(class<UTWeapon>(InventoryClass), WeaponsToReplace[j].Options.LockerOptions);
			}

			// replace translocator (checking for subclass as well if desired)
			if (G.TranslocatorClass != None)
			{
				if ((!WeaponsToReplace[j].Options.bSubClasses && G.TranslocatorClass.Name == WeaponsToReplace[j].OldClassName) ||
					(WeaponsToReplace[j].Options.bSubClasses && IsSubClass(G.TranslocatorClass, WeaponsToReplace[j].OldClassName)))
				{
					if (InventoryClass == none || WeaponsToReplace[j].Options.bNoReplaceWeapon)
					{
						// replace with nothing
						G.TranslocatorClass = None;
					}
					else
					{
						G.TranslocatorClass = InventoryClass;
					}
				}
			}
		}

		// count how many enforcers are in default inventory (for Dual/Akimbo)
		EnforcerIndizes.Length = 0;
		for (i=0; i<G.DefaultInventory.length; i++)
		{
			if (IsSubClass(G.DefaultInventory[i], 'UTWeap_Enforcer'))
			{
				EnforcerIndizes.AddItem(i);
			}
		}

		// check if hoverboard should be replaced
		for (i=0; i<VehiclesToReplace.length; i++)
		{
			if (VehiclesToReplace[i].OldClassName == 'UTVehicle_Hoverboard' &&
				ClassPathValid(VehiclesToReplace[i].NewClassPath) &&
				LoadClass(VehiclesToReplace[i].NewClassPath, NewClass) &&
				class<UTVehicle>(NewClass) != none)
			{
				bReplaceHoverboard = true;
				HoverboardClass = class<UTVehicle>(NewClass);
				break;
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
	local class<UTAmmoPickupFactory> NewAmmoClass;
	local UTHealthPickupFactory HealthPickup;
	local UTArmorPickupFactory ArmorPickup;
	local UTPowerupPickupFactory PowerupPickup;
	local UTDeployablePickupFactory DeployablePickup;
	local UTVehicleFactory VehicleFac;
	local PickupFactory PickupFac;
	local int i, Index;
	local class NewClass;
	local byte bAbort;

	if (UTWeaponPickupFactory(Other) != None)
	{
		WeaponPickup = UTWeaponPickupFactory(Other);
		if (WeaponPickup.WeaponPickupClass != None)
		{
			if (ShouldBeReplaced(index, WeaponPickup.WeaponPickupClass, RT_Weapon) && !WeaponsToReplace[index].Options.bNoReplaceWeapon)
			{
				if (!ClassPathValid(WeaponsToReplace[index].NewClassPath) || !LoadClass(WeaponsToReplace[index].NewClassPath, NewClass))
				{
					// replace with nothing
					return false;
				}

				if (class<Inventory>(NewClass) != none)
				{
					WeaponPickup.WeaponPickupClass = class<UTWeapon>(NewClass);
					WeaponPickup.InitializePickup();
				}
				else if (SpawnNewPickup(WeaponPickup, class<Actor>(NewClass), WeaponsToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0)
				{
					return false;
				}
			}
		}
	}
	else if (UTWeaponLocker(Other) != None)
	{
		Locker = UTWeaponLocker(Other);
		for (i = 0; i < Locker.Weapons.length; i++)
		{
			if (class<UTDeployable>(Locker.Weapons[i].WeaponClass) != none)
			{
				if (Locker.Weapons[i].WeaponClass != none &&
					ShouldBeReplaced(index, Locker.Weapons[i].WeaponClass, RT_Deployable) &&
					DeployablesToReplace[index].Options.bNoReplaceWeapon == false &&
					ShouldBeReplacedLocker(Locker, DeployablesToReplace[index].Options.LockerOptions))
				{
					if (!ClassPathValid(DeployablesToReplace[index].NewClassPath))
					{
						// replace with nothing
						Locker.ReplaceWeapon(i, None);
					}
					else
					{
						Locker.ReplaceWeapon(i, class<UTDeployable>(DynamicLoadObject(DeployablesToReplace[index].NewClassPath, class'Class')));
					}
				}
			}
			else if (Locker.Weapons[i].WeaponClass != none &&
				ShouldBeReplaced(index, Locker.Weapons[i].WeaponClass, RT_Weapon) &&
				WeaponsToReplace[index].Options.bNoReplaceWeapon == false &&
				ShouldBeReplacedLocker(Locker, WeaponsToReplace[index].Options.LockerOptions))
			{
				if (!ClassPathValid(WeaponsToReplace[index].NewClassPath))
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
			if (ShouldBeReplaced(index, AmmoPickup.Class, RT_Ammo) && !AmmoToReplace[index].Options.bNoReplaceWeapon)
			{
				if (!ClassPathValid(AmmoToReplace[index].NewClassPath))
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

	else if (UTHealthPickupFactory(Other) != none)
	{
		HealthPickup = UTHealthPickupFactory(Other);
		if (ShouldBeReplaced(index, HealthPickup.Class, RT_Health))
		{
			if (!ClassPathValid(HealthToReplace[index].NewClassPath) || !LoadClass(HealthToReplace[index].NewClassPath, NewClass) || 
				(Other.Class != NewClass && SpawnNewPickup(Other, class<Actor>(NewClass), HealthToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0))
			{
				return false;
			}
		}
	}
	
	else if (UTArmorPickupFactory(Other) != none)
	{
		ArmorPickup = UTArmorPickupFactory(Other);
		if (ShouldBeReplaced(index, ArmorPickup.Class, RT_Armor))
		{
			if (!ClassPathValid(ArmorToReplace[index].NewClassPath) || !LoadClass(ArmorToReplace[index].NewClassPath, NewClass) || 
				(Other.Class != NewClass && SpawnNewPickup(Other, class<Actor>(NewClass), ArmorToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0))
			{
				return false;
			}
		}
	}

	else if (UTPowerupPickupFactory(Other) != none)
	{
		PowerupPickup = UTPowerupPickupFactory(Other);
		if (ShouldBeReplaced(index, PowerupPickup.Class, RT_Powerup))
		{
			if (!ClassPathValid(PowerupsToReplace[index].NewClassPath) || !LoadClass(PowerupsToReplace[index].NewClassPath, NewClass) || 
				(Other.Class != NewClass && SpawnNewPickup(Other, class<Actor>(NewClass), PowerupsToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0))
			{
				return false;
			}
		}

		// alternative powerup class replacement
		else if (PowerupPickup.InventoryType != none && ShouldBeReplaced(index, PowerupPickup.InventoryType, RT_Powerup))
		{
			if (!ClassPathValid(PowerupsToReplace[index].NewClassPath) || !LoadClass(PowerupsToReplace[index].NewClassPath, NewClass))
			{
				// replace with nothing
				return false;
			}

			if (class<Inventory>(NewClass) != none)
			{
				PowerupPickup.InventoryType = class<Inventory>(NewClass);
				PowerupPickup.InitializePickup();
			}
			else if (SpawnNewPickup(PowerupPickup, class<Actor>(NewClass), PowerupsToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0)
			{
				return false;
			}
		}
	}

	else if (UTDeployablePickupFactory(Other) != none)
	{
		DeployablePickup = UTDeployablePickupFactory(Other);
		if (DeployablePickup.DeployablePickupClass != None && ShouldBeReplaced(index, DeployablePickup.DeployablePickupClass, RT_Deployable) && !DeployablesToReplace[index].Options.bNoReplaceWeapon)
		{
			if (!ClassPathValid(DeployablesToReplace[index].NewClassPath) || !LoadClass(DeployablesToReplace[index].NewClassPath, NewClass))
			{
				// replace with nothing
				return false;
			}

			if (class<UTDeployable>(NewClass) != none)
			{
				DeployablePickup.DeployablePickupClass = class<UTDeployable>(NewClass);
				DeployablePickup.InitializePickup();
			}
			else if (SpawnNewPickup(DeployablePickup, class<Actor>(NewClass), DeployablesToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0)
			{
				return false;
			}
		}

		// alternative deployable pickup factory replacement
		else if (ShouldBeReplaced(index, DeployablePickup.Class, RT_Deployable))
		{
			if (!ClassPathValid(DeployablesToReplace[index].NewClassPath) || !LoadClass(DeployablesToReplace[index].NewClassPath, NewClass) || 
				(Other.Class != NewClass && SpawnNewPickup(Other, class<Actor>(NewClass), DeployablesToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0))
			{
				return false;
			}
		}
	}

	else if (UTVehicleFactory(Other) != none)
	{
		VehicleFac = UTVehicleFactory(Other);
		if (ShouldBeReplaced(index, VehicleFac.Class, RT_Vehicle))
		{
			if (!ClassPathValid(VehiclesToReplace[index].NewClassPath) || !LoadClass(VehiclesToReplace[index].NewClassPath, NewClass) || 
				(Other.Class != NewClass && SpawnNewPickup(Other, class<Actor>(NewClass), VehiclesToReplace[index].Options.SpawnOptions, bAbort,, class<UTVehicleFactory>(NewClass) == none, VehicleFac.SpawnZOffset + VehicleFac.CollisionComponent.Bounds.BoxExtent.Z) && bAbort != 0))
			{
				VehicleFac.VehicleClassPath = "";
				VehicleFac.VehicleClass = none;
				VehicleFac.Deactivate();
				return false;
			}
		}

		// alternative vehicle class replacement
		else if (VehicleFac.VehicleClass != None && ShouldBeReplaced(index, VehicleFac.VehicleClass, RT_Vehicle))
		{
			if (!ClassPathValid(VehiclesToReplace[index].NewClassPath) || !LoadClass(VehiclesToReplace[index].NewClassPath, NewClass))
			{
				// replace with nothing
				VehicleFac.VehicleClassPath = "";
				VehicleFac.VehicleClass = none;
				VehicleFac.Deactivate();
				return false;
			}

			if (class<UTVehicle>(NewClass) != none)
			{
				VehicleFac.VehicleClassPath = PathName(NewClass);
				VehicleFac.VehicleClass = class<UTVehicle>(NewClass);
			}
			else if (SpawnNewPickup(VehicleFac, class<Actor>(NewClass), VehiclesToReplace[index].Options.SpawnOptions, bAbort,, class<UTVehicleFactory>(NewClass) == none, VehicleFac.SpawnZOffset + VehicleFac.CollisionComponent.Bounds.BoxExtent.Z) && bAbort != 0)
			{
				VehicleFac.VehicleClassPath = "";
				VehicleFac.VehicleClass = none;
				VehicleFac.Deactivate();
				return false;
			}
		}
	}

	else if (PickupFactory(Other) != none)
	{
		PickupFac = PickupFactory(Other);
		if (ShouldBeReplaced(index, PickupFac.Class, RT_Custom))
		{
			if (!ClassPathValid(CustomsToReplace[index].NewClassPath) || !LoadClass(CustomsToReplace[index].NewClassPath, NewClass) || 
				(Other.Class != NewClass && SpawnNewPickup(Other, class<Actor>(NewClass), CustomsToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0))
			{
				return false;
			}
		}

		// alternative powerup class replacement
		else if (PickupFac.InventoryType != none && ShouldBeReplaced(index, PickupFac.InventoryType, RT_Custom))
		{
			if (!ClassPathValid(CustomsToReplace[index].NewClassPath) || !LoadClass(CustomsToReplace[index].NewClassPath, NewClass))
			{
				// replace with nothing
				return false;
			}

			if (class<Inventory>(NewClass) != none)
			{
				PickupFac.InventoryType = class<Inventory>(NewClass);
				PickupFac.InitializePickup();
			}
			else if (SpawnNewPickup(PickupFac, class<Actor>(NewClass), CustomsToReplace[index].Options.SpawnOptions, bAbort) && bAbort != 0)
			{
				return false;
			}
		}
	}

	// remove initial anim for Enforcers (may only work on server/listen player)
	else if (EnforcerIndizes.Length > 1 && UTWeap_Enforcer(Other) != none)
	{
		UTWeap_Enforcer(Other).bLoaded = true;
		UTWeap_Enforcer(Other).EquipTime = UTWeap_Enforcer(Other).ReloadTime;
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

	// replace hoverboard class
	if (bReplaceHoverboard && UTPawn(Other) != none)
	{
		UTPawn(Other).bHasHoverboard = true;
		UTPawn(Other).HoverboardClass = HoverboardClass;
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

function RegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, EReplacementType ReplacementType, ReplacementOptionsInfo ReplacementOptions)
{
	local int index;
	local array<ReplacementInfoEx> Replacements;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	else NewClassPath = TrimRight(NewClassPath);

	if (!GetReplacements(self, ReplacementType, Replacements))
		return;

	if (IsNewItem(Replacements, index, OldClassName))
	{
		AddReplacementToArray(Replacements, Registrar, OldClassName, NewClassPath, ReplacementOptions);
	}
	else if (!(Replacements[index].NewClassPath ~= NewClassPath))
	{
		AddErrorMessage(Replacements[index].Registrar, Registrar, OldClassName, NewClassPath);
	}

	SetReplacements(self, ReplacementType, Replacements);
}

function RegisterWeaponReplacementInfo(Object Registrar, coerce TemplateInfo RepInfo, EReplacementType ReplacementType)
{
	RegisterWeaponReplacement(Registrar, RepInfo.OldClassName, RepInfo.NewClassPath, ReplacementType, RepInfo.Options);
}

function RegisterWeaponReplacementArray(Object Registrar, coerce array<TemplateInfo> Replacements, EReplacementType ReplacementType)
{
	local int i;
	for (i=0; i<Replacements.Length; i++)
	{
		RegisterWeaponReplacementInfo(Registrar, Replacements[i], ReplacementType);
	}
}

function UnRegisterWeaponReplacement(Object Registrar)
{
	RemoveReplacementFromArray(WeaponsToReplace, Registrar);
	RemoveReplacementFromArray(AmmoToReplace, Registrar);

	RemoveReplacementFromArray(HealthToReplace, Registrar);
	RemoveReplacementFromArray(ArmorToReplace, Registrar);
	RemoveReplacementFromArray(PowerupsToReplace, Registrar);
	RemoveReplacementFromArray(DeployablesToReplace, Registrar);
	RemoveReplacementFromArray(VehiclesToReplace, Registrar);
	RemoveReplacementFromArray(CustomsToReplace, Registrar);
}

static function bool StaticRegisterWeaponReplacement(Object Registrar, coerce name OldClassName, string NewClassPath, EReplacementType ReplacementType, optional ReplacementOptionsInfo ReplacementOptions, optional bool bPre, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local WorldInfo WI;
	local TestCentralWeaponReplacement mut;

	if (bPre)
	{
		return StaticPreRegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, ReplacementType, ReplacementOptions, bOnlyCheck, ErrorMessage);
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
	mut.RegisterWeaponReplacement(Registrar, OldClassName, NewClassPath, ReplacementType, ReplacementOptions);
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

	// ensure a valid mutator exists
	if (!EnsureMutator(WI, mut, true))
	{
		ErrorMessage = "No Mutator found.";
		return false;
	}

	// unregister the weapon replacement
	mut.UnRegisterWeaponReplacement(Registrar);
	return true;
}

/** Set batch operation flag for updating registered replacements for this Registrar and keeping order */
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

	default.StaticHealthToReplace.Length = 0;
	default.StaticArmorToReplace.Length = 0;
	default.StaticPowerupsToReplace.Length = 0;
	default.StaticDeployablesToReplace.Length = 0;
	default.StaticVehiclesToReplace.Length = 0;
	default.StaticCustomsToReplace.Length = 0;

	default.StaticOrder.Length = 0;
	default.StaticBatchOp = false;

	if (GetStaticMutator(MutatorObj))
	{
		MutatorObj.DataCache = class'TestCWRUI'.static.GetData();
	}

	for (i=0; i<default.DefaultWeaponsToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.DefaultWeaponsToReplace[i].OldClassName, default.DefaultWeaponsToReplace[i].NewClassPath, RT_Weapon, default.DefaultWeaponsToReplace[i].Options, true);

	for (i=0; i<default.DefaultAmmoToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.DefaultAmmoToReplace[i].OldClassName, default.DefaultAmmoToReplace[i].NewClassPath, RT_Ammo, default.DefaultAmmoToReplace[i].Options, true);

	for (i=0; i<default.StaticHealthToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.StaticHealthToReplace[i].OldClassName, default.StaticHealthToReplace[i].NewClassPath, RT_Health, default.StaticHealthToReplace[i].Options, true);

	for (i=0; i<default.StaticArmorToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.StaticArmorToReplace[i].OldClassName, default.StaticArmorToReplace[i].NewClassPath, RT_Armor, default.StaticArmorToReplace[i].Options, true);

	for (i=0; i<default.StaticPowerupsToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.StaticPowerupsToReplace[i].OldClassName, default.StaticPowerupsToReplace[i].NewClassPath, RT_Powerup, default.StaticPowerupsToReplace[i].Options, true);

	for (i=0; i<default.StaticDeployablesToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.StaticDeployablesToReplace[i].OldClassName, default.StaticDeployablesToReplace[i].NewClassPath, RT_Deployable, default.StaticDeployablesToReplace[i].Options, true);

	for (i=0; i<default.StaticVehiclesToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.StaticVehiclesToReplace[i].OldClassName, default.StaticVehiclesToReplace[i].NewClassPath, RT_Vehicle, default.StaticVehiclesToReplace[i].Options, true);

	for (i=0; i<default.StaticCustomsToReplace.Length; i++)
		StaticRegisterWeaponReplacement(none, default.StaticCustomsToReplace[i].OldClassName, default.StaticCustomsToReplace[i].NewClassPath, RT_Custom, default.StaticCustomsToReplace[i].Options, true);
}

static function StaticPreDestroy()
{
	local TestCentralWeaponReplacement MutatorObj;

	default.StaticWeaponsToReplace.Length = 0;
	default.StaticAmmoToReplace.Length = 0;

	default.StaticHealthToReplace.Length = 0;
	default.StaticArmorToReplace.Length = 0;
	default.StaticPowerupsToReplace.Length = 0;
	default.StaticDeployablesToReplace.Length = 0;
	default.StaticVehiclesToReplace.Length = 0;
	default.StaticCustomsToReplace.Length = 0;

	default.StaticOrder.Length = 0;
	default.StaticBatchOp = false;

	if (GetStaticMutator(MutatorObj) && MutatorObj.DataCache != none)
	{
		MutatorObj.DataCache.Kill();
		MutatorObj.DataCache = none;
	}
}

static private function bool StaticPreRegisterWeaponReplacement(Object Registrar, name OldClassName, string NewClassPath, EReplacementType ReplacementType, ReplacementOptionsInfo ReplacementOptions, optional bool bOnlyCheck, optional out string ErrorMessage)
{
	local bool bSuccess;
	local int index;
	local name RegistrarName;
	local array<ReplacementInfoEx> Replacements;

	// ensure empty class path
	if (NewClassPath ~= "None") NewClassPath = "";
	else NewClassPath = TrimRight(NewClassPath);

	if (GetReplacements(default.Class, ReplacementType, Replacements))
	{
		RegistrarName = Registrar != none ? Registrar.Name : '';
		if (!bOnlyCheck && default.StaticOrder.Find(RegistrarName) == INDEX_NONE)
		{
			default.StaticOrder.AddItem(RegistrarName);
		}

		if (IsNewItem(Replacements, index, OldClassName))
		{
			if (!bOnlyCheck)
			{
				if (default.StaticBatchOp) index = StaticPreGetInsertIndex(Replacements, Registrar);
				AddReplacementToArray(Replacements, Registrar, OldClassName, NewClassPath, ReplacementOptions, index);
			}
			bSuccess = true;
		}
		else if (!(Replacements[index].NewClassPath ~= NewClassPath))
		{
			ErrorMessage = class'TestCWRUI'.static.GetData().GetErrorMessage(Replacements[index].Registrar, Registrar, OldClassName, NewClassPath);
		}
		else
		{
			bSuccess = true;
		}

		SetReplacements(default.Class, ReplacementType, Replacements);
	}

	return bSuccess;
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

	bAnyRemoved = RemoveReplacementFromArray(default.StaticHealthToReplace, Registrar) || bAnyRemoved;
	bAnyRemoved = RemoveReplacementFromArray(default.StaticArmorToReplace, Registrar) || bAnyRemoved;
	bAnyRemoved = RemoveReplacementFromArray(default.StaticPowerupsToReplace, Registrar) || bAnyRemoved;
	bAnyRemoved = RemoveReplacementFromArray(default.StaticDeployablesToReplace, Registrar) || bAnyRemoved;
	bAnyRemoved = RemoveReplacementFromArray(default.StaticVehiclesToReplace, Registrar) || bAnyRemoved;
	bAnyRemoved = RemoveReplacementFromArray(default.StaticCustomsToReplace, Registrar) || bAnyRemoved;

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

static function bool GetConfigReplacements(EReplacementType ReplacementType, out array<ReplacementInfoEx> Replacements)
{
	switch (ReplacementType) {
	case RT_Weapon: Replacements = default.DefaultWeaponsToReplace;break;
	case RT_Ammo: Replacements = default.DefaultAmmoToReplace;break;

	case RT_Health: Replacements = default.DefaultHealthToReplace;break;
	case RT_Armor: Replacements = default.DefaultArmorToReplace;break;
	case RT_Powerup: Replacements = default.DefaultPowerupsToReplace;break;
	case RT_Deployable: Replacements = default.DefaultDeployablesToReplace;break;
	case RT_Vehicle: Replacements = default.DefaultVehiclesToReplace;break;
	case RT_Custom: Replacements = default.DefaultCustomsToReplace;break;
	default: return false;
	}

	return true;
}

static function bool SetConfigReplacements(EReplacementType ReplacementType, out array<ReplacementInfoEx> Replacements)
{
	if (ReplacementType == RT_Weapon) default.DefaultWeaponsToReplace = Replacements;
	else if (ReplacementType == RT_Ammo) default.DefaultAmmoToReplace = Replacements;

	else if (ReplacementType == RT_Health) default.DefaultHealthToReplace = Replacements;
	else if (ReplacementType == RT_Armor) default.DefaultArmorToReplace = Replacements;
	else if (ReplacementType == RT_Powerup) default.DefaultPowerupsToReplace = Replacements;
	else if (ReplacementType == RT_Deployable) default.DefaultDeployablesToReplace = Replacements;
	else if (ReplacementType == RT_Vehicle) default.DefaultVehiclesToReplace = Replacements;
	else if (ReplacementType == RT_Custom) default.DefaultCustomsToReplace = Replacements;
	else return false;

	StaticSaveConfig();
	return true;
}

//**********************************************************************************
// Private functions
//**********************************************************************************

static function bool GetReplacements(Object Context, EReplacementType ReplacementType, out array<ReplacementInfoEx> Replacements)
{
	local TestCentralWeaponReplacement ContextObj;
	local bool IsStatic;
	ContextObj = TestCentralWeaponReplacement(Context);
	IsStatic = ContextObj == none;

	switch (ReplacementType) {
	case RT_Weapon: Replacements = IsStatic ? default.StaticWeaponsToReplace : ContextObj.WeaponsToReplace;break;
	case RT_Ammo: Replacements = IsStatic ? default.StaticAmmoToReplace : ContextObj.AmmoToReplace;break;

	case RT_Health: Replacements = IsStatic ? default.StaticHealthToReplace : ContextObj.HealthToReplace;break;
	case RT_Armor: Replacements = IsStatic ? default.StaticArmorToReplace : ContextObj.ArmorToReplace;break;
	case RT_Powerup: Replacements = IsStatic ? default.StaticPowerupsToReplace : ContextObj.PowerupsToReplace;break;
	case RT_Deployable: Replacements = IsStatic ? default.StaticDeployablesToReplace : ContextObj.DeployablesToReplace;break;
	case RT_Vehicle: Replacements = IsStatic ? default.StaticVehiclesToReplace: ContextObj.VehiclesToReplace;break;
	case RT_Custom: Replacements = IsStatic ? default.StaticCustomsToReplace: ContextObj.CustomsToReplace;break;
	default: return false;
	}

	return true;
}

static function bool SetReplacements(Object Context, EReplacementType ReplacementType, out array<ReplacementInfoEx> Replacements)
{
	local TestCentralWeaponReplacement ContextObj;
	ContextObj = TestCentralWeaponReplacement(Context);

	if (ContextObj == none)
	{
		if (ReplacementType == RT_Weapon) default.StaticWeaponsToReplace = Replacements;
		else if (ReplacementType == RT_Ammo) default.StaticAmmoToReplace = Replacements;

		else if (ReplacementType == RT_Health) default.StaticHealthToReplace = Replacements;
		else if (ReplacementType == RT_Armor) default.StaticArmorToReplace = Replacements;
		else if (ReplacementType == RT_Powerup) default.StaticPowerupsToReplace = Replacements;
		else if (ReplacementType == RT_Deployable) default.StaticDeployablesToReplace = Replacements;
		else if (ReplacementType == RT_Vehicle) default.StaticVehiclesToReplace = Replacements;
		else if (ReplacementType == RT_Custom) default.StaticCustomsToReplace = Replacements;
		else return false;
	}
	else
	{
		switch (ReplacementType) {
		case RT_Weapon: ContextObj.WeaponsToReplace = Replacements;break;
		case RT_Ammo: ContextObj.AmmoToReplace = Replacements;break;

		case RT_Health: ContextObj.HealthToReplace = Replacements;break;
		case RT_Armor: ContextObj.ArmorToReplace = Replacements;break;
		case RT_Powerup: ContextObj.PowerupsToReplace = Replacements;break;
		case RT_Deployable: ContextObj.DeployablesToReplace = Replacements;break;
		case RT_Vehicle: ContextObj.VehiclesToReplace = Replacements;break;
		case RT_Custom: ContextObj.CustomsToReplace = Replacements;break;
		default: return false;
		}
	}

	return true;
}

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

function bool ShouldBeReplaced(out int index, class ClassToCheck, EReplacementType ReplacementType)
{
	local int i;
	local array<ReplacementInfoEx> Replacements;
	
	if (GetReplacements(self, ReplacementType, Replacements))
	{
		index = Replacements.Find('OldClassName', ClassToCheck.Name);
		if (index != INDEX_NONE) return true;

		for (i=0; i<Replacements.Length; i++)
		{
			if (Replacements[i].Options.bSubClasses && 
				IsSubClass(ClassToCheck, Replacements[i].OldClassName) &&
				!IgnoreSubClass(ClassToCheck, Replacements[i].Options.IgnoreSubClasses))
			{
				index = i;
				return true;
			}
		}
	}

	return false;
}

function bool ShouldBeReplacedLocker(UTWeaponLocker Locker, ReplacementLockerInfo LockerOptions)
{
	if (LockerOptions.Names.Length == 0 && LockerOptions.Groups.Length == 0 && LockerOptions.Tags.Length == 0)
		return true;

	return LockerOptions.Names.Find(Locker.Name) != INDEX_NONE ||
		LockerOptions.Groups.Find(Locker.Group) != INDEX_NONE ||
		LockerOptions.Tags.Find(Locker.Group) != INDEX_NONE;
}

function bool SpawnNewPickup(Actor Other, class<Actor> ActorClass, ReplacementSpawnInfo SpawnOptions, out byte OutAbort, optional out Actor NewActor, optional bool bTryToAlign, optional float MaxTrace = 100.0)
{
	local vector SpawnLocation;
	local rotator SpawnRotation;
	//local float SpawnScale;
	//local vector SpawnScale3D;

	local vector HitLocation;
	local vector HitNormal;
	local Vector TraceExtent;

	if (ActorClass == none)
		return false;

	OutAbort = 1;

	SpawnLocation = SpawnOptions.OverrideLocation ? SpawnOptions.Location : Other.Location;
	SpawnRotation = SpawnOptions.OverrideRotation ? SpawnOptions.Rotation : Other.Rotation;
	//SpawnScale = SpawnOptions.OverrideScale ? SpawnOptions.Scale : Other.DrawScale;
	//SpawnScale3D = SpawnOptions.OverrideScale ? SpawnOptions.Scale3D : Other.DrawScale3D;

	SpawnLocation += SpawnOptions.OffsetLocation;
	SpawnRotation += SpawnOptions.OffsetRotation;
	//SpawnScale += SpawnOptions.OffsetScale;
	//SpawnScale3D += SpawnOptions.OffsetScale3D;

	// snap/align new actor to floor
	if(!SpawnOptions.OverrideLocation && bTryToAlign && MaxTrace != 0.0)
	{
		TraceExtent = vect(1,1,1);
		if(CylinderComponent(ActorClass.default.CollisionComponent) != none)
		{
			TraceExtent.Z = CylinderComponent(ActorClass.default.CollisionComponent).CollisionHeight;
		}

		HitLocation = SpawnLocation-(vect(0,0,1)*MaxTrace);
		if (WorldInfo.Trace(HitLocation, HitNormal, HitLocation, SpawnLocation, false, TraceExtent, /*HitInfo*/, TRACEFLAG_PhysicsVolumes) != none)
		{
			SpawnLocation = HitLocation;
			if (!SpawnOptions.OverrideRotation)
			{
				SpawnRotation = rotator(HitNormal);
				SpawnRotation.Pitch -= 16384;
			}
		}
	}

	SpawnStaticActor(ActorClass, Other.WorldInfo, Other.Owner,, SpawnLocation, SpawnRotation,, NewActor);
	//if (NewActor != none)
	//{
	//	if (SpawnOptions.ApplyScale)
	//	{
	//		NewActor.SetDrawScale(SpawnScale);
	//		NewActor.SetDrawScale3D(SpawnScale3D);
	//	}
	//}
	return true;
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

private static function bool GetStaticMutator(out TestCentralWeaponReplacement OutMutator)
{
	local Object Obj;
	if (GetDefaultObject(default.Class, Obj) && TestCentralWeaponReplacement(Obj) != none)
	{
		OutMutator = TestCentralWeaponReplacement(Obj);
	}

	return OutMutator != none;
}

static function bool LoadClass(string ClassPath, out Class OutClass)
{
	OutClass = class(DynamicLoadObject(ClassPath, class'Class'));
	return OutClass != none;
}

static function bool SpawnStaticActor(
	class<Actor> ActorClass, 
	optional WorldInfo  WI,
	optional actor	    SpawnOwner,
	optional name       SpawnTag,
	optional vector     SpawnLocation,
	optional rotator    SpawnRotation,
	optional Actor      ActorTemplate,
	optional out Actor  NewActor)
{
	local bool DefaultbStatic, DefaultbNoDelete;

	if (WI == none)
		WI = class'Engine'.static.GetCurrentWorldInfo();

	DefaultbStatic = ActorClass.default.bStatic;
	DefaultbNoDelete = ActorClass.default.bNoDelete;

	class'TestCWRHelper'.static.SetActorStatic(ActorClass, false);
	class'TestCWRHelper'.static.SetActorNoDelete(ActorClass, false);

	NewActor = WI.Spawn(ActorClass, SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, true);
					
	class'TestCWRHelper'.static.SetActorStatic(ActorClass, DefaultbStatic);
	class'TestCWRHelper'.static.SetActorNoDelete(ActorClass, DefaultbNoDelete);

	return NewActor != none;
}

Defaultproperties
{
	GroupNames[0]="WEAPONMOD"

	ParameterProfile="CWRMapProfile"
}
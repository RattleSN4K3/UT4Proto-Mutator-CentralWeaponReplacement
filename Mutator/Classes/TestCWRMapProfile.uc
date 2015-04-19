class TestCWRMapProfile extends UTUIResourceDataProvider
	dependson(TestCWRTemplate)
	PerObjectConfig;

var config string ProfileName;
var config string FriendlyName;
var config string Description;

var config string FullMapName;
var config string MapName;

var config array<TemplateInfo> WeaponsToReplace;
var config array<TemplateInfo> AmmoToReplace;

var config array<TemplateInfo> HealthToReplace;
var config array<TemplateInfo> ArmorToReplace;
var config array<TemplateInfo> PowerupsToReplace;
var config array<TemplateInfo> DeployablesToReplace;

var config array<TemplateInfo> VehiclesToReplace;

var config array<TemplateInfo> CustomsToReplace;

//**********************************************************************************
// Static functions
//**********************************************************************************

static simulated function bool GetMapProfileByName(string InProfileName, out TestCWRMapProfile out_MapProvider)
{
	local array<TestCWRMapProfile> MapProviders;
	local TestCWRMapProfile MapProvider;

	if (GetMapProfiles(MapProviders))
	{
		foreach MapProviders(MapProvider)
		{
			if (string(MapProvider.Name) ~= InProfileName || MapProvider.ProfileName ~= InProfileName)
			{
				out_MapProvider = MapProvider;
				break;
			}
		}
	}

	return out_MapProvider != none;
}

static simulated function bool GetMapProfilesByFullMapName(string InFullMapName, out array<TestCWRMapProfile> out_MapProviders)
{
	local array<TestCWRMapProfile> MapProviders;
	local TestCWRMapProfile MapProvider;
	
	GetMapProfiles(MapProviders);

	out_MapProviders.Length = 0;
	foreach MapProviders(MapProvider)
	{
		if (MapProvider.FullMapName ~= InFullMapName)
		{
			out_MapProviders.AddItem(MapProvider);
		}
	}

	return out_MapProviders.Length > 0;
}

static simulated function bool GetMapProfilesByMapName(string InMapName, out array<TestCWRMapProfile> out_MapProviders)
{
	local array<TestCWRMapProfile> MapProviders;
	local TestCWRMapProfile MapProvider;
	
	GetMapProfiles(MapProviders);

	out_MapProviders.Length = 0;
	foreach MapProviders(MapProvider)
	{
		if (MapProvider.MapName ~= InMapName || MapProvider.FullMapName ~= InMapName)
		{
			out_MapProviders.AddItem(MapProvider);
		}
	}

	return out_MapProviders.Length > 0;
}

static simulated function bool GetMapProfiles(out array<TestCWRMapProfile> out_MapProviders)
{
	local array<UTUIResourceDataProvider> MapProviders;
	local UTUIResourceDataProvider MapProvider;
	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(Class'TestCWRMapProfile', MapProviders);

	if (MapProviders.Length > 0)
	{
		out_MapProviders.Length = 0;
		foreach MapProviders(MapProvider)
		{
			if (TestCWRMapProfile(MapProvider) != none)
			{
				out_MapProviders.AddItem(TestCWRMapProfile(MapProvider));
			}
		}

		return out_MapProviders.Length > 0;;
	}

	return false;
}

defaultproperties
{
	bSearchAllInis=True

	WeaponsToReplace.Add((OldClassName="UTWeapon",NewClassPath="UTGame.UTWeap_SniperRifle",Options=(bSubClasses=true,bNoDefaultInventory=true,bAddToDefault=true)))
	AmmoToReplace.Add((OldClassName="UTAmmoPickupFactory",NewClassPath="UTGame.UTAmmo_SniperRifle",Options=(bSubClasses=true)))
}

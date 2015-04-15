class TestCWR_ConfigWeaponUIConfig extends UTUIFrontEnd;

var transient localized string Title;

/** Replacement info. */
var transient name WeaponClassToReplace;
var transient name AmmoClassToReplace;

/** Reference to the weapon combo box. */
var transient UTUIComboBox WeaponCombo;

/** Reference to the string list datastore. */
var transient UTUIDataStore_StringList StringListDataStore;

/** Reference to the menu item datastore. */
var transient UTUIDataStore_MenuItems MenuItemDataStore;

/** List of possible weapon classes. */
var transient array<name> WeaponClassNames;
var transient array<string>	WeaponFriendlyNames;
var transient array<UTUIDataProvider_Weapon> WeaponProviders;

event PostInitialize()
{
	Super.PostInitialize();

	WeaponClassToReplace = class'TestCWR_ConfigWeaponMutatorCWR'.default.ReplaceWeaponClassName;
	AmmoClassToReplace = class'TestCWR_ConfigWeaponMutatorCWR'.default.ReplaceAmmoClassName;

	// Get datastore references
	StringListDataStore = UTUIDataStore_StringList(FindDataStore('UTStringList'));
	MenuItemDataStore = UTUIDataStore_MenuItems(FindDataStore('UTMenuItems'));

	// setup combo selection
	WeaponCombo = UTUIComboBox(FindChild('cboReplace', true));
	WeaponCombo.ComboEditbox.StringRenderComponent.SetAlignment(UIORIENT_Horizontal, UIALIGN_Left);
	WeaponCombo.ComboEditbox.StringRenderComponent.SetAlignment(UIORIENT_Vertical, UIALIGN_Center);

	BuildWeaponOptions();
}

/** Sets the title for this scene. */
function SetTitle()
{
	local UILabel TitleLabel;

	TitleLabel = GetTitleLabel();
	if ( TitleLabel != None ) TitleLabel.SetDataStoreBinding("");
}

/** Sets up the scene's button bar. */
function SetupButtonBar()
{
	ButtonBar.Clear();
	ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Back>", OnButtonBar_Back);
	ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Accept>", OnButtonBar_Accept);
}

/** Provides a hook for unrealscript to respond to input using actual input key names (i.e. Left, Tab, etc.) */
function bool HandleInputKey( const out InputEventParameters EventParms )
{
	local bool bResult;

	bResult = false;

	if(EventParms.EventType==IE_Released)
	{
		if(EventParms.InputKeyName=='XboxTypeS_B' || EventParms.InputKeyName=='Escape')
		{
			OnBack();
			bResult = true;
		}
	}

	return bResult;
}

/** Buttonbar Callback for Back. */
function bool OnButtonBar_Back(UIScreenObject InButton, int InPlayerIndex)
{
	OnBack();
	return true;
}

/** Buttonbar Callback for Accept. */
function bool OnButtonBar_Accept(UIScreenObject InButton, int InPlayerIndex)
{
	OnAccept();
	return true;
}

/** Callback for when the user wants to back out of this screen. */
function OnBack()
{
	CloseScene(self);
}

/** Callback for when the user accepts the changes. */
function OnAccept()
{
	local int index;
	local ReplacementOptionsInfo defaultoptions;

	index = WeaponCombo.ComboList.GetCurrentItem();
	if (WeaponCombo.ComboList.Items.Length > 0 && index != INDEX_NONE)
	{
		class'TestCWR_ConfigWeaponMutatorCWR'.default.ReplaceWeaponClassName = WeaponClassNames[index];
		class'TestCWR_ConfigWeaponMutatorCWR'.default.ReplaceAmmoClassName = GetClassName(WeaponProviders[index].AmmoClassPath);
		class'TestCWR_ConfigWeaponMutatorCWR'.default.ReplaceWeaponOptions = defaultoptions;
		class'TestCWR_ConfigWeaponMutatorCWR'.default.ReplaceAmmoOptions = defaultoptions;
		class'TestCWR_ConfigWeaponMutatorCWR'.static.StaticSaveConfig();
	}

	CloseScene(self);
}

/** Builds the weapons option lists. */
function BuildWeaponOptions()
{
	local int WeaponIdx;
	local array<UTUIResourceDataProvider> OutProviders;
	local name ClassName;
	local int SelectedIndex;
	local string SelectedString;

	// Build a list of weapons
	WeaponProviders.length = 0;
	WeaponClassNames.length = 0;
	WeaponFriendlyNames.length = 0;

	if(MenuItemDataStore.GetProviderSet('Weapons', OutProviders))
	{
		SelectedIndex = INDEX_NONE;
		StringListDataStore.Empty('WeaponSelection', true);
		for(WeaponIdx=0; WeaponIdx<OutProviders.length; WeaponIdx++)
		{
			ClassName = GetClassName(UTUIDataProvider_Weapon(OutProviders[WeaponIdx]).ClassName);
			WeaponProviders.AddItem(UTUIDataProvider_Weapon(OutProviders[WeaponIdx]));
			WeaponClassNames.AddItem(ClassName);
			WeaponFriendlyNames.AddItem(UTUIDataProvider_Weapon(OutProviders[WeaponIdx]).FriendlyName);

			StringListDataStore.AddStr('WeaponSelection', UTUIDataProvider_Weapon(OutProviders[WeaponIdx]).FriendlyName, true);
			if (SelectedIndex == INDEX_NONE && ClassName == WeaponClassToReplace)
			{
				SelectedIndex = WeaponIdx;
				SelectedString = UTUIDataProvider_Weapon(OutProviders[WeaponIdx]).FriendlyName;
			}
		}

		WeaponCombo.ComboList.SetDataStoreBinding("<"$StringListDataStore.tag$":WeaponSelection>");
		StringListDataStore.RefreshSubscribers('WeaponSelection');

		if (SelectedIndex != INDEX_NONE)
		{
			WeaponCombo.ComboList.SetIndex(SelectedIndex);
			WeaponCombo.ComboEditbox.SetDataStoreBinding(SelectedString);
		}
	}
}

/** @return string	Returns a fieldname given a weapon class name. */
function name GetClassName(string ClassPath)
{
	ClassPath = Mid(ClassPath, InStr(ClassPath, ".", true)+1);
	return name(ClassPath);
}

DefaultProperties
{
	Title="[Config Ripper Mutator (CWR)]" 
}

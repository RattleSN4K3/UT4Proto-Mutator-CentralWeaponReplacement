class TestCWR_ConfigCustomUIConfig extends UTUIFrontEnd;

var transient localized string Title;

/** Replacement info. */
var transient name HealthClassToReplace;

/** Reference to the pickup combo box. */
var transient UTUIComboBox PickupCombo;

/** Reference to the string list datastore. */
var transient UTUIDataStore_StringList StringListDataStore;

/** Reference to the menu item datastore. */
var transient UTUIDataStore_MenuItems MenuItemDataStore;

/** List of possible weapon classes. */
var transient array<name> PickupClassNames;
var transient array<string>	PickupFriendlyNames;

event PostInitialize()
{
	Super.PostInitialize();

	HealthClassToReplace = class'TestCWR_ConfigHealthMutatorCWR'.default.ReplaceHealthClassName;

	// Get datastore references
	StringListDataStore = UTUIDataStore_StringList(FindDataStore('UTStringList'));
	MenuItemDataStore = UTUIDataStore_MenuItems(FindDataStore('UTMenuItems'));

	// setup combo selection
	PickupCombo = UTUIComboBox(FindChild('cboReplace', true));
	PickupCombo.ComboEditbox.StringRenderComponent.SetAlignment(UIORIENT_Horizontal, UIALIGN_Left);
	PickupCombo.ComboEditbox.StringRenderComponent.SetAlignment(UIORIENT_Vertical, UIALIGN_Center);

	BuildPickupOptions();
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

	index = PickupCombo.ComboList.GetCurrentItem();
	if (PickupCombo.ComboList.Items.Length > 0 && index != INDEX_NONE)
	{
		class'TestCWR_ConfigHealthMutatorCWR'.default.ReplaceHealthClassName= PickupClassNames[index];
		class'TestCWR_ConfigHealthMutatorCWR'.default.ReplaceHealthOptions = defaultoptions;
		class'TestCWR_ConfigHealthMutatorCWR'.static.StaticSaveConfig();
	}

	CloseScene(self);
}

/** Builds the pickup option lists. */
function BuildPickupOptions()
{
	local UIInteraction UIController;

	local string str;
	local string line, ClassStr;
	local array<string> lines;
	local name ClassName;
	local int i, index, PrefixCount, IndentCount;
	local int SelectedIndex;
	local string SelectedString;

	// Build a list of pickups
	PickupClassNames.length = 0;
	PickupFriendlyNames.length = 0;

	SelectedIndex = INDEX_NONE;
	index = StringListDataStore.Num('HealthSelection');
	if (index <= 0)
	{
		UIController = GetCurrentUIController();
		if (UIController != none && UIController.Outer != None)
		{
			// fix to have the package UTGameContent loaded
			DynamicLoadObject("UTGameContent.UTPickupFactory_SuperHealth", class'class');

			str = UIController.Outer.ConsoleCommand("obj classes");
			ParseStringIntoArray(str, lines, Chr(10), true);

			index = lines.Find("            UTHealthPickupFactory");
			if (index == INDEX_NONE)
			{
				for (i=0; i<lines.Length; i++)
				{
					ClassStr = TrimWhitespace(lines[i]);
					if (ClassStr ~= "UTHealthPickupFactory")
					{
						PrefixCount = Len(lines[i])-Len(ClassStr);
						index = i;
						break;
					}
				}
			}

			line = TrimWhitespace(lines[index]);
			PrefixCount = Len(lines[index])-Len(line);
			for (i=index+1; i<lines.Length; i++)
			{
				ClassStr = TrimWhitespace(lines[i]);
				IndentCount = Len(lines[i])-Len(ClassStr);
				if (PrefixCount >= IndentCount)
				{
					break;
				}

				ClassName = name(ClassStr);
				PickupClassNames.AddItem(ClassName);
			}		
		}

		StringListDataStore.Empty('HealthSelection', true);
		StringListDataStore.Empty('HealthSelectionClass', true);
		PickupFriendlyNames.Length = PickupClassNames.Length;
		for(i=0; i<PickupClassNames.length; i++)
		{
			PickupFriendlyNames[i] = ""$PickupClassNames[i];
			StringListDataStore.AddStr('HealthSelection', PickupFriendlyNames[i], true);
			StringListDataStore.AddStr('HealthSelectionClass', ""$PickupClassNames[i], true);
			
			if (SelectedIndex == INDEX_NONE && PickupClassNames[i] == HealthClassToReplace)
			{
				SelectedIndex = i;
				SelectedString = PickupFriendlyNames[i];
			}
		}
	}
	else
	{
		PickupClassNames.Length = index;
		for (i=0; i<index; i++)
		{
			str = StringListDataStore.GetStr('HealthSelectionClass', i);
			PickupClassNames[i] = name(str);

			if (SelectedIndex == INDEX_NONE && PickupClassNames[i] == HealthClassToReplace)
			{
				SelectedIndex = i;
			}
		}

		PickupFriendlyNames.Length = index;
		for (i=0; i<index; i++)
		{
			str = StringListDataStore.GetStr('HealthSelection', i);
			PickupFriendlyNames[i] = str;

			if (SelectedIndex != INDEX_NONE && i == SelectedIndex)
			{
				SelectedString = PickupFriendlyNames[i];
			}
		}
	}

	PickupCombo.ComboList.SetDataStoreBinding("<"$StringListDataStore.tag$":HealthSelection>");
	StringListDataStore.RefreshSubscribers('HealthSelection');

	if (SelectedIndex != INDEX_NONE)
	{
		PickupCombo.ComboList.SetIndex(SelectedIndex);
		PickupCombo.ComboEditbox.SetDataStoreBinding(SelectedString);
	}
}

DefaultProperties
{
	Title="[Config Vials mutator (CWR)]" 
}

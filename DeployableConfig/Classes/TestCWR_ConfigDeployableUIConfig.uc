class TestCWR_ConfigDeployableUIConfig extends UTUIFrontEnd;

var transient localized string Title;

/** Replacement info. */
var transient name DeployableClassToReplace;

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

	DeployableClassToReplace = class'TestCWR_ConfigDeployableMutatorCWR'.default.ReplaceDeployableClassName;

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
		class'TestCWR_ConfigDeployableMutatorCWR'.default.ReplaceDeployableClassName= PickupClassNames[index];
		class'TestCWR_ConfigDeployableMutatorCWR'.default.ReplaceDeployableOptions = defaultoptions;
		class'TestCWR_ConfigDeployableMutatorCWR'.static.StaticSaveConfig();
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
	index = StringListDataStore.Num('DeployableSelection');
	if (index <= 0)
	{
		UIController = GetCurrentUIController();
		if (UIController != none && UIController.Outer != None)
		{
			// fix to have the package UTGameContent loaded
			DynamicLoadObject("UTGameContent.UTDeployableEMPMine", class'class');
			DynamicLoadObject("UTGameContent.UTDeployableEnergyShield", class'class');
			DynamicLoadObject("UTGameContent.UTDeployableLinkGenerator", class'class');
			DynamicLoadObject("UTGameContent.UTDeployableShapedCharge", class'class');
			DynamicLoadObject("UTGameContent.UTDeployableSlowVolume", class'class');
			DynamicLoadObject("UTGameContent.UTDeployableSpiderMineTrap", class'class');
			DynamicLoadObject("UT3Gold.UTDeployableXRayVolume", class'class');

			str = UIController.Outer.ConsoleCommand("obj classes");
			ParseStringIntoArray(str, lines, Chr(10), true);

			index = lines.Find("            UTDeployable");
			if (index == INDEX_NONE)
			{
				for (i=0; i<lines.Length; i++)
				{
					ClassStr = TrimWhitespace(lines[i]);
					if (ClassStr ~= "UTDeployable")
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

		StringListDataStore.Empty('DeployableSelection', true);
		StringListDataStore.Empty('DeployableSelectionClass', true);
		PickupFriendlyNames.Length = PickupClassNames.Length;
		for(i=0; i<PickupClassNames.length; i++)
		{
			PickupFriendlyNames[i] = ""$PickupClassNames[i];
			StringListDataStore.AddStr('DeployableSelection', PickupFriendlyNames[i], true);
			StringListDataStore.AddStr('DeployableSelectionClass', ""$PickupClassNames[i], true);
			
			if (SelectedIndex == INDEX_NONE && PickupClassNames[i] == DeployableClassToReplace)
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
			str = StringListDataStore.GetStr('DeployableSelectionClass', i);
			PickupClassNames[i] = name(str);

			if (SelectedIndex == INDEX_NONE && PickupClassNames[i] == DeployableClassToReplace)
			{
				SelectedIndex = i;
			}
		}

		PickupFriendlyNames.Length = index;
		for (i=0; i<index; i++)
		{
			str = StringListDataStore.GetStr('DeployableSelection', i);
			PickupFriendlyNames[i] = str;

			if (SelectedIndex != INDEX_NONE && i == SelectedIndex)
			{
				SelectedString = PickupFriendlyNames[i];
			}
		}
	}

	PickupCombo.ComboList.SetDataStoreBinding("<"$StringListDataStore.tag$":DeployableSelection>");
	StringListDataStore.RefreshSubscribers('DeployableSelection');

	if (SelectedIndex != INDEX_NONE)
	{
		PickupCombo.ComboList.SetIndex(SelectedIndex);
		PickupCombo.ComboEditbox.SetDataStoreBinding(SelectedString);
	}
}

DefaultProperties
{
	Title="[Config SlowVolume Mutator (CWR)]" 
}

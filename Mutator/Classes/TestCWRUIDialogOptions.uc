class TestCWRUIDialogOptions extends UTUIFrontEnd_CustomScreen;

var transient UIObject RefWidget;
var transient name ClassName;
var transient ReplacementOptionsInfo Options;

var transient string Title;

// Reference to the options page and list
var transient UTUITabPage_DynamicOptions OptionsPage;
var transient UTUIDynamicOptionList OptionsList;

/** Used to detect when the options are being regenerated */
var transient bool bRegeneratingOptions;

delegate OnSubmitCallback(UIObject InWidget, name InClassName, ReplacementOptionsInfo InOptions);


/** Post initialize callback */
function PostInitialize()
{
	Super.PostInitialize();

	OptionsPage = UTUITabPage_DynamicOptions(FindChild('pnlOptions', True));
	//OptionsPage.OnOptionChanged = OnOptionChanged;

	OptionsList = UTUIDynamicOptionList(FindChild('lstOptions', True));
}

/** Scene activated event, sets up the title for the scene. */
event SceneActivated(bool bInitialActivation)
{
	Super.SceneActivated(bInitialActivation);

	if (bInitialActivation)
	{
		SetupMenuOptions();
	}
}

/** Sets the title for this scene. */
function SetTitle()
{
	local UILabel TitleLabel;

	TitleLabel = GetTitleLabel();
	if ( TitleLabel != None )
	{
		TitleLabel.SetDataStoreBinding(Title);
	}
}

/** Sets up the scene's button bar. */
function SetupButtonBar()
{
	ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Cancel>", OnButtonBar_Cancel);
	ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Apply>", OnButtonBar_Submit);
}

function bool HandleInputKey( const out InputEventParameters EventParms )
{
	local bool bResult;

	if(EventParms.EventType==IE_Released)
	{
		if(EventParms.InputKeyName=='XboxTypeS_B' || EventParms.InputKeyName=='Escape')
		{
			OnCancel();
			bResult = true;
		}
	}

	return bResult;
}

// Initializes the menu option templates, and regenerates the option list
function SetupMenuOptions()
{
	local DynamicMenuOption CurMenuOpt;

	if (OptionsList == none)
		return;

	bRegeneratingOptions = True;
	OptionsList.DynamicOptionTemplates.Length = 0;

	CurMenuOpt.OptionName = 'bNoReplaceWeapon';
	CurMenuOpt.OptionType = UTOT_CheckBox;
	CurMenuOpt.FriendlyName = "No replace";
	CurMenuOpt.Description = "Whether to not replace/remove the pickup";
	OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);

	CurMenuOpt.OptionName = 'bAddToDefault';
	CurMenuOpt.OptionType = UTOT_CheckBox;
	CurMenuOpt.FriendlyName = "Add to default inventory";
	CurMenuOpt.Description = "Whether to add the inventory item to the default inventory (on spawn)";
	OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);

	CurMenuOpt.OptionName = 'bSubClasses';
	CurMenuOpt.OptionType = UTOT_CheckBox;
	CurMenuOpt.FriendlyName = "Sub Classes";
	CurMenuOpt.Description = "Whether to check for subclasses";
	OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);

	CurMenuOpt.OptionName = 'bNoDefaultInventory';
	CurMenuOpt.OptionType = UTOT_CheckBox;
	CurMenuOpt.FriendlyName = "No Default Inventory";
	CurMenuOpt.Description = "Whether to prevent replacing default inventory items (to be used with bSubClasses=true)";
	OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);

	CurMenuOpt.OptionName = 'bAddToLocker';
	CurMenuOpt.OptionType = UTOT_CheckBox;
	CurMenuOpt.FriendlyName = "Add to Locker";
	CurMenuOpt.Description = "Whether to add the weapon to the weapon lockers";
	OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);


	// Generate the option controls
	OptionsList.OnSetupOptionBindings = SetupOptionBindings;
	OptionsList.RegenerateOptions();

	// fix initial BG selection
	if (OptionsList.GeneratedObjects.Length > 0)
	{
		OptionsList.GeneratedObjects[0].OptionObj.SetFocus(None);

		// Disable the initiated selection change animation, so that it jumps to the focused object immediately
		OptionsList.bAnimatingBGPrefab = False;
	}
}

// Setup the data source bindings (but not the values)
function SetupOptionBindings()
{
	local int i;
	local UICheckbox CurCheckBox;

	for (i=0; i<OptionsList.GeneratedObjects.Length; i++)
	{
		CurCheckBox = UICheckbox(OptionsList.GeneratedObjects[i].OptionObj);
		switch (OptionsList.GeneratedObjects[i].OptionProviderName)
		{
		case 'bNoReplaceWeapon':
			CurCheckBox.SetValue(Options.bNoReplaceWeapon);
			break;
		case 'bAddToDefault':
			CurCheckBox.SetValue(Options.bAddToDefault);
			break;
		case 'bSubClasses':
			CurCheckBox.SetValue(Options.bSubClasses);
			break;
		case 'bNoDefaultInventory':
			CurCheckBox.SetValue(Options.bNoDefaultInventory);
			break;
		case 'bAddToLocker':
			CurCheckBox.SetValue(Options.bAddToLocker);
			break;
		}
	}

	bRegeneratingOptions = False;
}

// Buttonbar Callbacks.

function bool OnButtonBar_Submit(UIScreenObject InButton, int InPlayerIndex)
{
	OnSubmit();
	CloseScene(Self);

	return true;
}

function bool OnButtonBar_Cancel(UIScreenObject InButton, int InPlayerIndex)
{
	OnCancel();

	return true;
}

/** Callback for when the user wants to back out of this screen. */
function OnCancel()
{
	CloseScene(self);
}

function OnSubmit()
{
	local int i;
	local UICheckbox CurCheckBox;

	for (i=0; i<OptionsList.GeneratedObjects.Length; i++)
	{
		CurCheckBox = UICheckbox(OptionsList.GeneratedObjects[i].OptionObj);
		switch (OptionsList.GeneratedObjects[i].OptionProviderName)
		{
		case 'bNoReplaceWeapon':
			Options.bNoReplaceWeapon = CurCheckBox.IsChecked();
			break;
		case 'bAddToDefault':
			Options.bAddToDefault = CurCheckBox.IsChecked();
			break;
		case 'bSubClasses':
			Options.bSubClasses = CurCheckBox.IsChecked();
			break;
		case 'bNoDefaultInventory':
			Options.bNoDefaultInventory = CurCheckBox.IsChecked();
			break;
		case 'bAddToLocker':
			Options.bAddToLocker = CurCheckBox.IsChecked();
			break;
		}
	}


	OnSubmitCallback(RefWidget, ClassName, Options);
}

function InitDialog(UIObject InWidget, name InClassName, ReplacementOptionsInfo InOptions)
{
	RefWidget = InWidget;
	ClassName = InClassName;
	Options = InOptions;
}

/**
 * Wrapper for setting the OnSubmit delegate.
 */
function SetSubmitDelegate( delegate<OnSubmitCallback> OnSubmitDelegate )
{
	OnSubmitCallback = OnSubmitDelegate;
}

public function SetDialogTitle(string InTitle)
{
	Title = InTitle;
	if (bInitialized)
	{
		SetTitle();
	}
}

DefaultProperties
{
}

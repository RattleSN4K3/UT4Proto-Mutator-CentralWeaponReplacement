class TestCWRUITabList extends UTUITabPage_DynamicOptions;

var transient string Title;

var const int MAX_RANDOM_NUMBER;

var() bool bMinimalMode;

var() string OptionsScenePath;
var TestCWRUIDialogOptions OptionsScene;

var transient array<TestCWRUIListElement> ReplacementElements;
var transient array<ReplacementInfoEx> CurrentReplacements;

var array<DynamicMenuOption> BaseOptions;
var bool bHasOptions;
var bool bOptionsDirty;

/** Used to detect when the options are being regenerated */
var transient bool bRegeneratingOptions;


// Replacement info
var transient EReplacementType ReplacementType;
var transient name ReplacementReference;
var transient TestCWRUI UIData;


// Localization
var() transient localized string SwitchSimpleMode;
var() transient localized string SwitchAdvancedMode;
var() transient localized string DialogOptionsTitle;
var() transient localized string NoneReplacementName;

event Initialized()
{
	Super.Initialized();

	InsertChild(OptionList);
	InsertChild(DescriptionLabel);
}

event PostInitialize()
{
	Super.PostInitialize();
	//DescriptionLabel.SetVisibility(false);

	// Set the button tab caption.
	SetDataStoreBinding(Title);

	// hide option selection
	OptionList.BGPrefabInstance.SetVisibility(false);
}

/** Callback allowing the tabpage to setup the button bar for the current scene. */
function SetupButtonBar(UTUIButtonBar ButtonBar)
{
	ButtonBar.AppendButton(bMinimalMode ? SwitchAdvancedMode : SwitchSimpleMode, OnButtonBar_SwitchMode);
	ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.ClearAll>", OnButtonBar_ClearAll);
}

public function SetTitle(string InTitle)
{
	Title = InTitle;
	if (bInitialized)
	{
		SetDataStoreBinding(Title);
	}
}

public function SetReplacementInfo(EReplacementType type, name DataStoreReference)
{
	ReplacementType = type;
	ReplacementReference = DataStoreReference;
}

public function LoadReplacements(TestCWRUI InDataRef)
{
	UIData = InDataRef;
	SetupMenuOptions();
}

public function SaveReplacements()
{
	local int i;
	local ReplacementInfoEx RepInfo, EmptyInfo;
	local array<ReplacementInfoEx> Replacements;
	local ReplacementOptionsInfo EmptyOptions;

	for (i=0; i<ReplacementElements.Length; i++)
	{
		RepInfo = EmptyInfo;
		if (RetrieveReplacementInfoFor(ReplacementElements[i], RepInfo))
		{
			// clear options in simple mode
			if (bMinimalMode) RepInfo.Options = EmptyOptions;

			Replacements.AddItem(RepInfo);
		}
	}

	class'TestCentralWeaponReplacement'.static.SetConfigReplacements(ReplacementType, Replacements);
}

public function bool IsIgnoringOptions()
{
	return bMinimalMode && HasOptions();
}

/** Buttonbar ClearAll Callback. */
function bool OnButtonBar_ClearAll(UIScreenObject InButton, int InPlayerIndex)
{
	// clear options
	DynOptionList.DynamicOptionTemplates.Length = 0;
	BaseOptions.Length = 0;
	CurrentReplacements.Length = 0;

	AddNewEmpty();

	// Re-Generate the option controls
	DynOptionList.RegenerateOptions();

	return true;
}

/** Buttonbar Switch mode Callback. */
function bool OnButtonBar_SwitchMode(UIScreenObject InButton, int InPlayerIndex)
{
	UpdateReplacements();

	// override current options
	DynOptionList.DynamicOptionTemplates = BaseOptions;

	bMinimalMode = !bMinimalMode;
	AddNewEmpty();

	// Re-Generate the option controls
	DynOptionList.RegenerateOptions();

	// Update the button bar to get proper buttons
	UTUIFrontEnd(GetScene()).SetupButtonBar();

	return true;
}

// Initializes the menu option templates, and regenerates the option list
function SetupMenuOptions()
{
	local DynamicMenuOption CurMenuOpt;
	local int i;
	local bool bInOptions;
	local ReplacementOptionsInfo EmptyOptions;

	if (DynOptionList == none)
		return;

	bRegeneratingOptions = True;
	DynOptionList.DynamicOptionTemplates.Length = 0;

	if (class'TestCentralWeaponReplacement'.static.GetConfigReplacements(ReplacementType, CurrentReplacements))
	{
		for (i=0; i<CurrentReplacements.Length; i++)
		{
			// check for options and force advanced mode
			if (!bInOptions && CurrentReplacements[i].Options != EmptyOptions)
			{
				bInOptions = true;
				bMinimalMode = false;
			}

			CurMenuOpt.OptionName = name(""$i);
			CurMenuOpt.FriendlyName = ""$CurrentReplacements[i].OldClassName;
			DynOptionList.DynamicOptionTemplates.AddItem(CurMenuOpt);
		}
	}

	bHasOptions = bInOptions;
	bOptionsDirty = false;

	BaseOptions = DynOptionList.DynamicOptionTemplates;

	if (bMinimalMode)
	{
		CurMenuOpt.OptionName = 'NewItem';
		CurMenuOpt.FriendlyName = "";
		DynOptionList.DynamicOptionTemplates.AddItem(CurMenuOpt);
	}

	// Generate the option controls
	DynOptionList.OnSetupOptionBindings = SetupOptionBindings;
	DynOptionList.RegenerateOptions();
}

// Setup the data source bindings (but not the values)
function SetupOptionBindings()
{
	local int i;
	local UIObject GenObj;
	local UILabel LabelObj;
	local UIComboBox ComboBox;
	local TestCWRUIListElement RepObj;

	RemoveChildren(ReplacementElements);
	ReplacementElements.Length = 0;

	for (i=0; i<OptionList.GeneratedObjects.Length; i++)
	{
		LabelObj = UILabel(OptionList.GeneratedObjects[i].LabelObj);
		GenObj = OptionList.GeneratedObjects[i].OptionObj;
		if (GenObj == none) continue;

		RepObj = TestCWRUIListElement(GenObj.CreateWidget(GenObj, class'TestCWRUIListElement'));
		if (RepObj == none) continue;
		ReplacementElements.AddItem(RepObj);

		GenObj.InsertChild(RepObj);
		DockFill(RepObj, LabelObj, GenObj);
		
		RepObj.OnModify = OnReplacement_Modify;
		RepObj.OnRemove = OnReplacement_Remove;
		RepObj.OnReorder = OnReplacement_Reorder;
		RepObj.OnChangedNew = OnReplacement_NewChanged;

		RepObj.SetComboDatastoreBinding(GetDatastoreMarkup(ReplacementReference, ''));
		if (i < CurrentReplacements.Length)
		{
			PopulateReplacementInfoFor(RepObj, CurrentReplacements[i]);
		}

		RepObj.SwitchMode(bMinimalMode,
			BaseOptions.Length == 0 || (bMinimalMode && i == OptionList.GeneratedObjects.Length-1)
		);


		if (LabelObj != none)
		{
			LabelObj.StringRenderComponent.SetOpacity(0.0);
		}

		ComboBox = UIComboBox(GenObj);
		if (ComboBox != none)
		{
			ComboBox.ComboEditbox.AnimSetOpacity(0.0); 
			ComboBox.ComboButton.AnimSetOpacity(0.0); 
		}
	}

	bRegeneratingOptions = False;
}

function OnReplacement_Modify(UIObject CreatedWidget)
{
	local TestCWRUIListElement ThisElement;
	local UIScene StaticScene, OpenedScene;
	local ReplacementInfoEx RepInfo;
	local string dialogtitle;
	local int index;

	ThisElement = TestCWRUIListElement(CreatedWidget);
	if (ThisElement == none || !RetrieveReplacementInfoFor(ThisElement, RepInfo))
		return;

	StaticScene = UIScene(DynamicLoadObject(OptionsScenePath, class'UIScene'));
	if (StaticScene != None && GetSceneClient().InitializeScene(StaticScene,, OpenedScene) && TestCWRUIDialogOptions(OpenedScene) != none)
	{
		// setup vars
		OptionsScene = TestCWRUIDialogOptions(OpenedScene);
		OptionsScene.InitDialog(ThisElement, RepInfo.OldClassName, RepInfo.Options);
		OptionsScene.SetSubmitDelegate(OnReplacement_OptionsSubmit);

		index = ThisElement.GetReplacementIndexFrom();
		if (index == INDEX_NONE || !UIData.GetDataStoreValue(ReplacementReference, '', index, dialogtitle))
		{
			dialogtitle = RepInfo.OldClassName == '' ? NoneReplacementName : string(RepInfo.OldClassName);
		}
		OptionsScene.SetDialogTitle(Repl(DialogOptionsTitle, "`name", dialogtitle));

		// finally open scene
		GetScene().OpenScene(OpenedScene);
	}
}

function OnReplacement_Remove(UIObject CreatedWidget, bool bRemove)
{
	local int index;
	local TestCWRUIListElement ThisElement;

	ThisElement = TestCWRUIListElement(CreatedWidget);
	if (ThisElement == none)
		return;

	index = ReplacementElements.Find(ThisElement);
	if (index == INDEX_NONE)
		return;

	UpdateReplacements();

	if (bRemove)
	{
		BaseOptions.Remove(index, 1);
		CurrentReplacements.Remove(index, 1);
	}
	else
	{
		index += 1;
		BaseOptions.Insert(index, 1);
		BaseOptions[index].OptionName = GetRandomOptionName();
		CurrentReplacements.Insert(index, 1);
	}

	// override current options
	DynOptionList.DynamicOptionTemplates = BaseOptions;
	AddNewEmpty();

	// Re-Generate the option controls
	//DynOptionList.RegenerateOptions();
	DynOptionList.bRegenOptions = true;
}

function OnReplacement_Reorder(UIObject CreatedWidget, bool bUp)
{
	local int index;
	local TestCWRUIListElement ThisElement;

	ThisElement = TestCWRUIListElement(CreatedWidget);
	if (ThisElement == none)
		return;

	index = ReplacementElements.Find(ThisElement);
	if (index != INDEX_NONE)
	{
		ReplacementReorder(index, bUp ? index-1 : index+1);
	}
}

function OnReplacement_NewChanged(UIObject CreatedWidget, int NewIndex, string NewSelection)
{
	local DynamicMenuOption CurMenuOpt;
	local string str;

	CurrentReplacements.Add(1);
	if (UIData.GetDataStoreValue(ReplacementReference, 'Class', NewIndex, str))
	{
		CurrentReplacements[CurrentReplacements.Length-1].OldClassName = name(str);
	}

	UpdateReplacements();

	// Add pending new item
	CurMenuOpt.OptionName = name(""$BaseOptions.Length);
	BaseOptions.AddItem(CurMenuOpt);

	// override current options
	DynOptionList.DynamicOptionTemplates = BaseOptions;

	if (!bMinimalMode)
		return;

	// Add new "NewItem" for new selection
	AddNewEmpty();

	// Re-Generate the option controls
	DynOptionList.RegenerateOptions();

	DynOptionList.SelectItem(DynOptionList.GeneratedObjects.Length-1);
}

function OnReplacement_OptionsSubmit(UIObject InWidget, name InClassName, ReplacementOptionsInfo InOptions)
{
	local TestCWRUIListElement ThisElement;
	local int index;

	ThisElement = TestCWRUIListElement(InWidget);
	if (ThisElement == none)
		return;

	index = ReplacementElements.Find(ThisElement);
	if (index == INDEX_NONE)
		return;
	
	bOptionsDirty = true;
	CurrentReplacements[index].Options = InOptions;
	PopulateReplacementOptionsFor(ThisElement, InOptions);
}

function string GetDatastoreMarkup(name ListName, name FieldName)
{
	local string Markup;
	if (UIData.GetMarkup(ListName, FieldName, Markup))
	{
		return Markup;
	}
	
	return "";
}

function DockFill(UIObject NewObject, UIObject LabelObj, UIObject GenObj)
{
	NewObject.SetDockTarget(UIFACE_Left, LabelObj, UIFACE_Left);
	NewObject.SetDockTarget(UIFACE_Top, LabelObj, UIFACE_Top);
	NewObject.SetDockTarget(UIFACE_Right, GenObj, UIFACE_Right);
	NewObject.SetDockTarget(UIFACE_Bottom, GenObj, UIFACE_Bottom);
}

function name GetRandomOptionName()
{
	local int index;
	local name n;
	
	do
	{
		index = Rand(MAX_RANDOM_NUMBER);
		n = name(""$index);
	} until (BaseOptions.Find('OptionName', n) == INDEX_NONE);

	return n;
}

function AddNewEmpty()
{
	local DynamicMenuOption NewMenuOpt;

	if (bMinimalMode || BaseOptions.Length == 0)
	{
		NewMenuOpt.OptionName = bMinimalMode ? 'NewItem' : GetRandomOptionName();
		DynOptionList.DynamicOptionTemplates.AddItem(NewMenuOpt);
	}
}

function ReplacementReorder(int ThisIndex, int SwapIndex)
{
	local TestCWRUIListElement ThisElement, SwapElement;
	local ReplacementInfoEx ThisRep, SwapRep;
	local UIObject OwnerObj;

	if (SwapIndex < 0 || SwapIndex >= OptionList.GeneratedObjects.Length)
		return;

	// swap replace,emts
	ThisRep = CurrentReplacements[ThisIndex];
	SwapRep = CurrentReplacements[SwapIndex];
	CurrentReplacements[SwapIndex] = ThisRep;
	CurrentReplacements[ThisIndex] = SwapRep;

	// swap references
	ThisElement = ReplacementElements[ThisIndex];
	SwapElement = ReplacementElements[SwapIndex];
	ReplacementElements[SwapIndex] = ThisElement;
	ReplacementElements[ThisIndex] = SwapElement;

	// remove both elements from the options
	OptionList.GeneratedObjects[ThisIndex].OptionObj.RemoveChild(ThisElement);
	OptionList.GeneratedObjects[SwapIndex].OptionObj.RemoveChild(SwapElement);

	// add overridden object to current option
	OwnerObj = OptionList.GeneratedObjects[SwapIndex].OptionObj;
	OwnerObj.InsertChild(ThisElement);
	DockFill(ThisElement, OptionList.GeneratedObjects[SwapIndex].LabelObj, OwnerObj);
	
	// add current object to overriden option
	OwnerObj = OptionList.GeneratedObjects[ThisIndex].OptionObj;
	OwnerObj.InsertChild(SwapElement);
	DockFill(SwapElement, OptionList.GeneratedObjects[ThisIndex].LabelObj, OwnerObj);
}

function UpdateReplacements()
{
	local int i;
	local ReplacementInfoEx RepInfo;

	for (i=0; i<ReplacementElements.Length; i++)
	{
		if (RetrieveReplacementInfoFor(ReplacementElements[i], RepInfo))
		{
			CurrentReplacements[i] = RepInfo;
		}
	}
}

function bool HasOptions()
{
	local int i;
	local ReplacementOptionsInfo EmptyOptions;

	if (bOptionsDirty)
	{
		bOptionsDirty = false;
		bHasOptions = false;

		for (i=0; i<CurrentReplacements.Length; i++)
		{
			// check for options
			if (CurrentReplacements[i].Options != EmptyOptions)
			{
				bHasOptions = true;
				break;
			}
		}
	}

	return bHasOptions;
}

function PopulateReplacementInfoFor(TestCWRUIListElement element, ReplacementInfoEx RepInfo)
{
	local int index;
	if (UIData.GetDataStoreIndex(ReplacementReference, 'Class', RepInfo.OldClassName, index))
	{
		element.SetReplacementIndexFrom(index);
	}

	if (UIData.GetDataStoreIndex(ReplacementReference, 'Path', RepInfo.NewClassPath, index))
	{
		element.SetReplacementIndexTo(index);
	}

	PopulateReplacementOptionsFor(element, RepInfo.Options);
}

function bool RetrieveReplacementInfoFor(TestCWRUIListElement element, out ReplacementInfoEx RepInfo)
{
	local int index;
	local string ClassStr, PathStr;
	local ReplacementOptionsInfo RefOptions;

	index = element.GetReplacementIndexFrom();
	if (index == INDEX_NONE || !UIData.GetDataStoreValue(ReplacementReference, 'Class', index, ClassStr))
	{
		return false;
	}
	index = element.GetReplacementIndexTo();
	if (index == INDEX_NONE || ClassStr ~= "")
	{
		return false;
	}

	UIData.GetDataStoreValue(ReplacementReference, 'Path', index, PathStr);	
	RepInfo.NewClassPath = PathStr;
	RepInfo.OldClassName = name(ClassStr);

	if (RetrieveReplacementOptionsFor(element, RefOptions))
	{
		RepInfo.Options = RefOptions;
	}

	return true;
}

function PopulateReplacementOptionsFor(TestCWRUIListElement element, ReplacementOptionsInfo RepOptions)
{
	local ReplacementOptionsInfo emptyoptions;	
	element.SetReplacementOptions(emptyoptions != RepOptions);
}

function bool RetrieveReplacementOptionsFor(TestCWRUIListElement element, out ReplacementOptionsInfo RepOptions)
{
	local int index;

	//@TODO: store and retrieve options from UI element?

	index = ReplacementElements.Find(element);
	if (index != INDEX_NONE && index < CurrentReplacements.Length)
	{
		RepOptions = CurrentReplacements[index].Options;
		return true;
	}

	//if (element.GetReplacementOptions(RepOptions))
	//{
	//	return true;
	//}

	return false;
}

DefaultProperties
{
	bMinimalMode=true

	MAX_RANDOM_NUMBER=9999

	SwitchSimpleMode="SIMPLE"
	SwitchAdvancedMode="ADVANCED"
	DialogOptionsTitle="Options for `name replacement"
	NoneReplacementName="None"

	OptionsScenePath="TestCWRContent.UI.DialogOptions"

	// Option list
	Begin Object Class=UTUIDynamicOptionList Name=lstOptions
		WidgetTag=lstOptions

		Position={( Value[UIFACE_Left]=0.01,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Top]=0.05,
				ScaleType[UIFACE_Top]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.98,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=0.7,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	OptionList=lstOptions

	Begin Object Class=UILAbel Name=lblDescription
		WidgetTag=lblDescription

		PrimaryStyle=(DefaultStyleTag="Tool Tips",RequiredStyleClass=class'Engine.UIStyle_Combo')

		Position={( Value[UIFACE_Left]=0.001175,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Top]=0.799705,
				ScaleType[UIFACE_Top]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.827344,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=0.146274,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	DescriptionLabel=lblDescription
}

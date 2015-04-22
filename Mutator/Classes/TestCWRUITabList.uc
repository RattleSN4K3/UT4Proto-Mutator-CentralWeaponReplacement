class TestCWRUITabList extends UTUITabPage_DynamicOptions;

var transient string Title;

var const int MAX_RANDOM_NUMBER;

var() bool bMinimalMode;

var transient array<TestCWRUIListElement> ReplacementElements;
var transient array<ReplacementInfoEx> CurrentReplacements;

var array<DynamicMenuOption> BaseOptions;

/** Used to detect when the options are being regenerated */
var transient bool bRegeneratingOptions;


// Replacement info
var transient EReplacementType ReplacementType;
var transient name ReplacementReference;
var transient TestCWRUI UIData;


// Localization
var() transient localized string SwitchSimpleMode;
var() transient localized string SwitchAdvancedMode;

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

	//ButtonBar.AppendButton("New Elements", OnButtonBar_Test);
	ButtonBar.AppendButton("Add new element", OnButtonBar_Test2);
	ButtonBar.AppendButton("Refresh", OnButtonBar_TestRefresh);
	ButtonBar.AppendButton("Refresh elements", OnButtonBar_TestRefreshElements);
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

	//UpdateReplacements();
	for (i=0; i<ReplacementElements.Length; i++)
	{
		RepInfo = EmptyInfo;
		if (RetrieveReplacementInfoFor(ReplacementElements[i], RepInfo))
		{
			Replacements.AddItem(RepInfo);
		}
	}

	class'TestCentralWeaponReplacement'.static.SetConfigReplacements(ReplacementType, Replacements);
}

/** Buttonbar Test Callback. */
function bool OnButtonBar_Test(UIScreenObject InButton, int InPlayerIndex)
{
	SetupOptionBindings();
	return true;
}

/** Buttonbar Test Callback. */
function bool OnButtonBar_Test2(UIScreenObject InButton, int InPlayerIndex)
{
	local DynamicMenuOption CurMenuOpt;
	local int i;

	i = DynOptionList.GeneratedObjects.Length;

	CurMenuOpt.OptionName = name(""$i);
	CurMenuOpt.FriendlyName = "Item"@i;
	CurMenuOpt.Description = "Desc for Item"@i;
	DynOptionList.DynamicOptionTemplates.AddItem(CurMenuOpt);

	// Generate the option controls
	i = DynOptionList.CurrentIndex;
	DynOptionList.RefreshAllOptions();

	return true;
}

/** Buttonbar Test Callback. */
function bool OnButtonBar_TestRefresh(UIScreenObject InButton, int InPlayerIndex)
{
	OptionList.RegenerateOptions();
	return true;
}

/** Buttonbar Test Callback. */
function bool OnButtonBar_TestRefreshElements(UIScreenObject InButton, int InPlayerIndex)
{
	local int i;

	for (i=0; i<ReplacementElements.Length; i++)
	{
		ReplacementElements[i].RefreshCombo();
	}

	return true;
}

/** Buttonbar Switch mode Callback. */
function bool OnButtonBar_SwitchMode(UIScreenObject InButton, int InPlayerIndex)
{
	UpdateReplacements();

	// override current options
	DynOptionList.DynamicOptionTemplates = BaseOptions;

	bMinimalMode = !bMinimalMode;
	if (bMinimalMode ||BaseOptions.Length == 0)
	{
		AddNewEmpty();
	}

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

	if (DynOptionList == none)
		return;

	bRegeneratingOptions = True;
	DynOptionList.DynamicOptionTemplates.Length = 0;

	if (class'TestCentralWeaponReplacement'.static.GetConfigReplacements(ReplacementType, CurrentReplacements))
	{
		for (i=0; i<CurrentReplacements.Length; i++)
		{
			CurMenuOpt.OptionName = name(""$i);
			CurMenuOpt.FriendlyName = ""$CurrentReplacements[i].OldClassName;
			DynOptionList.DynamicOptionTemplates.AddItem(CurMenuOpt);
		}
	}

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
	local UTUIScene UTScene;
	UTScene = UTUIScene(GetScene());
	if (UTScene != none) UTScene.DisplayMessageBox("Modify"@CreatedWidget);
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

	if (BaseOptions.Length == 0)
	{
		AddNewEmpty();
	}

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

	NewMenuOpt.OptionName = bMinimalMode ? 'NewItem' : GetRandomOptionName();
	DynOptionList.DynamicOptionTemplates.AddItem(NewMenuOpt);
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

	//@TODO: options
}

function bool RetrieveReplacementInfoFor(TestCWRUIListElement element, out ReplacementInfoEx RepInfo)
{
	local int index;
	local string ClassStr, PathStr;

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

	//@TODO: options

	return true;
}

DefaultProperties
{
	bMinimalMode=true

	MAX_RANDOM_NUMBER=9999

	SwitchSimpleMode="SIMPLE"
	SwitchAdvancedMode="ADVANCED"

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

class TestCWRUIConfig extends UTUIFrontEnd;

var const int MAX_RANDOM_NUMBER;

var() transient localized string Title;
var() transient localized string PreLoadingMessage;

var() bool bMinimalMode;

// Reference to the options page and list
var transient UTUITabPage_DynamicOptions OptionsPage;
var transient UTUIDynamicOptionList OptionsList;

/** Reference to the messagebox scene. */
var transient UTUIScene_MessageBox MessageBoxReference;

var transient bool bRegeneratingOptions; // Used to detect when the options are being regenerated

var transient TestCWRUI UIData;

var transient array<TestCWRUIListElement> ReplacementElements;
var transient array<ReplacementInfoEx> CurrentReplacements;

var array<DynamicMenuOption> BaseOptions;

/** Post initialize callback */
event PostInitialize()
{
	OptionsPage = UTUITabPage_DynamicOptions(FindChild('pnlOptions', True));
	OptionsList = UTUIDynamicOptionList(FindChild('lstOptions', True));

	super.PostInitialize();

	UIData = class'TestCWRUI'.static.GetData();
}

/** Scene activated event, sets up the title for the scene. */
event SceneActivated(bool bInitialActivation)
{
	local array<string> MessageBoxOptions;

	Super.SceneActivated(bInitialActivation);

	if (bInitialActivation)
	{
		MessageBoxReference = GetMessageBoxScene();
		if (MessageBoxReference != none)
		{
			MessageBoxReference.SetPotentialOptions(MessageBoxOptions);
			MessageBoxReference.Display(PreLoadingMessage, Title);
			LoadTimed();
		}
		else
		{
			InitLoad();
		}
	}
}

function LoadTimed(optional float time = 2.0)
{
	local PlayerController PC;
	
	PC = GetPlayerOwner().Actor;
	if (PC != none)
	{
		PC.SetTimer(2.0, false, 'InitLoad', self);
	}
	else
	{
		InitLoad();
	}
}

function InitLoad()
{
	UIData.LoadAll();
	SetupMenuOptions();

	if (MessageBoxReference != none)
	{
		CloseScene(MessageBoxReference);
	}
}

// Initializes the menu option templates, and regenerates the option list
function SetupMenuOptions()
{
	local DynamicMenuOption CurMenuOpt;
	local int i;

	if (OptionsPage == none || OptionsList == none)
		return;

	bRegeneratingOptions = True;
	OptionsList.DynamicOptionTemplates.Length = 0;

	if (class'TestCentralWeaponReplacement'.static.GetConfigReplacements(RT_Weapon, CurrentReplacements))
	{
		for (i=0; i<CurrentReplacements.Length; i++)
		{
			CurMenuOpt.OptionName = name(""$i);
			CurMenuOpt.FriendlyName = ""$CurrentReplacements[i].OldClassName;
			OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);
		}
	}

	BaseOptions = OptionsList.DynamicOptionTemplates;

	if (bMinimalMode)
	{
		CurMenuOpt.OptionName = 'NewItem';
		CurMenuOpt.FriendlyName = "";
		OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);
	}

	// Generate the option controls
	OptionsList.OnSetupOptionBindings = SetupOptionBindings;
	OptionsList.RegenerateOptions();
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

	for (i=0; i<OptionsList.GeneratedObjects.Length; i++)
	{
		LabelObj = UILabel(OptionsList.GeneratedObjects[i].LabelObj);
		GenObj = OptionsList.GeneratedObjects[i].OptionObj;
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

		RepObj.SetComboDatastoreBinding(GetDatastoreMarkup('WeaponSelection', ''));
		if (i < CurrentReplacements.Length)
		{
			PopulateReplacementInfoFor(RepObj, CurrentReplacements[i]);
		}

		RepObj.SwitchMode(bMinimalMode,
			BaseOptions.Length == 0 || (bMinimalMode && i == OptionsList.GeneratedObjects.Length-1)
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

	OptionsPage.DescriptionLabel.SetVisibility(false);
	OptionsList.BGPrefabInstance.SetVisibility(false);

	bRegeneratingOptions = False;
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

//event Initialized()
//{
//	super.Initialized();

//	//TabControl.CreateTabPage(class'UITabPage');
//	//TabControl.CreateTabPage(class'UITabPage');
//	//TabControl.CreateTabPage(class'UITabPage');
//}

///** Post initialize callback. */
//event PostInitialize()
//{
//	local UITabPage NewPage;
//	local UILabel TempLabel;
//	local UIPanel ItemPanel;
//	local UILabel ItemLabel;
//	local UILabelButton ItemButton;
//	local UIObject NewWidget, PrevWidget;
//	local UIScrollFrame ScrollContainer;
//	local int i, MaxCount;


//	MaxCount = 20;
//	Super.PostInitialize();

//	TabControl.SetVisibility(false);

//	ScrollContainer = UIScrollFrame(CreateWidget(self, class'UIScrollFrame'));
//	InsertChild(ScrollContainer);

//	for (i=0; i<MaxCount; i++)
//	{
//		NewWidget = CreateWidget(Self, class'TestCWRUIListElement', None, name("item"$i));
//		ScrollContainer.InsertChild(NewWidget);
//		if (PrevWidget != none) 
//		{
//			NewWidget.SetDockTarget(UIFACE_Top, PrevWidget, UIFACE_Bottom);
//		}

//		PrevWidget = NewWidget;
//	}

//	ScrollContainer.SetDockTarget(UIFACE_Left, self, UIFACE_Left);
//	ScrollContainer.SetDockTarget(UIFACE_Right, self, UIFACE_Right);
//	ScrollContainer.SetDockTarget(UIFACE_Top, self, UIFACE_Top);
//	ScrollContainer.SetDockTarget(UIFACE_Bottom, self, UIFACE_Bottom);


//	//PrevWidget = CreateWidget(Self, class'TestCWRUIListElement', None, 'item1');
//	//InsertChild(PrevWidget);

//	//NewWidget = CreateWidget(Self, class'TestCWRUIListElement', None, 'item2');
//	//InsertChild(NewWidget);
//	//NewWidget.SetDockTarget(UIFACE_Top, PrevWidget, UIFACE_Bottom);

//	//ItemPanel = UIPanel(CreateWidget(Self, class'UIPanel', None, 'panelTest1'));
//	//ItemPanel.BackgroundImageComponent.SetOpacity(0.0);
//	//ItemPanel.SetDockTarget(UIFACE_Left, self, UIFACE_Left);
//	//ItemPanel.SetDockTarget(UIFACE_Right, self, UIFACE_Right);
//	//InsertChild(ItemPanel);

//	//ItemLabel = UILabel(CreateWidget(Self, class'UILabel', None, 'lblText'));
//	//ItemLabel.SetDataStoreBinding("Test");
//	//ItemLabel.SetVisibility(true);
//	//ItemPanel.InsertChild(ItemLabel);

//	//ItemButton = UILabelButton(CreateWidget(Self, class'UILabelButton', None, 'cmdRemove'));
//	//ItemButton.SetDockTarget(UIFACE_Right, ItemPanel, UIFACE_Right);
//	//ItemButton.SetVisibility(true);
//	//ItemPanel.InsertChild(ItemButton);
//	//ItemButton.SetCaption("Remove");

//	//ItemPanel.SetPosition(64.0, UIFACE_Bottom, EVALPOS_PixelOwner);
//}


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

/** Setup the scene's button bar. */
function SetupButtonBar()
{
	if(ButtonBar != None)
	{
		ButtonBar.Clear();
		ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Back>", OnButtonBar_Back);
		ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Accept>", OnButtonBar_Accept);

		ButtonBar.AppendButton("Switch mode", OnButtonBar_SwitchMode);

		////ButtonBar.AppendButton("New Elements", OnButtonBar_Test);
		//ButtonBar.AppendButton("Add new element", OnButtonBar_Test2);
		//ButtonBar.AppendButton("Refresh", OnButtonBar_TestRefresh);
		//ButtonBar.AppendButton("Refresh elements", OnButtonBar_TestRefreshElements);

		//if(TabControl != None && UTTabPage(TabControl.ActivePage) != none)
		//{
		//	// Let the current tab page append buttons.
		//	UTTabPage(TabControl.ActivePage).SetupButtonBar(ButtonBar);
		//}
	}
}

function bool HandleInputKey( const out InputEventParameters EventParms )
{
	if(EventParms.InputKeyName=='XboxTypeS_B' || EventParms.InputKeyName=='Escape')
	{
		CloseScene(self);
		return true;
	}

	return false;
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

	i = OptionsList.GeneratedObjects.Length;

	CurMenuOpt.OptionName = name(""$i);
	CurMenuOpt.FriendlyName = "Item"@i;
	CurMenuOpt.Description = "Desc for Item"@i;
	OptionsList.DynamicOptionTemplates.AddItem(CurMenuOpt);

	// Generate the option controls
	i = OptionsList.CurrentIndex;
	OptionsList.RefreshAllOptions();

	return true;
}

/** Buttonbar Test Callback. */
function bool OnButtonBar_TestRefresh(UIScreenObject InButton, int InPlayerIndex)
{
	OptionsList.RegenerateOptions();
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
	OptionsList.DynamicOptionTemplates = BaseOptions;

	bMinimalMode = !bMinimalMode;
	if (bMinimalMode ||BaseOptions.Length == 0)
	{
		AddNewEmpty();
	}

	// Re-Generate the option controls
	OptionsList.RegenerateOptions();

	return true;
}

/** Buttonbar Accept Callback. */
function bool OnButtonBar_Accept(UIScreenObject InButton, int PlayerIndex)
{
	OnAccept();
	CloseScene(Self);

	return true;
}

/** Buttonbar Back Callback. */
function bool OnButtonBar_Back(UIScreenObject InButton, int InPlayerIndex)
{
	OnBack();

	return true;
}

/** Callback for when the user wants to back out of this screen. */
function OnBack()
{
	CloseScene(self);
}

function OnAccept()
{
	local int i;
	local ReplacementInfoEx RepInfo, EmptyInfo;
	local array<ReplacementInfoEx> Replacements;

	for (i=0; i<ReplacementElements.Length; i++)
	{
		RepInfo = EmptyInfo;
		if (RetrieveReplacementInfoFor(ReplacementElements[i], RepInfo))
		{
			Replacements.AddItem(RepInfo);
		}
	}

	class'TestCentralWeaponReplacement'.static.SetConfigReplacements(RT_Weapon, Replacements);
}

function OnReplacement_Modify(UIObject CreatedWidget)
{
	DisplayMessageBox("Modify"@CreatedWidget);
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
	OptionsList.DynamicOptionTemplates = BaseOptions;

	if (BaseOptions.Length == 0)
	{
		AddNewEmpty();
	}

	// Re-Generate the option controls
	//OptionsList.RegenerateOptions();
	OptionsList.bRegenOptions = true;
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
	if (UIData.GetDataStoreValue('WeaponSelection', 'Class', NewIndex, str))
	{
		CurrentReplacements[CurrentReplacements.Length-1].OldClassName = name(str);
	}

	UpdateReplacements();

	// Add pending new item
	CurMenuOpt.OptionName = name(""$BaseOptions.Length);
	BaseOptions.AddItem(CurMenuOpt);

	// override current options
	OptionsList.DynamicOptionTemplates = BaseOptions;

	if (!bMinimalMode)
		return;

	// Add new "NewItem" for new selection
	AddNewEmpty();

	// Re-Generate the option controls
	OptionsList.RegenerateOptions();

	OptionsList.SelectItem(OptionsList.GeneratedObjects.Length-1);
}

function AddNewEmpty()
{
	local DynamicMenuOption NewMenuOpt;

	NewMenuOpt.OptionName = bMinimalMode ? 'NewItem' : GetRandomOptionName();
	OptionsList.DynamicOptionTemplates.AddItem(NewMenuOpt);
}

function ReplacementReorder(int ThisIndex, int SwapIndex)
{
	local TestCWRUIListElement ThisElement, SwapElement;
	local ReplacementInfoEx ThisRep, SwapRep;
	local UIObject OwnerObj;

	if (SwapIndex < 0 || SwapIndex >= OptionsList.GeneratedObjects.Length)
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
	OptionsList.GeneratedObjects[ThisIndex].OptionObj.RemoveChild(ThisElement);
	OptionsList.GeneratedObjects[SwapIndex].OptionObj.RemoveChild(SwapElement);

	// add overridden object to current option
	OwnerObj = OptionsList.GeneratedObjects[SwapIndex].OptionObj;
	OwnerObj.InsertChild(ThisElement);
	DockFill(ThisElement, OptionsList.GeneratedObjects[SwapIndex].LabelObj, OwnerObj);
	
	// add current object to overriden option
	OwnerObj = OptionsList.GeneratedObjects[ThisIndex].OptionObj;
	OwnerObj.InsertChild(SwapElement);
	DockFill(SwapElement, OptionsList.GeneratedObjects[ThisIndex].LabelObj, OwnerObj);
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
	if (UIData.GetDataStoreIndex('WeaponSelection', 'Class', RepInfo.OldClassName, index))
	{
		element.SetReplacementIndexFrom(index);
	}

	if (UIData.GetDataStoreIndex('WeaponSelection', 'Path', RepInfo.NewClassPath, index))
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
	if (index == INDEX_NONE || !UIData.GetDataStoreValue('WeaponSelection', 'Class', index, ClassStr))
	{
		return false;
	}
	index = element.GetReplacementIndexTo();
	if (index == INDEX_NONE || !UIData.GetDataStoreValue('WeaponSelection', 'Path', index, PathStr))
	{
		return false;
	}

	if (ClassStr ~= "")
	{
		return false;
	}
	
	RepInfo.NewClassPath = PathStr;
	RepInfo.OldClassName = name(ClassStr);

	//@TODO: options

	return true;
}
	
DefaultProperties
{
	Title="[Central Weapon Replacement]"
	PreLoadingMessage="Pre-loading classes. May take up to 30s"

	bMinimalMode=true

	MAX_RANDOM_NUMBER=9999
}

class TestCWRUIListElement extends UTUI_Widget
	transient
	placeable;

const BUTTON_SPACING = -20;

var transient bool bIsNew;
var transient bool bSimpleMode;

var instanced UILabelButton RemoveButton;
var instanced UILabelButton ModifyButton; 
var instanced UILabelButton AddButton;

var instanced UILabelButton MoveUpButton;
var instanced UILabelButton MoveDownButton;

var instanced UTUIComboBox ReplacementFromCombo;
var instanced UTUIComboBox ReplacementToCombo;
var instanced UIPanel ReplacementPanel;

delegate OnReorder(UIObject CreatedWidget, bool bUp);
delegate OnModify(UIObject CreatedWidget);
delegate OnRemove(UIObject CreatedWidget, bool bRemove);
delegate OnChangedNew(UIObject CreatedWidget, int NewIndex, string NewSelection);

event Initialized()
{
	Super.Initialized();

	// re-parent
	InsertChild(ReplacementPanel);
	ReplacementPanel.InsertChild(ReplacementFromCombo);
	ReplacementPanel.InsertChild(ReplacementToCombo);
	RemoveChild(ReplacementFromCombo);
	RemoveChild(ReplacementToCombo);
}

event PostInitialize()
{
	Super.PostInitialize();

	// order buttons

	MoveDownButton.DockTargets.bLockWidthWhenDocked = true;
	MoveDownButton.SetDockTarget(UIFACE_Right, self, UIFACE_Right);
	MoveDownButton.StringRenderComponent.EnableAutoSizing(UIORIENT_Horizontal, true);
	MoveDownButton.SetVisibility(true);
	MoveDownButton.SetEnabled(true);
	MoveDownButton.StringRenderComponent.SetOpacity(0.0);
	MoveDownButton.RefreshSubscriberValue();
	MoveDownButton.SetWidgetStyleByName('Background Image Style', 'SpinnerDecrementButtonBackground');
	MoveDownButton.OnClicked = OnButtonClicked;

	MoveUpButton.DockTargets.bLockWidthWhenDocked = true;
	MoveUpButton.SetDockTarget(UIFACE_Right, MoveDownButton, UIFACE_Left);
	MoveUpButton.StringRenderComponent.EnableAutoSizing(UIORIENT_Horizontal, true);
	MoveUpButton.SetVisibility(true);
	MoveUpButton.SetEnabled(true);
	MoveUpButton.StringRenderComponent.SetOpacity(0.0);
	MoveUpButton.RefreshSubscriberValue();
	MoveUpButton.SetWidgetStyleByName('Background Image Style', 'SpinnerIncrementButtonBackground');
	MoveUpButton.OnClicked = OnButtonClicked;

	// add/modify/remove buttons

	RemoveButton.DockTargets.bLockWidthWhenDocked = true;
	RemoveButton.SetDockParameters(UIFACE_Right, MoveUpButton, UIFACE_Left, BUTTON_SPACING);
	RemoveButton.StringRenderComponent.EnableAutoSizing(UIORIENT_Horizontal, true);
	RemoveButton.SetVisibility(true);
	RemoveButton.SetEnabled(true);
	RemoveButton.RefreshSubscriberValue();
	RemoveButton.SetWidgetStyleByName('Caption Style', 'UTButtonBarButtonCaption');
	RemoveButton.SetWidgetStyleByName('Background Image Style', 'UTButtonBarButtonBG_PC');
	RemoveButton.OnClicked = OnButtonClicked;
	
	ModifyButton.DockTargets.bLockWidthWhenDocked = true;
	ModifyButton.SetDockParameters(UIFACE_Right, RemoveButton, UIFACE_Left, BUTTON_SPACING);
	ModifyButton.StringRenderComponent.EnableAutoSizing(UIORIENT_Horizontal, true);
	ModifyButton.SetVisibility(true);
	ModifyButton.SetEnabled(true);
	ModifyButton.RefreshSubscriberValue();
	ModifyButton.SetWidgetStyleByName('Caption Style', 'UTButtonBarButtonCaption');
	ModifyButton.SetWidgetStyleByName('Background Image Style', 'UTButtonBarButtonBG_PC');
	ModifyButton.OnClicked = OnButtonClicked;

	AddButton.DockTargets.bLockWidthWhenDocked = true;
	AddButton.SetDockParameters(UIFACE_Left, self, UIFACE_Left, 0);
	AddButton.StringRenderComponent.EnableAutoSizing(UIORIENT_Horizontal, true);
	AddButton.SetVisibility(true);
	AddButton.SetEnabled(true);
	AddButton.RefreshSubscriberValue();
	AddButton.SetWidgetStyleByName('Caption Style', 'UTButtonBarButtonCaption');
	AddButton.SetWidgetStyleByName('Background Image Style', 'UTButtonBarButtonBG_PC');
	AddButton.OnClicked = OnButtonClicked;
	

	// combo lists

	ReplacementPanel.SetDockParameters(UIFACE_Left, AddButton, UIFACE_Right, 0);
	ReplacementPanel.SetDockParameters(UIFACE_Right, ModifyButton, UIFACE_Left, 0);
	ReplacementPanel.SetDockPadding(UIFACE_Left, 20.0);
	ReplacementPanel.SetDockPadding(UIFACE_Right, -20.0);
	ReplacementPanel.BackgroundImageComponent.SetOpacity(0.0);

	ReplacementFromCombo.ComboEditbox.StringRenderComponent.SetAlignment(UIORIENT_Horizontal, UIALIGN_Left);
	ReplacementToCombo.ComboEditbox.StringRenderComponent.SetAlignment(UIORIENT_Vertical, UIALIGN_Center);

	ReplacementFromCombo.OnValueChanged = OnReplacementFrom_ValueChanged;

	// Debug
	//ReplacementFromCombo.ComboList.SetDataStoreBinding("<UTMenuItems:Weapons>");
	//ReplacementToCombo.ComboList.SetDataStoreBinding("<UTMenuItems:Weapons>");
}

function bool OnButtonClicked(UIScreenObject EventObject, int PlayerIndex)
{
	switch (EventObject)
	{
	case MoveUpButton:
	case MoveDownButton:
		OnReorder(self, MoveUpButton == EventObject);
		break;

	case RemoveButton:
	case AddButton:
		OnRemove(self, RemoveButton == EventObject);
		break;

	case ModifyButton:
		OnModify(self);
		break;

	default:
		return false;
	}

	return true;
}

function OnReplacementFrom_ValueChanged( UIObject Sender, int PlayerIndex )
{
	local int index;
	local string str;

	if (bIsNew)
	{
		SwitchMode(bSimpleMode, false);

		index = ReplacementFromCombo.ComboList.GetCurrentItem();
		str = ReplacementFromCombo.ComboList.GetElementValue(index);
		OnChangedNew(self, index, str);
	}
}

function SetComboDatastoreBinding(string InDataStoreMarkup)
{
	ReplacementFromCombo.ComboList.SetDataStoreBinding(InDataStoreMarkup);
	ReplacementFromCombo.ComboList.RefreshSubscriberValue();
	ReplacementFromCombo.SetSelectionIndex(0);

	ReplacementToCombo.ComboList.SetDataStoreBinding(InDataStoreMarkup);
	ReplacementToCombo.ComboList.RefreshSubscriberValue();
	ReplacementToCombo.SetSelectionIndex(0);
}

function RefreshCombo()
{
	ReplacementFromCombo.ComboList.RefreshSubscriberValue();
	ReplacementToCombo.ComboList.RefreshSubscriberValue();
}

function SwitchMode(bool bSimple, optional bool bNew)
{
	bSimpleMode = bSimple;
	bIsNew = bNew;
	
	AddButton.SetVisibility(!bSimple && !bNew);
	ModifyButton.SetVisibility(!bSimple && !bNew);
	RemoveButton.SetVisibility(!bSimple && !bNew);

	MoveUpButton.SetVisibility(!bSimple && !bNew);
	MoveDownButton.SetVisibility(!bSimple && !bNew);

	if (bSimple)
	{
		ReplacementPanel.SetDockParameters(UIFACE_Left, AddButton, UIFACE_Left, 0);
		ReplacementPanel.SetDockParameters(UIFACE_Right, MoveDownButton, UIFACE_Right, 0);
		ReplacementPanel.SetDockPadding(UIFACE_Left, 0.0);
		ReplacementPanel.SetDockPadding(UIFACE_Right, 0.0);
	}
	else
	{
		ReplacementPanel.SetDockParameters(UIFACE_Left, AddButton, UIFACE_Right, 0);
		ReplacementPanel.SetDockParameters(UIFACE_Right, ModifyButton, UIFACE_Left, 0);
		ReplacementPanel.SetDockPadding(UIFACE_Left, 20.0);
		ReplacementPanel.SetDockPadding(UIFACE_Right, -20.0);
	}

	ReplacementFromCombo.RequestFormattingUpdate();
	ReplacementToCombo.RequestFormattingUpdate();

	ReplacementToCombo.SetVisibility(!bNew);
}

function int GetReplacementIndexFrom()
{
	return ReplacementFromCombo.ComboList.GetCurrentItem();
}

function int GetReplacementIndexTo()
{
	return ReplacementToCombo.ComboList.GetCurrentItem();
}

function SetReplacementIndexFrom(int index)
{
	ReplacementFromCombo.SetSelectionIndex(index);
}

function SetReplacementIndexTo(int index)
{
	ReplacementToCombo.SetSelectionIndex(index);
}

DefaultProperties
{
	DefaultStates.Add(class'Engine.UIState_Focused')
	DefaultStates.Add(class'Engine.UIState_Active')
	DefaultStates.Add(class'Engine.UIState_Pressed')

	Position={( Value[UIFACE_Left]=0,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Top]=0,
				ScaleType[UIFACE_Top]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=1,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner)}


	// Button Modify
	Begin Object Class=UILabelButton Name=ModifyButtonTemplate
		WidgetTag=btnModify
		CaptionDataSource=(MarkupString="Options")

		Position={( Value[UIFACE_Left]=0.9,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Top]=0,
				ScaleType[UIFACE_Top]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.1,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=0.70,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	ModifyButton=ModifyButtonTemplate

	// Button Remove
	Begin Object Class=UILabelButton Name=RemoveButtonTemplate
		WidgetTag=btnRemove
		CaptionDataSource=(MarkupString="Remove")


		Position={( Value[UIFACE_Left]=0.9,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Top]=0,
				ScaleType[UIFACE_Top]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.1,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=0.70,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	RemoveButton=RemoveButtonTemplate

	// Button Add
	Begin Object Class=UILabelButton Name=AddButtonTemplate
		WidgetTag=btnAdd
		CaptionDataSource=(MarkupString="Add")

		Position={( Value[UIFACE_Left]=0.1,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Top]=0,
				ScaleType[UIFACE_Top]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.9,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=0.70,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	AddButton=AddButtonTemplate

	// Panel 
	Begin Object Class=UIPanel Name=ReplacementPanelTemplate
		WidgetTag=pnlReplacement
	End Object
	ReplacementPanel=ReplacementPanelTemplate

	// Combo From 
	Begin Object Class=UTUIComboBox Name=ReplacementComboFromTemplate
		WidgetTag=cboReplacementFrom

		Position={( Value[UIFACE_Left]=0.0,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.475,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=1.0,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	ReplacementFromCombo=ReplacementComboFromTemplate

	// Combo To 
	Begin Object Class=UTUIComboBox Name=ReplacementComboToTemplate
		WidgetTag=cboReplacementTo

		Position={( Value[UIFACE_Left]=0.525,
				ScaleType[UIFACE_Left]=EVALPOS_PercentageOwner,
				Value[UIFACE_Right]=0.45,
				ScaleType[UIFACE_Right]=EVALPOS_PercentageOwner,
				Value[UIFACE_Bottom]=1.0,
				ScaleType[UIFACE_Bottom]=EVALPOS_PercentageOwner)}
	End Object
	ReplacementToCombo=ReplacementComboToTemplate

	Begin Object Class=UILabelButton Name=MoveUpButtonTemplate
		WidgetTag=bntMoveUp
		CaptionDataSource=(MarkupString="||")
	End Object
	MoveUpButton=MoveUpButtonTemplate

	Begin Object Class=UILabelButton Name=MoveDownButtonTemplate
		WidgetTag=btnMoveDown
		CaptionDataSource=(MarkupString="||")
	End Object
	MoveDownButton=MoveDownButtonTemplate
}

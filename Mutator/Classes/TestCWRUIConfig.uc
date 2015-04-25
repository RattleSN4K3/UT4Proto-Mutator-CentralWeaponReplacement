class TestCWRUIConfig extends UTUIFrontEnd;

struct DynamicPageInfo
{
	var name Tag;
	var EReplacementType ReplacementType;
	var name DatastoreReference;

	var bool Hidden;
	var name After;

	// Runtime
	var transient TestCWRUITabList CreatedPage;
};

struct LocalizedPageCaptionMap
{
	var localized name Tag;
	var localized string Text;
};

var() transient localized string Title;
var() transient localized string BuildingUIMessage;

var() transient localized string ConfirmNoOptionsMessage;
var() transient localized string ConfirmNoOptionsTitle;
var() transient localized string ConfirmNoOptionsButtonAccept;

var() transient localized string ConfirmHideAmmoMessage;
var() transient localized string ConfirmHideAmmoTitle;
var() transient localized string ConfirmHideAmmoButtonAccept;

var() transient localized string CustomAmmoReplacementMessage;
var() transient localized string CustomAmmoReplacementTitle;

var() transient localized string ShowAmmoCaption;
var() transient localized string HideAmmoCaption;
var() transient localized string TransferAmmoCaption;

var() transient localized array<LocalizedPageCaptionMap> TitlesMapping;
var() transient array<DynamicPageInfo> DynamicPages;

/** Reference to the messagebox scene. */
var transient UTUIScene_MessageBox MessageBoxReference;

var transient TestCWRUI UIData;

var bool bAmmoVisible;
var bool bAmmoInfoShown;

/** Initialize callback */
event Initialized()
{
	local int i;
	local UTUITabControl TempTabControl;

	Super.Initialized();

	TempTabControl = UTUITabControl(FindChild('pnlTabControl', true));

	for (i=0; i<DynamicPages.Length; i++)
	{
		if (DynamicPages[i].Hidden) continue;

		DynamicPages[i].CreatedPage = CreateReplacementTab(TempTabControl, DynamicPages[i]);
	}

	i = DynamicPages.Find('Tag', 'Weapons');
	if (i != INDEX_NONE && DynamicPages[i].CreatedPage != none)
	{
		DynamicPages[i].CreatedPage.OnExtraSave = OnReplacementsExtraSave_Weapons;
	}
}

/** Scene activated event, sets up the title for the scene. */
event SceneActivated(bool bInitialActivation)
{
	local array<string> MessageBoxOptions;

	Super.SceneActivated(bInitialActivation);

	if (bInitialActivation)
	{
		UIData = class'TestCWRUI'.static.GetData();

		MessageBoxReference = GetMessageBoxScene();
		if (MessageBoxReference != none)
		{
			MessageBoxOptions.Length = 0;
			MessageBoxReference.SetPotentialOptions(MessageBoxOptions);
			MessageBoxReference.Display(BuildingUIMessage, Title);
			LoadTimed();
		}
		else
		{
			InitLoad();
		}
	}
}

function InitLoad()
{
	UIData.LoadAll();
	InitReplacements();

	if (MessageBoxReference != none)
	{
		CloseScene(MessageBoxReference);
	}
}

function InitReplacements()
{
	local int i, AmmoIdx, InsertIdx;
	local array<ReplacementInfoEx> ConfigWeaponReplacements, ConfigAmmoReplacements;
	local array<ReplacementInfoEx> SimpleAmmoReplacements;
	local ReplacementOptionsInfo EmptyOptions;
	local bool bCustomAmmo;

	// update all dynamic pages
	for (i=0; i<DynamicPages.Length; i++)
	{
		if (DynamicPages[i].CreatedPage != none)
		{
			DynamicPages[i].CreatedPage.LoadReplacements(UIData);
		}
	}

	// check if config ammo replacements differ from current simple ammo replacements
	if (class'TestCentralWeaponReplacement'.static.GetConfigReplacements(RT_Weapon, ConfigWeaponReplacements) &&
		class'TestCentralWeaponReplacement'.static.GetConfigReplacements(RT_Ammo, ConfigAmmoReplacements))
	{
		for (i=0; i<ConfigAmmoReplacements.Length; i++)
		{
			if (ConfigAmmoReplacements[i].Options != EmptyOptions)
			{
				bCustomAmmo = true;
				break;
			}
		}

		if (!bCustomAmmo)
		{
			SimpleAmmoReplacements = GetAmmoBasicReplacementsFor(ConfigWeaponReplacements);

			if (ConfigAmmoReplacements.Length != SimpleAmmoReplacements.Length)
			{
				bCustomAmmo = true;
			}
			else
			{
				for (i=0; i<SimpleAmmoReplacements.Length; i++)
				{
					ConfigAmmoReplacements.RemoveItem(SimpleAmmoReplacements[i]);
				}

				if (ConfigAmmoReplacements.Length > 0)
				{
					bCustomAmmo = true;
				}
			}
		}
	}

	// add ammo tab if custom ammo replacements are found
	AmmoIdx = DynamicPages.Find('Tag', 'Ammo');
	if (bCustomAmmo && AmmoIdx != INDEX_NONE)
	{		
		bAmmoVisible = true;
		InsertIdx = DynamicPages.Find('Tag', DynamicPages[AmmoIdx].After);
		if (InsertIdx != INDEX_NONE) InsertIdx += 1;
		DynamicPages[AmmoIdx].CreatedPage = CreateReplacementTab(TabControl, DynamicPages[AmmoIdx], InsertIdx, true);
		if (DynamicPages[AmmoIdx].CreatedPage != none)
		{
			DynamicPages[AmmoIdx].CreatedPage.LoadReplacements(UIData);
		}
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

/** Setup the scene's button bar. */
function SetupButtonBar()
{
	local int index;

	if(ButtonBar != None)
	{
		ButtonBar.Clear();
		ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Back>", OnButtonBar_Back);
		ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Accept>", OnButtonBar_Accept);

		if(TabControl != None && UTTabPage(TabControl.ActivePage) != none)
		{
			if (bAmmoVisible)
			{
				index = DynamicPages.Find('Tag', 'Ammo');
				if (index != INDEX_NONE && TabControl.ActivePage == DynamicPages[index].CreatedPage)
				{
					ButtonBar.AppendButton(HideAmmoCaption, OnButtonBar_HideAmmo);
				}
			}

			index = DynamicPages.Find('Tag', 'Weapons');
			if (index != INDEX_NONE && TabControl.ActivePage == DynamicPages[index].CreatedPage)
			{
				ButtonBar.AppendButton(bAmmoVisible ? HideAmmoCaption : ShowAmmoCaption, OnButtonBar_ShowAmmo);
				if (bAmmoVisible)
				{
					ButtonBar.AppendButton(TransferAmmoCaption, OnButtonBar_TransferAmmo);
				}
			}

			// Let the current tab page append buttons.
			UTTabPage(TabControl.ActivePage).SetupButtonBar(ButtonBar);
		}
	}
}

function bool HandleInputKey( const out InputEventParameters EventParms )
{
	local bool bResult;
	local UTTabPage CurrentTabPage;

	// Let the tab page's get first chance at the input
	CurrentTabPage = UTTabPage(TabControl.ActivePage);
	bResult = CurrentTabPage.HandleInputKey(EventParms);

	// If the tab page didn't handle it, let's handle it ourselves.
	if(bResult==false)
	{
		if(EventParms.EventType==IE_Released)
		{
			if(EventParms.InputKeyName=='XboxTypeS_B' || EventParms.InputKeyName=='Escape')
			{
				OnBack();
				bResult=true;
			}
		}
	}

	return bResult;
}

/** Buttonbar Accept Callback. */
function bool OnButtonBar_Accept(UIScreenObject InButton, int PlayerIndex)
{
	local array<string> MessageBoxOptions;
	local array<string> pages;
	local string pagesstr, str;

	if (HasIgnoredOptions(pages))
	{
		MessageBoxReference = GetMessageBoxScene();
		if(MessageBoxReference != none)
		{
			JoinArray(pages, pagesstr, "\n");
			str = Repl(ConfirmNoOptionsMessage, "  ", "\n");
			str = Repl(str, "`pages", pagesstr);

			MessageBoxOptions.AddItem(ConfirmNoOptionsButtonAccept);
			MessageBoxOptions.AddItem("<Strings:UTGameUI.ButtonCallouts.Cancel>");

			MessageBoxReference.SetPotentialOptions(MessageBoxOptions);
			MessageBoxReference.Display(str, ConfirmNoOptionsTitle, OnAccept_Confirm, 1);
			return true;
		}
	}

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

/** Buttonbar ShowAmmo Callback. */
function bool OnButtonBar_HideAmmo(UIScreenObject InButton, int InPlayerIndex)
{
	local array<string> MessageBoxOptions;

	MessageBoxReference = GetMessageBoxScene();
	if(MessageBoxReference != none)
	{
		MessageBoxOptions.AddItem(ConfirmHideAmmoButtonAccept);
		MessageBoxOptions.AddItem("<Strings:UTGameUI.ButtonCallouts.Cancel>");

		MessageBoxReference.SetPotentialOptions(MessageBoxOptions);
		MessageBoxReference.Display(Repl(ConfirmHideAmmoMessage, "  ", "\n"), ConfirmHideAmmoTitle, OnHideAmmo_Confirm, 1);
		return true;
	}

	ToggleAmmoTab(true);
	return true;
}

/** Buttonbar ShowAmmo Callback. */
function bool OnButtonBar_ShowAmmo(UIScreenObject InButton, int InPlayerIndex)
{
	ToggleAmmoTab();

	return true;
}

/** Buttonbar TransferAmmo Callback. */
function bool OnButtonBar_TransferAmmo(UIScreenObject InButton, int InPlayerIndex)
{
	TransferAmmo();

	return true;
}

/**
 * Callback for the accept confirmation dialog box.
 *
 * @param SelectedOption	Selected item
 * @param PlayerIndex	Index of player that performed the action.
 */
function OnAccept_Confirm(UTUIScene_MessageBox MessageBox, int SelectedOption, int PlayerIndex)
{
	if(SelectedOption == 0)
	{
		OnAccept();
		CloseScene(self);
	}
}

/**
 * Callback for the ignore ammo replacement dialog box.
 *
 * @param SelectedOption	Selected item
 * @param PlayerIndex	Index of player that performed the action.
 */
function OnHideAmmo_Confirm(UTUIScene_MessageBox MessageBox, int SelectedOption, int PlayerIndex)
{
	if(SelectedOption == 0)
	{
		ToggleAmmoTab(true);
	}
}

/** Callback for when the user wants to back out of this screen. */
function OnBack()
{
	CloseScene(self);
}

function OnAccept()
{
	local int i;

	// save all dynamic pages
	for (i=0; i<DynamicPages.Length; i++)
	{
		if (DynamicPages[i].CreatedPage != none)
		{
			DynamicPages[i].CreatedPage.SaveReplacements();
		}
	}
}

function OnReplacementsExtraSave_Weapons(TestCWRUITabList RefTab)
{
	local array<ReplacementInfoEx> WeaponReplacements, AmmoReplacements;
	
	if (!bAmmoVisible)
	{
		WeaponReplacements = RefTab.GetReplacements();
		AmmoReplacements = GetAmmoBasicReplacementsFor(WeaponReplacements);

		class'TestCentralWeaponReplacement'.static.SetConfigReplacements(RT_Ammo, AmmoReplacements);
	}
}

function ToggleAmmoTab(optional bool bForceHide)
{
	local int AmmoIdx, InsertIdx;
	local TestCWRUITabList TabPage;
	AmmoIdx = DynamicPages.Find('Tag', 'Ammo');
	if (AmmoIdx == INDEX_NONE)
		return;

	if (bAmmoVisible || bForceHide)
	{
		bAmmoVisible = false;
		if (DynamicPages[AmmoIdx].CreatedPage != none)
		{
			TabControl.RemovePage(DynamicPages[AmmoIdx].CreatedPage, GetBestPlayerIndex());
			DynamicPages[AmmoIdx].CreatedPage = none;
		}
	}
	else
	{
		bAmmoVisible = true;
		InsertIdx = DynamicPages.Find('Tag', DynamicPages[AmmoIdx].After);
		if (InsertIdx != INDEX_NONE) InsertIdx += 1;
		TabPage = CreateReplacementTab(TabControl, DynamicPages[AmmoIdx], InsertIdx, true);
		if (TabPage != none)
		{
			DynamicPages[AmmoIdx].CreatedPage = TabPage;
			TabPage.LoadReplacements(UIData);
		}
		
		if (!bAmmoInfoShown)
		{
			bAmmoInfoShown = true;
			DisplayMessageBox(Repl(CustomAmmoReplacementMessage, "  ", "\n"), CustomAmmoReplacementTitle);
		}
	}

	SetupButtonBar();
}

function TransferAmmo()
{
	local int WeaponIdx, AmmoIdx;
	local array<ReplacementInfoEx> WeaponReplacements, AmmoReplacements;

	WeaponIdx = DynamicPages.Find('Tag', 'Weapons');
	AmmoIdx = DynamicPages.Find('Tag', 'Ammo');
	if (WeaponIdx == INDEX_NONE || AmmoIdx == INDEX_NONE ||
		DynamicPages[WeaponIdx].CreatedPage == none || DynamicPages[AmmoIdx].CreatedPage == none)
		return;

	WeaponReplacements = DynamicPages[WeaponIdx].CreatedPage.GetReplacements();
	AmmoReplacements = GetAmmoBasicReplacementsFor(WeaponReplacements);

	if (AmmoReplacements.Length > 0)
	{
		DynamicPages[AmmoIdx].CreatedPage.AddReplacements(AmmoReplacements, true);
	}
}

function array<ReplacementInfoEx> GetAmmoBasicReplacementsFor(array<ReplacementInfoEx> WeaponReplacements)
{
	local ReplacementInfoEx Replacement;
	local int i;
	local name AmmoClassFrom;
	local string AmmoClassTo;
	local array<ReplacementInfoEx> Replacements;

	for (i=0; i<WeaponReplacements.Length; i++)
	{
		if (!UIData.GetAmmoInfoForWeapon(WeaponReplacements[i].OldClassName,, AmmoClassFrom))
			continue;

		Replacement.OldClassName = AmmoClassFrom;

		if (UIData.GetAmmoInfoForWeapon(WeaponReplacements[i].NewClassPath, AmmoClassTo))
		{
			Replacement.NewClassPath = AmmoClassTo;
		}
		else
		{
			Replacement.NewClassPath = "";
		}

		Replacements.AddItem(Replacement);
	}

	return Replacements;
}

function bool HasIgnoredOptions(out array<string> OutPages)
{
	local int i;
	local string str;

	for (i=0; i<DynamicPages.Length; i++)
	{
		if (DynamicPages[i].CreatedPage != none && DynamicPages[i].CreatedPage.IsIgnoringOptions())
		{
			str = GetTabString(DynamicPages[i].Tag);
			OutPages.AddItem(str);
		}
	}

	return OutPages.Length > 0;
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

function string GetTabString(name Tag)
{
	local int index;
	index = TitlesMapping.Find('Tag', Tag);
	if (index != INDEX_NONE)
	{
		return TitlesMapping[index].Text;
	}

	 Return Localize("Titles", string(Tag), string(class.GetPackageName()));
}

function TestCWRUITabList CreateReplacementTab(UTUITabControl InTabControl, DynamicPageInfo PageInfo, optional int InsertIndex = INDEX_NONE, optional bool bSkipActivate, optional int PlayerIndex=GetBestPlayerIndex())
{
	local TestCWRUITabList TabPage;
	Local name TabName;
	TabName = name("pnlTabRep_"$PageInfo.Tag);
	TabPage = TestCWRUITabList(CreateNamedTabPage(InTabControl, class'TestCWRUITabList', TabName));
	if (TabPage != none)
	{
		TabPage.SetTitle(Caps(GetTabString(PageInfo.Tag)));
		TabPage.SetReplacementInfo(PageInfo.ReplacementType, PageInfo.DatastoreReference);

		InTabControl.InsertPage(TabPage, PlayerIndex, InsertIndex, !bSkipActivate);
	}

	return TabPage;
}

static function UITabPage CreateNamedTabPage(UITabControl OwnerControl, class<UITabPage> TabPageClass, optional name WidgetName, optional UITabPage PagePrefab )
{
	local UITabPage TabPage;
	TabPage = UITabPage(OwnerControl.CreateWidget(OwnerControl, TabPageClass, PagePrefab, WidgetName));
	if (TabPage != none) TabPage.GetTabButton(OwnerControl);
	return TabPage;
}

DefaultProperties
{
	Title="[Central Weapon Replacement]"
	BuildingUIMessage="Building UI. May take some seconds..."

	ConfirmNoOptionsMessage="You have switched to simple mode but there are replacement options set for the following pages:  `pages    By continuing saving the replacements, the options will be cleared to default. Do you want to continue?"
	ConfirmNoOptionsTitle="Clear out options"
	ConfirmNoOptionsButtonAccept="CONTINUE"

	CustomAmmoReplacementMessage="By enabling custom ammo replacement, you have to either transfer all the ammo replacements from the current weapon replacement or setup your own replacements.    No ammo pickups will be replaced automatically by whatever weapon you choose to be replaced."
	CustomAmmoReplacementTitle="Custom ammo replacment"

	ConfirmHideAmmoMessage="You made changes to the ammo replacements. By switching back to simple ammo replacement (based on the selected weapons), you will loose any made changes to the ammo replacements.    Do you want to ignore these changes and switch to simple ammo replacement?"
	ConfirmHideAmmoTitle="Ignore custom replacements?"
	ConfirmHideAmmoButtonAccept="IGNORE"

	ShowAmmoCaption="CUSTOM AMMO"
	HideAmmoCaption="SIMPLE AMMO"
	TransferAmmoCaption="TRANSFER AMMO"

	TitlesMapping[0]=(Tag="Weapons",Text="Weapons")
	TitlesMapping[1]=(Tag="Healths",Text="Health")
	TitlesMapping[2]=(Tag="Armors",Text="Armor")
	TitlesMapping[3]=(Tag="Powerups",Text="Powerups")
	TitlesMapping[4]=(Tag="Deployables",Text="Deployables")
	TitlesMapping[5]=(Tag="Vehicles",Text="Vehicles")
	TitlesMapping[6]=(Tag="Customs",Text="Customs")
	TitlesMapping[7]=(Tag="Ammos",Text="Ammo")

	DynamicPages.Add((Tag="Weapons",ReplacementType=RT_Weapon,DatastoreReference="WeaponSelection"))
	DynamicPages.Add((Tag="Ammo",ReplacementType=RT_Ammo,DatastoreReference="AmmoSelection",Hidden=true,After="Weapons"))
	DynamicPages.Add((Tag="Healths",ReplacementType=RT_Health,DatastoreReference="HealthSelection"))
	DynamicPages.Add((Tag="Armors",ReplacementType=RT_Armor,DatastoreReference="ArmorSelection"))
	DynamicPages.Add((Tag="Powerups",ReplacementType=RT_Powerup,DatastoreReference="PowerupSelection"))
	DynamicPages.Add((Tag="Deployables",ReplacementType=RT_Deployable,DatastoreReference="DeployableSelection"))
	DynamicPages.Add((Tag="Vehicles",ReplacementType=RT_Vehicle,DatastoreReference="VehicleSelection"))
	DynamicPages.Add((Tag="Customs",ReplacementType=RT_Custom,DatastoreReference="CustomSelection",Hidden=true))
}

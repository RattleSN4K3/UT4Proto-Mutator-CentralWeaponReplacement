class TestCWRUIConfig extends UTUIFrontEnd;

struct DynamicPageInfo
{
	var name Tag;
	var EReplacementType ReplacementType;
	var name DatastoreReference;

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

var() transient localized array<LocalizedPageCaptionMap> TitlesMapping;
var() transient array<DynamicPageInfo> DynamicPages;

/** Reference to the messagebox scene. */
var transient UTUIScene_MessageBox MessageBoxReference;

var transient TestCWRUI UIData;

/** Initialize callback */
event Initialized()
{
	local int i, PlayerIndex;
	local TestCWRUITabList TabPage;
	local UTUITabControl TempTabControl;

	Super.Initialized();

	TempTabControl = UTUITabControl(FindChild('pnlTabControl', true));

	PlayerIndex = GetBestPlayerIndex();
	for (i=0; i<DynamicPages.Length; i++)
	{
		TabPage = TestCWRUITabList(CreateNamedTabPage(TempTabControl, class'TestCWRUITabList', name("pnlTabRep_"$DynamicPages[i].Tag)));
		if (TabPage != none)
		{
			TabPage.SetTitle( Caps(GetTabString(DynamicPages[i].Tag)) );
			TabPage.SetReplacementInfo(DynamicPages[i].ReplacementType, DynamicPages[i].DatastoreReference);

			DynamicPages[i].CreatedPage = TabPage;
			TempTabControl.InsertPage(TabPage, PlayerIndex);
		}	
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
	local int i;

	// update all dynamic pages
	for (i=0; i<DynamicPages.Length; i++)
	{
		if (DynamicPages[i].CreatedPage != none)
		{
			DynamicPages[i].CreatedPage.LoadReplacements(UIData);
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
	if(ButtonBar != None)
	{
		ButtonBar.Clear();
		ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Back>", OnButtonBar_Back);
		ButtonBar.AppendButton("<Strings:UTGameUI.ButtonCallouts.Accept>", OnButtonBar_Accept);

		if(TabControl != None && UTTabPage(TabControl.ActivePage) != none)
		{
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

	// save all dynamic pages
	for (i=0; i<DynamicPages.Length; i++)
	{
		if (DynamicPages[i].CreatedPage != none)
		{
			DynamicPages[i].CreatedPage.SaveReplacements();
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

	TitlesMapping[0]=(Tag="Weapons",Text="Weapons")
	TitlesMapping[1]=(Tag="Healths",Text="Health")
	TitlesMapping[2]=(Tag="Armors",Text="Armor")
	TitlesMapping[3]=(Tag="Powerups",Text="Powerups")
	TitlesMapping[4]=(Tag="Deployables",Text="Deployables")
	TitlesMapping[5]=(Tag="Vehicles",Text="Vehicles")
	TitlesMapping[6]=(Tag="Customs",Text="Customs")

	DynamicPages.Add((Tag="Weapons",ReplacementType=RT_Weapon,DatastoreReference="WeaponSelection"))
	DynamicPages.Add((Tag="Healths",ReplacementType=RT_Health,DatastoreReference="HealthSelection"))
	DynamicPages.Add((Tag="Armors",ReplacementType=RT_Armor,DatastoreReference="ArmorSelection"))
	DynamicPages.Add((Tag="Powerups",ReplacementType=RT_Powerup,DatastoreReference="PowerupSelection"))
	DynamicPages.Add((Tag="Deployables",ReplacementType=RT_Deployable,DatastoreReference="DeployableSelection"))
	DynamicPages.Add((Tag="Vehicles",ReplacementType=RT_Vehicle,DatastoreReference="VehicleSelection"))
	//DynamicPages.Add((Tag="Customs",ReplacementType=RT_Custom,DatastoreReference="CustomSelection"))
}

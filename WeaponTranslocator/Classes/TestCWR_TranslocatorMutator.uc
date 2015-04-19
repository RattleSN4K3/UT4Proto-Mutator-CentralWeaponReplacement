class TestCWR_TranslocatorMutator extends UTMutator;

var class<Inventory> ReplaceTranslocatorClass;
var class<Inventory> NewTranslocatorClass;

var bool bReplaceTranslocator;
var bool bAddToDefault;

function PostBeginPlay()
{
	local int i;
	local UTGame G;

	Super.PostBeginPlay();

	G = UTGame(WorldInfo.Game);
	if(G != none)
	{
		G.TranslocatorClass = NewTranslocatorClass;
		
		for (i=0; i<G.DefaultInventory.Length; i++)
		{
			if (ClassIsChildOf(G.DefaultInventory[i], ReplaceTranslocatorClass))
			{
				if (bReplaceTranslocator)
				{
					G.DefaultInventory[i] = NewTranslocatorClass;
					break;
				}
			}
		}

		if (NewTranslocatorClass != none && i >= G.DefaultInventory.Length && bAddToDefault)
		{
			G.DefaultInventory.AddItem(NewTranslocatorClass);
		}
	}
}

DefaultProperties
{
	bAddToDefault=false
	bReplaceTranslocator=true

	ReplaceTranslocatorClass=class'UTWeap_Translocator'
	NewTranslocatorClass=class'TestCWR_TranslocatorWeapon'
}

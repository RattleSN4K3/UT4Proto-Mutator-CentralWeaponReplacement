class TestCWRHelper extends Object;

static function SetActorStatic(class<Actor> ActorClass, bool bNewStatic)
{
	bNewStatic = ActorClass.default.bStatic;
	return;
}

static function SetActorNoDelete(class<Actor> ActorClass, bool bNewNoDelete)
{
	bNewNoDelete = ActorClass.default.bNoDelete;
	return;
}
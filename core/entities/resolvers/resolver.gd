extends RefCounted
class_name Resolver


## Weak reference to the entity this resolver resolves for, assigned at
## construction and never changed. Held weakly so the reference chain between
## an entity and its resolvers does not form a RefCounted cycle that would
## prevent entities from ever being freed.
var _entity: WeakRef

## The entity this resolver resolves for.
var entity: Entity:
	get:
		if _entity == null:
			return null
		return _entity.get_ref()


## Creates a new resolver bound to the given entity.
func _init(p_entity: Entity) -> void:
	_entity = weakref(p_entity)
extends Element
class_name Entity


## Static counter used as a temporary mechanism to guarantee that each
## entity has its own identity. Not a final architectural decision.
static var _next_id: int = 0

## Modules owned by this entity. Written only at construction.
var _modules: Modules

## Resolvers owned by this entity. Written only at construction.
var _resolvers: EntityResolvers

## The world this entity currently belongs to, or null.
## Written only by the World lifecycle methods through set_world coordination.
var _world: World = null


## Creates a new entity with an automatically assigned unique identifier.
func _init(p_name: String = "") -> void:
	super(_next_id, p_name)
	_next_id += 1
	_modules = Modules.new(self)
	_resolvers = EntityResolvers.new(self)


## Returns the modules facade owned by this entity.
func get_modules() -> Modules:
	return _modules


## Returns the resolvers facade owned by this entity.
func get_resolvers() -> EntityResolvers:
	return _resolvers


## Returns the world this entity currently belongs to, or null.
func get_world() -> World:
	return _world


## Changes the world this entity belongs to, coordinating the module transition.
## Detaches active modules while still in the old world, then attaches them in the new one.
func set_world(world: World) -> void:
	if world == _world:
		return
	if _world != null:
		_world.remove_entity(self)
	if world != null:
		world.register_entity(self)

extends RefCounted
class_name Area


## Emitted when an entity successfully enters this area.
signal entity_entered(entity: Entity)

## Emitted when an entity successfully exits this area.
signal entity_exited(entity: Entity)

## Optional callable filter evaluated at admission time.
## Receives the candidate entity and returns whether it may enter.
## Entities already inside are never revalidated against it.
var admission_filter: Callable = Callable()

## Entities currently inside this area.
var _entities: EntityHandler


## Creates a new area with its own entity collection.
func _init() -> void:
	_entities = EntityHandler.new()


## Returns true if the given entity may enter this area.
## Entities already inside cannot enter again. When an admission filter is set,
## it decides the outcome; otherwise any entity may enter.
func can_enter(entity: Entity) -> bool:
	if _entities.contains(entity.id):
		return false
	if admission_filter.is_valid():
		return admission_filter.call(entity)
	return true


## Adds an entity to this area and emits entity_entered.
## Returns false and rejects the entity when it is already inside
## or when the admission filter denies it.
func enter(entity: Entity) -> bool:
	if not can_enter(entity):
		push_error("Entity %d cannot enter this area" % entity.id)
		return false
	_entities.add_entity(entity)
	entity_entered.emit(entity)
	return true


## Removes an entity from this area and emits entity_exited.
## Ignored with an error when the entity is not inside this area.
func exit(entity: Entity) -> void:
	if not _entities.contains(entity.id):
		push_error("Entity %d is not inside this area" % entity.id)
		return
	_entities.remove_entity(entity)
	entity_exited.emit(entity)


## Returns true if the given entity is currently inside this area.
func has_entity(entity: Entity) -> bool:
	return _entities.contains(entity.id)


## Returns the entities currently inside this area.
func get_entities() -> Array[Entity]:
	return _entities.get_entities()
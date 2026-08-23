extends Handler
class_name EntityHandler


## Adds an entity to this handler.
func add_entity(entity: Entity) -> void:
	add(entity)


## Removes an entity from this handler.
func remove_entity(entity: Entity) -> void:
	remove(entity)


## Returns the entity with the given identifier, or null if it does not exist.
func get_entity(id: int) -> Entity:
	return lookup_by_id(id) as Entity


## Returns all entities in this handler.
func get_entities() -> Array[Entity]:
	var entities: Array[Entity] = []
	entities.assign(get_elements())
	return entities
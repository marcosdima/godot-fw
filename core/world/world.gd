extends RefCounted
class_name World


## Pipeline coordinating the phases of the world update cycle.
var _update_pipeline: UpdatePipeline


## Collection of entities belonging to this world.
## Lookup and membership operations belong to this handler; World does not mirror them.
var entity_handler: EntityHandler


## Creates a new world with its own update pipeline and entity collection.
func _init() -> void:
	_update_pipeline = UpdatePipeline.new()
	entity_handler = EntityHandler.new()


## Advances the world update cycle through the update pipeline.
func update() -> void:
	_update_pipeline.update()


## Spawns a new entity, registers it and returns it.
func spawn(p_name: String = "") -> Entity:
	var entity := Entity.new(p_name)
	register_entity(entity)
	return entity


## Registers an externally created entity in this world.
## Sets the entity's world, attaches its active modules, and ignores with an error
## entities whose id already exists here or that already belong to another world.
func register_entity(entity: Entity) -> void:
	if entity_handler.contains(entity.id):
		push_error("World already contains an entity with id %d" % entity.id)
		return
	if entity.get_world() != null and entity.get_world() != self:
		push_error("Entity %d already belongs to another world" % entity.id)
		return
	entity_handler.add_entity(entity)
	entity._world = self
	entity.get_modules().attach_all()


## Removes an entity from this world, detaching its active modules and clearing its world.
## Removal is ignored with an error if the entity does not belong to this world.
func remove_entity(entity: Entity) -> void:
	if entity.get_world() != self:
		push_error("Entity %d does not belong to this world" % entity.id)
		return
	entity.get_modules().detach_all()
	entity_handler.remove_entity(entity)
	entity._world = null


## Returns the update pipeline owned by this world.
func get_update_pipeline() -> UpdatePipeline:
	return _update_pipeline
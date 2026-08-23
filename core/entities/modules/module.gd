extends RefCounted
class_name Module


## The entity this module belongs to. Assigned at construction and never changed.
var entity: Entity


## Creates a new module bound to the given entity.
func _init(p_entity: Entity) -> void:
	entity = p_entity


## Called when the module becomes active or when its entity changes world context.
## Base implementation does nothing; concrete modules connect to what they need.
func attach() -> void:
	pass


## Called before the entity leaves its current world context.
## Base implementation does nothing; concrete modules disconnect from what they connected.
func detach() -> void:
	pass
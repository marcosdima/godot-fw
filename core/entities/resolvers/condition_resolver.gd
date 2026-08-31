extends RefCounted
class_name ConditionResolver


## The entity this resolver resolves for. Assigned at construction and never changed.
var entity: Entity


## Creates a new condition resolver bound to the given entity.
func _init(p_entity: Entity) -> void:
	entity = p_entity


## Resolves the given condition in the context of its entity and returns the
## condition to add, possibly modified, or null to reject it. Resolvers return
## results; they never add conditions to the state module themselves. The base
## implementation returns the condition unchanged.
func resolve(condition: Condition) -> Condition:
	return condition
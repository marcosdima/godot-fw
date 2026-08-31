extends RefCounted
class_name EffectResolver


## The entity this resolver resolves for. Assigned at construction and never changed.
var entity: Entity


## Creates a new effect resolver bound to the given entity.
func _init(p_entity: Entity) -> void:
	entity = p_entity


## Resolves the given effect in the context of its entity and returns the effect to
## apply, possibly modified, or null to reject it. Resolvers return results; they
## never apply effects themselves. The base implementation returns the effect unchanged.
func resolve(effect: Effect) -> Effect:
	return effect
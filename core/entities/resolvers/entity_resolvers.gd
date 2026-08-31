extends RefCounted
class_name EntityResolvers


## The entity these resolvers belong to. Assigned at construction and never changed.
var _entity: Entity

## Resolves effects before they modify the entity's status. Games replace this
## with a subclass to provide concrete resolution behavior.
var effect: EffectResolver

## Resolves conditions before they are added to the entity's state. Games replace
## this with a subclass to provide concrete resolution behavior.
var condition: ConditionResolver


## Creates the resolvers facade for the given entity.
func _init(p_entity: Entity) -> void:
	_entity = p_entity
	effect = EffectResolver.new(_entity)
	condition = ConditionResolver.new(_entity)
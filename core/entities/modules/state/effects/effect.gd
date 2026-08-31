extends RefCounted
class_name Effect


## Gameplay kind of this effect. Core stores this value without interpreting it;
## concrete kinds are defined by the game.
var kind: int

## Identifier of the attribute this effect targets.
var target: int

## Value applied to the attribute when this effect is applied.
var value: float


## Creates a new effect with the given kind, target identifier and value.
func _init(p_kind: int, p_target: int, p_value: float) -> void:
	kind = p_kind
	target = p_target
	value = p_value

extends RefCounted
class_name Effect


## Identifier of the attribute this effect targets.
var target: int

## Value applied to the attribute when this effect is applied.
var value: float


## Creates a new effect with the given target identifier and value.
func _init(p_target: int, p_value: float) -> void:
	target = p_target
	value = p_value

extends Element
class_name Modifier


## Additive contribution of this modifier to the effective value.
var value: float


## Creates a new modifier with the given identifier, name and value.
func _init(p_id: int, p_name: String, p_value: float) -> void:
	super(p_id, p_name)
	value = p_value
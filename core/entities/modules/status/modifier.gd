extends Element
class_name Modifier


## Identifier of the attribute this modifier applies to.
var attribute_id: int

## Additive contribution of this modifier to the effective value.
var value: float


## Creates a new modifier with the given identifier, name, target attribute identifier and value.
func _init(p_id: int, p_name: String, p_attribute_id: int, p_value: float) -> void:
	super(p_id, p_name)
	attribute_id = p_attribute_id
	value = p_value
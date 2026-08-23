extends RefCounted
class_name Element


## Unique identifier of this element.
var id: int

## Human-readable name of this element.
var name: String


## Creates a new element with the given identifier and name.
func _init(p_id: int, p_name: String) -> void:
	id = p_id
	name = p_name


## Returns the string representation of this element.
func _to_string() -> String:
	return "%s(%d)" % [name, id]
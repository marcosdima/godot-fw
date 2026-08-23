extends Element
class_name Entity


## Static counter used as a temporary mechanism to guarantee that each
## entity has its own identity. Not a final architectural decision.
static var _next_id: int = 0


## Creates a new entity with an automatically assigned unique identifier.
func _init(p_name: String = "") -> void:
	super(_next_id, p_name)
	_next_id += 1
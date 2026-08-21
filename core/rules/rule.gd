extends Element
class_name Rule


## Execution priority. Higher values execute first.
var priority: int


## Creates a new rule with the given identifier, name and priority.
func _init(p_id: int, p_name: String, p_priority: int = 0) -> void:
	super(p_id, p_name)
	priority = p_priority


## Evaluates the rule against the current conditions.
## May directly modify condition intensity. The base implementation does nothing.
func apply(conditions: Array[Condition]) -> void:
	pass
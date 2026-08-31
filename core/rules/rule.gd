extends Element
class_name Rule


## Identifier of the condition this rule acts upon.
var target: int

## Execution priority. Higher values execute first.
var priority: int


## Creates a new rule with the given identifier, name, priority and target condition.
func _init(p_id: int, p_name: String, p_priority: int, p_target_id: int) -> void:
	super(p_id, p_name)
	priority = p_priority
	target = p_target_id


## Evaluates the rule against the current conditions.
## May directly modify condition intensity. The base implementation does nothing.
func apply(conditions: Array[Condition]) -> void:
	pass
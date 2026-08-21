extends Rule
class_name CancelRule


## Creates a new cancel rule for the given target condition.
func _init(p_id: int, p_name: String, p_priority: int, p_target_id: int) -> void:
	super(p_id, p_name, p_priority, p_target_id)


## Brings the target condition intensity to zero.
func apply(conditions: Array[Condition]) -> void:
	for condition in conditions:
		if condition.id == target:
			condition.intensity = 0.0
extends Rule
class_name IdleRule


## Proportion of intensity removed per evaluation. 0.1 removes 10% per tick.
var factor: float


## Creates a new idle rule for the given target condition and factor.
func _init(p_id: int, p_name: String, p_priority: int, p_target_id: int, p_factor: float) -> void:
	super(p_id, p_name, p_priority, p_target_id)
	factor = p_factor


## Reduces the target condition intensity proportionally on every evaluation.
func apply(conditions: Array[Condition]) -> void:
	for condition in conditions:
		if condition.id == target:
			condition.intensity *= 1.0 - factor
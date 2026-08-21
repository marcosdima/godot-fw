extends Rule
class_name WeakenRule


## Identifier of the condition whose living presence enables this rule.
var presence: int

## Proportion of intensity removed per evaluation. 0.1 removes 10%.
var factor: float


## Creates a new weaken rule for the given target, presence condition and factor.
func _init(p_id: int, p_name: String, p_priority: int, p_target_id: int, p_presence_id: int, p_factor: float) -> void:
	super(p_id, p_name, p_priority, p_target_id)
	presence = p_presence_id
	factor = p_factor


## Reduces the target condition intensity proportionally while both conditions are present and alive.
func apply(conditions: Array[Condition]) -> void:
	var presence_alive := false
	var target_condition: Condition = null
	for condition in conditions:
		if condition.id == presence and condition.is_alive():
			presence_alive = true
		elif condition.id == target:
			target_condition = condition
	if presence_alive and target_condition != null:
		target_condition.intensity *= 1.0 - factor
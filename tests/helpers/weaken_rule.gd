extends Rule


## Identifier of the condition weakened by this rule.
var _target_id: int

## Identifier of the condition whose presence triggers this rule.
var _presence_id: int

## Factor applied to the target intensity when the presence condition exists.
var _factor: float


## Creates a new weaken rule for the given target, presence and factor.
func _init(p_id: int, p_name: String, p_priority: int, p_target_id: int, p_presence_id: int, p_factor: float) -> void:
	super(p_id, p_name, p_priority)
	_target_id = p_target_id
	_presence_id = p_presence_id
	_factor = p_factor


## Reduces the target condition intensity by the factor while the presence condition exists.
func apply(conditions: Array[Condition]) -> void:
	var has_presence := false
	var target: Condition = null
	for condition in conditions:
		if condition.id == _presence_id:
			has_presence = true
		elif condition.id == _target_id:
			target = condition
	if has_presence and target != null:
		target.intensity *= _factor
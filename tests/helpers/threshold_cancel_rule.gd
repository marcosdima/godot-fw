extends Rule


## Intensity at or below which the target condition is cancelled.
var _threshold: float


## Creates a new threshold cancel rule for the given target condition and threshold.
func _init(p_id: int, p_name: String, p_priority: int, p_target_id: int, p_threshold: float) -> void:
	super(p_id, p_name, p_priority, p_target_id)
	_threshold = p_threshold


## Brings the target condition intensity to zero while it is at or below the threshold.
func apply(conditions: Array[Condition]) -> void:
	for condition in conditions:
		if condition.id == target and condition.intensity <= _threshold:
			condition.intensity = 0.0
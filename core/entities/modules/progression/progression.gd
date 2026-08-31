extends RefCounted
class_name Progression


## Progression values keyed by their identifier.
var _progressions: Dictionary = {}


## Sets the value of the progression with the given identifier.
func set_value(progression_id: int, value: int) -> void:
	_progressions[progression_id] = value


## Returns the value of the progression with the given identifier, or 0 if it does not exist.
func get_value(progression_id: int) -> int:
	return _progressions.get(progression_id, 0)


## Returns true if a progression with the given identifier exists.
func contains(progression_id: int) -> bool:
	return _progressions.has(progression_id)


## Adds the given amount to the progression with the given identifier,
## creating it with that amount when it does not exist yet.
func advance(progression_id: int, amount: int = 1) -> void:
	_progressions[progression_id] = get_value(progression_id) + amount
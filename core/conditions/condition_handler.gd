extends Handler
class_name ConditionHandler


## Adds a condition to this handler.
func add_condition(condition: Condition) -> void:
	add(condition)


## Removes a condition from this handler.
func remove_condition(condition: Condition) -> void:
	remove(condition)


## Returns the condition with the given identifier, or null if it does not exist.
func get_condition(id: int) -> Condition:
	return lookup_by_id(id) as Condition


## Returns all conditions in this handler.
func get_conditions() -> Array[Condition]:
	var conditions: Array[Condition] = []
	conditions.assign(get_elements())
	return conditions
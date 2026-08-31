extends Handler
class_name RuleHandler


## Adds a rule to this handler.
func add_rule(rule: Rule) -> void:
	add(rule)


## Removes a rule from this handler.
func remove_rule(rule: Rule) -> void:
	remove(rule)


## Returns all rules in this handler, in registration order.
func get_rules() -> Array[Rule]:
	var rules: Array[Rule] = []
	rules.assign(get_elements())
	return rules


## Returns all rules sorted by descending priority, breaking ties by ascending identifier.
func get_rules_by_priority() -> Array[Rule]:
	var rules := get_rules()
	rules.sort_custom(_compare_by_priority)
	return rules


## Compares two rules by descending priority, breaking ties by ascending identifier.
func _compare_by_priority(a: Rule, b: Rule) -> bool:
	if a.priority != b.priority:
		return a.priority > b.priority
	return a.id < b.id
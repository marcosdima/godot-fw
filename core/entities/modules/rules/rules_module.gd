extends Module
class_name RulesModule


## Rules owned by this module, in registration order.
var _rules: Array[Rule] = []


## Creates a rules module bound to the given entity.
func _init(p_entity: Entity) -> void:
	super(p_entity)


## Registers a rule and subscribes it to the module facts it declares.
func add_rule(rule: Rule) -> void:
	if _rules.has(rule):
		return
	_rules.append(rule)
	rule.subscribe()


## Unregisters a rule and disconnects its subscriptions.
func remove_rule(rule: Rule) -> void:
	var index := _rules.find(rule)
	if index == -1:
		return
	_rules.remove_at(index)
	rule.unsubscribe()


## Returns a copy of the registered rules, in registration order.
func get_rules() -> Array[Rule]:
	return _rules.duplicate()
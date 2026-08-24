extends Module
class_name StateModule


## Current values of the entity's attributes.
var _status: Status

## Conditions acquired by the entity.
var _condition_handler: ConditionHandler

## Active effect applications and their processing.
var _effect_handler: EffectHandler

## Rules evaluated by this state module.
var _rule_handler: RuleHandler

## Identifiers of conditions whose effect applications are already registered.
var _activated_condition_ids: Dictionary = {}


## Creates a new state module bound to the given entity.
func _init(p_entity: Entity) -> void:
	super(p_entity)
	_status = Status.new()
	_condition_handler = ConditionHandler.new()
	_effect_handler = EffectHandler.new()
	_rule_handler = RuleHandler.new()


## Returns the pipeline phases this module participates in.
func _get_phase_callbacks() -> Array[PhaseCallback]:
	return [PhaseCallback.new(UpdatePipeline.Phase.STATE, tick)]


## Advances the state module by one tick.
func tick() -> void:
	_evaluate_rules()
	_remove_dead_conditions()
	_activate_new_conditions()
	_effect_handler.process(_status)


## Adds a condition to this state module.
func add_condition(condition: Condition) -> void:
	_condition_handler.add_condition(condition)


## Adds a rule to this state module.
func add_rule(rule: Rule) -> void:
	_rule_handler.add_rule(rule)


## Returns the rule handler of this state module.
func get_rule_handler() -> RuleHandler:
	return _rule_handler


## Returns the status of this state module.
func get_status() -> Status:
	return _status


## Returns the condition handler of this state module.
func get_condition_handler() -> ConditionHandler:
	return _condition_handler


## Returns the effect handler of this state module.
func get_effect_handler() -> EffectHandler:
	return _effect_handler


## Evaluates the rules of this state module in priority order.
func _evaluate_rules() -> void:
	for rule in _rule_handler.get_rules_by_priority():
		rule.apply(_condition_handler.get_conditions())


## Registers the effect applications of conditions that are alive but not yet activated.
func _activate_new_conditions() -> void:
	for condition in _condition_handler.get_conditions():
		if condition.is_alive() and not _activated_condition_ids.has(condition.id):
			_activated_condition_ids[condition.id] = true
			for application in condition.get_effect_applications():
				_effect_handler.add(application)


## Removes conditions that are no longer alive together with their registered applications.
func _remove_dead_conditions() -> void:
	for condition in _condition_handler.get_conditions():
		if not condition.is_alive():
			_effect_handler.remove_applications(condition.get_effect_applications())
			_condition_handler.remove_condition(condition)
			_activated_condition_ids.erase(condition.id)
extends RefCounted
class_name StateSystem


## Current values of the entity's attributes.
var _status: Status

## Conditions acquired by the entity.
var _condition_handler: ConditionHandler

## Active effect applications and their processing.
var _effect_handler: EffectHandler

## Identifiers of conditions whose effect applications are already registered.
var _activated_condition_ids: Dictionary = {}


## Creates a new state system with its own status, condition handler and effect handler.
func _init() -> void:
	_status = Status.new()
	_condition_handler = ConditionHandler.new()
	_effect_handler = EffectHandler.new()


## Advances the state system by one tick.
func tick() -> void:
	_activate_new_conditions()
	_effect_handler.process(_status)
	_remove_dead_conditions()


## Adds a condition to this state system.
func add_condition(condition: Condition) -> void:
	_condition_handler.add_condition(condition)


## Returns the status of this state system.
func get_status() -> Status:
	return _status


## Returns the condition handler of this state system.
func get_condition_handler() -> ConditionHandler:
	return _condition_handler


## Returns the effect handler of this state system.
func get_effect_handler() -> EffectHandler:
	return _effect_handler


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
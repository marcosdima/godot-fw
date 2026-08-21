extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }


func _create_state_system() -> StateSystem:
	var state_system := StateSystem.new()
	state_system.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return state_system


func _get_health(state_system: StateSystem) -> Attribute:
	return state_system.get_status().get_attribute(TestAttributeId.HEALTH)


func _create_burn_condition() -> Condition:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	return condition


func test_condition_applications_fire_repeatedly_across_ticks() -> void:
	var state_system := _create_state_system()
	state_system.add_condition(_create_burn_condition())
	state_system.tick()
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 90.0)


func test_instant_submission_applies_once() -> void:
	var state_system := _create_state_system()
	state_system.get_effect_handler().submit_instant(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 95.0)
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 95.0)
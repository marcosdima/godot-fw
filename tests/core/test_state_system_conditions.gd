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


func test_tick_activates_alive_condition_and_applies_its_effects() -> void:
	var state_system := _create_state_system()
	state_system.add_condition(_create_burn_condition())
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 95.0)


func test_dead_condition_is_not_activated() -> void:
	var state_system := _create_state_system()
	var condition := Condition.new(TestConditionId.BURN, "Burn", 0.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	state_system.add_condition(condition)
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 100.0)


func test_dead_condition_is_removed_without_being_activated() -> void:
	var state_system := _create_state_system()
	var condition := Condition.new(TestConditionId.BURN, "Burn", 0.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	state_system.add_condition(condition)
	state_system.tick()
	assert_null(state_system.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(_get_health(state_system).current_value, 100.0)


func test_dead_condition_is_removed_with_its_applications() -> void:
	var state_system := _create_state_system()
	var condition := _create_burn_condition()
	state_system.add_condition(condition)
	state_system.tick()
	condition.intensity = 0.0
	state_system.tick()
	assert_null(state_system.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(state_system.get_effect_handler().get_elements().size(), 0)
	var health_after_removal: float = _get_health(state_system).current_value
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, health_after_removal)
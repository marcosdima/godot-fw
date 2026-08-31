extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestEffectKind { FIRE }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }


func _create_state_module() -> StateModule:
	var state_module := StateModule.new(Entity.new("TestEntity"))
	state_module.entity.get_modules().status.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return state_module


func _get_health(state_module: StateModule) -> Attribute:
	return state_module.entity.get_modules().status.get_status().get_attribute(TestAttributeId.HEALTH)


func _create_burn_condition() -> Condition:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	return condition


func test_tick_activates_alive_condition_and_applies_its_effects() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, 95.0)


func test_dead_condition_is_not_activated() -> void:
	var state_module := _create_state_module()
	var condition := Condition.new(TestConditionId.BURN, "Burn", 0.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	state_module.add_condition(condition)
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, 100.0)


func test_dead_condition_is_removed_without_being_activated() -> void:
	var state_module := _create_state_module()
	var condition := Condition.new(TestConditionId.BURN, "Burn", 0.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	state_module.add_condition(condition)
	state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(_get_health(state_module).current_value, 100.0)


func test_dead_condition_is_removed_with_its_applications() -> void:
	var state_module := _create_state_module()
	var condition := _create_burn_condition()
	state_module.add_condition(condition)
	state_module.tick()
	condition.intensity = 0.0
	state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(state_module.get_effect_handler().get_elements().size(), 0)
	var health_after_removal: float = _get_health(state_module).current_value
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, health_after_removal)
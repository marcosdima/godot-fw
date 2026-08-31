extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH, MISSING }
enum TestEffectKind { FIRE }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }


func _create_state_module() -> StateModule:
	var state_module := StateModule.new(Entity.new("TestEntity"))
	state_module.entity.get_modules().status.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return state_module


func _create_burn_condition() -> Condition:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	return condition


func test_condition_added_is_emitted_with_the_stored_condition() -> void:
	var state_module := _create_state_module()
	watch_signals(state_module)
	var condition := _create_burn_condition()
	state_module.add_condition(condition)
	assert_signal_emitted_with_parameters(state_module, "condition_added", [condition])


func test_condition_removed_is_emitted_with_the_removed_condition() -> void:
	var state_module := _create_state_module()
	var condition := _create_burn_condition()
	state_module.add_condition(condition)
	watch_signals(state_module)
	condition.intensity = 0.0
	state_module.tick()
	assert_signal_emitted_with_parameters(state_module, "condition_removed", [condition])


func test_effect_applied_is_emitted_with_the_applied_effect() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	watch_signals(state_module)
	state_module.tick()
	assert_signal_emit_count(state_module, "effect_applied", 1)
	var parameters: Array = get_signal_parameters(state_module, "effect_applied")
	assert_eq(parameters[0].kind, TestEffectKind.FIRE)
	assert_eq(parameters[0].target, TestAttributeId.HEALTH)
	assert_eq(parameters[0].value, -5.0)


func test_effect_applied_is_not_emitted_when_the_target_is_missing() -> void:
	var state_module := _create_state_module()
	var condition := _create_burn_condition()
	var application := ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.MISSING, -5.0))
	condition.add_effect_application(application)
	state_module.add_condition(condition)
	watch_signals(state_module)
	state_module.tick()
	assert_signal_not_emitted(state_module, "effect_applied")
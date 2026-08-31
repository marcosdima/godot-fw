extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestEffectKind { FIRE }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }


var _entity: Entity


func _create_state_module() -> StateModule:
	_entity = Entity.new("TestEntity")
	_entity.modules.status.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return _entity.modules.state


func _get_health(state_module: StateModule) -> Attribute:
	return state_module.entity.modules.status.get_status().get_attribute(TestAttributeId.HEALTH)


func _create_burn_condition() -> Condition:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	return condition


func test_condition_applications_fire_repeatedly_across_ticks() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	state_module.tick()
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, 90.0)


func test_instant_submission_applies_once() -> void:
	var state_module := _create_state_module()
	state_module.get_effect_handler().submit_instant(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, 95.0)
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, 95.0)
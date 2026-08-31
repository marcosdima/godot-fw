extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestEffectKind { FIRE }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }


func _create_entity() -> Entity:
	var entity := Entity.new("TestEntity")
	entity.modules.status.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return entity


func _create_burn_condition() -> Condition:
	var burn := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	burn.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	return burn


func test_condition_flows_through_application_effect_and_resolver_into_status() -> void:
	var entity := _create_entity()
	var state := entity.modules.state
	state.add_condition(_create_burn_condition())
	state.tick()
	assert_eq(entity.modules.status.get_status().get_attribute(TestAttributeId.HEALTH).current_value, 95.0)


func test_condition_expires_on_its_own_without_rules() -> void:
	var entity := _create_entity()
	var state := entity.modules.state
	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 2.0, 0.1, 1.0))
	state.tick()
	state.tick()
	assert_null(state.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(entity.modules.status.get_status().get_attribute(TestAttributeId.HEALTH).current_value, 100.0)


func test_state_signals_report_what_happened() -> void:
	var entity := _create_entity()
	var state := entity.modules.state
	watch_signals(state)
	state.add_condition(_create_burn_condition())
	state.tick()
	assert_signal_emitted(state, "condition_added")
	assert_signal_emitted(state, "effect_applied")
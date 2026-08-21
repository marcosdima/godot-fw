extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")
const ThresholdCancelRule := preload("res://tests/helpers/threshold_cancel_rule.gd")


enum TestAttributeId { HEALTH }
enum TestConditionId { BURN, WET }
enum TestApplicationId { FIRE_DAMAGE }
enum TestRuleId { WEAKEN_BURN, CANCEL_BURN, HALF_BURN, THRESHOLD_CANCEL_BURN }


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


func test_instant_submission_applies_once() -> void:
	var state_system := _create_state_system()
	state_system.get_effect_handler().submit_instant(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 95.0)
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 95.0)


func test_rule_reduces_condition_intensity_during_tick() -> void:
	var state_system := _create_state_system()
	state_system.add_condition(_create_burn_condition())
	state_system.add_condition(Condition.new(TestConditionId.WET, "Wet", 10.0))
	state_system.add_rule(WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.5))
	state_system.tick()
	assert_eq(state_system.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 5.0)


func test_cancelled_condition_exits_before_its_applications_process() -> void:
	var state_system := _create_state_system()
	state_system.add_condition(_create_burn_condition())
	state_system.tick()
	assert_eq(_get_health(state_system).current_value, 95.0)
	state_system.add_rule(CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN))
	state_system.tick()
	assert_null(state_system.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(state_system.get_effect_handler().get_elements().size(), 0)
	assert_eq(_get_health(state_system).current_value, 95.0)


func test_higher_priority_modifications_are_visible_to_lower_priority_rules() -> void:
	var state_system := _create_state_system()
	state_system.add_condition(_create_burn_condition())
	state_system.add_condition(Condition.new(TestConditionId.WET, "Wet", 10.0))
	state_system.add_rule(WeakenRule.new(TestRuleId.HALF_BURN, "HalfBurn", 10, TestConditionId.BURN, TestConditionId.WET, 0.5))
	state_system.add_rule(ThresholdCancelRule.new(TestRuleId.THRESHOLD_CANCEL_BURN, "ThresholdCancelBurn", 5, TestConditionId.BURN, 8.0))
	state_system.tick()
	assert_null(state_system.get_condition_handler().get_condition(TestConditionId.BURN))


func test_rules_can_be_injected_from_external_collections() -> void:
	var state_system := _create_state_system()
	var external_rules: Array[Rule] = [CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN)]
	state_system.add_condition(_create_burn_condition())
	for rule in external_rules:
		state_system.add_rule(rule)
	state_system.tick()
	assert_null(state_system.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(_get_health(state_system).current_value, 100.0)

extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")
const ThresholdCancelRule := preload("res://tests/helpers/threshold_cancel_rule.gd")


enum TestAttributeId { HEALTH }
enum TestConditionId { BURN, WET }
enum TestApplicationId { FIRE_DAMAGE }
enum TestRuleId { WEAKEN_BURN, CANCEL_BURN, HALF_BURN, THRESHOLD_CANCEL_BURN }


func _create_state_module() -> StateModule:
	var state_module := StateModule.new(Entity.new("TestEntity"))
	state_module.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	return state_module


func _get_health(state_module: StateModule) -> Attribute:
	return state_module.get_status().get_attribute(TestAttributeId.HEALTH)


func _create_burn_condition() -> Condition:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	condition.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	return condition


func test_rule_reduces_condition_intensity_during_tick() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	state_module.add_condition(Condition.new(TestConditionId.WET, "Wet", 10.0))
	state_module.add_rule(WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.5))
	state_module.tick()
	assert_eq(state_module.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 5.0)


func test_cancelled_condition_exits_before_its_applications_process() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	state_module.tick()
	assert_eq(_get_health(state_module).current_value, 95.0)
	state_module.add_rule(CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN))
	state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(state_module.get_effect_handler().get_elements().size(), 0)
	assert_eq(_get_health(state_module).current_value, 95.0)


func test_higher_priority_modifications_are_visible_to_lower_priority_rules() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	state_module.add_condition(Condition.new(TestConditionId.WET, "Wet", 10.0))
	state_module.add_rule(WeakenRule.new(TestRuleId.HALF_BURN, "HalfBurn", 10, TestConditionId.BURN, TestConditionId.WET, 0.5))
	state_module.add_rule(ThresholdCancelRule.new(TestRuleId.THRESHOLD_CANCEL_BURN, "ThresholdCancelBurn", 5, TestConditionId.BURN, 8.0))
	state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))


func test_weakened_condition_is_removed_by_default_once_below_the_death_threshold() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(_create_burn_condition())
	state_module.add_condition(Condition.new(TestConditionId.WET, "Wet", 100.0))
	state_module.add_rule(WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.5))
	for i in 7:
		state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(state_module.get_effect_handler().get_elements().size(), 0)
	assert_eq(_get_health(state_module).current_value, 70.0)


func test_condition_with_zero_death_threshold_survives_proportional_decay() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0, 0.0))
	state_module.add_condition(Condition.new(TestConditionId.WET, "Wet", 100.0))
	state_module.add_rule(WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.5))
	for i in 30:
		state_module.tick()
	var condition := state_module.get_condition_handler().get_condition(TestConditionId.BURN)
	assert_not_null(condition)
	assert_true(condition.is_alive())


func test_rules_can_be_injected_from_external_collections() -> void:
	var state_module := _create_state_module()
	var external_rules: Array[Rule] = [CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN)]
	state_module.add_condition(_create_burn_condition())
	for rule in external_rules:
		state_module.add_rule(rule)
	state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_eq(_get_health(state_module).current_value, 100.0)
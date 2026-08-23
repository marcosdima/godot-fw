extends GutTest


enum TestConditionId { BURN, WET, POISON }
enum TestRuleId { IDLE_BURN, WEAKEN_BURN, CANCEL_BURN }


func _create_conditions() -> Array[Condition]:
	var conditions: Array[Condition] = [
		Condition.new(TestConditionId.BURN, "Burn", 10.0),
		Condition.new(TestConditionId.WET, "Wet", 10.0),
	]
	return conditions


func _get_condition(conditions: Array[Condition], id: int) -> Condition:
	for condition in conditions:
		if condition.id == id:
			return condition
	return null


func test_idle_rule_reduces_intensity_proportionally() -> void:
	var conditions := _create_conditions()
	var rule := IdleRule.new(TestRuleId.IDLE_BURN, "IdleBurn", 0, TestConditionId.BURN, 0.1)
	rule.apply(conditions)
	assert_almost_eq(_get_condition(conditions, TestConditionId.BURN).intensity, 9.0, 0.0001)


func test_idle_rule_with_full_factor_kills_the_condition() -> void:
	var conditions := _create_conditions()
	var rule := IdleRule.new(TestRuleId.IDLE_BURN, "IdleBurn", 0, TestConditionId.BURN, 1.0)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.BURN).intensity, 0.0)
	assert_false(_get_condition(conditions, TestConditionId.BURN).is_alive())


func test_idle_rule_only_affects_its_target() -> void:
	var conditions := _create_conditions()
	var rule := IdleRule.new(TestRuleId.IDLE_BURN, "IdleBurn", 0, TestConditionId.BURN, 0.1)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.WET).intensity, 10.0)


func test_idle_rule_is_a_no_op_when_target_is_absent() -> void:
	var conditions: Array[Condition] = [Condition.new(TestConditionId.WET, "Wet", 10.0)]
	var rule := IdleRule.new(TestRuleId.IDLE_BURN, "IdleBurn", 0, TestConditionId.BURN, 0.1)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.WET).intensity, 10.0)


func test_weaken_rule_reduces_intensity_when_both_conditions_are_alive() -> void:
	var conditions := _create_conditions()
	var rule := WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.1)
	rule.apply(conditions)
	assert_almost_eq(_get_condition(conditions, TestConditionId.BURN).intensity, 9.0, 0.0001)


func test_weaken_rule_does_nothing_when_presence_is_absent() -> void:
	var conditions: Array[Condition] = [Condition.new(TestConditionId.BURN, "Burn", 10.0)]
	var rule := WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.1)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.BURN).intensity, 10.0)


func test_weaken_rule_does_nothing_when_presence_is_not_alive() -> void:
	var conditions := _create_conditions()
	_get_condition(conditions, TestConditionId.WET).intensity = 0.0
	var rule := WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.1)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.BURN).intensity, 10.0)


func test_weaken_rule_is_a_no_op_when_target_is_absent() -> void:
	var conditions: Array[Condition] = [Condition.new(TestConditionId.WET, "Wet", 10.0)]
	var rule := WeakenRule.new(TestRuleId.WEAKEN_BURN, "WeakenBurn", 0, TestConditionId.BURN, TestConditionId.WET, 0.1)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.WET).intensity, 10.0)


func test_cancel_rule_brings_target_intensity_to_zero() -> void:
	var conditions := _create_conditions()
	var rule := CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.BURN).intensity, 0.0)
	assert_false(_get_condition(conditions, TestConditionId.BURN).is_alive())


func test_cancel_rule_only_affects_its_target() -> void:
	var conditions := _create_conditions()
	var rule := CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.WET).intensity, 10.0)


func test_cancel_rule_is_a_no_op_when_target_is_absent() -> void:
	var conditions: Array[Condition] = [Condition.new(TestConditionId.WET, "Wet", 10.0)]
	var rule := CancelRule.new(TestRuleId.CANCEL_BURN, "CancelBurn", 0, TestConditionId.BURN)
	rule.apply(conditions)
	assert_eq(_get_condition(conditions, TestConditionId.WET).intensity, 10.0)
extends GutTest


enum TestConditionId { BURN }
enum TestRuleId { WEAKEN, CANCEL, IDLE }


func test_stores_target_and_priority() -> void:
	var rule := Rule.new(TestRuleId.WEAKEN, "Weaken", 5, TestConditionId.BURN)
	assert_eq(rule.target, TestConditionId.BURN)
	assert_eq(rule.priority, 5)


func test_base_apply_is_a_safe_no_op() -> void:
	var rule := Rule.new(TestRuleId.WEAKEN, "Weaken", 0, TestConditionId.BURN)
	rule.apply([] as Array[Condition])
	assert_true(true)


func test_rule_handler_add_get_remove() -> void:
	var handler := RuleHandler.new()
	var rule := Rule.new(TestRuleId.WEAKEN, "Weaken", 0, TestConditionId.BURN)
	handler.add_rule(rule)
	assert_eq(handler.get_rules().size(), 1)
	handler.remove_rule(rule)
	assert_eq(handler.get_rules().size(), 0)


func test_get_rules_by_priority_sorts_descending() -> void:
	var handler := RuleHandler.new()
	var low := Rule.new(TestRuleId.IDLE, "Idle", 1, TestConditionId.BURN)
	var high := Rule.new(TestRuleId.CANCEL, "Cancel", 10, TestConditionId.BURN)
	handler.add_rule(low)
	handler.add_rule(high)
	var ordered := handler.get_rules_by_priority()
	assert_eq(ordered[0], high)
	assert_eq(ordered[1], low)


func test_equal_priorities_are_ordered_by_ascending_id() -> void:
	var handler := RuleHandler.new()
	var second := Rule.new(TestRuleId.CANCEL, "Cancel", 5, TestConditionId.BURN)
	var first := Rule.new(TestRuleId.WEAKEN, "Weaken", 5, TestConditionId.BURN)
	handler.add_rule(second)
	handler.add_rule(first)
	var ordered := handler.get_rules_by_priority()
	assert_eq(ordered[0], first)
	assert_eq(ordered[1], second)


func test_registration_order_does_not_affect_evaluation_order() -> void:
	var handler := RuleHandler.new()
	handler.add_rule(Rule.new(TestRuleId.IDLE, "Idle", 1, TestConditionId.BURN))
	handler.add_rule(Rule.new(TestRuleId.CANCEL, "Cancel", 10, TestConditionId.BURN))
	handler.add_rule(Rule.new(TestRuleId.WEAKEN, "Weaken", 5, TestConditionId.BURN))
	var ordered := handler.get_rules_by_priority()
	assert_eq(ordered[0].id, TestRuleId.CANCEL)
	assert_eq(ordered[1].id, TestRuleId.WEAKEN)
	assert_eq(ordered[2].id, TestRuleId.IDLE)
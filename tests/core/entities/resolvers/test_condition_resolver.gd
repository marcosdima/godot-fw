extends GutTest


enum TestConditionId { BURN, WET }


class RejectingBurnResolver extends ConditionResolver:
	func resolve(condition: Condition) -> Condition:
		if condition.id == TestConditionId.BURN:
			return null
		return condition


class DrenchingResolver extends ConditionResolver:
	func resolve(condition: Condition) -> Condition:
		if condition.id == TestConditionId.BURN:
			return Condition.new(TestConditionId.WET, "Wet", condition.intensity)
		return condition


func test_base_resolver_returns_the_condition_unchanged() -> void:
	var condition := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	var resolver := ConditionResolver.new(Entity.new("TestEntity"))
	assert_same(resolver.resolve(condition), condition)


func test_resolver_is_bound_to_its_entity() -> void:
	var entity := Entity.new("TestEntity")
	var resolver := ConditionResolver.new(entity)
	assert_same(resolver.entity, entity)


func test_entity_provides_a_condition_resolver() -> void:
	var entity := Entity.new("TestEntity")
	assert_same(entity.get_resolvers().condition.entity, entity)


func test_rejected_condition_is_not_added_and_signals_nothing() -> void:
	var entity := Entity.new("TestEntity")
	entity.get_resolvers().condition = RejectingBurnResolver.new(entity)
	var state := entity.get_modules().state
	watch_signals(state)
	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	assert_null(state.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_signal_not_emitted(state, "condition_added")


func test_modified_condition_is_added_instead_of_the_original() -> void:
	var entity := Entity.new("TestEntity")
	entity.get_resolvers().condition = DrenchingResolver.new(entity)
	var state := entity.get_modules().state
	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	assert_null(state.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_not_null(state.get_condition_handler().get_condition(TestConditionId.WET))


func test_condition_added_reports_the_resolved_condition() -> void:
	var entity := Entity.new("TestEntity")
	entity.get_resolvers().condition = DrenchingResolver.new(entity)
	var state := entity.get_modules().state
	watch_signals(state)
	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	var parameters: Array = get_signal_parameters(state, "condition_added")
	assert_eq(parameters[0].id, TestConditionId.WET)
extends GutTest


enum TestConditionId { BURN }


var _entity: Entity


func _create_state_module() -> StateModule:
	_entity = Entity.new("TestEntity")
	return _entity.modules.state


func test_condition_without_decay_remains_alive_indefinitely() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	for i in 20:
		state_module.tick()
	assert_not_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))


func test_condition_decays_by_its_decay_rate_each_tick() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0, 0.1, 1.0))
	state_module.tick()
	assert_almost_eq(state_module.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 9.0, 0.0001)


func test_condition_dies_when_decay_exhausts_its_intensity() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0, 0.1, 1.0))
	for i in 10:
		state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))


func test_condition_with_zero_death_threshold_survives_until_intensity_reaches_zero() -> void:
	var state_module := _create_state_module()
	state_module.add_condition(Condition.new(TestConditionId.BURN, "Burn", 1.0, 0.0, 0.3))
	state_module.tick()
	var condition := state_module.get_condition_handler().get_condition(TestConditionId.BURN)
	assert_almost_eq(condition.intensity, 0.7, 0.0001)
	assert_true(condition.is_alive())
	state_module.tick()
	state_module.tick()
	condition = state_module.get_condition_handler().get_condition(TestConditionId.BURN)
	assert_almost_eq(condition.intensity, 0.1, 0.0001)
	assert_true(condition.is_alive())
	state_module.tick()
	assert_null(state_module.get_condition_handler().get_condition(TestConditionId.BURN))
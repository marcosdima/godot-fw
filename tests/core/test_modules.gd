extends GutTest


enum TestConditionId { BURN }


func _create_entity() -> Entity:
	return Entity.new("TestEntity")


func test_no_modules_are_instantiated_by_default() -> void:
	var entity := _create_entity()
	assert_eq(entity.get_modules()._active.size(), 0)


func test_state_module_is_created_lazily_on_first_access() -> void:
	var entity := _create_entity()
	var state := entity.get_modules().state
	assert_not_null(state)
	assert_same(state, entity.get_modules().state)


func test_attach_runs_on_lazy_creation_even_without_world() -> void:
	var entity := _create_entity()
	assert_null(entity.get_world())
	entity.get_modules().state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	assert_true(true)


func test_state_persists_across_world_change() -> void:
	var entity := _create_entity()
	var world_a := World.new()
	var world_b := World.new()
	entity.set_world(world_a)
	entity.get_modules().state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	entity.set_world(world_b)
	assert_false(world_a.has_entity(entity.id))
	assert_true(world_b.has_entity(entity.id))
	assert_eq(entity.get_world(), world_b)
	var state := entity.get_modules().state
	assert_eq(state.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 10.0)
	state.tick()
	assert_eq(state.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 10.0)


func test_set_world_to_null_leaves_the_collection_and_clears_world() -> void:
	var entity := _create_entity()
	var world := World.new()
	entity.set_world(world)
	entity.set_world(null)
	assert_false(world.has_entity(entity.id))
	assert_null(entity.get_world())


func test_set_world_to_same_world_is_a_no_op() -> void:
	var entity := _create_entity()
	var world := World.new()
	entity.set_world(world)
	entity.set_world(world)
	assert_push_error_count(0, "same-world transition emits no errors")
	assert_eq(world.get_entities().size(), 1)


func test_cross_registration_is_rejected() -> void:
	var entity := _create_entity()
	var world_a := World.new()
	var world_b := World.new()
	entity.set_world(world_a)
	world_b.register_entity(entity)
	assert_push_error_count(1, "cross registration emits an error")
	assert_false(world_b.has_entity(entity.id))
	assert_eq(entity.get_world(), world_a)
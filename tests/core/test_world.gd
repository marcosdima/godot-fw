extends GutTest


func test_spawn_creates_registers_and_returns_entity() -> void:
	var world := World.new()
	var entity := world.spawn("Hero")
	assert_not_null(entity)
	assert_true(world.has_entity(entity.id))
	assert_eq(world.get_entity(entity.id), entity)
	assert_eq(world.get_entities().size(), 1)


func test_spawn_assigns_unique_ids() -> void:
	var world := World.new()
	var first := world.spawn("First")
	var second := world.spawn("Second")
	assert_ne(first.id, second.id)
	assert_eq(world.get_entities().size(), 2)


func test_register_adds_external_entity() -> void:
	var world := World.new()
	var entity := Entity.new("External")
	world.register_entity(entity)
	assert_true(world.has_entity(entity.id))
	assert_eq(world.get_entity(entity.id), entity)


func test_register_ignores_duplicate_id_with_error() -> void:
	var world := World.new()
	var entity := world.spawn("Hero")
	world.register_entity(entity)
	assert_push_error_count(1, "duplicate registration emits an error")
	assert_eq(world.get_entities().size(), 1)
	assert_eq(world.get_entity(entity.id), entity)


func test_remove_unregisters_entity() -> void:
	var world := World.new()
	var entity := world.spawn("Hero")
	world.remove_entity(entity)
	assert_false(world.has_entity(entity.id))
	assert_null(world.get_entity(entity.id))
	assert_eq(world.get_entities().size(), 0)


func test_update_runs_without_error() -> void:
	var world := World.new()
	world.update()
	assert_true(true)


func test_update_pipeline_is_owned_by_world() -> void:
	var world := World.new()
	assert_same(world.get_update_pipeline(), world.get_update_pipeline())
	world.get_update_pipeline().update()
	assert_true(true)


func test_entity_handler_is_owned_by_world() -> void:
	var world := World.new()
	assert_same(world.get_entity_handler(), world.get_entity_handler())
extends GutTest


func test_assigns_unique_incremental_ids() -> void:
	var first := Entity.new("First")
	var second := Entity.new("Second")
	assert_ne(first.id, second.id)
	assert_lt(first.id, second.id)


func test_keeps_identity_fields() -> void:
	var entity := Entity.new("Hero")
	assert_gte(entity.id, 0)
	assert_eq(entity.name, "Hero")


func test_ids_are_unique_across_worlds() -> void:
	var world_a := World.new()
	var world_b := World.new()
	var a := world_a.spawn("A")
	var b := world_b.spawn("B")
	assert_ne(a.id, b.id)


func test_entity_handler_add_get_remove() -> void:
	var handler := EntityHandler.new()
	var entity := Entity.new("Entity")
	handler.add_entity(entity)
	assert_eq(handler.get_entity(entity.id), entity)
	handler.remove_entity(entity)
	assert_null(handler.get_entity(entity.id))


func test_entity_handler_get_entities_returns_all() -> void:
	var handler := EntityHandler.new()
	handler.add_entity(Entity.new("First"))
	handler.add_entity(Entity.new("Second"))
	assert_eq(handler.get_entities().size(), 2)
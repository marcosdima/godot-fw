extends GutTest


func _create_entity() -> Entity:
	return Entity.new("TestEntity")


func _create_item() -> Object:
	return RefCounted.new()


func test_participates_in_no_pipeline_phase() -> void:
	var inventory := InventoryModule.new(_create_entity())
	assert_eq(inventory._get_phase_callbacks().size(), 0)


func test_module_is_created_lazily_and_reused() -> void:
	var entity := _create_entity()
	var inventory := entity.modules.inventory
	assert_not_null(inventory)
	assert_same(inventory, entity.modules.inventory)


func test_add_holds_the_item_and_emits_signal() -> void:
	var inventory := InventoryModule.new(_create_entity())
	var item := _create_item()
	watch_signals(inventory)
	assert_true(inventory.add(item))
	assert_true(inventory.has_item(item))
	assert_signal_emitted_with_parameters(inventory, "item_added", [item])


func test_add_rejects_an_item_already_held() -> void:
	var inventory := InventoryModule.new(_create_entity())
	var item := _create_item()
	inventory.add(item)
	watch_signals(inventory)
	assert_false(inventory.add(item))
	assert_push_error_count(1, "adding an item twice emits an error")
	assert_signal_not_emitted(inventory, "item_added")


func test_remove_drops_the_item_and_emits_signal() -> void:
	var inventory := InventoryModule.new(_create_entity())
	var item := _create_item()
	inventory.add(item)
	watch_signals(inventory)
	inventory.remove(item)
	assert_false(inventory.has_item(item))
	assert_signal_emitted_with_parameters(inventory, "item_removed", [item])


func test_remove_rejects_a_non_held_item() -> void:
	var inventory := InventoryModule.new(_create_entity())
	var item := _create_item()
	watch_signals(inventory)
	inventory.remove(item)
	assert_push_error_count(1, "removing a non held item emits an error")
	assert_signal_not_emitted(inventory, "item_removed")


func test_get_items_returns_insertion_order_of_distinct_instances() -> void:
	var inventory := InventoryModule.new(_create_entity())
	var first := _create_item()
	var second := _create_item()
	inventory.add(first)
	inventory.add(second)
	var items := inventory.get_items()
	assert_eq(items.size(), 2)
	assert_same(items[0], first)
	assert_same(items[1], second)


func test_get_items_returns_a_copy() -> void:
	var inventory := InventoryModule.new(_create_entity())
	var item := _create_item()
	inventory.add(item)
	var items := inventory.get_items()
	items.clear()
	assert_eq(inventory.get_items().size(), 1)
	assert_true(inventory.has_item(item))
extends GutTest


func _create_entity(p_name: String) -> Entity:
	return Entity.new(p_name)


func _create_node() -> Node2D:
	return Node2D.new()


func test_enter_adds_entity_returns_true_and_emits_signal() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	watch_signals(area)
	assert_true(area.enter(entity))
	assert_true(area.has_occupant(entity))
	assert_signal_emitted(area, "occupant_entered")
	assert_signal_emitted_with_parameters(area, "occupant_entered", [entity])


func test_enter_rejects_entity_already_inside() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	area.enter(entity)
	watch_signals(area)
	assert_false(area.enter(entity))
	assert_push_error_count(1, "duplicate entry emits an error")
	assert_signal_not_emitted(area, "occupant_entered")
	assert_eq(area.get_occupants().size(), 1)


func test_can_enter_is_false_when_already_inside() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	area.enter(entity)
	assert_false(area.can_enter(entity))


func test_exit_removes_entity_and_emits_signal() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	area.enter(entity)
	watch_signals(area)
	area.exit(entity)
	assert_false(area.has_occupant(entity))
	assert_signal_emitted(area, "occupant_exited")
	assert_signal_emitted_with_parameters(area, "occupant_exited", [entity])


func test_exit_rejects_entity_not_inside() -> void:
	var area := Area.new()
	var entity := _create_entity("Outsider")
	watch_signals(area)
	area.exit(entity)
	assert_push_error_count(1, "exiting a non member emits an error")
	assert_signal_not_emitted(area, "occupant_exited")


func test_has_occupant_reflects_membership() -> void:
	var area := Area.new()
	var insider := _create_entity("Insider")
	var outsider := _create_entity("Outsider")
	area.enter(insider)
	assert_true(area.has_occupant(insider))
	assert_false(area.has_occupant(outsider))


func test_get_occupants_returns_members() -> void:
	var area := Area.new()
	var first := _create_entity("First")
	var second := _create_entity("Second")
	area.enter(first)
	area.enter(second)
	var occupants := area.get_occupants()
	assert_eq(occupants.size(), 2)
	assert_same(occupants[0], first)
	assert_same(occupants[1], second)
	occupants.clear()
	assert_eq(area.get_occupants().size(), 2)


func test_without_filter_any_entity_may_enter() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	assert_true(area.can_enter(entity))
	assert_true(area.enter(entity))


func test_filter_denies_entry() -> void:
	var area := Area.new()
	area.admission_filter = func(_occupant: Object) -> bool: return false
	var entity := _create_entity("Hero")
	assert_false(area.can_enter(entity))
	watch_signals(area)
	assert_false(area.enter(entity))
	assert_push_error_count(1, "filtered entry emits an error")
	assert_signal_not_emitted(area, "occupant_entered")
	assert_false(area.has_occupant(entity))


func test_filter_receives_the_candidate_occupant() -> void:
	var area := Area.new()
	var received: Array[Object] = []
	area.admission_filter = func(occupant: Object) -> bool:
		received.append(occupant)
		return true
	var entity := _create_entity("Hero")
	area.enter(entity)
	assert_eq(received.size(), 1)
	assert_same(received[0], entity)


func test_filter_is_not_reapplied_to_occupants_already_inside() -> void:
	var area := Area.new()
	area.admission_filter = func(_occupant: Object) -> bool: return true
	var entity := _create_entity("Hero")
	area.enter(entity)
	area.admission_filter = func(_occupant: Object) -> bool: return false
	assert_true(area.has_occupant(entity))
	assert_eq(area.get_occupants().size(), 1)


func test_node_can_be_an_occupant() -> void:
	var area := Area.new()
	var node := _create_node()
	assert_true(area.enter(node))
	assert_true(area.has_occupant(node))
	assert_same(area.get_occupants()[0], node)
	area.exit(node)
	assert_false(area.has_occupant(node))
	node.free()


func test_entities_and_nodes_can_coexist_as_occupants() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	var node := _create_node()
	assert_true(area.enter(entity))
	assert_true(area.enter(node))
	var occupants := area.get_occupants()
	assert_eq(occupants.size(), 2)
	assert_same(occupants[0], entity)
	assert_same(occupants[1], node)
	node.free()


func test_object_identity_distinguishes_occupants() -> void:
	var area := Area.new()
	var first := _create_node()
	var second := _create_node()
	assert_true(area.enter(first))
	assert_true(area.enter(second))
	assert_eq(area.get_occupants().size(), 2)
	assert_false(area.enter(first))
	assert_push_error_count(1, "re-entering the same instance is rejected")
	assert_eq(area.get_occupants().size(), 2)
	area.exit(first)
	assert_true(area.has_occupant(second))
	assert_false(area.has_occupant(first))
	first.free()
	second.free()
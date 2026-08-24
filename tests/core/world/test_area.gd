extends GutTest


func _create_entity(p_name: String) -> Entity:
	return Entity.new(p_name)


func test_enter_adds_entity_returns_true_and_emits_signal() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	watch_signals(area)
	assert_true(area.enter(entity))
	assert_true(area.has_entity(entity))
	assert_signal_emitted(area, "entity_entered")
	assert_signal_emitted_with_parameters(area, "entity_entered", [entity])


func test_enter_rejects_entity_already_inside() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	area.enter(entity)
	watch_signals(area)
	assert_false(area.enter(entity))
	assert_push_error_count(1, "duplicate entry emits an error")
	assert_signal_not_emitted(area, "entity_entered")
	assert_eq(area.get_entities().size(), 1)


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
	assert_false(area.has_entity(entity))
	assert_signal_emitted(area, "entity_exited")
	assert_signal_emitted_with_parameters(area, "entity_exited", [entity])


func test_exit_rejects_entity_not_inside() -> void:
	var area := Area.new()
	var entity := _create_entity("Outsider")
	watch_signals(area)
	area.exit(entity)
	assert_push_error_count(1, "exiting a non member emits an error")
	assert_signal_not_emitted(area, "entity_exited")


func test_has_entity_reflects_membership() -> void:
	var area := Area.new()
	var insider := _create_entity("Insider")
	var outsider := _create_entity("Outsider")
	area.enter(insider)
	assert_true(area.has_entity(insider))
	assert_false(area.has_entity(outsider))


func test_get_entities_returns_members() -> void:
	var area := Area.new()
	var first := _create_entity("First")
	var second := _create_entity("Second")
	area.enter(first)
	area.enter(second)
	var entities := area.get_entities()
	assert_eq(entities.size(), 2)
	assert_same(entities[0], first)
	assert_same(entities[1], second)


func test_without_filter_any_entity_may_enter() -> void:
	var area := Area.new()
	var entity := _create_entity("Hero")
	assert_true(area.can_enter(entity))
	assert_true(area.enter(entity))


func test_filter_denies_entry() -> void:
	var area := Area.new()
	area.admission_filter = func(_entity: Entity) -> bool: return false
	var entity := _create_entity("Hero")
	assert_false(area.can_enter(entity))
	watch_signals(area)
	assert_false(area.enter(entity))
	assert_push_error_count(1, "filtered entry emits an error")
	assert_signal_not_emitted(area, "entity_entered")
	assert_false(area.has_entity(entity))


func test_filter_receives_the_candidate_entity() -> void:
	var area := Area.new()
	var received: Array[Entity] = []
	area.admission_filter = func(entity: Entity) -> bool:
		received.append(entity)
		return true
	var entity := _create_entity("Hero")
	area.enter(entity)
	assert_eq(received.size(), 1)
	assert_same(received[0], entity)


func test_filter_is_not_reapplied_to_entities_already_inside() -> void:
	var area := Area.new()
	area.admission_filter = func(_entity: Entity) -> bool: return true
	var entity := _create_entity("Hero")
	area.enter(entity)
	area.admission_filter = func(_entity: Entity) -> bool: return false
	assert_true(area.has_entity(entity))
	assert_eq(area.get_entities().size(), 1)
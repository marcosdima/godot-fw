extends GutTest


var _events: Array[String] = []


func _create_entity() -> Entity:
	return Entity.new("TestEntity")


func _create_interaction(name: String) -> Interaction:
	return Interaction.new(
		Callable(),
		func() -> void: _events.append(name + "_focused"),
		func() -> void: _events.append(name + "_unfocused")
	)


func test_add_focuses_first_interaction_when_none_focused() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	module.add(a)
	assert_same(module.get_focused(), a)
	assert_eq(_events, ["a_focused"] as Array[String])


func test_add_does_not_change_existing_focus() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	module.add(a)
	_events.clear()
	module.add(b)
	assert_same(module.get_focused(), a)
	assert_eq(_events.size(), 0)


func test_next_cycles_forward_with_wrap_around() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	var c := _create_interaction("c")
	module.add(a)
	module.add(b)
	module.add(c)
	module.next()
	assert_same(module.get_focused(), b)
	module.next()
	assert_same(module.get_focused(), c)
	module.next()
	assert_same(module.get_focused(), a)


func test_previous_cycles_backward_with_wrap_around() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	module.add(a)
	module.add(b)
	module.previous()
	assert_same(module.get_focused(), b)
	module.previous()
	assert_same(module.get_focused(), a)


func test_next_from_null_focuses_first_available() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	module.add(a)
	module.add(b)
	module.remove(a)
	module.next()
	assert_same(module.get_focused(), b)


func test_navigation_with_zero_interactions_is_a_no_op() -> void:
	var module := InteractionModule.new(_create_entity())
	module.next()
	module.previous()
	assert_null(module.get_focused())


func test_single_interaction_navigation_does_not_refire_callbacks() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	module.add(a)
	_events.clear()
	module.next()
	module.previous()
	assert_same(module.get_focused(), a)
	assert_eq(_events.size(), 0)


func test_execute_focused_calls_the_action() -> void:
	var executed := [false]
	var module := InteractionModule.new(_create_entity())
	module.add(Interaction.new(func() -> void: executed[0] = true))
	module.execute_focused()
	assert_true(executed[0])


func test_execute_without_focus_is_a_no_op() -> void:
	var executed := [false]
	var module := InteractionModule.new(_create_entity())
	module.add(Interaction.new(func() -> void: executed[0] = true))
	module.remove(module.get_interactions()[0])
	module.execute_focused()
	assert_false(executed[0])


func test_remove_focused_unfocuses_and_clears_focus() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	module.add(a)
	_events.clear()
	module.remove(a)
	assert_null(module.get_focused())
	assert_eq(_events, ["a_unfocused"] as Array[String])
	assert_eq(module.get_interactions().size(), 0)


func test_remove_non_focused_preserves_focus() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	module.add(a)
	module.add(b)
	module.remove(b)
	assert_same(module.get_focused(), a)
	assert_eq(module.get_interactions().size(), 1)


func test_duplicate_add_is_rejected() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	module.add(a)
	module.add(a)
	assert_push_error_count(1, "duplicate add emits an error")
	assert_eq(module.get_interactions().size(), 1)


func test_focus_unavailable_interaction_is_rejected() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var outside := _create_interaction("outside")
	module.add(a)
	module.focus(outside)
	assert_push_error_count(1, "focusing an unavailable interaction emits an error")
	assert_same(module.get_focused(), a)


func test_direct_focus_switch_fires_callbacks_in_order() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	module.add(a)
	module.add(b)
	_events.clear()
	module.focus(b)
	assert_eq(_events, ["a_unfocused", "b_focused"] as Array[String])
	assert_same(module.get_focused(), b)


func test_get_interactions_returns_same_instances_in_insertion_order() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	module.add(a)
	module.add(b)
	var interactions := module.get_interactions()
	assert_same(interactions[0], a)
	assert_same(interactions[1], b)
	interactions.clear()
	assert_eq(module.get_interactions().size(), 2)


func test_modules_facade_creates_interaction_module_lazily() -> void:
	var entity := _create_entity()
	var interaction_module := entity.get_modules().interaction
	assert_not_null(interaction_module)
	assert_same(interaction_module, entity.get_modules().interaction)


func test_shared_interaction_keeps_focus_independent_per_entity() -> void:
	var shared := _create_interaction("shared")
	var other := _create_interaction("other")
	var entity_a := _create_entity()
	var entity_b := _create_entity()
	var module_a := entity_a.get_modules().interaction
	var module_b := entity_b.get_modules().interaction
	module_a.add(shared)
	module_a.add(other)
	module_b.add(shared)
	assert_same(module_a.get_focused(), shared)
	assert_same(module_b.get_focused(), shared)
	module_a.focus(other)
	assert_same(module_a.get_focused(), other)
	assert_same(module_b.get_focused(), shared)

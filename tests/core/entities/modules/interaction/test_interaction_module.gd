extends GutTest


var _events: Array[String] = []
var _signal_events: Array[String] = []
var _focus_transitions: Array = []


func _create_entity() -> Entity:
	return Entity.new("TestEntity")


func _create_interaction(name: String) -> Interaction:
	return Interaction.new(
		Callable(),
		func() -> void: _events.append(name + "_focused"),
		func() -> void: _events.append(name + "_unfocused")
	)


func _create_action_interaction() -> Interaction:
	return Interaction.new(func() -> void: pass)


func _create_source() -> Object:
	return RefCounted.new()


func _watch_module_signals(module: InteractionModule) -> void:
	watch_signals(module)
	_signal_events.clear()
	_focus_transitions.clear()
	module.interaction_added.connect(_on_interaction_added)
	module.interaction_removed.connect(_on_interaction_removed)
	module.focused_changed.connect(_on_focused_changed)


func _on_interaction_added(_interaction: Interaction) -> void:
	_signal_events.append("added")


func _on_interaction_removed(_interaction: Interaction) -> void:
	_signal_events.append("removed")


func _on_focused_changed(previous: Interaction, current: Interaction) -> void:
	_focus_transitions.append([previous, current])
	_signal_events.append("focused")


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
	var interaction_module := entity.modules.interaction
	assert_not_null(interaction_module)
	assert_same(interaction_module, entity.modules.interaction)


func test_shared_interaction_keeps_focus_independent_per_entity() -> void:
	var shared := _create_interaction("shared")
	var other := _create_interaction("other")
	var entity_a := _create_entity()
	var entity_b := _create_entity()
	var module_a := entity_a.modules.interaction
	var module_b := entity_b.modules.interaction
	module_a.add(shared)
	module_a.add(other)
	module_b.add(shared)
	assert_same(module_a.get_focused(), shared)
	assert_same(module_b.get_focused(), shared)
	module_a.focus(other)
	assert_same(module_a.get_focused(), other)
	assert_same(module_b.get_focused(), shared)


func test_present_adds_the_offering_in_order() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	module.present(source, [a, b])
	var interactions := module.get_interactions()
	assert_eq(interactions.size(), 2)
	assert_same(interactions[0], a)
	assert_same(interactions[1], b)


func test_present_focuses_first_offered_when_nothing_focused() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	_events.clear()
	module.present(source, [a, b])
	assert_same(module.get_focused(), a)
	assert_eq(_events, ["a_focused"] as Array[String])


func test_presenting_multiple_sources_unions_without_interference() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	module.present(first, [a])
	module.present(second, [b])
	var interactions := module.get_interactions()
	assert_eq(interactions.size(), 2)
	assert_same(interactions[0], a)
	assert_same(interactions[1], b)


func test_representing_replaces_the_source_offering() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	module.present(source, [a, b])
	module.present(source, [c])
	var interactions := module.get_interactions()
	assert_eq(interactions.size(), 1)
	assert_same(interactions[0], c)


func test_presenting_empty_offering_retracts_the_source() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	module.present(source, [a])
	module.present(source, [])
	assert_null(module.get_focused())
	assert_eq(module.get_interactions().size(), 0)


func test_retract_removes_only_that_sources_interactions() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	module.present(first, [a])
	module.present(second, [b])
	module.retract(first)
	var interactions := module.get_interactions()
	assert_eq(interactions.size(), 1)
	assert_same(interactions[0], b)


func test_retract_unknown_source_is_an_idempotent_no_op() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_action_interaction()
	module.add(a)
	_watch_module_signals(module)
	module.retract(_create_source())
	assert_signal_not_emitted(module, "interaction_removed")
	assert_signal_not_emitted(module, "focused_changed")
	assert_eq(module.get_interactions().size(), 1)
	assert_same(module.get_interactions()[0], a)


func test_same_instance_from_two_sources_is_available_once() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var shared := _create_action_interaction()
	module.present(first, [shared])
	module.present(second, [shared])
	assert_eq(module.get_interactions().size(), 1)
	module.retract(first)
	assert_eq(module.get_interactions().size(), 1)
	module.retract(second)
	assert_eq(module.get_interactions().size(), 0)


func test_present_with_null_source_is_rejected() -> void:
	var module := InteractionModule.new(_create_entity())
	module.present(null, [])
	assert_push_error_count(1, "null source emits an error")
	assert_eq(module.get_interactions().size(), 0)


func test_replacement_preserving_focused_keeps_focus_without_refiring() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_interaction("a")
	var b := _create_interaction("b")
	var c := _create_interaction("c")
	module.present(source, [a, b])
	_watch_module_signals(module)
	_events.clear()
	module.present(source, [a, c])
	assert_same(module.get_focused(), a)
	assert_eq(_events.size(), 0)
	assert_signal_not_emitted(module, "focused_changed")
	assert_eq(_signal_events, ["removed", "added"] as Array[String])


func test_replacement_removing_focused_selects_first_available() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	module.present(source, [a, b])
	module.present(source, [c])
	assert_same(module.get_focused(), c)


func test_retract_removing_focused_selects_first_available() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	module.present(first, [a])
	module.present(second, [b])
	module.retract(first)
	assert_same(module.get_focused(), b)


func test_retract_removing_focused_with_nothing_left_unfocuses() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	module.present(source, [a])
	module.retract(source)
	assert_null(module.get_focused())


func test_present_after_focus_loss_focuses_first_available() -> void:
	var module := InteractionModule.new(_create_entity())
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	var d := _create_action_interaction()
	module.add(a)
	module.remove(a)
	module.add(b)
	module.remove(b)
	assert_null(module.get_focused())
	var source := _create_source()
	module.present(source, [c, d])
	assert_same(module.get_focused(), c)


func test_navigation_after_present_and_retract() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	module.present(first, [a, b])
	module.present(second, [c])
	module.next()
	assert_same(module.get_focused(), b)
	module.next()
	assert_same(module.get_focused(), c)
	module.next()
	assert_same(module.get_focused(), a)
	module.previous()
	assert_same(module.get_focused(), c)
	module.retract(second)
	module.next()
	assert_same(module.get_focused(), b)


func test_order_follows_source_arrival() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	module.present(first, [a, b])
	module.present(second, [c])
	var interactions := module.get_interactions()
	assert_eq(interactions.size(), 3)
	assert_same(interactions[0], a)
	assert_same(interactions[1], b)
	assert_same(interactions[2], c)


func test_replacement_keeps_kept_positions_and_appends_new() -> void:
	var module := InteractionModule.new(_create_entity())
	var first := _create_source()
	var second := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	var d := _create_action_interaction()
	module.present(first, [a, b])
	module.present(second, [c])
	module.present(first, [a, d])
	var interactions := module.get_interactions()
	assert_eq(interactions.size(), 3)
	assert_same(interactions[0], a)
	assert_same(interactions[1], c)
	assert_same(interactions[2], d)


func test_manual_add_survives_retract_of_source_presenting_same_instance() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var x := _create_action_interaction()
	module.add(x)
	module.present(source, [x])
	module.retract(source)
	assert_eq(module.get_interactions().size(), 1)
	assert_same(module.get_interactions()[0], x)
	assert_same(module.get_focused(), x)


func test_manual_add_after_present_survives_retract() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var x := _create_action_interaction()
	module.present(source, [x])
	module.add(x)
	module.retract(source)
	assert_eq(module.get_interactions().size(), 1)
	assert_same(module.get_interactions()[0], x)
	assert_same(module.get_focused(), x)


func test_remove_while_offered_keeps_interaction_and_emits_nothing() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var x := _create_action_interaction()
	module.present(source, [x])
	_watch_module_signals(module)
	module.remove(x)
	assert_signal_not_emitted(module, "interaction_removed")
	assert_eq(module.get_interactions().size(), 1)
	module.retract(source)
	assert_signal_emitted(module, "interaction_removed")
	assert_eq(module.get_interactions().size(), 0)
	assert_null(module.get_focused())


func test_manual_add_of_available_instance_does_not_emit_added() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var x := _create_action_interaction()
	module.present(source, [x])
	_watch_module_signals(module)
	module.add(x)
	assert_signal_not_emitted(module, "interaction_added")
	assert_eq(module.get_interactions().size(), 1)


func test_add_and_remove_emit_availability_signals() -> void:
	var module := InteractionModule.new(_create_entity())
	var x := _create_action_interaction()
	_watch_module_signals(module)
	module.add(x)
	assert_signal_emitted_with_parameters(module, "interaction_added", [x])
	module.remove(x)
	assert_signal_emitted_with_parameters(module, "interaction_removed", [x])
	assert_signal_emit_count(module, "focused_changed", 2)


func test_present_emits_added_per_new_interaction() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	_watch_module_signals(module)
	module.present(source, [a, b])
	assert_signal_emit_count(module, "interaction_added", 2)
	assert_signal_emit_count(module, "focused_changed", 1)
	assert_eq(_signal_events, ["added", "added", "focused"] as Array[String])


func test_replacement_emits_removed_then_added_then_focused_changed() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	var c := _create_action_interaction()
	module.present(source, [a, b])
	_watch_module_signals(module)
	module.present(source, [c])
	assert_eq(_signal_events, ["removed", "removed", "added", "focused"] as Array[String])
	assert_signal_emit_count(module, "interaction_removed", 2)
	assert_signal_emit_count(module, "interaction_added", 1)


func test_focused_changed_reports_previous_and_current() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	module.present(source, [a, b])
	_watch_module_signals(module)
	module.focus(b)
	assert_eq(_focus_transitions.size(), 1)
	assert_same(_focus_transitions[0][0], a)
	assert_same(_focus_transitions[0][1], b)


func test_no_signals_when_presenting_identical_offering() -> void:
	var module := InteractionModule.new(_create_entity())
	var source := _create_source()
	var a := _create_action_interaction()
	var b := _create_action_interaction()
	module.present(source, [a, b])
	_watch_module_signals(module)
	module.present(source, [a, b])
	assert_signal_not_emitted(module, "interaction_added")
	assert_signal_not_emitted(module, "interaction_removed")
	assert_signal_not_emitted(module, "focused_changed")
	assert_eq(_signal_events.size(), 0)

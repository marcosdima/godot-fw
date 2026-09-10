extends GutTest


func _playback(element: UIElement, definition: UIAnimationDefinition, time: float) -> UIAnimationPlayback:
	var playback := UIAnimationPlayback.new(element, definition)
	playback.set_time(time)
	return playback


func test_definition_rejects_non_animatable_property() -> void:
	var definition := UIAnimationDefinition.new()
	var result := definition.add_track(&"rotation", 1.0)
	assert_null(result)
	assert_push_error_count(1, "non-animatable property emits an error")
	assert_eq(definition.tracks.size(), 0)


func test_definition_accepts_animatable_property() -> void:
	var definition := UIAnimationDefinition.new()
	var track := definition.add_track(&"position", Vector2(10, 0))
	assert_not_null(track)
	assert_eq(definition.tracks.size(), 1)


func test_override_blends_towards_the_target() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"position", Vector2(10, 10))
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_eq(playback.value_for(&"position", Vector2.ZERO), Vector2(5, 5))


func test_add_blends_by_scaled_target() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"position", Vector2(2, 2), Track.Blend.ADD)
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_eq(playback.value_for(&"position", Vector2(1, 1)), Vector2(2, 2))


func test_multiply_blends_from_one_towards_the_target() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"scale", Vector2(2, 2), Track.Blend.MULTIPLY)
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_eq(playback.value_for(&"scale", Vector2.ONE), Vector2(1.5, 1.5))


func test_scalar_override_for_modulate() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"modulate", 0.0)
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_eq(playback.value_for(&"modulate", 1.0), 0.5)


func test_scalar_multiply_blends_from_one() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"modulate", 2.0, Track.Blend.MULTIPLY)
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_eq(playback.value_for(&"modulate", 1.0), 1.5)


func test_delay_holds_progress_at_zero() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.delay = 2.0
	definition.add_track(&"modulate", 0.0)
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 1.0)
	assert_eq(playback.value_for(&"modulate", 1.0), 1.0)


func test_ease_in_quadratic_progress() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.easing = UIAnimationDefinition.Easing.EASE_IN
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_almost_eq(playback.eased_progress(), 0.25, 0.001)


func test_ease_out_progress() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.easing = UIAnimationDefinition.Easing.EASE_OUT
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_almost_eq(playback.eased_progress(), 0.75, 0.001)


func test_loop_none_finishes_and_emits_finished() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"modulate", 0.0)
	var element: UIElement = UIElement.new(0, "element")
	var playback := UIAnimationPlayback.new(element, definition)
	watch_signals(playback)
	playback.advance(0.5)
	assert_false(playback.is_finished())
	playback.advance(0.5)
	assert_true(playback.is_finished())
	assert_signal_emitted(playback, "finished")
	assert_eq(playback.value_for(&"modulate", 1.0), 0.0)


func test_loop_restart_wraps_progress() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.loop = UIAnimationDefinition.Loop.RESTART
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 2.5)
	assert_almost_eq(playback.eased_progress(), 0.5, 0.001)


func test_loop_ping_pong_reverses_direction() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.loop = UIAnimationDefinition.Loop.PING_PONG
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 1.5)
	assert_almost_eq(playback.eased_progress(), 0.5, 0.001)


func test_ping_pong_forward_at_quarter() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.loop = UIAnimationDefinition.Loop.PING_PONG
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.25)
	assert_almost_eq(playback.eased_progress(), 0.25, 0.001)


func test_stop_emits_stopped_and_holds_final_state() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"modulate", 0.0)
	var element: UIElement = UIElement.new(0, "element")
	var playback := UIAnimationPlayback.new(element, definition)
	playback.advance(0.5)
	watch_signals(playback)
	playback.stop()
	assert_true(playback.is_finished())
	assert_signal_emitted(playback, "stopped")


func test_property_without_track_comes_back_unchanged() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"position", Vector2(10, 0))
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	assert_eq(playback.value_for(&"size", Vector2(100, 100)), Vector2(100, 100))


func test_tracks_apply_in_order_for_same_property() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	var size: UIElement = UIElement.new(0, "element")
	definition.add_track(&"position", Vector2(10, 0))
	definition.add_track(&"position", Vector2(2, 0), Track.Blend.ADD)
	var playback := _playback(size, definition, 0.5)
	var result := playback.value_for(&"position", Vector2(0, 0)) as Vector2
	assert_eq(result, Vector2(6, 0))


func test_value_for_never_mutates_the_element() -> void:
	var definition := UIAnimationDefinition.new()
	definition.duration = 1.0
	definition.add_track(&"position", Vector2(10, 10))
	definition.add_track(&"modulate", 0.0)
	var element: UIElement = UIElement.new(0, "element")
	var playback := _playback(element, definition, 0.5)
	playback.value_for(&"position", element.position)
	playback.value_for(&"modulate", element.modulate)
	assert_eq(element.position, Vector2.ZERO)
	assert_eq(element.modulate, 1.0)
extends GutTest


var _host: UIHost = null
var _app: AppUI = null


func before_each() -> void:
	_host = UIHost.new()
	add_child_autofree(_host)
	_host.set_process(false)
	_app = AppUI.compose(_host)


func after_each() -> void:
	if _app != null:
		_app.free()
		_app = null
	_host = null


func _press(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	_host._unhandled_input(event)


func _title_element() -> UIElement:
	return _host.get_current_screen().root.get_children()[0]


func _open_contracts() -> void:
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	_press(KEY_ENTER)


func test_screen_entry_animation_replays_on_reshow() -> void:
	await wait_frames(1)
	_host._process(0.6)
	assert_eq(_host.get_adapter().get_control(_title_element()).modulate.a, 1.0)
	_open_contracts()
	_press(KEY_ESCAPE)
	assert_eq(_host.get_current_screen().root.name, "main_root")
	var title := _host.get_adapter().get_control(_title_element()) as Control
	assert_eq(title.modulate.a, 0.0)
	_host._process(0.3)
	assert_gt(title.modulate.a, 0.0)
	assert_lt(title.modulate.a, 1.0)


func test_finished_screen_playback_is_reconnected_once_on_reshow() -> void:
	await wait_frames(1)
	var playback: UIAnimationPlayback = _host.get_current_screen().playbacks[0]
	_host._process(0.6)
	assert_eq(playback.finished.get_connections().size(), 0)
	assert_eq(playback.stopped.get_connections().size(), 0)
	_open_contracts()
	_press(KEY_ESCAPE)
	assert_eq(playback.finished.get_connections().size(), 1)
	for i in 3:
		_press(KEY_ENTER)
		_press(KEY_ESCAPE)
		assert_eq(
			playback.finished.get_connections().size(),
			1,
			"finished connections accumulated at reopen %d" % (i + 1),
		)
	assert_eq(playback.stopped.get_connections().size(), 1)


func test_screen_switch_disconnects_playback_signals() -> void:
	await wait_frames(1)
	var playback: UIAnimationPlayback = _host.get_current_screen().playbacks[0]
	_open_contracts()
	assert_eq(playback.finished.get_connections().size(), 0)
	assert_eq(playback.stopped.get_connections().size(), 0)


func test_finished_playback_removes_itself_and_disconnects() -> void:
	await wait_frames(1)
	var adapter := _host.get_adapter()
	var title := _title_element()
	title.modulate = 0.0
	adapter.build(_host.get_current_screen().root)
	var fade := UIAnimationDefinition.new()
	fade.duration = 0.2
	fade.add_track(&"modulate", 1.0)
	var playback := UIAnimationPlayback.new(title, fade)
	adapter.add_playback(playback)
	_host._process(0.2)
	assert_eq(adapter.get_control(title).modulate.a, 1.0)
	assert_eq(playback.finished.get_connections().size(), 0)
	assert_eq(playback.stopped.get_connections().size(), 0)


func test_stopped_playback_removes_itself_and_disconnects() -> void:
	await wait_frames(1)
	var adapter := _host.get_adapter()
	var title := _title_element()
	adapter.build(_host.get_current_screen().root)
	var fade := UIAnimationDefinition.new()
	fade.duration = 0.2
	fade.add_track(&"modulate", 1.0)
	var playback := UIAnimationPlayback.new(title, fade)
	adapter.add_playback(playback)
	playback.stop()
	assert_eq(playback.finished.get_connections().size(), 0)
	assert_eq(playback.stopped.get_connections().size(), 0)


func test_tick_iterates_a_safe_copy() -> void:
	await wait_frames(1)
	var adapter := _host.get_adapter()
	var root := _host.get_current_screen().root
	var title := root.get_children()[0]
	var play := root.get_children()[1]
	title.modulate = 0.0
	play.modulate = 0.0
	adapter.build(root)
	var short_definition := UIAnimationDefinition.new()
	short_definition.duration = 0.1
	short_definition.add_track(&"modulate", 1.0)
	var short := UIAnimationPlayback.new(title, short_definition)
	var long_definition := UIAnimationDefinition.new()
	long_definition.duration = 5.0
	long_definition.add_track(&"modulate", 1.0)
	var long := UIAnimationPlayback.new(play, long_definition)
	adapter.add_playback(short)
	adapter.add_playback(long)
	_host._process(0.1)
	assert_eq(adapter.get_control(title).modulate.a, 1.0)
	var long_alpha := adapter.get_control(play).modulate.a
	assert_gt(long_alpha, 0.0)
	assert_lt(long_alpha, 1.0)


func test_same_property_playbacks_are_last_registered_wins() -> void:
	await wait_frames(1)
	var adapter := _host.get_adapter()
	var title := _title_element()
	title.modulate = 0.0
	adapter.build(_host.get_current_screen().root)
	var pull := UIAnimationDefinition.new()
	pull.duration = 1.0
	pull.add_track(&"modulate", 1.0)
	var pump := UIAnimationDefinition.new()
	pump.duration = 1.0
	pump.add_track(&"modulate", 0.4, Track.Blend.ADD)
	adapter.add_playback(UIAnimationPlayback.new(title, pull))
	adapter.add_playback(UIAnimationPlayback.new(title, pump))
	_host._process(0.5)
	assert_almost_eq(adapter.get_control(title).modulate.a, 0.2, 0.001)


func test_overlap_winner_follows_registration_order() -> void:
	await wait_frames(1)
	var adapter := _host.get_adapter()
	var title := _title_element()
	title.modulate = 0.0
	adapter.build(_host.get_current_screen().root)
	var pull := UIAnimationDefinition.new()
	pull.duration = 1.0
	pull.add_track(&"modulate", 1.0)
	var pump := UIAnimationDefinition.new()
	pump.duration = 1.0
	pump.add_track(&"modulate", 0.4, Track.Blend.ADD)
	adapter.add_playback(UIAnimationPlayback.new(title, pump))
	adapter.add_playback(UIAnimationPlayback.new(title, pull))
	_host._process(0.5)
	assert_almost_eq(adapter.get_control(title).modulate.a, 0.5, 0.001)
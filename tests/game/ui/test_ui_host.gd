extends GutTest


var _host: UIHost = null


func before_each() -> void:
	_host = UIHost.new()
	add_child_autofree(_host)


func after_each() -> void:
	_host = null


func _press(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	_host._unhandled_input(event)


func _mouse_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.global_position = position
	_host._gui_input(event)


func _mouse_click(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.global_position = position
	_host._gui_input(event)


func _button_center(name: String) -> Vector2:
	var screen := _host.get_current_screen()
	var adapter := _host.get_adapter()
	for child in screen.root.get_children():
		if child.name == name:
			var control := adapter.get_control(child) as Control
			return control.get_global_rect().get_center()
	return Vector2.ZERO


func _prepare_geometry() -> void:
	_host.size = Vector2(800.0, 600.0)
	await wait_frames(2)
	var screen := _host.get_current_screen()
	_host.get_adapter().arrange(screen.root)


func test_host_starts_on_the_main_menu() -> void:
	await wait_frames(1)
	assert_not_null(_host.get_current_screen())
	var screen := _host.get_current_screen()
	assert_eq(screen.root.name, "main_root")
	assert_eq(_host.get_child_count(), 1)
	assert_eq(_host.get_child(0).get_child_count(), 4)


func test_input_navigates_the_selection_group() -> void:
	await wait_frames(1)
	var screen := _host.get_current_screen()
	var focus_order: Array[String] = []
	screen.group.focused_changed.connect(func(_p: UIElement, current: UIElement) -> void: focus_order.append(current.name))
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	assert_eq(focus_order, ["settings", "quit"])


func test_confirming_settings_pushes_the_settings_screen() -> void:
	await wait_frames(1)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	await wait_frames(1)
	var screen := _host.get_current_screen()
	assert_eq(screen.root.name, "settings_root")
	assert_eq(screen.root.get_children().back().name, "back")


func test_cancel_from_settings_returns_to_the_main_menu() -> void:
	await wait_frames(1)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	await wait_frames(1)
	_press(KEY_ESCAPE)
	await wait_frames(1)
	var screen := _host.get_current_screen()
	assert_eq(screen.root.name, "main_root")


func test_quit_button_invokes_quit_callback() -> void:
	var quitting := [false]
	var menu: UIScreen = UIMainMenu.build(func() -> void: pass, func() -> void: quitting[0] = true)
	menu.group.focus_first()
	menu.group.next()
	menu.group.next()
	(menu.group.get_focused() as UIButton).press()
	assert_true(quitting[0])


func test_mouse_hover_moves_focus_to_the_hovered_button() -> void:
	await wait_frames(1)
	await _prepare_geometry()
	var screen := _host.get_current_screen()
	_mouse_motion(_button_center("settings"))
	assert_same(screen.group.get_focused().name, "settings")


func test_mouse_click_activates_the_hovered_button() -> void:
	await wait_frames(1)
	await _prepare_geometry()
	_mouse_motion(_button_center("settings"))
	_mouse_click(_button_center("settings"))
	await wait_frames(1)
	var screen := _host.get_current_screen()
	assert_eq(screen.root.name, "settings_root")
	assert_eq(screen.root.get_children().back().name, "back")


func test_mouse_clicking_outside_a_button_does_not_activate() -> void:
	await wait_frames(1)
	await _prepare_geometry()
	var screen := _host.get_current_screen()
	var title := _host.get_adapter().get_control(screen.root.get_children()[0]) as Control
	_mouse_click(title.get_global_rect().get_center())
	assert_eq(screen.root.name, "main_root")


func test_play_button_is_inert_and_stays_on_main() -> void:
	await wait_frames(1)
	await _prepare_geometry()
	_mouse_motion(_button_center("play"))
	_mouse_click(_button_center("play"))
	await wait_frames(1)
	var screen := _host.get_current_screen()
	assert_eq(screen.root.name, "main_root")


func test_keyboard_navigates_and_activates_settings_rows() -> void:
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_eq(_host.get_current_screen().root.name, "settings_root")
	var screen := _host.get_current_screen()
	assert_eq(screen.group.get_focused().name, "volume_dec")
	for expected in ["volume_inc", "fullscreen", "resolution"]:
		_press(KEY_DOWN)
		assert_eq(screen.group.get_focused().name, expected, "expected %s focused" % expected)
	var resolution := screen.group.get_focused() as UIButton
	var control := _host.get_adapter().get_control(resolution) as Button
	assert_eq(control.text, "Resolution: 1280×720")
	_press(KEY_ENTER)
	assert_eq((resolution as UIButton).text, "Resolution: 1920×1080")
	assert_eq(control.text, "Resolution: 1920×1080")


func test_settings_values_persist_across_reopen() -> void:
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	var screen := _host.get_current_screen()
	var value := _host.get_adapter().get_control(_find_by_name(screen.root, "volume_value")) as Label
	assert_eq(value.text, "60%")
	screen.group.focus(_find_by_name(screen.root, "volume_inc"))
	(_find_by_name(screen.root, "volume_inc") as UIButton).press()
	assert_eq(value.text, "70%")
	_press(KEY_ESCAPE)
	assert_eq(_host.get_current_screen().root.name, "main_root")
	_press(KEY_ENTER)
	screen = _host.get_current_screen()
	value = _host.get_adapter().get_control(_find_by_name(screen.root, "volume_value")) as Label
	assert_eq(value.text, "70%")
	assert_eq(_host.get_child_count(), 1)


func test_repeated_open_close_keeps_one_root_control_and_single_highlight() -> void:
	_press(KEY_DOWN)
	for i in 3:
		_press(KEY_ENTER)
		_press(KEY_ESCAPE)
	assert_eq(_host.get_current_screen().root.name, "main_root")
	assert_eq(_host.get_child_count(), 1)
	var main_control := _host.get_adapter().get_control(_host.get_current_screen().root)
	assert_eq(main_control.get_child_count(), 4)


func _find_by_name(element: UIElement, name: String) -> UIElement:
	if element.name == name:
		return element
	for child in element.get_children():
		var found := _find_by_name(child, name)
		if found != null:
			return found
	return null
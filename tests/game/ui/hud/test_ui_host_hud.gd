extends GutTest


var _host: UIHost = null
var _app: AppUI = null
var _demo: HudDemo = null


func before_each() -> void:
	_host = UIHost.new()
	_demo = HudDemo.new()
	_host.add_child(_demo)
	add_child_autofree(_host)
	_app = AppUI.compose(_host)
	_demo.set_process(false)
	await get_tree().process_frame


func after_each() -> void:
	if _app != null:
		_app.free()
		_app = null
	_demo = null
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
	await get_tree().process_frame
	var screen := _host.get_current_screen()
	_host.get_adapter().arrange(screen.root)
	_host.get_hud_adapter().arrange(_demo.get_hud() as UIContainer)


func _hud_control() -> Control:
	return _host.get_hud_adapter().get_control(_demo.get_hud()) as Control


func test_hud_overlays_the_current_screen() -> void:
	var hud_control := _hud_control()
	assert_not_null(hud_control)
	assert_same(hud_control.get_parent(), _host)
	var screen_root := _host.get_adapter().get_control(_host.get_current_screen().root) as Control
	assert_gt(hud_control.z_index, screen_root.z_index)


func test_hud_survives_pushes_and_pops() -> void:
	var hud_control := _hud_control()
	assert_same(hud_control.get_parent(), _host)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	await get_tree().process_frame
	assert_eq(_host.get_current_screen().root.name, "settings_root")
	assert_same(hud_control.get_parent(), _host)
	_press(KEY_ESCAPE)
	await get_tree().process_frame
	assert_eq(_host.get_current_screen().root.name, "main_root")
	assert_same(hud_control.get_parent(), _host)
	for i in 2:
		_press(KEY_DOWN)
	_press(KEY_ENTER)
	await get_tree().process_frame
	assert_eq(_host.get_current_screen().root.name, "create_root")
	assert_same(hud_control.get_parent(), _host)


func test_overlay_reflects_demo_sync_through_the_adapter() -> void:
	_demo.step()
	var vitality := _host.get_hud_adapter().get_control(UIHud.find_id(_demo.get_hud(), UIHud.HudId.VITALITY_TEXT)) as Label
	assert_eq(vitality.text, "16/20")
	var fill := _host.get_hud_adapter().get_control(UIHud.find_id(_demo.get_hud(), UIHud.HudId.VITALITY_FILL)) as Control
	assert_eq(fill.size.x, UIHud.VITALITY_BAR_SIZE.x * 0.8)


func test_mouse_clicks_pass_through_the_hud() -> void:
	await _prepare_geometry()
	var screen := _host.get_current_screen()
	var settings := _find_by_name(screen.root, "settings")
	assert_same(_host.get_adapter().element_at(_button_center("settings")), settings)
	_mouse_motion(_button_center("settings"))
	_mouse_click(_button_center("settings"))
	await get_tree().process_frame
	assert_eq(_host.get_current_screen().root.name, "settings_root")


func test_resize_keeps_the_hud_pinned_top_left() -> void:
	await _prepare_geometry()
	var hud_control := _hud_control()
	assert_gt(hud_control.size.x, 0.0)
	var bar := _host.get_hud_adapter().get_control(UIHud.find_id(_demo.get_hud(), UIHud.HudId.VITALITY_BAR)) as Control
	assert_eq(bar.get_global_rect().position, UIHud.VITALITY_BAR_POSITION)
	_host.size = Vector2(400.0, 300.0)
	await get_tree().process_frame
	_host.get_hud_adapter().arrange(_demo.get_hud() as UIContainer)
	assert_eq(bar.get_global_rect().position, UIHud.VITALITY_BAR_POSITION)


func test_set_hud_replaces_the_overlay_keeping_a_single_control() -> void:
	var previous := _hud_control()
	_host.set_hud(UIHud.build())
	await get_tree().process_frame
	var huds: Array[Node] = []
	for child in _host.get_children():
		if child.name == "hud":
			huds.append(child)
	assert_eq(huds.size(), 1)
	assert_false(is_instance_valid(previous))


func _find_by_name(element: UIElement, name: String) -> UIElement:
	if element.name == name:
		return element
	for child in element.get_children():
		var found := _find_by_name(child, name)
		if found != null:
			return found
	return null
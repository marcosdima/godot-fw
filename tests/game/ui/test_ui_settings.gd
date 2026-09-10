extends GutTest


var _settings: AgentSettings = null
var _menu: UIScreen = null
var _back_pressed := [false]


func before_each() -> void:
	_settings = AgentSettings.new()
	_menu = UISettingsMenu.build(_settings, func() -> void: _back_pressed[0] = true)


func test_build_creates_the_expected_structure() -> void:
	var root := _menu.root as UIContainer
	assert_true(root.full_view)
	assert_eq(root.orientation, UIContainer.Orientation.COLUMN)
	var children := root.get_children()
	assert_eq(children[0].name, "title")
	assert_eq(children[1].name, "volume_row")
	assert_eq(children[2].name, "fullscreen")
	assert_eq(children[3].name, "resolution")
	assert_eq(children[4].name, "back")
	var volume_row := children[1] as UIContainer
	assert_eq(volume_row.orientation, UIContainer.Orientation.ROW)
	assert_eq(volume_row.get_children().size(), 3)


func test_group_covers_the_interactive_rows_in_order() -> void:
	var names: Array[String] = []
	for item in _menu.group.get_items():
		names.append(item.name)
	assert_eq(names, ["volume_dec", "volume_inc", "fullscreen", "resolution", "back"])


func test_initial_texts_reflect_the_default_settings() -> void:
	assert_eq(_find("fullscreen").text, "Fullscreen: Off")
	assert_eq(_find("resolution").text, "Resolution: 1280×720")
	assert_eq(_find("volume_value").text, "60%")


func test_fullscreen_toggle_updates_state_and_text() -> void:
	var row := _find("fullscreen") as UIButton
	_menu.group.focus(row)
	row.press()
	assert_true(_settings.fullscreen)
	assert_eq(row.text, "Fullscreen: On")
	row.press()
	assert_false(_settings.fullscreen)
	assert_eq(row.text, "Fullscreen: Off")


func test_resolution_cycles_and_wraps() -> void:
	var row := _find("resolution") as UIButton
	_menu.group.focus(row)
	row.press()
	assert_eq(_settings.resolution, 1)
	assert_eq(row.text, "Resolution: 1920×1080")
	row.press()
	assert_eq(_settings.resolution, 2)
	assert_eq(row.text, "Resolution: 2560×1440")
	row.press()
	assert_eq(_settings.resolution, 0)
	assert_eq(row.text, "Resolution: 1280×720")


func test_volume_stepper_adjusts_and_clamps_at_bounds() -> void:
	var dec := _find("volume_dec") as UIButton
	var inc := _find("volume_inc") as UIButton
	var value := _find("volume_value") as UIText
	_menu.group.focus(inc)
	inc.press()
	inc.press()
	assert_eq(_settings.volume, 80)
	assert_eq(value.text, "80%")
	_menu.group.focus(dec)
	for i in 9:
		dec.press()
	assert_eq(_settings.volume, 0)
	assert_eq(value.text, "0%")
	dec.press()
	assert_eq(_settings.volume, 0)


func test_back_button_invokes_the_callback() -> void:
	var back := _find("back") as UIButton
	_menu.group.focus(back)
	back.press()
	assert_true(_back_pressed[0])


func test_buttons_keep_a_font_color_distinct_from_the_surface() -> void:
	var adapter := UIControlAdapter.new()
	adapter.build(_menu.root)
	for button in _buttons_in(_menu.root):
		assert_false(
			button.style.font_color.is_equal_approx(Color.TRANSPARENT),
			"%s would fall back to the surface color" % button.name,
		)
		assert_false(
			button.style.font_color.is_equal_approx(button.style.color),
			"%s text matches its surface" % button.name,
		)
		var control := adapter.get_control(button) as Button
		assert_eq(control.get_theme_color("font_color"), button.style.font_color)
		assert_eq((control.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, button.style.color)


func _buttons_in(element: UIElement) -> Array[UIButton]:
	var buttons: Array[UIButton] = []
	if element is UIButton:
		buttons.append(element)
	for child in element.get_children():
		buttons.append_array(_buttons_in(child))
	return buttons


func _find(name: String) -> UIElement:
	var found := _find_in(_menu.root, name)
	assert_not_null(found, "element %s not found" % name)
	return found


func _find_in(element: UIElement, name: String) -> UIElement:
	if element.name == name:
		return element
	for child in element.get_children():
		var found := _find_in(child, name)
		if found != null:
			return found
	return null
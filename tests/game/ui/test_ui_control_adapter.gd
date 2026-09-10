extends GutTest


var _adapter: UIControlAdapter = null
var _main: UIScreen = null


func before_each() -> void:
	_adapter = UIControlAdapter.new()
	_main = UIMainMenu.build(func() -> void: pass, func() -> void: pass)


func after_each() -> void:
	_adapter.release()


func test_build_creates_one_control_per_element() -> void:
	var root_control := _adapter.build(_main.root)
	assert_not_null(root_control)
	assert_eq(_main.root.get_children().size(), 4)
	assert_eq(root_control.get_child_count(), 4)


func test_text_is_materialized_into_labels_and_buttons() -> void:
	var root_control := _adapter.build(_main.root)
	var child := root_control.get_child(0)
	assert_true(child is Label)
	assert_eq((child as Label).text, "Agents")
	var play := root_control.get_child(1)
	assert_true(play is Button)
	assert_eq((play as Button).text, "Play")


func test_property_change_reaches_the_control() -> void:
	_adapter.build(_main.root)
	var title: UIText = _main.root.get_children()[0]
	var root_control := _adapter.get_control(_main.root)
	var title_control := _adapter.get_control(title)
	title_control.visible = true
	title.visible = false
	assert_false(title_control.visible)
	title.position = Vector2(40, 40)
	assert_eq(title_control.position, Vector2(40, 40))


func test_button_text_change_reaches_the_control() -> void:
	_adapter.build(_main.root)
	var settings: UIButton = _main.root.get_children()[2]
	var control := _adapter.get_control(settings) as Button
	settings.text = "Preferences"
	assert_eq(control.text, "Preferences")


func test_highlight_applies_and_restores_button_style() -> void:
	_adapter.build(_main.root)
	var play: UIButton = _main.root.get_children()[1]
	_adapter.highlight(play)
	var control := _adapter.get_control(play) as Button
	assert_not_null(control.get_theme_stylebox("normal"))


func test_column_layout_stacks_children_vertically() -> void:
	_adapter.build(_main.root)
	var title: UIText = _main.root.get_children()[0]
	var play: UIButton = _main.root.get_children()[1]
	var title_control := _adapter.get_control(title) as Control
	var play_control := _adapter.get_control(play) as Control
	assert_lt(title_control.position.y, play_control.position.y)


func test_adapter_never_writes_measurement_back_to_model() -> void:
	_adapter.build(_main.root)
	var title: UIText = _main.root.get_children()[0]
	var before := title.position
	assert_eq(before, Vector2.ZERO)


func test_button_controls_are_input_agnostic() -> void:
	_adapter.build(_main.root)
	var play: UIButton = _main.root.get_children()[1]
	var control := _adapter.get_control(play) as Button
	assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(control.focus_mode, Control.FOCUS_NONE)


func test_button_styleboxes_are_ours_in_every_state() -> void:
	_adapter.build(_main.root)
	var play: UIButton = _main.root.get_children()[1]
	var control := _adapter.get_control(play) as Button
	for state in ["normal", "hover", "focus", "pressed"]:
		assert_not_null(control.get_theme_stylebox(state), "missing overrides for %s" % state)


func test_column_centers_children_in_a_sized_container() -> void:
	var root := UIContainer.new(0, "root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.separation = 4.0
	var a: UIButton = UIButton.new(1, "a")
	a.text = "Alfa"
	var b: UIButton = UIButton.new(2, "b")
	b.text = "Beta"
	root.add(a)
	root.add(b)
	var adapter := UIControlAdapter.new()
	var control := adapter.build(root)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.size = Vector2(600.0, 400.0)
	adapter.arrange(root)
	var a_control := adapter.get_control(a) as Control
	var b_control := adapter.get_control(b) as Control
	var total_height := a_control.size.y + 4.0 + b_control.size.y
	assert_almost_eq(a_control.position.x, (600.0 - a_control.size.x) * 0.5, 0.5)
	assert_almost_eq(b_control.position.x, (600.0 - b_control.size.x) * 0.5, 0.5)
	assert_almost_eq(b_control.position.y + b_control.size.y, (400.0 + total_height) * 0.5, 1.0)
	assert_eq(a.position, Vector2.ZERO)
	assert_eq(a.size, Vector2.ZERO)


func test_element_at_hit_tests_the_deepest_control() -> void:
	var root := UIContainer.new(0, "root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	var a: UIButton = UIButton.new(1, "a")
	a.text = "Alfa"
	var b: UIButton = UIButton.new(2, "b")
	b.text = "Beta"
	root.add(a)
	root.add(b)
	var adapter := UIControlAdapter.new()
	var control := adapter.build(root)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.size = Vector2(600.0, 400.0)
	adapter.arrange(root)
	var a_control := adapter.get_control(a) as Control
	var b_control := adapter.get_control(b) as Control
	assert_same(adapter.element_at(a_control.get_global_rect().get_center()), a)
	assert_same(adapter.element_at(b_control.get_global_rect().get_center()), b)
	assert_null(adapter.element_at(Vector2(-20.0, -20.0)))
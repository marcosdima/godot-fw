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
	assert_eq(_main.root.get_children().size(), 5)
	assert_eq(root_control.get_child_count(), 5)


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


func test_row_layout_places_children_horizontally() -> void:
	var root := UIContainer.new(0, "root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.ROW
	root.separation = 4.0
	var a: UIButton = UIButton.new(1, "a")
	a.text = "Alfa"
	var b: UIButton = UIButton.new(2, "b")
	b.text = "Beta"
	var c: UIButton = UIButton.new(3, "c")
	c.text = "Charlie"
	root.add(a)
	root.add(b)
	root.add(c)
	var adapter := UIControlAdapter.new()
	var control := adapter.build(root)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.size = Vector2(600.0, 200.0)
	adapter.arrange(root)
	var a_control := adapter.get_control(a) as Control
	var b_control := adapter.get_control(b) as Control
	var c_control := adapter.get_control(c) as Control
	assert_lt(a_control.position.x, b_control.position.x)
	assert_lt(b_control.position.x, c_control.position.x)
	var total_width := a_control.size.x + 4.0 + b_control.size.x + 4.0 + c_control.size.x
	assert_almost_eq(c_control.position.x + c_control.size.x, (600.0 + total_width) * 0.5, 1.0)
	assert_eq(a.position, Vector2.ZERO)


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


func test_text_change_relayouts_the_owning_row() -> void:
	var root := UIContainer.new(0, "root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.margin.set_all(8.0)
	var row := UIContainer.new(1, "row")
	row.orientation = UIContainer.Orientation.ROW
	row.separation = 4.0
	var dec: UIButton = UIButton.new(2, "dec")
	dec.text = "−"
	var value: UIText = UIText.new(3, "value")
	value.text = "90%"
	value.style.font_size = 20
	var inc: UIButton = UIButton.new(4, "inc")
	inc.text = "+"
	row.add(dec)
	row.add(value)
	row.add(inc)
	root.add(row)
	var adapter := UIControlAdapter.new()
	var control := adapter.build(root)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.size = Vector2(600.0, 200.0)
	adapter.arrange(root)
	var row_control := adapter.get_control(row) as Control
	var value_control := adapter.get_control(value) as Label
	var inc_control := adapter.get_control(inc) as Button
	var value_90 := value_control.size.x
	var row_90 := row_control.size.x
	value.text = "100%"
	assert_gt(adapter.get_control(row).size.x, row_90)
	assert_gt(value_control.size.x, value_90)
	assert_lt(value_control.position.x + value_control.size.x, inc_control.position.x)
	var inc_at_100 := inc_control.position.x
	value.text = "90%"
	assert_lt(inc_control.position.x, inc_at_100)


func test_nested_row_inside_column_is_sized_positioned_and_laid_out() -> void:
	var root := UIContainer.new(0, "root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.COLUMN
	root.separation = 4.0
	root.margin.set_all(8.0)
	var head: UIButton = UIButton.new(1, "head")
	head.text = "Alpha"
	root.add(head)
	var row := UIContainer.new(2, "row")
	row.orientation = UIContainer.Orientation.ROW
	row.separation = 4.0
	var dec: UIButton = UIButton.new(3, "dec")
	dec.text = "−"
	var value: UIText = UIText.new(4, "value")
	value.text = "100%"
	value.style.font_size = 20
	var inc: UIButton = UIButton.new(5, "inc")
	inc.text = "+"
	row.add(dec)
	row.add(value)
	row.add(inc)
	root.add(row)
	var tail: UIButton = UIButton.new(6, "tail")
	tail.text = "Back"
	root.add(tail)
	var adapter := UIControlAdapter.new()
	var control := adapter.build(root)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.size = Vector2(600.0, 400.0)
	adapter.arrange(root)
	var row_control := adapter.get_control(row) as Control
	var dec_control := adapter.get_control(dec) as Control
	var value_control := adapter.get_control(value) as Control
	var inc_control := adapter.get_control(inc) as Control
	assert_gt(row_control.size.x, 0.0)
	assert_gt(row_control.size.y, 0.0)
	var expected_width := dec_control.size.x + 4.0 + value_control.size.x + 4.0 + inc_control.size.x
	assert_almost_eq(row_control.size.x, expected_width, 1.0)
	assert_almost_eq(dec_control.size.x, dec_control.get_minimum_size().x, 0.5)
	assert_almost_eq(value_control.size.x, value_control.get_minimum_size().x, 0.5)
	assert_lt(dec_control.position.x, value_control.position.x)
	assert_lt(value_control.position.x, inc_control.position.x)
	assert_gt(row_control.position.y, 0.0)
	var slot_left := 8.0 + (600.0 - 16.0 - expected_width) * 0.5
	assert_almost_eq(row_control.position.x, slot_left, 1.0)
	assert_almost_eq(dec_control.position.y, (row_control.size.y - dec_control.size.y) * 0.5, 1.0)
	assert_eq(root.get_children()[1], row)
	assert_eq(row.size, Vector2.ZERO)
	assert_eq(row.position, Vector2.ZERO)
	assert_eq(dec.position, Vector2.ZERO)
	assert_eq(dec.size, Vector2.ZERO)
	assert_eq(value.position, Vector2.ZERO)
	assert_eq(value.size, Vector2.ZERO)
	assert_eq(inc.position, Vector2.ZERO)
	assert_eq(inc.size, Vector2.ZERO)


func test_input_materializes_as_a_display_only_line_edit() -> void:
	var input := UIInput.new(1, "field")
	input.text = "Marcos"
	input.placeholder = "Name"
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	assert_not_null(edit)
	assert_eq(edit.text, "Marcos")
	assert_eq(edit.placeholder_text, "Name")
	assert_false(edit.editable)
	assert_eq(edit.focus_mode, Control.FOCUS_NONE)
	assert_eq(edit.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_input_layout_uses_the_authored_size_in_a_row() -> void:
	var root := UIContainer.new(0, "root")
	root.full_view = true
	root.orientation = UIContainer.Orientation.ROW
	root.separation = 4.0
	var label := UIText.new(1, "label")
	label.text = "Name"
	label.size = Vector2(120.0, 36.0)
	var input := UIInput.new(2, "field")
	input.size = Vector2(320.0, 36.0)
	root.add(label)
	root.add(input)
	var adapter := UIControlAdapter.new()
	var control := adapter.build(root)
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.size = Vector2(600.0, 200.0)
	adapter.arrange(root)
	var label_control := adapter.get_control(label) as Control
	var input_control := adapter.get_control(input) as Control
	assert_eq(input_control.size, Vector2(320.0, 36.0))
	assert_gt(input_control.position.x, label_control.position.x + label_control.size.x)
	assert_almost_eq(input_control.position.y, (200.0 - 36.0) * 0.5, 1.0)
	assert_eq(input.size, Vector2(320.0, 36.0))
	assert_eq(input.position, Vector2.ZERO)


func test_input_property_changes_reach_the_control_when_inactive() -> void:
	var input := UIInput.new(1, "field")
	input.text = "First"
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	input.placeholder = "Hint"
	assert_eq(edit.placeholder_text, "Hint")
	input.text = "Second"
	assert_eq(edit.text, "Second")


func test_activate_input_makes_the_field_editable_and_focusable() -> void:
	var input := UIInput.new(1, "field")
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	_adapter.activate_input(input)
	assert_true(edit.editable)
	assert_eq(edit.focus_mode, Control.FOCUS_ALL)
	assert_eq(edit.mouse_filter, Control.MOUSE_FILTER_PASS)


func test_text_submitted_commits_and_reports_the_submit() -> void:
	var input := UIInput.new(1, "field")
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	var reports: Array = []
	_adapter.submitted.connect(func(element: UIElement, text: String) -> void: reports.append([element, text]))
	edit.text = "March"
	edit.emit_signal("text_submitted", "March")
	assert_eq(input.text, "March")
	assert_eq(reports.size(), 1)
	assert_same(reports[0][0], input)
	assert_eq(reports[0][1], "March")


func test_focus_exited_commits_the_draft_while_editing() -> void:
	var input := UIInput.new(1, "field")
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	_adapter.activate_input(input)
	edit.text = "typed but not submitted"
	edit.emit_signal("focus_exited")
	assert_eq(input.text, "typed but not submitted")


func test_deactivate_input_commits_and_restores_the_display_state() -> void:
	var input := UIInput.new(1, "field")
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	_adapter.activate_input(input)
	edit.text = "draft"
	_adapter.deactivate_input(input)
	assert_eq(input.text, "draft")
	assert_false(edit.editable)
	assert_eq(edit.focus_mode, Control.FOCUS_NONE)
	assert_eq(edit.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_cancel_input_restores_the_committed_value() -> void:
	var input := UIInput.new(1, "field")
	input.text = "Saved"
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	_adapter.activate_input(input)
	edit.text = "Unsaved"
	_adapter.cancel_input(input)
	assert_eq(input.text, "Saved")
	assert_eq(edit.text, "Saved")


func test_stale_focus_exited_after_cancel_does_not_recommit() -> void:
	var input := UIInput.new(1, "field")
	input.text = "Saved"
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	_adapter.activate_input(input)
	_adapter.cancel_input(input)
	edit.text = "SNEAK"
	edit.emit_signal("focus_exited")
	assert_eq(input.text, "Saved")


func test_input_font_color_takes_precedence_over_the_surface_color() -> void:
	var input := UIInput.new(1, "field")
	input.style.color = Color(0.1, 0.2, 0.3)
	input.style.font_color = Color(0.9, 0.95, 1.0)
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	assert_eq(edit.get_theme_color("font_color"), Color(0.9, 0.95, 1.0))
	assert_almost_eq(edit.get_theme_color("font_placeholder_color").a, 0.5, 0.01)


func test_surfaces_without_font_color_fall_back_to_the_surface_color() -> void:
	var label := UIText.new(1, "label")
	label.text = "x"
	label.style.color = Color(0.4, 0.5, 0.6)
	var root := UIContainer.new(0, "root")
	root.add(label)
	var label_control := _adapter.build(root).get_child(0) as Label
	assert_eq(label_control.get_theme_color("font_color"), Color(0.4, 0.5, 0.6))


func test_highlight_applies_a_lighter_stylebox_to_the_input() -> void:
	var input := UIInput.new(1, "field")
	var root := UIContainer.new(0, "root")
	root.add(input)
	var edit := _adapter.build(root).get_child(0) as LineEdit
	_adapter.highlight(input)
	assert_eq((edit.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, input.style.color.lightened(0.25))

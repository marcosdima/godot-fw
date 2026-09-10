extends GutTest


var _data: Array = []
var _submitted: Array = []
var _back_calls := 0


func before_each() -> void:
	_data = UIContractsMenu.CONTRACTS
	_submitted.clear()
	_back_calls = 0


func _build() -> UIScreen:
	return UIContractsMenu.build(
		_data,
		func(contract: Dictionary) -> void: _submitted.append(contract),
		func() -> void: _back_calls += 1,
	)


func _by_name(element: UIElement, name: String) -> UIElement:
	if element.name == name:
		return element
	for child in element.get_children():
		var found := _by_name(child, name)
		if found != null:
			return found
	return null


func _entry_name(index: int) -> String:
	return (_data[index].name as String).to_snake_case()


func test_build_creates_title_entries_status_and_footer() -> void:
	var screen := _build()
	assert_eq(screen.root.name, "contracts_root")
	assert_eq(screen.root.orientation, UIContainer.Orientation.COLUMN)
	var title := _by_name(screen.root, "title") as UIText
	assert_eq(title.text, "Contracts")
	assert_eq(title.style.font_size, 40)
	var status := _by_name(screen.root, "status") as UIText
	assert_not_null(status)
	assert_eq(status.text, "Selection: —")
	assert_eq(screen.root.get_children().size(), _data.size() + 3)
	var footer := _by_name(screen.root, "footer_row") as UIContainer
	assert_not_null(footer)
	assert_eq(footer.orientation, UIContainer.Orientation.ROW)
	assert_not_null(_by_name(footer, "footer_hint"))
	assert_not_null(_by_name(footer, "exit"))


func test_items_follow_the_source_data_order() -> void:
	var screen := _build()
	var buttons: Array[UIElement] = []
	for child in screen.root.get_children():
		if child is UIButton:
			buttons.append(child)
	assert_eq(buttons.size(), _data.size())
	for i in _data.size():
		assert_eq((buttons[i] as UIButton).text, _data[i].name)


func test_group_covers_entries_then_exit_in_order() -> void:
	var screen := _build()
	var names: Array[String] = []
	for item in screen.group.get_items():
		names.append(item.name)
	assert_eq(names.size(), _data.size() + 1)
	for i in _data.size():
		assert_eq(names[i], _entry_name(i))
	assert_eq(names.back(), "exit")


func test_group_navigation_wraps_forward_and_backward() -> void:
	var screen := _build()
	screen.group.focus_first()
	assert_eq(screen.group.get_focused().name, _entry_name(0))
	var visited: Array[String] = []
	for i in _data.size():
		visited.append(screen.group.get_focused().name)
		screen.group.next()
	assert_eq(visited.back(), _entry_name(_data.size() - 1))
	assert_eq(screen.group.get_focused().name, "exit")
	screen.group.next()
	assert_eq(screen.group.get_focused().name, _entry_name(0))
	screen.group.previous()
	assert_eq(screen.group.get_focused().name, "exit")


func test_status_follows_selection_changes() -> void:
	var screen := _build()
	var status := _by_name(screen.root, "status") as UIText
	screen.group.focus_first()
	assert_eq(status.text, "Selection: %s — %s" % [_data[0].name, _data[0].desc])
	screen.group.focus(screen.group.get_items()[2])
	assert_eq(status.text, "Selection: %s — %s" % [_data[2].name, _data[2].desc])
	screen.group.focus(_by_name(screen.root, "exit"))
	assert_eq(status.text, "Selection: —")


func test_enter_presses_the_focused_entry_and_submits_it() -> void:
	var screen := _build()
	screen.group.focus_first()
	(screen.group.get_focused() as UIButton).press()
	assert_eq(_submitted.size(), 1)
	assert_eq(_submitted[0], _data[0])
	screen.group.focus(screen.group.get_items()[2])
	(screen.group.get_focused() as UIButton).press()
	assert_eq(_submitted.size(), 2)
	assert_eq(_submitted[1], _data[2])


func test_exit_presses_the_back_callback() -> void:
	var screen := _build()
	(_by_name(screen.root, "exit") as UIButton).press()
	assert_eq(_back_calls, 1)


func test_long_entry_drives_the_column_width_via_natural_size() -> void:
	var adapter := UIControlAdapter.new()
	var screen := _build()
	var root_control := adapter.build(screen.root)
	root_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_control.size = Vector2(800.0, 600.0)
	adapter.arrange(screen.root)
	var widest := 0.0
	var widest_button: UIButton = null
	for child in screen.root.get_children():
		if child is UIButton:
			var width := (adapter.get_control(child) as Control).size.x
			if width > widest:
				widest = width
				widest_button = child
	assert_not_null(widest_button)
	assert_eq((widest_button as UIButton).text, "Containment Breach Extract the S 2 Prototype Unit")
	adapter.release()


func test_status_text_change_relayouts_the_screen_tree() -> void:
	var adapter := UIControlAdapter.new()
	var screen := _build()
	var root_control := adapter.build(screen.root)
	root_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_control.size = Vector2(800.0, 600.0)
	adapter.arrange(screen.root)
	var status := _by_name(screen.root, "status")
	var status_control := adapter.get_control(status) as Control
	var status_x_before := status_control.position.x
	screen.group.focus_first()
	var status_x_after := status_control.position.x
	assert_ne(status_x_after, status_x_before)
	var width_at_first := status_control.size.x
	screen.group.focus(screen.group.get_items()[6])
	assert_gt(status_control.size.x, width_at_first)
	adapter.release()


func test_many_entries_overflow_the_viewport_bottom() -> void:
	var data: Array = UIContractsMenu.CONTRACTS.duplicate()
	for i in 12:
		data.append({ "name": "Overflow Agent %d" % i, "desc": "synthetic overflow row" })
	var adapter := UIControlAdapter.new()
	var screen := UIContractsMenu.build(data, func(_c: Dictionary) -> void: pass, func() -> void: pass)
	var root_control := adapter.build(screen.root)
	root_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root_control.size = Vector2(800.0, 648.0)
	adapter.arrange(screen.root)
	var last := _by_name(screen.root, "overflow_agent_11") as UIButton
	assert_not_null(last)
	var last_control := adapter.get_control(last) as Control
	assert_gt(last_control.position.y + last_control.size.y, 648.0)
	adapter.release()
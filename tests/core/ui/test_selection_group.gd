extends GutTest


var _transitions: Array = []


func _on_focused_changed(previous: UIElement, current: UIElement) -> void:
	_transitions.append([previous, current])


func _watch_group(group: SelectionGroup) -> void:
	watch_signals(group)
	_transitions.clear()
	group.focused_changed.connect(_on_focused_changed)


func _create_button(id: int, name: String) -> UIButton:
	return UIButton.new(id, name)


func test_empty_group_has_no_focus() -> void:
	var group := SelectionGroup.new()
	assert_null(group.get_focused())
	assert_true(group.get_items().is_empty())


func test_add_does_not_auto_focus() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	group.add(a)
	assert_null(group.get_focused())


func test_focus_first_focuses_the_first_element() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	_watch_group(group)
	group.focus_first()
	assert_same(group.get_focused(), a)
	assert_eq(_transitions, [[null, a]])


func test_focus_first_on_empty_group_stays_null() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	group.add(a)
	group.focus_first()
	group.remove(a)
	_watch_group(group)
	group.focus_first()
	assert_null(group.get_focused())
	assert_signal_not_emitted(group, "focused_changed")


func test_next_cycles_forward_with_wrap_around() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	var c: UIButton = _create_button(2, "c")
	group.add(a)
	group.add(b)
	group.add(c)
	group.focus_first()
	group.next()
	assert_same(group.get_focused(), b)
	group.next()
	assert_same(group.get_focused(), c)
	group.next()
	assert_same(group.get_focused(), a)


func test_previous_cycles_backward_with_wrap_around() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	group.focus_first()
	group.previous()
	assert_same(group.get_focused(), b)


func test_next_from_no_focus_focuses_first() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	_watch_group(group)
	group.next()
	assert_same(group.get_focused(), a)


func test_navigation_with_empty_group_is_a_no_op() -> void:
	var group := SelectionGroup.new()
	_watch_group(group)
	group.next()
	group.previous()
	assert_signal_not_emitted(group, "focused_changed")


func test_single_element_navigation_does_not_refire() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	group.add(a)
	group.focus_first()
	_watch_group(group)
	group.next()
	group.previous()
	assert_same(group.get_focused(), a)
	assert_signal_not_emitted(group, "focused_changed")


func test_focus_unavailable_element_emits_error_and_is_rejected() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var outside: UIButton = _create_button(1, "outside")
	group.add(a)
	group.focus_first()
	_watch_group(group)
	group.focus(outside)
	assert_push_error_count(1, "focusing a non-member emits an error")
	assert_same(group.get_focused(), a)


func test_focus_reports_previous_and_current() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	group.focus_first()
	_watch_group(group)
	group.focus(b)
	assert_same(group.get_focused(), b)
	assert_eq(_transitions, [[a, b]])


func test_focusing_same_element_is_a_no_op() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	group.add(a)
	group.focus_first()
	_watch_group(group)
	group.focus(a)
	assert_signal_not_emitted(group, "focused_changed")


func test_remove_focused_clears_focus() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	group.focus_first()
	_watch_group(group)
	group.remove(a)
	assert_null(group.get_focused())
	assert_same(group.get_focused(), null)


func test_remove_non_focused_preserves_focus() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	group.focus_first()
	_watch_group(group)
	group.remove(b)
	assert_same(group.get_focused(), a)
	assert_signal_not_emitted(group, "focused_changed")


func test_duplicate_add_emits_error() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	group.add(a)
	group.add(a)
	assert_push_error_count(1, "duplicate add emits an error")
	assert_eq(group.get_items().size(), 1)


func test_get_items_returns_copy_in_insertion_order() -> void:
	var group := SelectionGroup.new()
	var a: UIButton = _create_button(0, "a")
	var b: UIButton = _create_button(1, "b")
	group.add(a)
	group.add(b)
	var items := group.get_items()
	assert_same(items[0], a)
	assert_same(items[1], b)
	items.clear()
	assert_eq(group.get_items().size(), 2)
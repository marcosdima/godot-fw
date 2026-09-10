extends GutTest


func test_defaults_are_neutral() -> void:
	var container: UIContainer = UIContainer.new(0, "root")
	assert_eq(container.orientation, UIContainer.Orientation.COLUMN)
	assert_eq(container.separation, 0)
	assert_false(container.full_view)
	assert_eq(container.margin.get_left(), 0.0)


func test_orientation_setter_emits_changed() -> void:
	var container: UIContainer = UIContainer.new(0, "root")
	watch_signals(container)
	container.orientation = UIContainer.Orientation.ROW
	assert_signal_emitted_with_parameters(container, "changed", [&"orientation"])


func test_assigning_same_orientation_does_not_emit_changed() -> void:
	var container: UIContainer = UIContainer.new(0, "root")
	watch_signals(container)
	container.orientation = UIContainer.Orientation.ROW
	container.orientation = UIContainer.Orientation.ROW
	assert_signal_emit_count(container, "changed", 1)


func test_full_view_setter_emits_changed() -> void:
	var container: UIContainer = UIContainer.new(0, "root")
	watch_signals(container)
	container.full_view = true
	assert_signal_emitted_with_parameters(container, "changed", [&"full_view"])


func test_child_tree_inherited_from_ui_element() -> void:
	var container: UIContainer = UIContainer.new(0, "root")
	var child: UIElement = UIElement.new(1, "child")
	container.add(child)
	assert_same(child.parent, container)
	assert_eq(container.get_children().size(), 1)
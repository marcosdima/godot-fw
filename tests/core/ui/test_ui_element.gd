extends GutTest


var _child_events: Array[String] = []
var _property_events: Array[StringName] = []


func _on_child_added(_child: UIElement) -> void:
	_child_events.append("added")


func _on_child_removed(_child: UIElement) -> void:
	_child_events.append("removed")


func _on_changed(property: StringName) -> void:
	_property_events.append(property)


func _watch_element(element: UIElement) -> void:
	watch_signals(element)
	_child_events.clear()
	_property_events.clear()
	element.child_added.connect(_on_child_added)
	element.child_removed.connect(_on_child_removed)
	element.changed.connect(_on_changed)


func test_add_appends_child_and_sets_parent() -> void:
	var root: UIElement = UIElement.new(0, "root")
	var child: UIElement = UIElement.new(1, "child")
	_watch_element(root)
	root.add(child)
	assert_same(child.parent, root)
	assert_eq(root.get_children(), [child])
	assert_signal_emitted_with_parameters(root, "child_added", [child])


func test_add_reparents_by_removing_from_previous_parent() -> void:
	var first: UIElement = UIElement.new(0, "first")
	var second: UIElement = UIElement.new(1, "second")
	var child: UIElement = UIElement.new(2, "child")
	first.add(child)
	_watch_element(second)
	second.add(child)
	assert_true(first.get_children().is_empty())
	assert_same(child.parent, second)
	assert_eq(second.get_children(), [child])


func test_add_self_is_rejected() -> void:
	var root: UIElement = UIElement.new(0, "root")
	_watch_element(root)
	root.add(root)
	assert_push_error_count(1, "adding itself emits an error")
	assert_signal_not_emitted(root, "child_added")
	assert_same(root.parent, null)


func test_add_ancestor_creates_error_and_is_rejected() -> void:
	var grandparent: UIElement = UIElement.new(0, "grandparent")
	var parent: UIElement = UIElement.new(1, "parent")
	var child: UIElement = UIElement.new(2, "child")
	grandparent.add(parent)
	parent.add(child)
	_watch_element(child)
	child.add(grandparent)
	assert_push_error_count(1, "adding an ancestor emits an error")
	assert_signal_not_emitted(child, "child_added")
	assert_same(grandparent.parent, null)


func test_duplicate_add_is_a_no_op() -> void:
	var root: UIElement = UIElement.new(0, "root")
	var child: UIElement = UIElement.new(1, "child")
	root.add(child)
	_watch_element(root)
	root.add(child)
	assert_signal_not_emitted(root, "child_added")
	assert_eq(root.get_children(), [child])


func test_remove_detaches_child_and_emits_signal() -> void:
	var root: UIElement = UIElement.new(0, "root")
	var child: UIElement = UIElement.new(1, "child")
	root.add(child)
	_watch_element(root)
	root.remove(child)
	assert_true(root.get_children().is_empty())
	assert_same(child.parent, null)
	assert_signal_emitted_with_parameters(root, "child_removed", [child])


func test_remove_non_child_emits_error() -> void:
	var root: UIElement = UIElement.new(0, "root")
	var stranger: UIElement = UIElement.new(1, "stranger")
	_watch_element(root)
	root.remove(stranger)
	assert_push_error_count(1, "removing a non-child emits an error")
	assert_signal_not_emitted(root, "child_removed")


func test_clear_removes_all_children() -> void:
	var root: UIElement = UIElement.new(0, "root")
	var a: UIElement = UIElement.new(1, "a")
	var b: UIElement = UIElement.new(2, "b")
	root.add(a)
	root.add(b)
	_watch_element(root)
	root.clear()
	assert_true(root.get_children().is_empty())
	assert_same(a.parent, null)
	assert_same(b.parent, null)
	assert_eq(_child_events, ["removed", "removed"] as Array[String])


func test_get_children_returns_copy_in_insertion_order() -> void:
	var root: UIElement = UIElement.new(0, "root")
	var a: UIElement = UIElement.new(1, "a")
	var b: UIElement = UIElement.new(2, "b")
	root.add(a)
	root.add(b)
	var children := root.get_children()
	assert_same(children[0], a)
	assert_same(children[1], b)
	children.clear()
	assert_eq(root.get_children().size(), 2)


func test_property_setter_emits_changed_with_property_name() -> void:
	var element: UIElement = UIElement.new(0, "element")
	_watch_element(element)
	element.visible = false
	element.position = Vector2(10, 20)
	element.modulate = 0.5
	assert_eq(_property_events, [&"visible", &"position", &"modulate"])


func test_assigning_same_value_does_not_emit_changed() -> void:
	var element: UIElement = UIElement.new(0, "element")
	_watch_element(element)
	element.visible = true
	element.position = Vector2.ZERO
	element.modulate = 1.0
	assert_signal_not_emitted(element, "changed")
	assert_eq(_property_events.size(), 0)


func test_default_values_are_neutral() -> void:
	var element: UIElement = UIElement.new(0, "element")
	assert_true(element.visible)
	assert_true(element.enabled)
	assert_eq(element.position, Vector2.ZERO)
	assert_eq(element.size, Vector2.ZERO)
	assert_eq(element.scale, Vector2.ONE)
	assert_eq(element.z_index, 0)
	assert_eq(element.modulate, 1.0)
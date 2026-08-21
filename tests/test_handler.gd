extends GutTest


enum TestElementId { FIRST, SECOND }


func test_add_and_lookup_by_id() -> void:
	var handler := Handler.new()
	var element := Element.new(TestElementId.FIRST, "First")
	handler.add(element)
	assert_eq(handler.lookup_by_id(TestElementId.FIRST), element)


func test_contains() -> void:
	var handler := Handler.new()
	assert_false(handler.contains(TestElementId.FIRST))
	handler.add(Element.new(TestElementId.FIRST, "First"))
	assert_true(handler.contains(TestElementId.FIRST))


func test_remove() -> void:
	var handler := Handler.new()
	var element := Element.new(TestElementId.FIRST, "First")
	handler.add(element)
	handler.remove(element)
	assert_false(handler.contains(TestElementId.FIRST))


func test_clear_removes_all_elements() -> void:
	var handler := Handler.new()
	handler.add(Element.new(TestElementId.FIRST, "First"))
	handler.add(Element.new(TestElementId.SECOND, "Second"))
	handler.clear()
	assert_eq(handler.get_elements().size(), 0)


func test_get_value_and_set_value() -> void:
	var handler := Handler.new()
	var element := Element.new(TestElementId.FIRST, "First")
	handler.set_value(TestElementId.FIRST, element)
	assert_eq(handler.get_value(TestElementId.FIRST), element)


func test_set_value_replaces_previous_element() -> void:
	var handler := Handler.new()
	var first := Element.new(TestElementId.FIRST, "First")
	var replacement := Element.new(TestElementId.FIRST, "Replacement")
	handler.add(first)
	handler.set_value(TestElementId.FIRST, replacement)
	assert_eq(handler.get_value(TestElementId.FIRST), replacement)


func test_get_elements_returns_all() -> void:
	var handler := Handler.new()
	handler.add(Element.new(TestElementId.FIRST, "First"))
	handler.add(Element.new(TestElementId.SECOND, "Second"))
	assert_eq(handler.get_elements().size(), 2)


func test_lookup_unknown_id_returns_null() -> void:
	var handler := Handler.new()
	assert_null(handler.lookup_by_id(TestElementId.FIRST))
extends GutTest


enum TestElementId { FIRST }


func test_stores_id_and_name() -> void:
	var element := Element.new(TestElementId.FIRST, "First")
	assert_eq(element.id, TestElementId.FIRST)
	assert_eq(element.name, "First")


func test_string_representation_contains_name_and_id() -> void:
	var element := Element.new(TestElementId.FIRST, "First")
	assert_eq(str(element), "First(0)")
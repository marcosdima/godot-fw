extends GutTest


enum TestAttributeId { HEALTH, SPEED }


func test_add_and_get_attribute() -> void:
	var status := Status.new()
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	status.add_attribute(attribute)
	assert_eq(status.get_attribute(TestAttributeId.HEALTH), attribute)


func test_has_attribute() -> void:
	var status := Status.new()
	assert_false(status.has_attribute(TestAttributeId.HEALTH))
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	assert_true(status.has_attribute(TestAttributeId.HEALTH))


func test_remove_attribute() -> void:
	var status := Status.new()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	status.remove_attribute(TestAttributeId.HEALTH)
	assert_null(status.get_attribute(TestAttributeId.HEALTH))


func test_get_attributes_returns_all() -> void:
	var status := Status.new()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	status.add_attribute(Attribute.new(TestAttributeId.SPEED, "Speed", 10.0))
	assert_eq(status.get_attributes().size(), 2)


func test_get_unknown_attribute_returns_null() -> void:
	var status := Status.new()
	assert_null(status.get_attribute(TestAttributeId.HEALTH))


func test_modify_attribute_adds_delta_to_current_value() -> void:
	var status := Status.new()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	assert_true(status.modify_attribute(TestAttributeId.HEALTH, -5.0))
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 95.0)


func test_modify_attribute_respects_min_value() -> void:
	var status := Status.new()
	status.add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 10.0, 0.0))
	assert_true(status.modify_attribute(TestAttributeId.HEALTH, -40.0))
	assert_eq(status.get_attribute(TestAttributeId.HEALTH).current_value, 0.0)


func test_modify_unknown_attribute_returns_false() -> void:
	var status := Status.new()
	assert_false(status.modify_attribute(TestAttributeId.HEALTH, -5.0))
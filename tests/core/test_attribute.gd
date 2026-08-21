extends GutTest


enum TestAttributeId { HEALTH }
enum TestModifierId { SLOW }


func test_initializes_base_and_current_value() -> void:
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	assert_eq(attribute.base_value, 100.0)
	assert_eq(attribute.current_value, 100.0)


func test_effective_value_equals_current_value_without_modifiers() -> void:
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	assert_eq(attribute.get_effective_value(), 100.0)


func test_effective_value_sums_active_modifiers() -> void:
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	attribute.add_modifier(Modifier.new(TestModifierId.SLOW, "Slow", -40.0))
	assert_eq(attribute.get_effective_value(), 60.0)


func test_effective_value_sums_multiple_modifiers() -> void:
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	attribute.add_modifier(Modifier.new(TestModifierId.SLOW, "Slow", -40.0))
	attribute.add_modifier(Modifier.new(TestModifierId.SLOW, "Slow", -10.0))
	assert_eq(attribute.get_effective_value(), 50.0)


func test_removing_modifier_restores_previous_effective_value() -> void:
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	var modifier := Modifier.new(TestModifierId.SLOW, "Slow", -40.0)
	attribute.add_modifier(modifier)
	attribute.remove_modifier(modifier)
	assert_eq(attribute.get_effective_value(), 100.0)
extends GutTest


enum TestProgressionId { FIRE_RESISTANCE, KNIFE_PROFICIENCY }


func test_stores_and_returns_progression_values() -> void:
	var progression := Progression.new()
	assert_eq(progression.get_value(TestProgressionId.FIRE_RESISTANCE), 0)
	assert_false(progression.contains(TestProgressionId.FIRE_RESISTANCE))
	progression.set_value(TestProgressionId.FIRE_RESISTANCE, 3)
	assert_true(progression.contains(TestProgressionId.FIRE_RESISTANCE))
	assert_eq(progression.get_value(TestProgressionId.FIRE_RESISTANCE), 3)


func test_advance_creates_the_progression_when_absent() -> void:
	var progression := Progression.new()
	progression.advance(TestProgressionId.FIRE_RESISTANCE)
	assert_eq(progression.get_value(TestProgressionId.FIRE_RESISTANCE), 1)


func test_advance_accumulates_on_the_existing_value() -> void:
	var progression := Progression.new()
	progression.set_value(TestProgressionId.FIRE_RESISTANCE, 2)
	progression.advance(TestProgressionId.FIRE_RESISTANCE, 3)
	assert_eq(progression.get_value(TestProgressionId.FIRE_RESISTANCE), 5)


func test_progressions_are_independent() -> void:
	var progression := Progression.new()
	progression.set_value(TestProgressionId.FIRE_RESISTANCE, 3)
	assert_eq(progression.get_value(TestProgressionId.KNIFE_PROFICIENCY), 0)
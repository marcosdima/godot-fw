extends GutTest


enum TestProgressionId { FIRE_RESISTANCE }


func test_participates_in_no_pipeline_phase() -> void:
	var progression_module := ProgressionModule.new(Entity.new("TestEntity"))
	assert_eq(progression_module._get_phase_callbacks().size(), 0)


func test_progression_module_owns_progression() -> void:
	var progression_module := ProgressionModule.new(Entity.new("TestEntity"))
	progression_module.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, 2)
	assert_eq(progression_module.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE), 2)


func test_entity_access_creates_the_progression_module_lazily_and_reuses_it() -> void:
	var entity := Entity.new("TestEntity")
	var progression := entity.modules.progression.get_progression()
	assert_same(entity.modules.progression.get_progression(), progression)
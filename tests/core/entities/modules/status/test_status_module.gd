extends GutTest


enum TestAttributeId { HEALTH }


func test_participates_in_no_pipeline_phase() -> void:
	var status_module := StatusModule.new(Entity.new("TestEntity"))
	assert_eq(status_module._get_phase_callbacks().size(), 0)


func test_status_module_owns_a_status() -> void:
	var status_module := StatusModule.new(Entity.new("TestEntity"))
	var attribute := Attribute.new(TestAttributeId.HEALTH, "Health", 100.0)
	status_module.get_status().add_attribute(attribute)
	assert_same(status_module.get_status().get_attribute(TestAttributeId.HEALTH), attribute)


func test_entity_access_creates_the_status_module_lazily_and_reuses_it() -> void:
	var entity := Entity.new("TestEntity")
	var status := entity.get_modules().status.get_status()
	assert_same(entity.get_modules().status.get_status(), status)
extends GutTest


func test_pipeline_can_be_created_and_updated() -> void:
	var pipeline := UpdatePipeline.new()
	pipeline.update()
	assert_true(true)


func test_phase_enum_is_deliberately_empty() -> void:
	assert_eq(UpdatePipeline.Phase.size(), 0)
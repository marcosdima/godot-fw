extends GutTest


func test_pipeline_can_be_created_and_updated() -> void:
	var pipeline := UpdatePipeline.new()
	pipeline.update()
	assert_true(true)


func test_state_phase_is_the_currently_defined_phase() -> void:
	assert_eq(UpdatePipeline.Phase.size(), 1)
	assert_true(UpdatePipeline.Phase.has("STATE"))


func test_phase_signal_returns_the_signal_of_the_phase() -> void:
	var pipeline := UpdatePipeline.new()
	assert_eq(pipeline.phase_signal(UpdatePipeline.Phase.STATE), pipeline.phase_signal(UpdatePipeline.Phase.STATE))


func test_update_emits_connected_callbacks_on_every_cycle() -> void:
	var pipeline := UpdatePipeline.new()
	var ticks := []
	pipeline.phase_signal(UpdatePipeline.Phase.STATE).connect(func() -> void: ticks.append(true))
	pipeline.update()
	assert_eq(ticks.size(), 1)
	pipeline.update()
	assert_eq(ticks.size(), 2)


func test_phase_signals_receive_no_arguments() -> void:
	var pipeline := UpdatePipeline.new()
	var received := []
	pipeline.phase_signal(UpdatePipeline.Phase.STATE).connect(func(argument = "sentinel") -> void: received.append(argument))
	pipeline.update()
	assert_eq(received.size(), 1)
	assert_eq(received[0], "sentinel")
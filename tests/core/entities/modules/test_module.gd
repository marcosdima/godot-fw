extends GutTest


class TrackingModule extends Module:
	var ticks: Array = []


	func _get_phase_callbacks() -> Array[PhaseCallback]:
		return [PhaseCallback.new(UpdatePipeline.Phase.STATE, _tick)]


	func _tick() -> void:
		ticks.append(true)


func test_base_module_declares_no_phase_participation() -> void:
	var module := Module.new(Entity.new("TestEntity"))
	assert_eq(module._get_phase_callbacks().size(), 0)


func test_attach_without_world_connects_nothing() -> void:
	var world := World.new()
	var entity := Entity.new("TestEntity")
	var module := TrackingModule.new(entity)
	module.attach()
	world.update()
	assert_eq(module.ticks.size(), 0)


func test_attach_connects_to_the_world_pipeline() -> void:
	var world := World.new()
	var entity := world.spawn("TestEntity")
	var module := TrackingModule.new(entity)
	module.attach()
	world.update()
	world.update()
	assert_eq(module.ticks.size(), 2)


func test_detach_disconnects_from_the_world_pipeline() -> void:
	var world := World.new()
	var entity := world.spawn("TestEntity")
	var module := TrackingModule.new(entity)
	module.attach()
	module.detach()
	world.update()
	assert_eq(module.ticks.size(), 0)
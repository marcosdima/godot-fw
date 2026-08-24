extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }
enum TestRuleId { IDLE_BURN }


func test_world_update_ticks_the_state_module_through_the_pipeline() -> void:
	var world := World.new()
	var entity := world.spawn("Hero")
	var state := entity.get_modules().state
	state.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	var burn := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	burn.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestAttributeId.HEALTH, -5.0)))
	state.add_condition(burn)
	world.update()
	var health := state.get_status().get_attribute(TestAttributeId.HEALTH)
	assert_eq(health.current_value, 95.0)


func test_set_world_moves_the_connection_to_the_new_world_pipeline() -> void:
	var world_a := World.new()
	var world_b := World.new()
	var entity := world_a.spawn("Traveler")
	var state := entity.get_modules().state
	state.add_condition(Condition.new(TestConditionId.BURN, "Burn", 10.0))
	state.add_rule(IdleRule.new(TestRuleId.IDLE_BURN, "IdleBurn", 0, TestConditionId.BURN, 0.5))
	world_a.update()
	assert_eq(state.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 5.0)
	entity.set_world(world_b)
	world_a.update()
	assert_eq(state.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 5.0)
	world_b.update()
	assert_eq(state.get_condition_handler().get_condition(TestConditionId.BURN).intensity, 2.5)
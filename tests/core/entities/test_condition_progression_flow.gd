extends GutTest


const ConstantApplication := preload("res://tests/helpers/constant_application.gd")


enum TestAttributeId { HEALTH }
enum TestEffectKind { FIRE }
enum TestConditionId { BURN }
enum TestApplicationId { FIRE_DAMAGE }
enum TestProgressionId { FIRE_RESISTANCE }

const REJECTION_RESISTANCE_THRESHOLD := 10


class FireConditionResolver extends ConditionResolver:
	func resolve(condition: Condition) -> Condition:
		if condition.id == TestConditionId.BURN:
			var resistance := entity.modules.progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE)
			if resistance >= REJECTION_RESISTANCE_THRESHOLD:
				return null
		return condition


class FireDamageEffectResolver extends EffectResolver:
	func resolve(effect: Effect) -> Effect:
		if effect.kind != TestEffectKind.FIRE:
			return effect
		var resistance := entity.modules.progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE)
		if resistance == 0:
			return effect
		return Effect.new(effect.kind, effect.target, effect.value + resistance)


func _create_entity(p_advance_resistance_on_fire: bool = true) -> Entity:
	var entity := Entity.new("TestEntity")
	entity.modules.status.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	entity.resolvers.condition = FireConditionResolver.new(entity)
	entity.resolvers.effect = FireDamageEffectResolver.new(entity)
	if p_advance_resistance_on_fire:
		entity.modules.state.effect_applied.connect(_on_fire_effect_applied.bind(entity))
	return entity


func _on_fire_effect_applied(effect: Effect, entity: Entity) -> void:
	if effect.kind == TestEffectKind.FIRE:
		entity.modules.progression.get_progression().advance(TestProgressionId.FIRE_RESISTANCE, 1)


func _create_burn() -> Condition:
	var burn := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	burn.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	return burn


func _get_health(entity: Entity) -> Attribute:
	return entity.modules.status.get_status().get_attribute(TestAttributeId.HEALTH)


func _get_fire_resistance(entity: Entity) -> int:
	return entity.modules.progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE)


func test_low_resistance_lets_burn_in_with_full_damage() -> void:
	var entity := _create_entity()
	entity.modules.progression.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, 0)
	var state := entity.modules.state
	watch_signals(state)
	state.add_condition(_create_burn())
	state.tick()
	assert_not_null(state.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_signal_emitted(state, "condition_added")
	assert_eq(_get_health(entity).current_value, 95.0)
	assert_eq(_get_fire_resistance(entity), 1)


func test_intermediate_resistance_reduces_the_fire_damage() -> void:
	var entity := _create_entity()
	entity.modules.progression.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, 2)
	var state := entity.modules.state
	state.add_condition(_create_burn())
	state.tick()
	assert_eq(_get_health(entity).current_value, 97.0)
	assert_eq(_get_fire_resistance(entity), 3)
	state.tick()
	assert_eq(_get_health(entity).current_value, 95.0)
	assert_eq(_get_fire_resistance(entity), 4)


func test_high_resistance_rejects_the_burn_condition() -> void:
	var entity := _create_entity()
	entity.modules.progression.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, REJECTION_RESISTANCE_THRESHOLD)
	var state := entity.modules.state
	watch_signals(state)
	state.add_condition(_create_burn())
	state.tick()
	assert_null(state.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_signal_not_emitted(state, "condition_added")
	assert_signal_not_emitted(state, "effect_applied")
	assert_eq(_get_health(entity).current_value, 100.0)
	assert_eq(_get_fire_resistance(entity), REJECTION_RESISTANCE_THRESHOLD)


func test_state_module_does_not_need_progression_to_process_effects() -> void:
	var entity := _create_entity(false)
	entity.modules.progression.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, 1)
	var state := entity.modules.state
	state.add_condition(_create_burn())
	state.tick()
	assert_eq(_get_health(entity).current_value, 96.0)
	assert_eq(_get_fire_resistance(entity), 1)
	state.tick()
	assert_eq(_get_health(entity).current_value, 92.0)
	assert_eq(_get_fire_resistance(entity), 1)
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
			var resistance := entity.get_modules().progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE)
			if resistance >= REJECTION_RESISTANCE_THRESHOLD:
				return null
		return condition


class FireDamageEffectResolver extends EffectResolver:
	func resolve(effect: Effect) -> Effect:
		if effect.kind != TestEffectKind.FIRE:
			return effect
		var resistance := entity.get_modules().progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE)
		if resistance == 0:
			return effect
		return Effect.new(effect.kind, effect.target, effect.value + resistance)


func _create_entity() -> Entity:
	var entity := Entity.new("TestEntity")
	entity.get_modules().status.get_status().add_attribute(Attribute.new(TestAttributeId.HEALTH, "Health", 100.0))
	entity.get_resolvers().condition = FireConditionResolver.new(entity)
	entity.get_resolvers().effect = FireDamageEffectResolver.new(entity)
	var state := entity.get_modules().state
	state.effect_applied.connect(_on_fire_effect_applied.bind(entity))
	return entity


func _on_fire_effect_applied(effect: Effect, entity: Entity) -> void:
	if effect.kind == TestEffectKind.FIRE:
		entity.get_modules().progression.get_progression().advance(TestProgressionId.FIRE_RESISTANCE, 1)


func _create_burn() -> Condition:
	var burn := Condition.new(TestConditionId.BURN, "Burn", 10.0)
	burn.add_effect_application(ConstantApplication.new(TestApplicationId.FIRE_DAMAGE, "FireDamage", 1, Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)))
	return burn


func test_burn_applies_reduced_fire_damage_and_advances_resistance() -> void:
	var entity := _create_entity()
	entity.get_modules().progression.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, 2)
	var state := entity.get_modules().state
	state.add_condition(_create_burn())
	state.tick()
	assert_eq(entity.get_modules().status.get_status().get_attribute(TestAttributeId.HEALTH).current_value, 97.0)
	assert_eq(entity.get_modules().progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE), 3)
	state.tick()
	assert_eq(entity.get_modules().status.get_status().get_attribute(TestAttributeId.HEALTH).current_value, 95.0)
	assert_eq(entity.get_modules().progression.get_progression().get_value(TestProgressionId.FIRE_RESISTANCE), 4)


func test_enough_resistance_rejects_the_burn_condition() -> void:
	var entity := _create_entity()
	entity.get_modules().progression.get_progression().set_value(TestProgressionId.FIRE_RESISTANCE, REJECTION_RESISTANCE_THRESHOLD)
	var state := entity.get_modules().state
	watch_signals(state)
	state.add_condition(_create_burn())
	state.tick()
	assert_null(state.get_condition_handler().get_condition(TestConditionId.BURN))
	assert_signal_not_emitted(state, "condition_added")
	assert_signal_not_emitted(state, "effect_applied")
	assert_eq(entity.get_modules().status.get_status().get_attribute(TestAttributeId.HEALTH).current_value, 100.0)
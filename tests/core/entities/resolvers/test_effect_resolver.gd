extends GutTest


enum TestAttributeId { HEALTH }
enum TestEffectKind { FIRE }


class HalvingEffectResolver extends EffectResolver:
	func resolve(effect: Effect) -> Effect:
		return Effect.new(effect.kind, effect.target, effect.value * 0.5)


class RejectingEffectResolver extends EffectResolver:
	func resolve(effect: Effect) -> Effect:
		return null


func test_base_resolver_returns_the_effect_unchanged() -> void:
	var effect := Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)
	var resolver := EffectResolver.new(Entity.new("TestEntity"))
	assert_same(resolver.resolve(effect), effect)


func test_resolver_is_bound_to_its_entity() -> void:
	var entity := Entity.new("TestEntity")
	var resolver := EffectResolver.new(entity)
	assert_same(resolver.entity, entity)


func test_entity_provides_a_resolvers_facade_with_an_effect_resolver() -> void:
	var entity := Entity.new("TestEntity")
	assert_same(entity.get_resolvers().effect.entity, entity)


func test_subclass_can_modify_the_effect() -> void:
	var effect := Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)
	var resolver := HalvingEffectResolver.new(Entity.new("TestEntity"))
	var resolved := resolver.resolve(effect)
	assert_eq(resolved.kind, TestEffectKind.FIRE)
	assert_eq(resolved.target, TestAttributeId.HEALTH)
	assert_eq(resolved.value, -2.5)


func test_subclass_can_reject_the_effect() -> void:
	var effect := Effect.new(TestEffectKind.FIRE, TestAttributeId.HEALTH, -5.0)
	var resolver := RejectingEffectResolver.new(Entity.new("TestEntity"))
	assert_null(resolver.resolve(effect))